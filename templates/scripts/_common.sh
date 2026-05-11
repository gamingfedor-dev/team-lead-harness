#!/bin/bash
# _common.sh — Shared utilities for hooks
# Source this from other hooks: source "${CLAUDE_PROJECT_DIR}/.claude/hooks/_common.sh"

VAULT="${CLAUDE_PROJECT_DIR}/../{{VAULT_NAME}}"
LOG_FILE="${CLAUDE_PROJECT_DIR}/.claude/sessions/hook_errors.log"

# ┌─────────────────────────────────────────────────────────────────┐
# │ CUSTOMIZE: If using Obsidian CLI, add its binary to PATH here   │
# └─────────────────────────────────────────────────────────────────┘
# export PATH="$PATH:/Applications/Obsidian.app/Contents/MacOS"

log_error() {
    local caller="${BASH_SOURCE[1]##*/}"
    echo "[$(date +%H:%M:%S)] ${caller}: $1" >> "$LOG_FILE" 2>/dev/null
}

# daily_append — Appends content to today's daily note
# Primary: Obsidian CLI. Fallback: direct file append.
# Usage: daily_append "content to append"
daily_append() {
    local content="$1"
    [ -z "$content" ] && return 0

    if command -v obsidian &>/dev/null; then
        obsidian daily:append content="$content" vault={{VAULT_NAME}} 2>/dev/null
    else
        local daily_note
        daily_note=$(ensure_daily_note) || return 1
        echo -e "$content" >> "$daily_note"
    fi
}

# ensure_daily_note — Creates daily note from template if needed, echoes path
ensure_daily_note() {
    local today=$(date +%Y-%m-%d)
    local daily_note="${VAULT}/daily/${today}.md"

    if [ ! -f "$daily_note" ]; then
        local template="${VAULT}/templates/Daily.md"
        if [ ! -f "$template" ]; then
            log_error "Template not found: $template"
            return 1
        fi
        local branch=$(git -C "$CLAUDE_PROJECT_DIR" branch --show-current 2>/dev/null || echo "unknown")
        local branch_tag=$(echo "$branch" | tr '/' '-')
        mkdir -p "$(dirname "$daily_note")"
        sed -e "s/{{date}}/${today}/g" \
            -e "s/{{branch}}/${branch}/g" \
            -e "s/{{branch-tag}}/${branch_tag}/g" \
            "$template" > "$daily_note"
    fi
    echo "$daily_note"
}
