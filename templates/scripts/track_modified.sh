#!/bin/bash
# track_modified.sh - PostToolUse hook
# Accumulates modified file paths to a tracking file.
#
# Matches both:
#   - Edit / Write (input: .file_path with absolute project path)
#   - mcp__obsidian__obsidian_update_note / obsidian_append_note (input: .path + .vault — relative to vault root)

set -euo pipefail

TRACKING_FILE="${CLAUDE_PROJECT_DIR}/.claude/sessions/modified_files.txt"

mkdir -p "$(dirname "$TRACKING_FILE")"
touch "$TRACKING_FILE"

FILE_PATH=""
if command -v jq &>/dev/null; then
    # First: try the Edit/Write shape
    FILE_PATH=$(echo "$CLAUDE_TOOL_INPUT" | jq -r '.file_path // empty' 2>/dev/null || echo "")

    # Fallback: try the Obsidian MCP shape (.path + .vault → reconstruct full path)
    if [ -z "$FILE_PATH" ] || [ "$FILE_PATH" = "null" ]; then
        VAULT_REL=$(echo "$CLAUDE_TOOL_INPUT" | jq -r '.path // empty' 2>/dev/null || echo "")
        VAULT_NAME=$(echo "$CLAUDE_TOOL_INPUT" | jq -r '.vault // empty' 2>/dev/null || echo "")
        if [ -n "$VAULT_REL" ] && [ -n "$VAULT_NAME" ]; then
            FILE_PATH="../${VAULT_NAME}/${VAULT_REL}"
        fi
    fi
fi

if [ -n "$FILE_PATH" ] && [ "$FILE_PATH" != "null" ]; then
    if ! grep -qF "$FILE_PATH" "$TRACKING_FILE" 2>/dev/null; then
        echo "$FILE_PATH" >> "$TRACKING_FILE"
    fi
fi

exit 0
