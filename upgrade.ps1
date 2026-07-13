#!/usr/bin/env pwsh
# upgrade.ps1 — Apply the latest harness-core / language-pack framework files
# to an already-generated project (Windows).
#
# Usage: .\upgrade.ps1 -ProjectDir "C:\projects\my-app"
#
# Only overwrites files listed in harness-core/harness-manifest.json
# ("frameworkOwned" + the project's "languageSpecific" set). Never touches
# AGENTS.md, CLAUDE.md, README.md, HARNESS-CHANGELOG.md, .workspace/STATUS.md,
# .workspace/worklog.md, .workspace/plans/*.md (except plans/README.md), or
# any build-config file (eslint.config.js, tsconfig.json, pom.xml, etc.) —
# those are user-owned. Changes are left uncommitted for review.

param([Parameter(Mandatory = $true)][string]$ProjectDir)

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
function Write-Warn([string]$text) { Write-Host "⚠ $text" -ForegroundColor Yellow }

if (-not (Test-Path $ProjectDir)) { Write-Error "Project directory not found: $ProjectDir"; exit 1 }
$ProjectDir = (Resolve-Path $ProjectDir).Path

$ScriptDir      = Split-Path -Parent $MyInvocation.MyCommand.Path
$HarnessCoreDir = Join-Path $ScriptDir "harness-core"
$ManifestPath   = Join-Path $HarnessCoreDir "harness-manifest.json"
$utf8NoBom      = New-Object System.Text.UTF8Encoding $false

if (-not (Test-Path $ManifestPath)) { Write-Error "harness-manifest.json not found: $ManifestPath"; exit 1 }

$MetaPath = Join-Path $ProjectDir ".harness-meta.json"
$HasMeta  = Test-Path $MetaPath
$Meta     = if ($HasMeta) { Get-Content $MetaPath -Raw | ConvertFrom-Json } else { $null }
$Language = if ($Meta) { $Meta.language } else { $null }

$OldVersionPath = Join-Path $ProjectDir "HARNESS-VERSION"
$OldVersion = if (Test-Path $OldVersionPath) { (Get-Content $OldVersionPath -Raw).Trim() } else { "unknown (pre-versioning)" }
$NewVersion = (Get-Content (Join-Path $HarnessCoreDir "HARNESS-VERSION") -Raw).Trim()

Write-Header "Harness Upgrade"
Write-Info "Project     : $ProjectDir"
Write-Info "Old version : $OldVersion"
Write-Info "New version : $NewVersion"
Write-Info "Language    : $(if ($Language) { $Language } else { 'unknown (no .harness-meta.json)' })"
Write-Host ""

if (-not $HasMeta) {
    Write-Warn ".harness-meta.json not found — this project predates harness versioning."
    Write-Warn "Language-specific files and any file needing {{...}} re-substitution will be skipped."
}

if ($OldVersion -eq $NewVersion -and $HasMeta) {
    Write-Ok "Already up to date."
    exit 0
}

$Manifest = Get-Content $ManifestPath -Raw | ConvertFrom-Json

$FilesToUpdate = [System.Collections.Generic.List[string]]::new()
foreach ($rel in $Manifest.frameworkOwned) { $FilesToUpdate.Add($rel) }
if ($Language) {
    $langFiles = $Manifest.languageSpecific.$Language
    if ($langFiles) { foreach ($rel in $langFiles) { $FilesToUpdate.Add($rel) } }
} else {
    Write-Warn "Skipping language-specific files (scripts/validate.sh, arch tests) — language unknown."
}

$LangPackDir = if ($Language) { Join-Path $ScriptDir "language-packs\$Language" } else { $null }

$Changed = [System.Collections.Generic.List[string]]::new()
$Skipped = [System.Collections.Generic.List[string]]::new()

