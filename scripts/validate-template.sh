#!/usr/bin/env bash
# validate-template.sh — 템플릿 파일 유효성 검사
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
TEMPLATE_DIR="$ROOT_DIR/templates/typescript-web"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
PASS=0; FAIL=0

check() {
    local desc="$1"; local result="$2"
    if [[ "$result" == "ok" ]]; then
        echo -e "  ${GREEN}✓${NC} $desc"; ((PASS++)) || true
    else
        echo -e "  ${RED}✗${NC} $desc — $result"; ((FAIL++)) || true
    fi
}

echo "▶ typescript-web 템플릿 유효성 검사"
echo ""

# ── 1. 필수 파일 존재 확인 ──────────────────────────────────────────────────────
echo "필수 파일 확인:"
REQUIRED_FILES=(
    "CLAUDE.md"
    "AGENTS.md"
    "package.json"
    "tsconfig.json"
    "eslint.config.js"
    ".prettierrc"
    "vitest.config.ts"
    "scripts/validate.sh"
    "scripts/lint-format-hook.mjs"
    ".claude/settings.json"
    ".claude/commands/start.md"
    ".claude/commands/fix.md"
    ".claude/commands/review.md"
    ".claude/commands/commit.md"
    ".claude/commands/test.md"
    "docs/adr-template.md"
    "docs/how-to/component-guide.md"
    "docs/how-to/testing-guide.md"
    "docs/how-to/git-workflow.md"
    "src/tests/arch/dependencies.test.ts"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [[ -f "$TEMPLATE_DIR/$file" ]]; then
        check "$file" "ok"
    else
        check "$file" "파일 없음"
    fi
done

# ── 2. 플레이스홀더 존재 확인 ───────────────────────────────────────────────────
echo ""
echo "플레이스홀더 확인:"
PLACEHOLDERS=("{{PROJECT_NAME}}" "{{PROJECT_DESCRIPTION}}" "{{AUTHOR}}" "{{TECH_STACK}}" "{{DATE}}")

for ph in "${PLACEHOLDERS[@]}"; do
    count=$(grep -r "$ph" "$TEMPLATE_DIR" \
        --include="*.md" --include="*.json" --include="*.ts" \
        -l 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$count" -gt 0 ]]; then
        check "$ph ($count개 파일에서 사용)" "ok"
    else
        check "$ph" "미사용 — 치환 대상 없음"
    fi
done

# ── 3. package.json 구조 확인 ──────────────────────────────────────────────────
echo ""
echo "package.json 구조 확인:"
PKG="$TEMPLATE_DIR/package.json"
for field in '"name"' '"description"' '"author"' '"scripts"' '"devDependencies"'; do
    if grep -q "$field" "$PKG" 2>/dev/null; then
        check "$field 필드" "ok"
    else
        check "$field 필드" "없음"
    fi
done

# ── 결과 ────────────────────────────────────────────────────────────────────────
echo ""
echo "────────────────────────────────────────"
echo -e "  통과: ${GREEN}$PASS${NC}  실패: ${RED}$FAIL${NC}"
echo "────────────────────────────────────────"

if [[ "$FAIL" -gt 0 ]]; then
    echo -e "${RED}❌ 유효성 검사 실패${NC}"; exit 1
else
    echo -e "${GREEN}✅ 모든 검사 통과${NC}"
fi
