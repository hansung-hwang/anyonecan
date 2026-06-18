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

python -m ruff check --fix "$FILE" 2>/dev/null || true
python -m ruff format "$FILE" 2>/dev/null || true
