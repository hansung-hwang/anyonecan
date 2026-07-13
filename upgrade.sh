#!/usr/bin/env bash
# upgrade.sh — Apply the latest harness-core / language-pack framework files
# to an already-generated project (Mac/Linux).
#
# Usage: ./upgrade.sh /path/to/my-app
set -euo pipefail

RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'

if [[ $# -lt 1 ]]; then
    echo -e "${RED}Usage: ./upgrade.sh /path/to/project${NC}" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$1"

if [[ ! -d "$PROJECT_DIR" ]]; then
    echo -e "${RED}Project directory not found: $PROJECT_DIR${NC}" >&2
    exit 1
fi

if [[ ! -f "$SCRIPT_DIR/harness-core/harness-manifest.json" ]]; then
    echo -e "${RED}harness-manifest.json not found: $SCRIPT_DIR/harness-core/harness-manifest.json${NC}" >&2
    exit 1
fi

echo -e "${CYAN}================================================${NC}"
echo -e "${CYAN}  Harness Upgrade${NC}"
echo -e "${CYAN}================================================${NC}"
echo ""

python3 "$SCRIPT_DIR/upgrade.py" "$PROJECT_DIR" "$SCRIPT_DIR"
