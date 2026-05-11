#!/bin/bash
# on_agent_stop.sh — SubagentStop hook
# Auto-appends agent findings summary to the daily note

set -euo pipefail

source "${CLAUDE_PROJECT_DIR}/.claude/hooks/_common.sh"

INPUT=$(cat)

AGENT_NAME=""
SUMMARY=""
if command -v jq &>/dev/null; then
    AGENT_NAME=$(echo "$INPUT" | jq -r '.agent_name // .subagent_type // "unknown"' 2>/dev/null || echo "unknown")
    SUMMARY=$(echo "$INPUT" | jq -r '.agent_summary // .result // empty' 2>/dev/null || true)
fi

[ -z "$SUMMARY" ] || [ "$SUMMARY" = "null" ] && exit 0

if [ ${#SUMMARY} -gt 500 ]; then
    SUMMARY="${SUMMARY:0:500}..."
fi

TIME=$(date +%H:%M)
ENTRY="\n### ${TIME} — Agent: ${AGENT_NAME}\n\n${SUMMARY}\n\n---"

daily_append "$ENTRY" || log_error "Failed to append agent entry"

exit 0
