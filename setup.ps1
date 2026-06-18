#!/usr/bin/env pwsh
# setup.ps1 — Harness Engineering Framework project generator (Windows)
#
# Usage: .\setup.ps1
#        .\setup.ps1 -OutputDir "C:\projects\my-app"

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

# ── Collect input ──────────────────────────────────────────────────────────────
Write-Header "Harness Engineering Framework Setup"

$ProjectName = Read-Host "Project name (lowercase, hyphens allowed)"
if ([string]::IsNullOrWhiteSpace($ProjectName)) { Write-Error "Project name is required."; exit 1 }
if ($ProjectName -notmatch '^[a-z0-9][a-z0-9\-]*$') {
    Write-Error "Project name may only contain lowercase letters, numbers, and hyphens."
    exit 1
}

$ProjectDescription = Read-Host "Project description"
$Author = Read-Host "Author name"

Write-Host ""
Write-Host "Select language:" -ForegroundColor White
Write-Host "  1. TypeScript (default)"
Write-Host "  2. Python"
Write-Host "  3. Java"
$LangChoice = Read-Host "Enter number"

$Language = switch ($LangChoice.Trim().ToLower()) {
    { $_ -in "2", "python" }     { "python" }
    { $_ -in "3", "java" }       { "java" }
    default                       { "typescript" }
}
$LanguageDisplay = switch ($Language) {
    "python" { "Python" }
    "java"   { "Java" }
    default  { "TypeScript" }
}

$BasePackage = ""
if ($Language -eq "java") {
    $BasePackageInput = Read-Host "Java base package (e.g. com.example.myproject)"
    $SafeName = $ProjectName -replace '-', ''
    $BasePackage = if ([string]::IsNullOrWhiteSpace($BasePackageInput)) { "com.example.$SafeName" } else { $BasePackageInput }
}

if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDirInput = Read-Host "Output directory (default: .\$ProjectName)"
    $OutputDir = if ([string]::IsNullOrWhiteSpace($OutputDirInput)) { ".\$ProjectName" } else { $OutputDirInput }
}

$Today = Get-Date -Format "yyyy-MM-dd"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$utf8NoBom = New-Object System.Text.UTF8Encoding $false  # WriteAllText with Encoding.UTF8 emits a BOM; JSON.parse rejects it
$HarnessCoreDir = Join-Path $ScriptDir "harness-core"
$LangPackDir    = Join-Path $ScriptDir "language-packs\$Language"

if (-not (Test-Path $HarnessCoreDir)) { Write-Error "harness-core/ not found: $HarnessCoreDir"; exit 1 }
if (-not (Test-Path $LangPackDir))    { Write-Error "language-packs/$Language not found: $LangPackDir"; exit 1 }

Write-Host ""
Write-Host "────────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Info "Project name  : $ProjectName"
Write-Info "Description   : $ProjectDescription"
Write-Info "Author        : $Author"
Write-Info "Language      : $LanguageDisplay"
if ($Language -eq "java") { Write-Info "Base package  : $BasePackage" }
Write-Info "Output dir    : $OutputDir"
Write-Host "────────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host ""

$Confirm = Read-Host "Proceed? (y/N)"
if ($Confirm -notmatch '^[yY]') { Write-Host "Cancelled." -ForegroundColor Yellow; exit 0 }

# ── 1. Copy harness-core ────────────────────────────────────────────────────────
Write-Step "Copying harness-core..."
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
$OutputDir = (Resolve-Path $OutputDir).Path  # prevent .NET APIs from resolving relative paths against a different working directory than PowerShell
foreach ($item in Get-ChildItem -Path $HarnessCoreDir -Force) {
    Copy-Item -Path $item.FullName -Destination $OutputDir -Recurse -Force
}
Write-Ok "harness-core copied"

# ── 2. Copy language pack (overlay on top of harness-core) ─────────────────────
Write-Step "Copying $LanguageDisplay language pack..."
foreach ($item in Get-ChildItem -Path $LangPackDir -Force) {
    Copy-Item -Path $item.FullName -Destination $OutputDir -Recurse -Force
}
Write-Ok "Language pack copied"

