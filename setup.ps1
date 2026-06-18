#!/usr/bin/env pwsh
# setup.ps1 — 하네스 엔지니어링 프레임워크 프로젝트 생성 (Windows)
#
# 사용법: .\setup.ps1
#         .\setup.ps1 -OutputDir "C:\projects\my-app"

param([string]$OutputDir = "")

$ErrorActionPreference = "Stop"

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
if ([string]::IsNullOrWhiteSpace($ProjectName)) { Write-Error "프로젝트명은 필수입니다."; exit 1 }
if ($ProjectName -notmatch '^[a-z0-9][a-z0-9\-]*$') {
    Write-Error "프로젝트명은 소문자 영문, 숫자, 하이픈만 사용할 수 있습니다."
    exit 1
}

$ProjectDescription = Read-Host "프로젝트 설명"
$Author = Read-Host "저자명"

Write-Host ""
Write-Host "언어 선택:" -ForegroundColor White
Write-Host "  1. TypeScript (기본값)"
Write-Host "  2. Python"
Write-Host "  3. Java"
$LangChoice = Read-Host "번호 선택"

$Language = switch ($LangChoice) {
    "2" { "python" }
    "3" { "java" }
    default { "typescript" }
}
$LanguageDisplay = switch ($Language) {
    "python" { "Python" }
    "java"   { "Java" }
    default  { "TypeScript" }
}

$BasePackage = ""
if ($Language -eq "java") {
    $BasePackageInput = Read-Host "Java 기본 패키지 (예: com.example.myproject)"
    $SafeName = $ProjectName -replace '-', ''
    $BasePackage = if ([string]::IsNullOrWhiteSpace($BasePackageInput)) { "com.example.$SafeName" } else { $BasePackageInput }
}

if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDirInput = Read-Host "프로젝트 생성 위치 (기본값: .\$ProjectName)"
    $OutputDir = if ([string]::IsNullOrWhiteSpace($OutputDirInput)) { ".\$ProjectName" } else { $OutputDirInput }
}

$Today = Get-Date -Format "yyyy-MM-dd"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$HarnessCoreDir = Join-Path $ScriptDir "harness-core"
$LangPackDir    = Join-Path $ScriptDir "language-packs\$Language"

if (-not (Test-Path $HarnessCoreDir)) { Write-Error "harness-core/ 를 찾을 수 없습니다: $HarnessCoreDir"; exit 1 }
if (-not (Test-Path $LangPackDir))    { Write-Error "language-packs/$Language 를 찾을 수 없습니다: $LangPackDir"; exit 1 }

Write-Host ""
Write-Host "────────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Info "프로젝트명    : $ProjectName"
Write-Info "설명          : $ProjectDescription"
Write-Info "저자          : $Author"
Write-Info "언어          : $LanguageDisplay"
if ($Language -eq "java") { Write-Info "기본 패키지   : $BasePackage" }
Write-Info "생성 위치     : $OutputDir"
Write-Host "────────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host ""

$Confirm = Read-Host "계속 진행하시겠습니까? (y/N)"
if ($Confirm -notmatch '^[yY]') { Write-Host "취소되었습니다." -ForegroundColor Yellow; exit 0 }

# ── 1. harness-core 복사 ────────────────────────────────────────────────────────
Write-Step "harness-core 복사 중..."
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
foreach ($item in Get-ChildItem -Path $HarnessCoreDir -Force) {
    Copy-Item -Path $item.FullName -Destination $OutputDir -Recurse -Force
}
Write-Ok "harness-core 복사 완료"

# ── 2. 언어팩 복사 (harness-core 위에 덮어쓰기) ────────────────────────────────
Write-Step "$LanguageDisplay 언어팩 복사 중..."
foreach ($item in Get-ChildItem -Path $LangPackDir -Force) {
    Copy-Item -Path $item.FullName -Destination $OutputDir -Recurse -Force
}
Write-Ok "언어팩 복사 완료"

