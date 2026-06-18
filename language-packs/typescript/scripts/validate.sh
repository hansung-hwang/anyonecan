#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
step() { echo -e "${YELLOW}▶ $1${NC}"; }
ok()   { echo -e "${GREEN}✓ $1${NC}"; }

step "typecheck..."
npx tsc --noEmit
ok "typecheck passed"

step "lint..."
npx eslint src --ext .ts,.tsx
ok "lint passed"

step "test..."
npx vitest run
ok "tests passed"

echo -e "${GREEN}✅ All validations passed.${NC}"
