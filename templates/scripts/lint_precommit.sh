#!/bin/bash
# lint_precommit.sh — PreToolUse hook for mcp__git__git_commit
# Blocks commit if lint fails

set -euo pipefail

TRACKING_FILE="${CLAUDE_PROJECT_DIR}/.claude/sessions/modified_files.txt"
[ ! -f "$TRACKING_FILE" ] && exit 0

# ┌─────────────────────────────────────────────────────────────────┐
# │ CUSTOMIZE: Run lint only on staged/modified files               │
# └─────────────────────────────────────────────────────────────────┘
# Example: run eslint on staged .ts files
# STAGED=$(git -C "$CLAUDE_PROJECT_DIR" diff --cached --name-only --diff-filter=ACM | grep '\.ts$' || true)
# if [ -n "$STAGED" ]; then
#     npx eslint $STAGED || { echo "Fix lint errors before committing."; exit 1; }
# fi

exit 0