function Resolve-Source([string]$rel) {
    if ($LangPackDir) {
        $p = Join-Path $LangPackDir $rel
        if (Test-Path $p) { return $p }
    }
    $p = Join-Path $HarnessCoreDir $rel
    if (Test-Path $p) { return $p }
    return $null
}

foreach ($rel in $FilesToUpdate) {
    $src = Resolve-Source $rel
    if (-not $src) { $Skipped.Add("$rel (no source found in harness-core or language pack)"); continue }

    $needsSub = $Manifest.needsSubstitution.$rel
    if ($needsSub -and -not $Meta) {
        $Skipped.Add("$rel (needs {{...}} substitution but no .harness-meta.json)")
        continue
    }

    $content = [System.IO.File]::ReadAllText($src, [System.Text.Encoding]::UTF8)
    if ($needsSub) {
        foreach ($key in $needsSub) {
            # DATE uses the project's original creation date (from .harness-meta.json),
            # not today's date -- an ADR records when the decision was made, not when
            # the framework happened to be upgraded.
            $value = switch ($key) {
                "BASE_PACKAGE" { $Meta.basePackage }
                "DATE"         { $Meta.createdDate }
                default        { $null }
            }
            if ($null -ne $value) { $content = $content.Replace("{{$key}}", $value) }
        }
    }

    $dst = Join-Path $ProjectDir $rel
    New-Item -ItemType Directory -Force -Path (Split-Path $dst -Parent) | Out-Null
    $existing = if (Test-Path $dst) { [System.IO.File]::ReadAllText($dst, [System.Text.Encoding]::UTF8) } else { $null }
    # Compare with CRLF normalized to LF -- a checkout with core.autocrlf=true
    # can leave working-tree files as CRLF while every template source is LF,
    # which would otherwise report a spurious change on every run.
    $existingNormalized = if ($null -ne $existing) { $existing -replace "`r`n", "`n" } else { $null }
    $contentNormalized = $content -replace "`r`n", "`n"
    if ($existingNormalized -ne $contentNormalized) {
        [System.IO.File]::WriteAllText($dst, $content, $utf8NoBom)
        $Changed.Add($rel)
    }
}

# HARNESS-VERSION is in frameworkOwned already, but write it explicitly so the
# marker always advances even if the loop above skipped it for some reason.
[System.IO.File]::WriteAllText((Join-Path $ProjectDir "HARNESS-VERSION"), "$NewVersion`n", $utf8NoBom)
if (-not $Changed.Contains("HARNESS-VERSION")) { $Changed.Add("HARNESS-VERSION") }

# Bootstrap files that should exist but never overwrite an existing one.
foreach ($rel in $Manifest.bootstrapIfMissing) {
    $dst = Join-Path $ProjectDir $rel
    if (Test-Path $dst) { continue }
    $src = Resolve-Source $rel
    if (-not $src) { $Skipped.Add("$rel (bootstrap source not found)"); continue }
    $content = [System.IO.File]::ReadAllText($src, [System.Text.Encoding]::UTF8)
    $content = $content.Replace('{{DATE}}', (Get-Date -Format "yyyy-MM-dd"))
    New-Item -ItemType Directory -Force -Path (Split-Path $dst -Parent) | Out-Null
    [System.IO.File]::WriteAllText($dst, $content, $utf8NoBom)
    $Changed.Add("$rel (bootstrapped)")
}

Write-Host ""
if ($Changed.Count -gt 0) {
    Write-Ok "$($Changed.Count) file(s) updated:"
    foreach ($f in $Changed) { Write-Info $f }
} else {
    Write-Ok "No file content changes (already current)."
}
if ($Skipped.Count -gt 0) {
    Write-Host ""
    Write-Warn "Skipped ($($Skipped.Count)):"
    foreach ($f in $Skipped) { Write-Host "  $f" -ForegroundColor Yellow }
}

Write-Host ""
Write-Warn "Changes are NOT committed. Review with 'git diff' inside the project, then commit."
