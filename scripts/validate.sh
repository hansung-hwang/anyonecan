#!/usr/bin/env bash
set -euo pipefail

echo "▶ check-sync (root ↔ harness-core drift)..."
node scripts/check-sync.mjs
echo "✓ check-sync passed"

echo ""
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
