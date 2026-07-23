#!/usr/bin/env pwsh
# upgrade.ps1 — Apply the latest harness-core / language-pack framework files
# to an already-generated project (Windows).
#
# Usage: .\upgrade.ps1 -ProjectDir "C:\projects\my-app"
#
# Only touches files listed in harness-core/harness-manifest.json
# ("frameworkOwned" + the project's "languageSpecific" set). Never touches
# AGENTS.md, CLAUDE.md, README.md, HARNESS-CHANGELOG.md, .workspace/STATUS.md,
# .workspace/worklog.md, .workspace/plans/*.md (except plans/README.md), or
# any build-config file (eslint.config.js, tsconfig.json, pom.xml, etc.) —
# those are user-owned. Changes are left uncommitted for review.
#
# Customization safety: each managed file has a baseline hash recorded in
# .harness-meta.json (written by setup.ps1, advanced by this script). If a
# project's copy of a file no longer matches its baseline, the project
# customized it — this script leaves that file alone and writes the new
# template as "<file>.new" next to it for manual merge, instead of silently
# discarding the customization. Projects without a baselines map (created
# before this existed) fall back to the old always-overwrite behavior once,
# with a warning, and gain baseline tracking from that point on.

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
$Sha256         = [System.Security.Cryptography.SHA256]::Create()

function Get-NormalizedHash([string]$text) {
    $normalized = $text -replace "`r`n", "`n"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($normalized)
    return [System.BitConverter]::ToString($Sha256.ComputeHash($bytes)).Replace("-", "").ToLower()
}

if (-not (Test-Path $ManifestPath)) { Write-Error "harness-manifest.json not found: $ManifestPath"; exit 1 }

$MetaPath = Join-Path $ProjectDir ".harness-meta.json"
$HasMeta  = Test-Path $MetaPath
$Meta     = if ($HasMeta) { Get-Content $MetaPath -Raw | ConvertFrom-Json } else { $null }
$Language = if ($Meta) { $Meta.language } else { $null }
$HasBaselines = $HasMeta -and $Meta.PSObject.Properties.Name -contains "baselines" -and $Meta.baselines

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
} elseif (-not $HasBaselines) {
    Write-Warn "No baseline hashes recorded (project predates 1.3.0) — files will be overwritten"
    Write-Warn "unconditionally this one run (review with git diff). Baselines will be recorded now"
    Write-Warn "so future upgrades can detect local customizations and protect them."
}

if ($OldVersion -eq $NewVersion -and $HasMeta -and $HasBaselines) {
    Write-Ok "Already up to date."
    exit 0
}

$Manifest = Get-Content $ManifestPath -Raw | ConvertFrom-Json

# HARNESS-VERSION is handled separately below (unconditional marker bump, no
# baseline/customization concept applies to it).
$FilesToUpdate = [System.Collections.Generic.List[string]]::new()
foreach ($rel in $Manifest.frameworkOwned) { if ($rel -ne "HARNESS-VERSION") { $FilesToUpdate.Add($rel) } }
if ($Language) {
    $langFiles = $Manifest.languageSpecific.$Language
    if ($langFiles) { foreach ($rel in $langFiles) { $FilesToUpdate.Add($rel) } }
} else {
    Write-Warn "Skipping language-specific files (scripts/validate.sh, arch tests) — language unknown."
}

$LangPackDir = if ($Language) { Join-Path $ScriptDir "language-packs\$Language" } else { $null }

