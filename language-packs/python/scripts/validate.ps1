#!/usr/bin/env pwsh
# validate.ps1 — typecheck + lint + test entrypoint for Windows PowerShell.
# Mirrors validate.sh; use this on Windows so pytest cache/basetemp paths
# stay under the project dir instead of a PowerShell-resolved temp path.

$ErrorActionPreference = "Stop"

function Step([string]$text) { Write-Host "▶ $text" -ForegroundColor Yellow }
function Ok([string]$text)   { Write-Host "✓ $text" -ForegroundColor Green }

if (Test-Path ".venv\Scripts\python.exe") {
    $Py = ".venv\Scripts\python.exe"
} elseif (Test-Path ".venv\bin\python") {
    $Py = ".venv\bin\python"
} else {
    $Py = "python"
}

Step "typecheck (mypy)..."
& $Py -m mypy src/
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Ok "typecheck passed"

Step "lint (ruff)..."
& $Py -m ruff check src/ tests/
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Ok "lint passed"

Step "test (pytest)..."
& $Py -m pytest
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Ok "tests passed"

Write-Host "✅ All validations passed." -ForegroundColor Green
