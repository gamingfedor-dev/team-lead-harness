#!/bin/bash
# on_commit.sh - PostToolUse hook for mcp__git__git_commit
# Appends commit entry to today's daily note via Obsidian CLI

set -euo pipefail

source "${CLAUDE_PROJECT_DIR}/.claude/hooks/_common.sh"

TRACKING_FILE="${CLAUDE_PROJECT_DIR}/.claude/sessions/modified_files.txt"
TIME=$(date +%H:%M)

COMMIT_MSG=""
if command -v jq &>/dev/null; then
    COMMIT_MSG=$(echo "$CLAUDE_TOOL_RESULT" | jq -r '.message // empty' 2>/dev/null || true)
fi
if [ -z "$COMMIT_MSG" ]; then
    log_error "Could not extract commit message from tool result"
    exit 0
fi

FILES=""
if [ -f "$TRACKING_FILE" ]; then
    FILES=$(tr '\n' ', ' < "$TRACKING_FILE" | sed 's/,$//')
fi

ENTRY="\n### ${TIME} — Commit\n\n\`\`\`\n${COMMIT_MSG}\n\`\`\`\n\n**Files modified:** ${FILES:-none}\n\n---"

daily_append "$ENTRY" || log_error "Failed to append commit entry"

rm -f "$TRACKING_FILE"

exit 0