# ── 3. Substitute language-specific rules into CLAUDE.md ───────────────────────
Write-Step "Applying language-specific rules..."

$LanguageRules = switch ($Language) {
    "typescript" {
'- No `any` → use `unknown` + type guards
- Explicit return type on every function (`explicit-function-return-type`)
- `as` assertions only when unavoidable; explain the reason in a comment
- File names: `kebab-case.ts` / `.test.ts` / `.types.ts` / `.interface.ts`'
    }
    "python" {
'- Type hints required (Python 3.12+, `X | Y` union style)
- No `Any` type → use concrete types
- Explicit return type on every function
- Prefer dataclass or Pydantic models (avoid overusing dict)
- File names: `snake_case.py` / `test_*.py`'
    }
    "java" {
'- No `null` returns → use `Optional<T>`
- Avoid checked exceptions → domain exceptions should be unchecked
- Prefer record classes (immutable data, Java 16+)
- `var` allowed only when type inference is clear
- File names: `PascalCase.java` / `*Test.java`'
    }
}

$BannedItems = switch ($Language) {
    "typescript" { '`any` · `@ts-ignore` · `@ts-nocheck` · `@ts-expect-error` · `console.log` · excessive `eslint-disable`' }
    "python"     { '`Any` · `# type: ignore` · `print()` (use logging instead) · excessive `pass`' }
    "java"       { '`null` returns · raw type usage · `System.out.println` · excessive `@SuppressWarnings`' }
}

$langFiles = @("CLAUDE.md", "AGENTS.md", ".cursorrules", ".windsurfrules", ".cursor\rules\harness.mdc")
foreach ($relPath in $langFiles) {
    $fp = Join-Path $OutputDir $relPath
    if (-not (Test-Path $fp)) { continue }
    $fc = [System.IO.File]::ReadAllText($fp, [System.Text.Encoding]::UTF8)
    $fc = $fc.Replace('{{LANGUAGE_RULES}}', $LanguageRules)
    $fc = $fc.Replace('{{BANNED_ITEMS}}', $BannedItems)
    $fc = $fc.Replace('{{LANGUAGE_DISPLAY}}', $LanguageDisplay)
    [System.IO.File]::WriteAllText($fp, $fc, $utf8NoBom)
}
Write-Ok "Language-specific rules applied"

# ── 4. Substitute standard placeholders ────────────────────────────────────────
Write-Step "Substituting placeholders..."

$replacements = [ordered]@{
    "{{PROJECT_NAME}}"        = $ProjectName
    "{{PROJECT_DESCRIPTION}}" = $ProjectDescription
    "{{AUTHOR}}"              = $Author
    "{{DATE}}"                = $Today
}

$targetExts  = @(".md", ".mdc", ".json", ".ts", ".tsx", ".js", ".mjs", ".sh", ".yaml", ".yml", ".toml", ".xml", ".java")
$targetNames = @("AGENTS.md", "CLAUDE.md", ".cursorrules", ".windsurfrules")

Get-ChildItem -Path $OutputDir -Recurse -File -Force |
    Where-Object { $targetExts -contains $_.Extension -or $targetNames -contains $_.Name } |
    Where-Object { $_.FullName -notlike "*\node_modules\*" -and $_.FullName -notlike "*\target\*" } |
    ForEach-Object {
        $fp = $_.FullName
        $fc = Get-Content $fp -Raw -Encoding UTF8
        if ($null -eq $fc) { return }
        $modified = $false
        foreach ($key in $replacements.Keys) {
            if ($fc.Contains($key)) { $fc = $fc.Replace($key, $replacements[$key]); $modified = $true }
        }
        if ($modified) { [System.IO.File]::WriteAllText($fp, $fc, $utf8NoBom) }
    }

Write-Ok "Placeholders substituted"

