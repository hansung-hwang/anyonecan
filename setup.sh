#!/usr/bin/env bash
# setup.sh — Harness Engineering Framework project generator (Mac/Linux)
#
# Usage: ./setup.sh
#        OUTPUT_DIR=/path/to/dir ./setup.sh
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[0;37m'; NC='\033[0m'

header() { echo -e "\n${CYAN}================================================${NC}\n  ${CYAN}$1${NC}\n${CYAN}================================================${NC}\n"; }
step()   { echo -e "${YELLOW}▶ $1${NC}"; }
ok()     { echo -e "${GREEN}✓ $1${NC}"; }
info()   { echo -e "${GRAY}  $1${NC}"; }

# ── Collect input ──────────────────────────────────────────────────────────────
header "Harness Engineering Framework Setup"

read -rp "Project name (lowercase, hyphens allowed): " PROJECT_NAME
if [[ -z "$PROJECT_NAME" ]]; then
    echo -e "${RED}Error: project name is required.${NC}" >&2; exit 1
fi
if [[ ! "$PROJECT_NAME" =~ ^[a-z0-9][a-z0-9\-]*$ ]]; then
    echo -e "${RED}Error: only lowercase letters, numbers, and hyphens are allowed.${NC}" >&2; exit 1
fi

read -rp "Project description: " PROJECT_DESCRIPTION
read -rp "Author name: " AUTHOR

echo ""
echo "Select language:"
echo "  1. TypeScript (default)"
echo "  2. Python"
echo "  3. Java"
read -rp "Enter number: " LANG_CHOICE

# Normalize so a number or a language name (e.g. "python") is accepted, matching setup.ps1
LANG_CHOICE_NORM=$(echo "${LANG_CHOICE:-1}" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')
case "$LANG_CHOICE_NORM" in
    2|python)         LANGUAGE="python";     LANGUAGE_DISPLAY="Python" ;;
    3|java)           LANGUAGE="java";       LANGUAGE_DISPLAY="Java" ;;
    *)                LANGUAGE="typescript"; LANGUAGE_DISPLAY="TypeScript" ;;
esac

echo ""
echo "Select comment/description language (controls the language the AI writes comments in):"
echo "  1. English (default)"
echo "  2. Korean (한국어)"
read -rp "Enter number: " COMMENT_CHOICE
COMMENT_CHOICE_NORM=$(echo "${COMMENT_CHOICE:-1}" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')
case "$COMMENT_CHOICE_NORM" in
    2|korean|ko|kr|한국어) COMMENT_LANGUAGE="한국어 (Korean)" ;;
    *)                     COMMENT_LANGUAGE="English" ;;
esac

BASE_PACKAGE=""
if [[ "$LANGUAGE" == "java" ]]; then
    SAFE_NAME=$(echo "$PROJECT_NAME" | tr -d '-')
    read -rp "Java base package (default: com.example.$SAFE_NAME): " BASE_PACKAGE_INPUT
    BASE_PACKAGE="${BASE_PACKAGE_INPUT:-com.example.$SAFE_NAME}"
fi

read -rp "Output directory (default: ./$PROJECT_NAME): " OUTPUT_DIR_INPUT
OUTPUT_DIR="${OUTPUT_DIR_INPUT:-./$PROJECT_NAME}"

TODAY=$(date +%Y-%m-%d)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_CORE_DIR="$SCRIPT_DIR/harness-core"
LANG_PACK_DIR="$SCRIPT_DIR/language-packs/$LANGUAGE"

if [[ ! -d "$HARNESS_CORE_DIR" ]]; then
    echo -e "${RED}Error: harness-core/ not found: $HARNESS_CORE_DIR${NC}" >&2; exit 1
fi
if [[ ! -d "$LANG_PACK_DIR" ]]; then
    echo -e "${RED}Error: language-packs/$LANGUAGE not found: $LANG_PACK_DIR${NC}" >&2; exit 1
fi

echo ""
echo "────────────────────────────────────────────────"
info "Project name  : $PROJECT_NAME"
info "Description   : $PROJECT_DESCRIPTION"
info "Author        : $AUTHOR"
info "Language      : $LANGUAGE_DISPLAY"
info "Comment lang  : $COMMENT_LANGUAGE"
[[ "$LANGUAGE" == "java" ]] && info "Base package  : $BASE_PACKAGE"
info "Output dir    : $OUTPUT_DIR"
echo "────────────────────────────────────────────────"
echo ""

