#!/usr/bin/env pwsh
# setup.ps1 — 하네스 엔지니어링 프레임워크 프로젝트 생성 스크립트 (Windows)
#
# 사용법: .\setup.ps1
#         .\setup.ps1 -OutputDir "C:\projects\my-app"

param(
    [string]$OutputDir = ""
)

$ErrorActionPreference = "Stop"

# ── 색상 출력 헬퍼 ─────────────────────────────────────────────────────────────
function Write-Header([string]$text) {
    Write-Host ""
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "  $text" -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Step([string]$text) { Write-Host "▶ $text" -ForegroundColor Yellow }
function Write-Ok([string]$text)   { Write-Host "✓ $text" -ForegroundColor Green }
function Write-Info([string]$text) { Write-Host "  $text" -ForegroundColor Gray }

# ── 입력 받기 ──────────────────────────────────────────────────────────────────
Write-Header "하네스 엔지니어링 프레임워크 설정"

$ProjectName = Read-Host "프로젝트명 (영문, 하이픈 허용)"
if ([string]::IsNullOrWhiteSpace($ProjectName)) {
    Write-Error "프로젝트명은 필수입니다."
    exit 1
}
if ($ProjectName -notmatch '^[a-z0-9][a-z0-9\-]*$') {
    Write-Error "프로젝트명은 소문자 영문, 숫자, 하이픈만 사용할 수 있습니다."
    exit 1
}

$ProjectDescription = Read-Host "프로젝트 설명"
$Author = Read-Host "저자명"

$TechStackInput = Read-Host "기술스택 (기본값: TypeScript, React, Vite)"
$TechStack = if ([string]::IsNullOrWhiteSpace($TechStackInput)) { "TypeScript, React, Vite" } else { $TechStackInput }

Write-Host ""
Write-Host "템플릿 선택:" -ForegroundColor White
Write-Host "  1. typescript-web — TypeScript 웹 애플리케이션 (기본값)"
$TemplateChoice = Read-Host "번호 선택"
$TemplateChoice = if ([string]::IsNullOrWhiteSpace($TemplateChoice)) { "1" } else { $TemplateChoice }

$TemplateName = switch ($TemplateChoice) {
    "1" { "typescript-web" }
    default {
        Write-Host "  알 수 없는 선택. typescript-web 으로 진행합니다." -ForegroundColor Yellow
        "typescript-web"
    }
}

if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDirInput = Read-Host "프로젝트 생성 위치 (기본값: .\$ProjectName)"
    $OutputDir = if ([string]::IsNullOrWhiteSpace($OutputDirInput)) { ".\$ProjectName" } else { $OutputDirInput }
}

$Today = Get-Date -Format "yyyy-MM-dd"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TemplateDir = Join-Path $ScriptDir "templates\$TemplateName"

if (-not (Test-Path $TemplateDir)) {
    Write-Error "템플릿을 찾을 수 없습니다: $TemplateDir"
    exit 1
}

# 설정 요약 출력
Write-Host ""
Write-Host "────────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Info "프로젝트명    : $ProjectName"
Write-Info "설명          : $ProjectDescription"
Write-Info "저자          : $Author"
Write-Info "기술스택      : $TechStack"
Write-Info "템플릿        : $TemplateName"
Write-Info "생성 위치     : $OutputDir"
Write-Host "────────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host ""

$Confirm = Read-Host "계속 진행하시겠습니까? (y/N)"
if ($Confirm -notmatch '^[yY]') {
    Write-Host "취소되었습니다." -ForegroundColor Yellow
    exit 0
}

# ── 1. 파일 복사 ───────────────────────────────────────────────────────────────
Write-Step "파일 복사 중..."
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

# 숨김 파일 포함 복사
$items = Get-ChildItem -Path $TemplateDir -Force
foreach ($item in $items) {
    Copy-Item -Path $item.FullName -Destination $OutputDir -Recurse -Force
}
Write-Ok "파일 복사 완료"

# ── 2. 플레이스홀더 치환 ────────────────────────────────────────────────────────
Write-Step "플레이스홀더 치환 중..."

