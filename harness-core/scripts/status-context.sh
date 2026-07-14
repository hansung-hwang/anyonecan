#!/usr/bin/env bash
# SessionStart hook: surface the current work snapshot automatically so a new
# session doesn't have to be told to read it -- the agent gets it for free.
set -euo pipefail

STATUS=".workspace/STATUS.md"
[ -f "$STATUS" ] || exit 0

echo "Current work snapshot (.workspace/STATUS.md):"
echo
cat "$STATUS"
