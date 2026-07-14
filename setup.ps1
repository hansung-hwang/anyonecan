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

# ── Discover language packs (data-driven: language-packs/*/pack.json) ──────────
$ScriptDirEarly = Split-Path -Parent $MyInvocation.MyCommand.Path
$PackFiles = Get-ChildItem -Path (Join-Path $ScriptDirEarly "language-packs") -Filter "pack.json" -Recurse -Depth 1 -ErrorAction Stop
$Packs = @($PackFiles | ForEach-Object { Get-Content $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } | Sort-Object order)
$DefaultPack = $Packs | Where-Object { $_.default } | Select-Object -First 1
if (-not $DefaultPack) { $DefaultPack = $Packs[0] }

Write-Host ""
Write-Host "Select language:" -ForegroundColor White
foreach ($p in $Packs) {
    $suffix = if ($p -eq $DefaultPack) { " (default)" } else { "" }
    Write-Host "  $($p.order). $($p.display)$suffix"
}
$LangChoice = Read-Host "Enter number"
$LangChoiceNorm = $LangChoice.Trim().ToLower()

$SelectedPack = $null
if ([string]::IsNullOrWhiteSpace($LangChoiceNorm)) {
    $SelectedPack = $DefaultPack
} else {
    foreach ($p in $Packs) {
        if (@($p.aliases) -contains $LangChoiceNorm) { $SelectedPack = $p; break }
    }
    if (-not $SelectedPack) { $SelectedPack = $DefaultPack }
}

$Language = $SelectedPack.language
$LanguageDisplay = $SelectedPack.display

Write-Host ""
Write-Host "Select comment/description language (controls the language the AI writes comments in):" -ForegroundColor White
Write-Host "  1. English (default)"
Write-Host "  2. Korean (한국어)"
$CommentChoice = Read-Host "Enter number"
$CommentLanguage = switch ($CommentChoice.Trim().ToLower()) {
    { $_ -in "2", "korean", "한국어", "ko", "kr" } { "한국어 (Korean)" }
    default                                        { "English" }
}

