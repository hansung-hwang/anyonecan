#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
step() { echo -e "${YELLOW}▶ $1${NC}"; }
ok()   { echo -e "${GREEN}✓ $1${NC}"; }

step "build + checkstyle + test (Maven)..."
mvn verify -q
ok "All checks passed"

echo -e "${GREEN}✅ All validations passed.${NC}"