# ── 3. 언어별 규칙 → CLAUDE.md 치환 ────────────────────────────────────────────
Write-Step "언어별 규칙 적용 중..."

$LanguageRules = switch ($Language) {
    "typescript" {
'- `any` 금지 → `unknown` + 타입 가드
- 모든 함수에 반환 타입 명시 (`explicit-function-return-type`)
- `as` 단언은 불가피한 경우에만, 한국어 주석으로 이유 설명
- 파일명: `kebab-case.ts` / `.test.ts` / `.types.ts` / `.interface.ts`'
    }
    "python" {
'- 타입 힌트 필수 (Python 3.12+, `X | Y` union 스타일)
- `Any` 타입 금지 → 구체 타입 사용
- 모든 함수에 반환 타입 명시
- dataclass 또는 Pydantic 모델 우선 (dict 남발 금지)
- 파일명: `snake_case.py` / `test_*.py`'
    }
    "java" {
'- `null` 반환 금지 → `Optional<T>` 사용
- checked exception 남발 금지 → 도메인 예외는 unchecked
- record 클래스 우선 (불변 데이터, Java 16+)
- `var` 허용 (타입 추론이 명확한 경우만)
- 파일명: `PascalCase.java` / `*Test.java`'
    }
}

$BannedItems = switch ($Language) {
    "typescript" { '`any` · `@ts-ignore` · `@ts-nocheck` · `@ts-expect-error` · `console.log` · `eslint-disable` 남발' }
    "python"     { '`Any` · `# type: ignore` · `print()` (로깅 대신) · `pass` 남발' }
    "java"       { '`null` 반환 · raw type 사용 · `System.out.println` · `@SuppressWarnings` 남발' }
}

$claudePath = Join-Path $OutputDir "CLAUDE.md"
$claudeContent = [System.IO.File]::ReadAllText($claudePath, [System.Text.Encoding]::UTF8)
$claudeContent = $claudeContent.Replace('{{LANGUAGE_RULES}}', $LanguageRules)
$claudeContent = $claudeContent.Replace('{{BANNED_ITEMS}}', $BannedItems)
$claudeContent = $claudeContent.Replace('{{LANGUAGE_DISPLAY}}', $LanguageDisplay)
[System.IO.File]::WriteAllText($claudePath, $claudeContent, [System.Text.Encoding]::UTF8)
Write-Ok "언어별 규칙 적용 완료"

# ── 4. 표준 플레이스홀더 치환 ───────────────────────────────────────────────────
Write-Step "플레이스홀더 치환 중..."

$replacements = [ordered]@{
    "{{PROJECT_NAME}}"        = $ProjectName
    "{{PROJECT_DESCRIPTION}}" = $ProjectDescription
    "{{AUTHOR}}"              = $Author
    "{{DATE}}"                = $Today
}

$targetExts = @(".md", ".json", ".ts", ".tsx", ".js", ".mjs", ".sh", ".yaml", ".yml", ".toml", ".xml", ".java")

Get-ChildItem -Path $OutputDir -Recurse -File -Force |
    Where-Object { $targetExts -contains $_.Extension } |
    Where-Object { $_.FullName -notlike "*\node_modules\*" -and $_.FullName -notlike "*\target\*" } |
    ForEach-Object {
        $fp = $_.FullName
        $fc = Get-Content $fp -Raw -Encoding UTF8
        if ($null -eq $fc) { return }
        $modified = $false
        foreach ($key in $replacements.Keys) {
            if ($fc.Contains($key)) { $fc = $fc.Replace($key, $replacements[$key]); $modified = $true }
        }
        if ($modified) { [System.IO.File]::WriteAllText($fp, $fc, [System.Text.Encoding]::UTF8) }
    }

Write-Ok "플레이스홀더 치환 완료"

