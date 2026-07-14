#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
step() { echo -e "${YELLOW}▶ $1${NC}"; }
ok()   { echo -e "${GREEN}✓ $1${NC}"; }

# Prefer the project venv over whatever "python" resolves to on PATH -- a
# system/global Python won't have mypy/ruff/pytest installed and produces
# confusing import-not-found errors that look like real type errors.
if [ -x ".venv/bin/python" ]; then
    PY=".venv/bin/python"
elif [ -x ".venv/Scripts/python.exe" ]; then
    PY=".venv/Scripts/python.exe"
elif command -v python3 &>/dev/null; then
    PY="python3"
else
    PY="python"
fi

step "typecheck (mypy)..."
"$PY" -m mypy src/
ok "typecheck passed"

step "lint (ruff)..."
"$PY" -m ruff check src/ tests/
ok "lint passed"

step "test (pytest)..."
"$PY" -m pytest
ok "tests passed"

echo -e "${GREEN}✅ All validations passed.${NC}"