$Added       = [System.Collections.Generic.List[string]]::new()
$Updated     = [System.Collections.Generic.List[string]]::new()
$Overwritten = [System.Collections.Generic.List[string]]::new()
$MergeNeeded = [System.Collections.Generic.List[string]]::new()
$Skipped     = [System.Collections.Generic.List[string]]::new()
$NewBaselines = [ordered]@{}

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
    $newDst = "$dst.new"
    New-Item -ItemType Directory -Force -Path (Split-Path $dst -Parent) | Out-Null

    $contentNormalized = $content -replace "`r`n", "`n"
    $newHash = Get-NormalizedHash $content

    $existing = if (Test-Path $dst) { [System.IO.File]::ReadAllText($dst, [System.Text.Encoding]::UTF8) } else { $null }
    # Compare with CRLF normalized to LF -- a checkout with core.autocrlf=true
    # can leave working-tree files as CRLF while every template source is LF,
    # which would otherwise report a spurious change on every run.
    $existingNormalized = if ($null -ne $existing) { $existing -replace "`r`n", "`n" } else { $null }

    if ($existingNormalized -eq $contentNormalized) {
        # Already matches the incoming template -- nothing to write. Covers
        # "never changed" and "user already hand-merged .new" alike.
        if ($HasMeta) { $NewBaselines[$rel] = $newHash }
        if (Test-Path $newDst) { Remove-Item $newDst -Force }
        continue
    }

    if ($null -eq $existing) {
        # File doesn't exist in the project yet -- just add it.
        [System.IO.File]::WriteAllText($dst, $content, $utf8NoBom)
        if ($HasMeta) { $NewBaselines[$rel] = $newHash }
        if (Test-Path $newDst) { Remove-Item $newDst -Force }
        $Added.Add($rel)
        continue
    }

    $baselineHash = if ($HasBaselines -and ($Meta.baselines.PSObject.Properties.Name -contains $rel)) { $Meta.baselines.$rel } else { $null }

    if ($baselineHash) {
        $existingHash = Get-NormalizedHash $existing
        if ($existingHash -eq $baselineHash) {
            # Unmodified since it was installed -- safe to take the new template.
            [System.IO.File]::WriteAllText($dst, $content, $utf8NoBom)
            $NewBaselines[$rel] = $newHash
            if (Test-Path $newDst) { Remove-Item $newDst -Force }
            $Updated.Add($rel)
        } else {
            # Project customized this file -- don't clobber it. Baseline stays
            # at the old hash so the next upgrade offers the merge again.
            [System.IO.File]::WriteAllText($newDst, $content, $utf8NoBom)
            $MergeNeeded.Add($rel)
        }
    } else {
        # No baseline recorded for this file (pre-1.3.0 project, or the file
        # was added to the manifest after this project's baseline snapshot) --
        # fall back to the old unconditional-overwrite behavior, once.
        [System.IO.File]::WriteAllText($dst, $content, $utf8NoBom)
        if ($HasMeta) { $NewBaselines[$rel] = $newHash }
        if (Test-Path $newDst) { Remove-Item $newDst -Force }
        $Overwritten.Add($rel)
    }
}

# HARNESS-VERSION is in frameworkOwned already, but write it explicitly so the
# marker always advances even if the loop above skipped it for some reason.
[System.IO.File]::WriteAllText((Join-Path $ProjectDir "HARNESS-VERSION"), "$NewVersion`n", $utf8NoBom)

# Bootstrap files that should exist but never overwrite an existing one.
$BootstrapList = [System.Collections.Generic.List[string]]::new()
foreach ($rel in $Manifest.bootstrapIfMissing) { $BootstrapList.Add($rel) }
if ($Language) {
    $bootstrapLangFiles = $Manifest.bootstrapLanguageSpecific.$Language
    if ($bootstrapLangFiles) { foreach ($rel in $bootstrapLangFiles) { $BootstrapList.Add($rel) } }
}

$Bootstrapped = [System.Collections.Generic.List[string]]::new()
foreach ($rel in $BootstrapList) {
    $dst = Join-Path $ProjectDir $rel
    if (Test-Path $dst) { continue }
    $src = Resolve-Source $rel
    if (-not $src) { $Skipped.Add("$rel (bootstrap source not found)"); continue }
    $content = [System.IO.File]::ReadAllText($src, [System.Text.Encoding]::UTF8)
    $needsSub = $Manifest.needsSubstitution.$rel
    if ($needsSub) {
        foreach ($key in $needsSub) {
            $value = switch ($key) {
                "BASE_PACKAGE" { if ($Meta) { $Meta.basePackage } else { $null } }
                "DATE"         { if ($Meta -and $Meta.createdDate) { $Meta.createdDate } else { Get-Date -Format "yyyy-MM-dd" } }
                default        { $null }
            }
            if ($null -ne $value) { $content = $content.Replace("{{$key}}", $value) }
        }
    } else {
        $content = $content.Replace('{{DATE}}', (Get-Date -Format "yyyy-MM-dd"))
    }
    New-Item -ItemType Directory -Force -Path (Split-Path $dst -Parent) | Out-Null
    [System.IO.File]::WriteAllText($dst, $content, $utf8NoBom)
    if ($HasMeta) { $NewBaselines[$rel] = (Get-NormalizedHash $content) }
    $Bootstrapped.Add($rel)
}