# ── 5. Java: 패키지 디렉터리 생성 ───────────────────────────────────────────────
if ($Language -eq "java") {
    Write-Step "Java 패키지 구조 생성 중..."
    $BasePkgPath = $BasePackage.Replace('.', '\')
    $JavaSrcRoot = Join-Path $OutputDir "src\main\java\$BasePkgPath"
    foreach ($layer in @("domain", "application", "infrastructure", "presentation")) {
        New-Item -ItemType Directory -Force -Path "$JavaSrcRoot\$layer" | Out-Null
        $pkgInfo = "/** $layer 레이어 */`npackage $BasePackage.$layer;`n"
        [System.IO.File]::WriteAllText("$JavaSrcRoot\$layer\package-info.java", $pkgInfo, [System.Text.Encoding]::UTF8)
    }
    $archTestPath = Join-Path $OutputDir "src\test\java\arch\DependencyTest.java"
    if (Test-Path $archTestPath) {
        $atContent = [System.IO.File]::ReadAllText($archTestPath, [System.Text.Encoding]::UTF8)
        $atContent = $atContent.Replace('{{BASE_PACKAGE}}', $BasePackage)
        [System.IO.File]::WriteAllText($archTestPath, $atContent, [System.Text.Encoding]::UTF8)
    }
    Write-Ok "Java 패키지 구조 생성 완료 ($BasePackage)"
}

# ── 6. 의존성 설치 ───────────────────────────────────────────────────────────────
Write-Step "의존성 설치 중..."
Push-Location $OutputDir
try {
    switch ($Language) {
        "typescript" {
            if (Get-Command pnpm -ErrorAction SilentlyContinue) {
                pnpm install 2>&1 | Out-Null
                if ($LASTEXITCODE -ne 0) {
                    Write-Host "  빌드 스크립트 승인 중 (esbuild)..." -ForegroundColor Gray
                    pnpm approve-builds esbuild 2>&1 | Out-Null
                    pnpm install 2>&1 | Out-Null
                }
                Write-Ok "pnpm install 완료"
            } else {
                Write-Host "  ⚠ pnpm이 없습니다. 수동으로 실행하세요: pnpm install" -ForegroundColor Yellow
            }
        }
        "python" {
            if (Get-Command uv -ErrorAction SilentlyContinue) {
                uv sync 2>&1 | Out-Null; Write-Ok "uv sync 완료"
            } elseif (Get-Command pip -ErrorAction SilentlyContinue) {
                pip install ruff mypy pytest pytest-cov --quiet 2>&1 | Out-Null; Write-Ok "pip install 완료"
            } else {
                Write-Host "  ⚠ uv 또는 pip를 설치하세요." -ForegroundColor Yellow
            }
        }
        "java" {
            if (Get-Command mvn -ErrorAction SilentlyContinue) {
                Write-Ok "Maven 확인됨 (첫 빌드 시 의존성 자동 다운로드)"
            } else {
                Write-Host "  ⚠ Maven(mvn)이 없습니다. Java 21+ 및 Maven 3.9+를 설치하세요." -ForegroundColor Yellow
            }
        }
    }
} catch {
    Write-Host "  ⚠ 의존성 설치 실패. 수동으로 확인하세요." -ForegroundColor Yellow
} finally {
    Pop-Location
}

# ── 7. git init + 첫 커밋 ───────────────────────────────────────────────────────
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

# ── 8. 완료 메시지 ──────────────────────────────────────────────────────────────
Write-Header "✅ 설정 완료!"
Write-Host "생성된 프로젝트: " -NoNewline; Write-Host $OutputDir -ForegroundColor Cyan
Write-Host ""
Write-Host "다음 단계:" -ForegroundColor Yellow
Write-Host "  1. " -NoNewline; Write-Host "cd $OutputDir" -ForegroundColor Cyan
Write-Host "  2. " -NoNewline; Write-Host "claude" -ForegroundColor Cyan -NoNewline; Write-Host " 실행"
Write-Host "  3. " -NoNewline; Write-Host "/start" -ForegroundColor Cyan -NoNewline; Write-Host " 입력해서 세션 시작"
Write-Host ""
