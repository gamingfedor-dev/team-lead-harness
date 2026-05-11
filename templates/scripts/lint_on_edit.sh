#!/bin/bash
# lint_on_edit.sh — PostToolUse hook for Edit|Write
# Runs language-specific lint checks immediately after edits

set -euo pipefail

FILE_PATH=""
if command -v jq &>/dev/null; then
    FILE_PATH=$(echo "$CLAUDE_TOOL_INPUT" | jq -r '.file_path // empty' 2>/dev/null || echo "")
fi

[ -z "$FILE_PATH" ] && exit 0
[ ! -f "$FILE_PATH" ] && exit 0

# Only lint project source files (skip vendor, node_modules, etc.)
case "$FILE_PATH" in
    "${CLAUDE_PROJECT_DIR}/src/"*) ;;
    *) exit 0 ;;
esac

EXT="${FILE_PATH##*.}"

# ┌─────────────────────────────────────────────────────────────────┐
# │ CUSTOMIZE: Add your language's lint commands here               │
# └─────────────────────────────────────────────────────────────────┘
case "$EXT" in
    # js|ts|tsx)
    #     npx eslint --quiet "$FILE_PATH" || { echo "ESLint issues in $FILE_PATH"; exit 1; }
    #     ;;
    # py)
    #     python -m flake8 "$FILE_PATH" || { echo "flake8 issues in $FILE_PATH"; exit 1; }
    #     ;;
    # go)
    #     gofmt -l "$FILE_PATH" | grep . && { echo "gofmt issues in $FILE_PATH"; exit 1; }
    #     ;;
    *)
        exit 0
        ;;
esac

exit 0