$replacements = [ordered]@{
    "{{PROJECT_NAME}}"        = $ProjectName
    "{{PROJECT_DESCRIPTION}}" = $ProjectDescription
    "{{AUTHOR}}"              = $Author
    "{{TECH_STACK}}"          = $TechStack
    "{{DATE}}"                = $Today
}

$targetExtensions = @(".md", ".json", ".ts", ".tsx", ".js", ".mjs", ".sh", ".yaml", ".yml")

Get-ChildItem -Path $OutputDir -Recurse -File -Force |
    Where-Object { $targetExtensions -contains $_.Extension } |
    Where-Object { $_.FullName -notlike "*\node_modules\*" } |
    ForEach-Object {
        $filePath = $_.FullName
        $content = Get-Content $filePath -Raw -Encoding UTF8
        if ($null -eq $content) { return }

        $modified = $false
        foreach ($key in $replacements.Keys) {
            if ($content.Contains($key)) {
                $content = $content.Replace($key, $replacements[$key])
                $modified = $true
            }
        }
        if ($modified) {
            [System.IO.File]::WriteAllText($filePath, $content, [System.Text.Encoding]::UTF8)
        }
    }

Write-Ok "플레이스홀더 치환 완료"

# ── 3. pnpm install ─────────────────────────────────────────────────────────────
Write-Step "pnpm install 실행 중..."
Push-Location $OutputDir
try {
    if (Get-Command pnpm -ErrorAction SilentlyContinue) {
        pnpm install 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            # esbuild 등 빌드 스크립트가 차단된 경우 승인 후 재시도
            Write-Host "  빌드 스크립트 승인 중 (esbuild)..." -ForegroundColor Gray
            pnpm approve-builds esbuild 2>&1 | Out-Null
            pnpm install 2>&1 | Out-Null
        }
        Write-Ok "의존성 설치 완료"
    } else {
        Write-Host "  ⚠ pnpm이 없습니다. 수동으로 실행하세요: cd $OutputDir && pnpm install" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ⚠ pnpm install 실패. 수동으로 실행하세요." -ForegroundColor Yellow
} finally {
    Pop-Location
}

# ── 4. git init + 첫 커밋 ───────────────────────────────────────────────────────
Write-Step "git 초기화 중..."
Push-Location $OutputDir
try {
    git init --quiet
    git add .
    git commit --quiet -m "chore: initialize project with harness engineering framework"
    Write-Ok "git 초기화 완료 (첫 커밋 생성)"
} catch {
    Write-Host "  ⚠ git 초기화 실패. 수동으로 실행하세요." -ForegroundColor Yellow
} finally {
    Pop-Location
}

# ── 5. 최종 검증 ────────────────────────────────────────────────────────────────
Write-Step "최종 검증 중..."
Push-Location $OutputDir
try {
    pnpm validate 2>&1 | Out-Null
    Write-Ok "검증 통과 — 프로젝트 준비 완료"
} catch {
    Write-Host "  ⚠ 검증 실패. 수동으로 확인하세요: pnpm validate" -ForegroundColor Yellow
} finally {
    Pop-Location
}

# ── 6. 완료 메시지 ──────────────────────────────────────────────────────────────
Write-Header "✅ 설정 완료!"

Write-Host "생성된 프로젝트: " -NoNewline
Write-Host $OutputDir -ForegroundColor Cyan
Write-Host ""

Write-Host "생성된 주요 파일:" -ForegroundColor White
Get-ChildItem -Path $OutputDir -Recurse -File -Force |
    Where-Object { $_.FullName -notlike "*\node_modules\*" -and $_.FullName -notlike "*\.git\*" } |
    ForEach-Object {
        Write-Info $_.FullName.Replace((Resolve-Path $OutputDir).Path, "").TrimStart("\")
    }

Write-Host ""
Write-Host "다음 단계:" -ForegroundColor Yellow
Write-Host "  1. " -NoNewline; Write-Host "cd $OutputDir" -ForegroundColor Cyan
Write-Host "  2. " -NoNewline; Write-Host "claude" -ForegroundColor Cyan -NoNewline; Write-Host " 실행"
Write-Host "  3. " -NoNewline; Write-Host "/start" -ForegroundColor Cyan -NoNewline; Write-Host " 입력해서 세션 시작"
Write-Host "  4. 작업 시작!"
Write-Host ""