read -rp "Proceed? (y/N): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[yY] ]]; then echo "Cancelled."; exit 0; fi

# ── 1. Copy harness-core ────────────────────────────────────────────────────────
step "Copying harness-core..."
mkdir -p "$OUTPUT_DIR"
cp -r "$HARNESS_CORE_DIR/." "$OUTPUT_DIR/"
ok "harness-core copied"

# ── 2. Copy language pack (overlay on top of harness-core) ─────────────────────
step "Copying $LANGUAGE_DISPLAY language pack..."
cp -r "$LANG_PACK_DIR/." "$OUTPUT_DIR/"
ok "Language pack copied"

# ── 3. Substitute language-specific rules into CLAUDE.md (uses python3) ────────
step "Applying language-specific rules..."

export LANGUAGE OUTPUT_DIR LANGUAGE_DISPLAY COMMENT_LANGUAGE

python3 << 'PYEOF'
import os, pathlib

lang    = os.environ["LANGUAGE"]
output  = pathlib.Path(os.environ["OUTPUT_DIR"])
display = os.environ["LANGUAGE_DISPLAY"]
comment = os.environ["COMMENT_LANGUAGE"]

rules = {
    "typescript": (
        "- No `any` → use `unknown` + type guards\n"
        "- Explicit return type on every function (`explicit-function-return-type`)\n"
        "- `as` assertions only when unavoidable; explain the reason in a comment\n"
        "- File names: `kebab-case.ts` / `.test.ts` / `.types.ts` / `.interface.ts`"
    ),
    "python": (
        "- Type hints required (Python 3.12+, `X | Y` union style)\n"
        "- No `Any` type → use concrete types\n"
        "- Explicit return type on every function\n"
        "- Prefer dataclass or Pydantic models (avoid overusing dict)\n"
        "- File names: `snake_case.py` / `test_*.py`"
    ),
    "java": (
        "- No `null` returns → use `Optional<T>`\n"
        "- Avoid checked exceptions → domain exceptions should be unchecked\n"
        "- Prefer record classes (immutable data, Java 16+)\n"
        "- `var` allowed only when type inference is clear\n"
        "- File names: `PascalCase.java` / `*Test.java`"
    ),
}

banned = {
    "typescript": "`any` · `@ts-ignore` · `@ts-nocheck` · `@ts-expect-error` · `console.log` · excessive `eslint-disable`",
    "python":     "`Any` · `# type: ignore` · `print()` (use logging instead) · excessive `pass`",
    "java":       "`null` returns · raw type usage · `System.out.println` · excessive `@SuppressWarnings`",
}

for rel in ["CLAUDE.md", "AGENTS.md", ".cursorrules", ".windsurfrules", ".cursor/rules/harness.mdc"]:
    p = output / rel
    if not p.exists():
        continue
    content = p.read_text(encoding="utf-8")
    content = content.replace("{{LANGUAGE_RULES}}", rules[lang])
    content = content.replace("{{BANNED_ITEMS}}", banned[lang])
    content = content.replace("{{LANGUAGE_DISPLAY}}", display)
    content = content.replace("{{COMMENT_LANGUAGE}}", comment)
    p.write_text(content, encoding="utf-8")
PYEOF

ok "Language-specific rules applied"

# ── 4. Substitute standard placeholders ────────────────────────────────────────
step "Substituting placeholders..."

# Pass values through the environment and reference them as $ENV{...} in the
# replacement so special characters (|, \, $, @, /) in free-text fields cannot
# break the regex or inject perl code.
# BASE_PACKAGE is empty for non-Java; only Java files contain that placeholder (e.g. pom.xml groupId)
export PROJECT_NAME PROJECT_DESCRIPTION AUTHOR TODAY BASE_PACKAGE

