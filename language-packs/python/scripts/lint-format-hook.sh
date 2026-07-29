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

if [[ -f "$IGNORE_FILE" ]]; then
  while IFS= read -r pattern || [[ -n "$pattern" ]]; do
    pattern="${pattern#"${pattern%%[![:space:]]*}"}"
    pattern="${pattern%"${pattern##*[![:space:]]}"}"
    [[ -z "$pattern" || "$pattern" == \#* ]] && continue
    if [[ "$pattern" == */* ]]; then
      [[ "$NORM_FILE" == *"$pattern"* ]] && exit 0
    else
      IFS='/' read -ra SEGMENTS <<< "$NORM_FILE"
      for seg in "${SEGMENTS[@]}"; do
        [[ "$seg" == "$pattern" ]] && exit 0
      done
    fi
  done < "$IGNORE_FILE"
fi

python -m ruff check --fix "$FILE" 2>/dev/null || true
python -m ruff format "$FILE" 2>/dev/null || true
