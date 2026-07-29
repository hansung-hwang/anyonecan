#!/usr/bin/env bash
# PostToolUse hook: auto-format with ruff after Write/Edit
INPUT=$(cat)
FILE=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('file_path', ''))
except Exception:
    print('')
" 2>/dev/null || true)

[[ "$FILE" == *.py ]] || exit 0

# Windows delivers file_path with backslashes; normalize before any path
# matching below, or a pattern like */vendor/* silently never matches
# (rediscovered 2026-07-19 -- see docs/how-to/file-ownership.md).
NORM_FILE=$(printf '%s' "$FILE" | tr '\\' '/')

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IGNORE_FILE="$SCRIPT_DIR/../.harnessignore"

# .harnessignore patterns match the path RELATIVE TO THE PROJECT ROOT (same rule
# the arch test uses). Matching the absolute path instead makes an ancestor
# directory outside the project silently ignore everything -- a project living
# under ~/research/ with "research" in .harnessignore would never be linted.
# On Git Bash, pwd is MSYS-form (/c/...) while file_path is Windows-form (C:\...),
# so the prefix would never strip; pwd -W yields the comparable C:/... form and
# fails harmlessly on Mac/Linux, where plain pwd is already comparable.
PROJECT_ROOT=$( cd "$SCRIPT_DIR/.." && { pwd -W 2>/dev/null || pwd; } )
PROJECT_ROOT=$(printf '%s' "$PROJECT_ROOT" | tr '\\' '/')

# Compare case-insensitively: Windows paths are case-insensitive and the drive
# letter's case is not guaranteed to agree between pwd -W and the hook input.
shopt -s nocasematch
case "$NORM_FILE" in
  "$PROJECT_ROOT"/*) REL_FILE="${NORM_FILE:${#PROJECT_ROOT}+1}" ;;
  *)                 REL_FILE="$NORM_FILE" ;;
esac
shopt -u nocasematch

if [[ -f "$IGNORE_FILE" ]]; then
  while IFS= read -r pattern || [[ -n "$pattern" ]]; do
    pattern="${pattern#"${pattern%%[![:space:]]*}"}"
    pattern="${pattern%"${pattern##*[![:space:]]}"}"
    [[ -z "$pattern" || "$pattern" == \#* ]] && continue
    if [[ "$pattern" == */* ]]; then
      [[ "$REL_FILE" == *"$pattern"* ]] && exit 0
    else
      IFS='/' read -ra SEGMENTS <<< "$REL_FILE"
      for seg in "${SEGMENTS[@]}"; do
        [[ "$seg" == "$pattern" ]] && exit 0
      done
    fi
  done < "$IGNORE_FILE"
fi

python -m ruff check --fix "$FILE" 2>/dev/null || true
python -m ruff format "$FILE" 2>/dev/null || true
