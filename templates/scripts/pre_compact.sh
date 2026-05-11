#!/bin/bash
# pre_compact.sh — PreCompact hook
# Snapshots transient session state before context compaction

set -euo pipefail

SESSION_DIR="${CLAUDE_PROJECT_DIR}/.claude/sessions"
TRACKING="${SESSION_DIR}/modified_files.txt"

if [ -f "$TRACKING" ] && [ -s "$TRACKING" ]; then
    cp "$TRACKING" "${SESSION_DIR}/pre_compact_files_$(date +%s).txt"
fi

exit 0
