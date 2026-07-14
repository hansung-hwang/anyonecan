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

# ── Discover language packs (data-driven: language-packs/*/pack.json) ──────────
SCRIPT_DIR_EARLY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKS_RAW=$(python3 - "$SCRIPT_DIR_EARLY/language-packs" << 'PYEOF'
import sys, json, glob, os

root = sys.argv[1]
packs = []
for p in sorted(glob.glob(os.path.join(root, "*", "pack.json"))):
    with open(p, encoding="utf-8") as f:
        packs.append(json.load(f))
packs.sort(key=lambda p: p["order"])

default_lang = next((p["language"] for p in packs if p.get("default")), packs[0]["language"])

for p in packs:
    suffix = " (default)" if p["language"] == default_lang else ""
    print(f"MENU:{p['order']}. {p['display']}{suffix}")
for p in packs:
    print(f"DATA:{p['language']}:{p['display']}:{','.join(p['aliases'])}:{p.get('postGenerate', '')}")
print(f"DEFAULT:{default_lang}")
PYEOF
)

echo ""
echo "Select language:"
echo "$PACKS_RAW" | grep '^MENU:' | sed 's/^MENU://'
read -rp "Enter number: " LANG_CHOICE

# Normalize so a number or a language name (e.g. "python") is accepted, matching setup.ps1
LANG_CHOICE_NORM=$(echo "${LANG_CHOICE:-}" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')
DEFAULT_LANGUAGE=$(echo "$PACKS_RAW" | grep '^DEFAULT:' | cut -d: -f2)

MATCH_LANG=""
if [[ -n "$LANG_CHOICE_NORM" ]]; then
    while IFS=: read -r tag lang display aliases postgen; do
        [[ "$tag" != "DATA" ]] && continue
        IFS=',' read -ra ALIAS_ARR <<< "$aliases"
        for a in "${ALIAS_ARR[@]}"; do
            if [[ "$a" == "$LANG_CHOICE_NORM" ]]; then MATCH_LANG="$lang"; break 2; fi
        done
    done <<< "$PACKS_RAW"
fi
[[ -z "$MATCH_LANG" ]] && MATCH_LANG="$DEFAULT_LANGUAGE"

LANGUAGE=""; LANGUAGE_DISPLAY=""; POST_GENERATE=""
while IFS=: read -r tag lang display aliases postgen; do
    [[ "$tag" != "DATA" ]] && continue
    if [[ "$lang" == "$MATCH_LANG" ]]; then
        LANGUAGE="$lang"; LANGUAGE_DISPLAY="$display"; POST_GENERATE="$postgen"
    fi
done <<< "$PACKS_RAW"

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
if [[ "$POST_GENERATE" == "java-packages" ]]; then
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
[[ "$POST_GENERATE" == "java-packages" ]] && info "Base package  : $BASE_PACKAGE"
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
rm -f "$OUTPUT_DIR/pack.json"  # setup-time metadata only, not part of the generated project
ok "Language pack copied"

# ── 3. Substitute language-specific rules into CLAUDE.md (uses python3) ────────
step "Applying language-specific rules..."

export LANGUAGE OUTPUT_DIR LANGUAGE_DISPLAY COMMENT_LANGUAGE SCRIPT_DIR

python3 << 'PYEOF'
import os, pathlib, json

lang       = os.environ["LANGUAGE"]
output     = pathlib.Path(os.environ["OUTPUT_DIR"])
display    = os.environ["LANGUAGE_DISPLAY"]
comment    = os.environ["COMMENT_LANGUAGE"]
script_dir = pathlib.Path(os.environ["SCRIPT_DIR"])

# Rules/banned items come from the language pack's pack.json (single source of truth)
pack = json.loads((script_dir / "language-packs" / lang / "pack.json").read_text(encoding="utf-8"))
rules_text = "\n".join(pack["rules"])
banned_text = pack["banned"]

# AGENTS.md is the single source of truth for rules — CLAUDE.md/.cursorrules/
# .windsurfrules/harness.mdc are thin pointers with no {{LANGUAGE_RULES}}/
# {{BANNED_ITEMS}} placeholders, so only AGENTS.md needs this substitution.
for rel in ["AGENTS.md"]:
    p = output / rel
    if not p.exists():
        continue
    content = p.read_text(encoding="utf-8")
    content = content.replace("{{LANGUAGE_RULES}}", rules_text)
    content = content.replace("{{BANNED_ITEMS}}", banned_text)
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
    # A single multi-statement -e (not multiple -e flags) — some perl builds
    # (observed: Cygwin/Git-for-Windows perl 5.42.2) fail to concatenate
    # separate -e arguments into one program and error on the 2nd statement.
    perl -pi -e '
        s/\{\{PROJECT_NAME\}\}/$ENV{PROJECT_NAME}/g;
        s/\{\{PROJECT_DESCRIPTION\}\}/$ENV{PROJECT_DESCRIPTION}/g;
        s/\{\{AUTHOR\}\}/$ENV{AUTHOR}/g;
        s/\{\{DATE\}\}/$ENV{TODAY}/g;
        s/\{\{BASE_PACKAGE\}\}/$ENV{BASE_PACKAGE}/g;
    ' "$file"
done

ok "Placeholders substituted"

# ── 5. Java: create package directories + substitute BASE_PACKAGE ───────────────
if [[ "$POST_GENERATE" == "java-packages" ]]; then
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

# ── 5b. Write .harness-meta.json (lets upgrade.sh re-render templated files later) ──
HARNESS_VERSION=$(cat "$HARNESS_CORE_DIR/HARNESS-VERSION" | tr -d '[:space:]')
json_escape() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }
cat > "$OUTPUT_DIR/.harness-meta.json" << EOF
{
  "projectName": "$(json_escape "$PROJECT_NAME")",
  "projectDescription": "$(json_escape "$PROJECT_DESCRIPTION")",
  "author": "$(json_escape "$AUTHOR")",
  "createdDate": "$(json_escape "$TODAY")",
  "language": "$(json_escape "$LANGUAGE")",
  "commentLanguage": "$(json_escape "$COMMENT_LANGUAGE")",
  "basePackage": "$(json_escape "$BASE_PACKAGE")",
  "harnessVersion": "$(json_escape "$HARNESS_VERSION")"
}
EOF