$BasePackage = ""
if ($SelectedPack.postGenerate -eq "java-packages") {
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
Write-Info "Comment lang  : $CommentLanguage"
if ($SelectedPack.postGenerate -eq "java-packages") { Write-Info "Base package  : $BasePackage" }
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
Remove-Item -Path (Join-Path $OutputDir "pack.json") -Force -ErrorAction SilentlyContinue  # setup-time metadata only, not part of the generated project
Write-Ok "Language pack copied"

# ── 3. Substitute language-specific rules into CLAUDE.md ───────────────────────
Write-Step "Applying language-specific rules..."

# Rules/banned items come from the language pack's pack.json (see language-packs/<lang>/pack.json)
$LanguageRules = ($SelectedPack.rules -join "`n")
$BannedItems = $SelectedPack.banned

# AGENTS.md is the single source of truth for rules — CLAUDE.md/.cursorrules/
# .windsurfrules/harness.mdc are thin pointers with no {{LANGUAGE_RULES}}/
# {{BANNED_ITEMS}} placeholders, so only AGENTS.md needs this substitution.
$langFiles = @("AGENTS.md")
foreach ($relPath in $langFiles) {
    $fp = Join-Path $OutputDir $relPath
    if (-not (Test-Path $fp)) { continue }
    $fc = [System.IO.File]::ReadAllText($fp, [System.Text.Encoding]::UTF8)
    $fc = $fc.Replace('{{LANGUAGE_RULES}}', $LanguageRules)
    $fc = $fc.Replace('{{BANNED_ITEMS}}', $BannedItems)
    $fc = $fc.Replace('{{LANGUAGE_DISPLAY}}', $LanguageDisplay)
    $fc = $fc.Replace('{{COMMENT_LANGUAGE}}', $CommentLanguage)
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
    "{{BASE_PACKAGE}}"        = $BasePackage  # empty for non-Java; only Java files contain this placeholder (e.g. pom.xml groupId)
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
if ($SelectedPack.postGenerate -eq "java-packages") {
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

# ── 5b. Write .harness-meta.json (lets upgrade.ps1 re-render templated files
#         and detect local customizations later) ──
$HarnessVersion = (Get-Content (Join-Path $HarnessCoreDir "HARNESS-VERSION") -Raw).Trim()

# Baseline hash (LF-normalized SHA-256) of every file upgrade.ps1 is allowed to
# overwrite, recorded at generation time. On a later upgrade, a file whose hash
# no longer matches its baseline was customized by the project -- upgrade
# leaves it alone instead of silently discarding the change.
$ManifestForBaselines = Get-Content (Join-Path $HarnessCoreDir "harness-manifest.json") -Raw | ConvertFrom-Json
$BaselineFiles = [System.Collections.Generic.List[string]]::new()
foreach ($rel in $ManifestForBaselines.frameworkOwned) { if ($rel -ne "HARNESS-VERSION") { $BaselineFiles.Add($rel) } }
$langFilesForBaseline = $ManifestForBaselines.languageSpecific.$Language
if ($langFilesForBaseline) { foreach ($rel in $langFilesForBaseline) { $BaselineFiles.Add($rel) } }

$Sha256 = [System.Security.Cryptography.SHA256]::Create()
$Baselines = [ordered]@{}
foreach ($rel in $BaselineFiles) {
    $fp = Join-Path $OutputDir $rel
    if (-not (Test-Path $fp)) { continue }
    $raw = [System.IO.File]::ReadAllText($fp, [System.Text.Encoding]::UTF8)
    $normalized = ($raw -replace "`r`n", "`n")
    $hash = [System.BitConverter]::ToString($Sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($normalized))).Replace("-", "").ToLower()
    $Baselines[$rel] = $hash
}
$Sha256.Dispose()

$MetaJson = @{
    projectName        = $ProjectName
    projectDescription = $ProjectDescription
    author              = $Author
    createdDate         = $Today
    language            = $Language
    commentLanguage     = $CommentLanguage
    basePackage         = $BasePackage
    harnessVersion      = $HarnessVersion
    baselines           = $Baselines
} | ConvertTo-Json -Depth 6
[System.IO.File]::WriteAllText((Join-Path $OutputDir ".harness-meta.json"), $MetaJson, $utf8NoBom)

# ── 6. Install dependencies (candidates come from pack.json's install.candidates) ──
Write-Step "Installing dependencies..."
Push-Location $OutputDir
try {
    $handled = $false
    foreach ($candidate in @($SelectedPack.install.candidates)) {
        if (-not (Get-Command $candidate.check -ErrorAction SilentlyContinue)) { continue }
        if (-not [string]::IsNullOrWhiteSpace($candidate.run)) {
            Invoke-Expression $candidate.run 2>&1 | Out-Null
            if ($LASTEXITCODE -ne 0 -and $candidate.PSObject.Properties.Name -contains "retryFix") {
                Write-Host "  Approving build scripts (esbuild)..." -ForegroundColor Gray
                Invoke-Expression $candidate.retryFix 2>&1 | Out-Null
                Invoke-Expression $candidate.run 2>&1 | Out-Null
            }
        }
        Write-Ok $candidate.successMessage
        $handled = $true
        break
    }
    if (-not $handled) {
        Write-Host "  ⚠ $($SelectedPack.install.notFoundMessage)" -ForegroundColor Yellow
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
Write-Host "Harness version  : " -NoNewline; Write-Host $HarnessVersion -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. " -NoNewline; Write-Host "cd $OutputDir" -ForegroundColor Cyan
Write-Host "  2. " -NoNewline; Write-Host "claude" -ForegroundColor Cyan -NoNewline; Write-Host " (launch Claude Code)"
Write-Host "  3. " -NoNewline; Write-Host "/start" -ForegroundColor Cyan -NoNewline; Write-Host " to begin the session"
Write-Host ""
