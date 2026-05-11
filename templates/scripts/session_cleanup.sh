#!/bin/bash
# session_cleanup.sh - SessionEnd hook
# Cleans up transient tracking files

set -euo pipefail

TRACKING_FILE="${CLAUDE_PROJECT_DIR}/.claude/sessions/modified_files.txt"

rm -f "$TRACKING_FILE"

exit 0
