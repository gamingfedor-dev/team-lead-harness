#!/bin/bash
# track_modified.sh - PostToolUse hook for Edit|Write tools
# Accumulates modified file paths to a tracking file

set -euo pipefail

TRACKING_FILE="${CLAUDE_PROJECT_DIR}/.claude/sessions/modified_files.txt"

mkdir -p "$(dirname "$TRACKING_FILE")"
touch "$TRACKING_FILE"

FILE_PATH=""
if command -v jq &>/dev/null; then
    FILE_PATH=$(echo "$CLAUDE_TOOL_INPUT" | jq -r '.file_path // empty' 2>/dev/null || echo "")
fi

if [ -n "$FILE_PATH" ] && [ "$FILE_PATH" != "null" ]; then
    if ! grep -qF "$FILE_PATH" "$TRACKING_FILE" 2>/dev/null; then
        echo "$FILE_PATH" >> "$TRACKING_FILE"
    fi
fi

exit 0