# Persist advanced baselines (existing entries survive unless replaced above --
# a merge-needed file's baseline intentionally stays at its old value).
if ($HasMeta) {
    $FinalBaselines = [ordered]@{}
    if ($HasBaselines) {
        foreach ($prop in $Meta.baselines.PSObject.Properties) { $FinalBaselines[$prop.Name] = $prop.Value }
    }
    foreach ($key in $NewBaselines.Keys) { $FinalBaselines[$key] = $NewBaselines[$key] }

    if ($Meta.PSObject.Properties.Name -contains "baselines") {
        $Meta.baselines = $FinalBaselines
    } else {
        $Meta | Add-Member -MemberType NoteProperty -Name "baselines" -Value $FinalBaselines
    }
    # .harness-meta.json's own harnessVersion field must track the HARNESS-VERSION
    # file written above -- otherwise the project's metadata silently reports the
    # pre-upgrade version even though the file on disk (and every framework-owned
    # file) has moved on.
    if ($Meta.PSObject.Properties.Name -contains "harnessVersion") {
        $Meta.harnessVersion = $NewVersion
    } else {
        $Meta | Add-Member -MemberType NoteProperty -Name "harnessVersion" -Value $NewVersion
    }
    $MetaJson = $Meta | ConvertTo-Json -Depth 6
    [System.IO.File]::WriteAllText($MetaPath, $MetaJson, $utf8NoBom)
}

$Sha256.Dispose()

Write-Host ""
if ($Added.Count -gt 0) {
    Write-Ok "$($Added.Count) file(s) added:"
    foreach ($f in $Added) { Write-Info $f }
}
if ($Updated.Count -gt 0) {
    Write-Ok "$($Updated.Count) file(s) updated:"
    foreach ($f in $Updated) { Write-Info $f }
}
if ($Overwritten.Count -gt 0) {
    Write-Warn "$($Overwritten.Count) file(s) overwritten (no baseline recorded — review with git diff):"
    foreach ($f in $Overwritten) { Write-Host "  $f" -ForegroundColor Yellow }
}
if ($Bootstrapped.Count -gt 0) {
    Write-Ok "$($Bootstrapped.Count) file(s) bootstrapped (were missing):"
    foreach ($f in $Bootstrapped) { Write-Info $f }
}
if ($Added.Count -eq 0 -and $Updated.Count -eq 0 -and $Overwritten.Count -eq 0 -and $Bootstrapped.Count -eq 0) {
    Write-Ok "No file content changes (already current)."
}
if ($MergeNeeded.Count -gt 0) {
    Write-Host ""
    Write-Warn "$($MergeNeeded.Count) file(s) customized locally — left untouched, new template written as '<file>.new':"
    foreach ($f in $MergeNeeded) { Write-Host "  $f  ->  $f.new" -ForegroundColor Yellow }
    Write-Host ""
    Write-Warn "Diff each file against its '.new', merge by hand, delete the '.new', then re-run"
    Write-Warn "upgrade — a file matching its template exactly is treated as caught up."
}
if ($Skipped.Count -gt 0) {
    Write-Host ""
    Write-Warn "Skipped ($($Skipped.Count)):"
    foreach ($f in $Skipped) { Write-Host "  $f" -ForegroundColor Yellow }
}

Write-Host ""
Write-Warn "Changes are NOT committed. Review with 'git diff' inside the project, then commit."