# ── 6. Install dependencies (candidates come from pack.json's install.candidates) ──
step "Installing dependencies..."
cd "$OUTPUT_DIR"

INSTALL_DATA=$(python3 - "$SCRIPT_DIR/language-packs/$LANGUAGE/pack.json" << 'PYEOF'
import sys, json

pack = json.load(open(sys.argv[1], encoding="utf-8"))
install = pack["install"]
for c in install["candidates"]:
    print("\t".join([c["tool"], c["check"], c.get("run", ""), c.get("retryFix", ""), c["successMessage"]]))
print("NOTFOUND\t" + install["notFoundMessage"])
PYEOF
)

HANDLED=0
while IFS=$'\t' read -r tool check run retryfix successmsg; do
    if [[ "$tool" == "NOTFOUND" ]]; then
        [[ "$HANDLED" -eq 0 ]] && echo -e "${YELLOW}  ⚠ $check${NC}"
        continue
    fi
    [[ "$HANDLED" -eq 1 ]] && continue
    if command -v "$check" &>/dev/null; then
        if [[ -n "$run" ]]; then
            if ! eval "$run" &>/dev/null && [[ -n "$retryfix" ]]; then
                echo -e "${GRAY}  Approving build scripts (esbuild)...${NC}"
                eval "$retryfix" &>/dev/null || true
                eval "$run" &>/dev/null || true
            fi
        fi
        ok "$successmsg"
        HANDLED=1
    fi
done <<< "$INSTALL_DATA"

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
echo -e "Harness version  : ${CYAN}$HARNESS_VERSION${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. ${CYAN}cd $OUTPUT_DIR${NC}"
echo -e "  2. ${CYAN}claude${NC} (launch Claude Code)"
echo -e "  3. ${CYAN}/start${NC} to begin the session"
echo ""