# ── 5. Java: create package directory structure ──────────────────────────────────
if ($Language -eq "java") {
    Write-Step "Creating Java package structure..."
    $BasePkgPath = $BasePackage.Replace('.', '\')
    $JavaSrcRoot = Join-Path $OutputDir "src\main\java\$BasePkgPath"
    foreach ($layer in @("domain", "application", "infrastructure", "presentation")) {
        New-Item -ItemType Directory -Force -Path "$JavaSrcRoot\$layer" | Out-Null
        $pkgInfo = "/** $layer layer */`npackage $BasePackage.$layer;`n"
        [System.IO.File]::WriteAllText("$JavaSrcRoot\$layer\package-info.java", $pkgInfo, $utf8NoBom)
    }
    $archTestPath = Join-Path $OutputDir "src\test\java\arch\DependencyTest.java"
    if (Test-Path $archTestPath) {
        $atContent = [System.IO.File]::ReadAllText($archTestPath, [System.Text.Encoding]::UTF8)
        $atContent = $atContent.Replace('{{BASE_PACKAGE}}', $BasePackage)
        [System.IO.File]::WriteAllText($archTestPath, $atContent, $utf8NoBom)
    }
    Write-Ok "Java package structure created ($BasePackage)"
}

# ── 6. Install dependencies ──────────────────────────────────────────────────────
Write-Step "Installing dependencies..."
Push-Location $OutputDir
try {
    switch ($Language) {
        "typescript" {
            if (Get-Command pnpm -ErrorAction SilentlyContinue) {
                pnpm install 2>&1 | Out-Null
                if ($LASTEXITCODE -ne 0) {
                    Write-Host "  Approving build scripts (esbuild)..." -ForegroundColor Gray
                    pnpm approve-builds esbuild 2>&1 | Out-Null
                    pnpm install 2>&1 | Out-Null
                }
                Write-Ok "pnpm install complete"
            } else {
                Write-Host "  ⚠ pnpm not found. Run manually: pnpm install" -ForegroundColor Yellow
            }
        }
        "python" {
            if (Get-Command uv -ErrorAction SilentlyContinue) {
                uv sync 2>&1 | Out-Null; Write-Ok "uv sync complete"
            } elseif (Get-Command pip -ErrorAction SilentlyContinue) {
                pip install ruff mypy pytest pytest-cov --quiet 2>&1 | Out-Null; Write-Ok "pip install complete"
            } else {
                Write-Host "  ⚠ Please install uv or pip." -ForegroundColor Yellow
            }
        }
        "java" {
            if (Get-Command mvn -ErrorAction SilentlyContinue) {
                Write-Ok "Maven found (dependencies will be downloaded on first build)"
            } else {
                Write-Host "  ⚠ Maven (mvn) not found. Install Java 21+ and Maven 3.9+." -ForegroundColor Yellow
            }
        }
    }
} catch {
    Write-Host "  ⚠ Dependency installation failed. Please check manually." -ForegroundColor Yellow
} finally {
    Pop-Location
}

# ── 7. git init + initial commit ─────────────────────────────────────────────────
Write-Step "Initializing git..."
Push-Location $OutputDir
try {
    git init --quiet
    git add .
    git commit --quiet -m "chore: initialize project with harness engineering framework"
    Write-Ok "Git initialized (initial commit created)"
} catch {
    Write-Host "  ⚠ Git initialization failed. Run manually." -ForegroundColor Yellow
} finally {
    Pop-Location
}

# ── 8. Done ───────────────────────────────────────────────────────────────────────
Write-Header "✅ Setup Complete!"
Write-Host "Generated project: " -NoNewline; Write-Host $OutputDir -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. " -NoNewline; Write-Host "cd $OutputDir" -ForegroundColor Cyan
Write-Host "  2. " -NoNewline; Write-Host "claude" -ForegroundColor Cyan -NoNewline; Write-Host " (launch Claude Code)"
Write-Host "  3. " -NoNewline; Write-Host "/start" -ForegroundColor Cyan -NoNewline; Write-Host " to begin the session"
Write-Host ""
