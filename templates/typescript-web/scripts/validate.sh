#!/usr/bin/env bash
set -euo pipefail

echo "▶ typecheck..."
pnpm typecheck
echo "✓ typecheck passed"

echo ""
echo "▶ lint..."
pnpm lint
echo "✓ lint passed"

echo ""
echo "▶ test..."
pnpm test
echo "✓ tests passed"

echo ""
echo "✅ All validations passed."