find "$OUTPUT_DIR" -type f \( \
    -name "*.md" -o -name "*.mdc" -o -name "*.json" \
    -o -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.mjs" \
    -o -name "*.sh" -o -name "*.yaml" -o -name "*.yml" \
    -o -name "*.toml" -o -name "*.xml" -o -name "*.java" \
    -o -name ".cursorrules" -o -name ".windsurfrules" \
\) ! -path "*/node_modules/*" ! -path "*/target/*" | while IFS= read -r file; do
    perl -pi \
        -e 's/\{\{PROJECT_NAME\}\}/$ENV{PROJECT_NAME}/g' \
        -e 's/\{\{PROJECT_DESCRIPTION\}\}/$ENV{PROJECT_DESCRIPTION}/g' \
        -e 's/\{\{AUTHOR\}\}/$ENV{AUTHOR}/g' \
        -e 's/\{\{DATE\}\}/$ENV{TODAY}/g' \
        -e 's/\{\{BASE_PACKAGE\}\}/$ENV{BASE_PACKAGE}/g' \
        "$file"
done

ok "Placeholders substituted"

# ── 5. Java: create package directories + substitute BASE_PACKAGE ───────────────
if [[ "$LANGUAGE" == "java" ]]; then
    step "Creating Java package structure..."
    BASE_PKG_PATH=$(echo "$BASE_PACKAGE" | tr '.' '/')
    JAVA_SRC_ROOT="$OUTPUT_DIR/src/main/java/$BASE_PKG_PATH"

    for layer in domain application infrastructure presentation; do
        mkdir -p "$JAVA_SRC_ROOT/$layer"
        cat > "$JAVA_SRC_ROOT/$layer/package-info.java" << EOF
/** ${layer} layer */
package $BASE_PACKAGE.$layer;
EOF
    done

    # Substitute BASE_PACKAGE in DependencyTest.java (env-passed for the same safety reason as above)
    ARCH_TEST="$OUTPUT_DIR/src/test/java/arch/DependencyTest.java"
    if [[ -f "$ARCH_TEST" ]]; then
        BASE_PACKAGE="$BASE_PACKAGE" perl -pi -e 's/\{\{BASE_PACKAGE\}\}/$ENV{BASE_PACKAGE}/g' "$ARCH_TEST"
    fi

    ok "Java package structure created ($BASE_PACKAGE)"
fi

# ── 6. Install dependencies ──────────────────────────────────────────────────────
step "Installing dependencies..."
cd "$OUTPUT_DIR"

case "$LANGUAGE" in
    typescript)
        if command -v pnpm &>/dev/null; then
            if ! pnpm install --silent 2>/dev/null; then
                echo -e "${GRAY}  Approving build scripts (esbuild)...${NC}"
                pnpm approve-builds esbuild --silent 2>/dev/null || true
                pnpm install --silent
            fi
            ok "pnpm install complete"
        else
            echo -e "${YELLOW}  ⚠ pnpm not found. Run manually: pnpm install${NC}"
        fi
        ;;
    python)
        if command -v uv &>/dev/null; then
            uv sync --quiet 2>/dev/null; ok "uv sync complete"
        elif command -v pip &>/dev/null; then
            pip install ruff mypy pytest pytest-cov -q; ok "pip install complete"
        else
            echo -e "${YELLOW}  ⚠ Please install uv or pip.${NC}"
        fi
        ;;
    java)
        if command -v mvn &>/dev/null; then
            ok "Maven found (dependencies will be downloaded on first build)"
        else
            echo -e "${YELLOW}  ⚠ Maven (mvn) not found. Install Java 21+ and Maven 3.9+.${NC}"
        fi
        ;;
esac

# ── 7. git init + initial commit ─────────────────────────────────────────────────
step "Initializing git..."
if git init --quiet && git add . && \
   git commit --quiet -m "chore: initialize project with harness engineering framework"; then
    ok "Git initialized (initial commit created)"
else
    echo -e "${YELLOW}  ⚠ Git initialization failed (is user.name/user.email set?). Commit manually.${NC}"
fi

# ── 8. Done ───────────────────────────────────────────────────────────────────────
header "✅ Setup Complete!"
echo -e "Generated project: ${CYAN}$OUTPUT_DIR${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. ${CYAN}cd $OUTPUT_DIR${NC}"
echo -e "  2. ${CYAN}claude${NC} (launch Claude Code)"
echo -e "  3. ${CYAN}/start${NC} to begin the session"
echo ""
