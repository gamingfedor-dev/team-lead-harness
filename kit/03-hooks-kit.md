---
title: "Hooks & Automation Kit"
type: reference
tags: [portable-setup, white-label, hooks, automation]
version: "2.0"
created: 2026-02-25
updated: 2026-04-28
---

# Hooks & Automation Kit

> **What this provides:** Hook scripts, a shared helper library, and the `settings.local.json` hook configuration. A minimal setup uses 4 hooks; a mature project may run 13 across 7 event types. Start with the core 4 and add domain hooks as needed.

---

## Hook Architecture

```
Session Lifecycle:

  SessionStart ──→ session_context.sh ──→ Injects branch, plans,
                                          dailies, guide recommendations

  During Session:
    Edit/Write ──→ track_modified.sh  ──→ Accumulates modified file paths
    Edit/Write ──→ lint_on_edit.sh    ──→ Lint-on-save feedback (optional)

    git_commit ──→ on_commit.sh       ──→ Appends commit entry to daily note

    Bash ──→ mark_tests_run.sh        ──→ Tracks which tests passed (optional)

  PreToolUse:
    Bash ──→ check_domain_tests.sh    ──→ Block build if stale tests (optional)
    git_commit ──→ lint_precommit.sh  ──→ Block commit if lint fails (optional)

  Stop (task completion):
    ──→ enforce_task_tests.sh         ──→ Block if required tests not run (optional)

  PreCompact:
    auto ──→ pre_compact.sh           ──→ Snapshot modified_files before compaction

  SubagentStop:
    o7|reviewer|... ──→ on_agent_stop.sh ──→ Append agent summary to daily note

  SessionEnd ──→ session_cleanup.sh   ──→ Removes tracking file
```

### How Hooks Fire

Hooks are configured in `settings.local.json` and triggered by Claude Code's tool lifecycle:

| Event | Matcher | Script | Timing |
|-------|---------|--------|--------|
| Session starts/resumes | `startup\|resume` | `session_context.sh` | Sync (3s timeout) |
| File edited or written | `Edit\|Write` | `track_modified.sh` | Async (5s timeout) |
| File edited or written | `Edit\|Write` | `lint_on_edit.sh` | Sync (30s timeout) |
| Git commit via MCP | `mcp__git__git_commit` | `on_commit.sh` | Async (10s timeout) |
| Git commit via MCP | `mcp__git__git_commit` | `lint_precommit.sh` | Sync (120s timeout) |
| Task tool call | `Bash` | `mark_tests_run.sh` | Async |
| Bash tool call | `Bash` | `check_domain_tests.sh` | Sync (gate) |
| Subagent finishes | `o7\|reviewer\|...` | `on_agent_stop.sh` | Async (5s timeout) |
| PreCompact auto | `auto` | `pre_compact.sh` | Async (5s timeout) |
| Task completion | *(Stop event)* | `enforce_task_tests.sh` | Sync (5s timeout) |
| Session ends | *(SessionEnd)* | `session_cleanup.sh` | Sync (5s timeout) |

**Multiple hooks per event:** A single event matcher can trigger multiple scripts. See the PostToolUse `Edit|Write` example — it fires both `track_modified.sh` AND `lint_on_edit.sh`.

**Critical:** `on_commit.sh` matches `mcp__git__git_commit` specifically. If you use `bash git commit`, the hook never fires. Always use MCP git tools.

---

## Shared Helper: _common.sh

**Purpose:** Shared utilities sourced by all hook scripts. Provides logging, vault path, Obsidian CLI helpers, and a fallback daily-note writer.

**Location:** `.claude/hooks/_common.sh`

```bash
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
        # Fallback: direct file append
        local daily_note
        daily_note=$(ensure_daily_note) || return 1
        echo -e "$content" >> "$daily_note"
    fi
}

# ensure_daily_note — Creates daily note from template if needed, echoes path
# Kept as fallback for when Obsidian CLI is unavailable
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
```

**Hook composition order matters:** `track_modified.sh` must run before `on_commit.sh` — it accumulates the file list that the commit hook reads. Since both are async, this works naturally within a session (track fires during edits, commit fires at commit time).

---

## Core Hook 1: session_context.sh (SessionStart)

**Purpose:** Injects a context banner at session start showing current branch, active plans, recent daily notes, and recommended vault guides based on recently changed files.

**Location:** `.claude/hooks/session_context.sh`

```bash
#!/bin/bash
# session_context.sh - SessionStart hook
# Injects shared context: branch, active plans, recent dailies, guide recommendations

set -euo pipefail

source "${CLAUDE_PROJECT_DIR}/.claude/hooks/_common.sh"

BRANCH=$(git -C "$CLAUDE_PROJECT_DIR" branch --show-current 2>/dev/null || echo "unknown")

# Get active plans (as wikilinks)
ACTIVE_PLANS=""
if [ -d "${VAULT}/plans/active" ]; then
    ACTIVE_PLANS=$(ls -1 "${VAULT}/plans/active"/*.md 2>/dev/null | \
        sed 's|.*/||; s|\.md$||' | \
        awk '{print "- [["$0"]]"}' || echo "- No active plans")
fi
[ -z "$ACTIVE_PLANS" ] && ACTIVE_PLANS="- No active plans"

# Get recent daily notes (last 3 days)
RECENT_DAILIES=""
if [ -d "${VAULT}/daily" ]; then
    RECENT_DAILIES=$(ls -1t "${VAULT}/daily"/*.md 2>/dev/null | head -3 | \
        sed 's|.*/||; s|\.md$||' | \
        awk '{print "- [["$0"]]"}' || echo "- No recent daily notes")
fi
[ -z "$RECENT_DAILIES" ] && RECENT_DAILIES="- No recent daily notes"

RECENT_CHANGES=$(git -C "$CLAUDE_PROJECT_DIR" diff --name-only HEAD~5..HEAD 2>/dev/null | head -20 || echo "no recent changes")

# ┌─────────────────────────────────────────────────────────────────┐
# │ CUSTOMIZE: Guide recommendations based on changed file paths    │
# │ Add your own pattern→guide mappings below                       │
# └─────────────────────────────────────────────────────────────────┘
RECOMMENDED_GUIDES=""
# Example patterns — replace with YOUR project's domain→guide mappings:
#
# if echo "$RECENT_CHANGES" | grep -q "src/api\|routes"; then
#     RECOMMENDED_GUIDES="${RECOMMENDED_GUIDES}- [[api_best_practices]]
# "
# fi
# if echo "$RECENT_CHANGES" | grep -q "\.test\.\|__tests__"; then
#     RECOMMENDED_GUIDES="${RECOMMENDED_GUIDES}- [[testing_best_practices]]
# "
# fi

[ -z "$RECOMMENDED_GUIDES" ] && RECOMMENDED_GUIDES="- No specific guides recommended"

cat << EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SESSION CONTEXT (SessionStart Hook)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Branch: ${BRANCH}

Active Plans:
${ACTIVE_PLANS}

Recent Daily Notes:
${RECENT_DAILIES}

Recommended Guides (based on recent changes):
${RECOMMENDED_GUIDES}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF

exit 0
```

---

## Core Hook 2: track_modified.sh (PostToolUse — Edit|Write)

**Purpose:** Accumulates modified file paths to a tracking file. On commit, `on_commit.sh` reads this list to log which files were changed.

**Location:** `.claude/hooks/track_modified.sh`

```bash
#!/bin/bash
# track_modified.sh - PostToolUse hook for Edit|Write tools
# Accumulates modified file paths to a tracking file

set -euo pipefail

TRACKING_FILE="${CLAUDE_PROJECT_DIR}/.claude/sessions/modified_files.txt"

mkdir -p "$(dirname "$TRACKING_FILE")"
touch "$TRACKING_FILE"

# Parse tool call input to extract file path
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
```

> **Note:** This hook reads from `CLAUDE_TOOL_INPUT` (the input to the tool that triggered it), not `CLAUDE_TOOL_RESULT`. Adjust if your Claude Code version differs.

---

## Core Hook 3: on_commit.sh (PostToolUse — mcp__git__git_commit)

**Purpose:** Appends a commit entry to today's daily note in the vault, including commit message, timestamp, and modified files.

**Location:** `.claude/hooks/on_commit.sh`

```bash
#!/bin/bash
# on_commit.sh - PostToolUse hook for git_commit
# Appends commit entry to daily note via Obsidian CLI

set -euo pipefail

source "${CLAUDE_PROJECT_DIR}/.claude/hooks/_common.sh"

TRACKING_FILE="${CLAUDE_PROJECT_DIR}/.claude/sessions/modified_files.txt"
TIME=$(date +%H:%M)

# Extract commit message from tool result
COMMIT_MSG=""
if command -v jq &>/dev/null; then
    COMMIT_MSG=$(echo "$CLAUDE_TOOL_RESULT" | jq -r '.message // empty' 2>/dev/null || true)
fi
if [ -z "$COMMIT_MSG" ]; then
    log_error "Could not extract commit message from tool result"
    exit 0
fi

# Get modified files from tracking file
FILES=""
if [ -f "$TRACKING_FILE" ]; then
    FILES=$(tr '\n' ', ' < "$TRACKING_FILE" | sed 's/,$//')
fi

# Build the entry
ENTRY="\n### ${TIME} — Commit\n\n\`\`\`\n${COMMIT_MSG}\n\`\`\`\n\n**Files modified:** ${FILES:-none}\n\n---"

# Append to daily note
daily_append "$ENTRY" || log_error "Failed to append commit entry"

# Reset tracking file after commit
rm -f "$TRACKING_FILE"

exit 0
```

---

## Core Hook 4: session_cleanup.sh (SessionEnd)

**Purpose:** Cleans up transient tracking files when a session ends.

**Location:** `.claude/hooks/session_cleanup.sh`

```bash
#!/bin/bash
# session_cleanup.sh - SessionEnd hook
# Cleans up transient tracking files

set -euo pipefail

TRACKING_FILE="${CLAUDE_PROJECT_DIR}/.claude/sessions/modified_files.txt"

rm -f "$TRACKING_FILE"

exit 0
```

---

## Domain Hook Pattern Catalogue

These hooks are optional additions for mature setups. Add them as your project grows.

### Pattern 1: Lint on Save (PostToolUse — Edit|Write)

Runs a lightweight lint check after every file edit. Non-zero exit surfaces lint errors as blocking feedback to Claude.

```bash
#!/bin/bash
# lint_on_edit.sh — PostToolUse hook for Edit|Write
# Runs language-specific lint checks immediately after edits

set -euo pipefail

# Extract file path from tool input
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
        exit 0  # Unknown extension — skip
        ;;
esac

exit 0
```

### Pattern 2: Pre-commit Lint Gate (PreToolUse — mcp__git__git_commit)

Blocks the commit if lint fails. Runs synchronously so the commit tool call is cancelled on failure.

```bash
#!/bin/bash
# lint_precommit.sh — PreToolUse hook for git_commit
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
```

### Pattern 3: Test Enforcement Gate (Stop event)

Blocks task completion if domain-critical files were modified but relevant tests haven't been run this session.

```bash
#!/bin/bash
# enforce_task_tests.sh — Stop hook
# Blocks task completion if modified files require tests that haven't passed

INPUT=$(cat)

# Guard: prevent infinite loop (Stop hook re-fires after block)
STOP_ACTIVE="false"
if command -v jq &>/dev/null; then
    STOP_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null || echo "false")
fi
[ "$STOP_ACTIVE" = "true" ] && exit 0

SESSION_DIR="${CLAUDE_PROJECT_DIR}/.claude/sessions"
TRACKING="${SESSION_DIR}/modified_files.txt"
PASSED_FILE="${SESSION_DIR}/passed_tests.txt"

[ ! -f "$TRACKING" ] && exit 0

declare -A required_tests

# ┌─────────────────────────────────────────────────────────────────┐
# │ CUSTOMIZE: Map source file paths to required test binaries      │
# └─────────────────────────────────────────────────────────────────┘
while IFS= read -r filepath; do
    [ -z "$filepath" ] && continue
    case "$filepath" in
        # *src/auth/*)           required_tests[tst_auth]=1 ;;
        # *src/api/payments/*)   required_tests[tst_payments]=1 ;;
        *) ;;
    esac
done < "$TRACKING"

[ ${#required_tests[@]} -eq 0 ] && exit 0

# Subtract already-passed tests
if [ -f "$PASSED_FILE" ]; then
    while IFS= read -r passed; do
        unset "required_tests[$passed]" 2>/dev/null || true
    done < <(sort -u "$PASSED_FILE")
fi

[ ${#required_tests[@]} -eq 0 ] && exit 0

# Build outstanding test list
OUTSTANDING=""
for test_name in "${!required_tests[@]}"; do
    OUTSTANDING="${OUTSTANDING}  - ${test_name}\n"
done

echo -e "Modified critical files require test verification before completion.\n" >&2
echo -e "Outstanding tests:\n${OUTSTANDING}" >&2
exit 2
```

### Pattern 4: Agent Summary Logging (SubagentStop)

Appends agent findings to today's daily note when an agent finishes.

> **Important:** The `SubagentStop` matcher in `settings.local.json` (see the full hook config below) lists generic persona handles by default: `implementer|reviewer|investigator|safety|performance`. **You must substitute your actual persona handles before this hook will fire.** If you renamed `/implementer` to `/o7`, `/reviewer` to `/devil`, etc., set the matcher to `o7|devil|hanji|gojo|rock`. The matcher uses Bash regex syntax with `|` as alternation. A hook that never matches is silently broken.

```bash
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

# Truncate overly long summaries
if [ ${#SUMMARY} -gt 500 ]; then
    SUMMARY="${SUMMARY:0:500}..."
fi

TIME=$(date +%H:%M)
ENTRY="\n### ${TIME} — Agent: ${AGENT_NAME}\n\n${SUMMARY}\n\n---"

daily_append "$ENTRY" || log_error "Failed to append agent entry"

exit 0
```

### Pattern 5: PreCompact Snapshot

Preserves the modified-files tracking list before Claude Code compacts the context window.

```bash
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
```

---

## Helper Script: skill_context.sh

**Purpose:** Shared context helper for skill `!` command blocks. Provides subcommands that return vault links, git status, and other context data without triggering pipe-permission issues.

**Location:** `.claude/scripts/skill_context.sh`

```bash
#!/bin/bash
# Shared context helper for .claude/skills/ !`command` blocks.
# Single-command invocation avoids pipe-permission issues in skill preprocessing.
# Usage: bash .claude/scripts/skill_context.sh <subcommand> [args...]

VAULT="../{{VAULT_NAME}}"

case "$1" in
  vault-links)
    # List vault notes as wikilinks. $2 = subdir (e.g., "guides", "plans/active")
    ls -1 "$VAULT/$2"/*.md 2>/dev/null | sed 's|.*/||; s|\.md$||; s|^|- [[|; s|$|]]|' || echo "- none found"
    ;;
  vault-links-recent)
    # List N most recent vault notes as wikilinks. $2 = subdir, $3 = count (default 3)
    ls -1t "$VAULT/$2"/*.md 2>/dev/null | head -"${3:-3}" | sed 's|.*/||; s|\.md$||; s|^|- [[|; s|$|]]|' || echo "- none found"
    ;;
  git-changes-filtered)
    # Recent git changes filtered by regex. $2 = regex, $3 = count (default 10)
    git diff --name-status HEAD~5..HEAD 2>/dev/null | grep -E "${2:-.}" | head -"${3:-10}" || echo "no recent changes"
    ;;
  git-status-short)
    # Short git status. $2 = max lines (default 10)
    git status --short 2>/dev/null | head -"${2:-10}" || echo "no changes"
    ;;
  git-recent-changes)
    # Recent commit file changes. $2 = count (default 10)
    git diff --name-status HEAD~1..HEAD 2>/dev/null | head -"${2:-10}" || echo "no recent changes"
    ;;
  *)
    echo "Unknown subcommand: $1"
    ;;
esac
```

---

## settings.local.json Hook Configuration

Full hook configuration for a mature setup with all 13 hooks:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/session_context.sh",
            "timeout": 3
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/track_modified.sh",
            "timeout": 5,
            "async": true
          },
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/lint_on_edit.sh",
            "timeout": 30
          }
        ]
      },
      {
        "matcher": "mcp__git__git_commit",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/on_commit.sh",
            "timeout": 10,
            "async": true
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "mcp__git__git_commit",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/lint_precommit.sh",
            "timeout": 120
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/enforce_task_tests.sh",
            "timeout": 5
          }
        ]
      }
    ],
    "PreCompact": [
      {
        "matcher": "auto",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/pre_compact.sh",
            "timeout": 5,
            "async": true
          }
        ]
      }
    ],
    "SubagentStop": [
      {
        "matcher": "implementer|reviewer|investigator|safety|performance",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/on_agent_stop.sh",
            "timeout": 5,
            "async": true
          }
        ]
      }
    ],
    "SessionEnd": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/session_cleanup.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

### Hook Configuration Reference

| Field | Type | Description |
|-------|------|-------------|
| `matcher` | string (regex) | Tool name pattern to match. `\|` separates alternatives |
| `type` | `"command"` | Always `"command"` for shell scripts |
| `command` | string | Path to script. Use `$CLAUDE_PROJECT_DIR` for portability |
| `timeout` | number | Max seconds before hook is killed |
| `async` | boolean | If `true`, hook runs in background (doesn't block Claude) |

**Key rules:**
- SessionStart hooks must be **sync** — Claude waits for context before proceeding
- PostToolUse tracking hooks should be **async** — don't slow down the editing flow
- Lint hooks should be **sync** — Claude must see lint errors before continuing
- Gate hooks (lint-precommit, enforce-tests) must be **sync** and exit non-zero to block
- SessionEnd hooks should be **sync** — ensure cleanup completes before session dies
- Always `exit 0` in non-gate hooks — non-zero exit shows as hook failure

---

## Post-Setup Checklist

```bash
# Make scripts executable
chmod +x .claude/hooks/*.sh
chmod +x .claude/scripts/*.sh

# Create sessions directory
mkdir -p .claude/sessions

# Test session context hook manually
CLAUDE_PROJECT_DIR="$(pwd)" bash .claude/hooks/session_context.sh

# Test skill context helper
bash .claude/scripts/skill_context.sh git-status-short
bash .claude/scripts/skill_context.sh vault-links guides
```

### Starter Hook Set (minimal)

If you want to start lean:

| Hook | Event | Required? |
|------|-------|-----------|
| `session_context.sh` | SessionStart | Yes — context injection |
| `track_modified.sh` | PostToolUse(Edit\|Write) | Yes — feeds on_commit |
| `on_commit.sh` | PostToolUse(git_commit) | Yes — daily note tracking |
| `session_cleanup.sh` | SessionEnd | Yes — cleanup |
| `_common.sh` | (sourced) | Yes — shared helpers |
| `on_agent_stop.sh` | SubagentStop | Add when using orchestrator |
| `lint_on_edit.sh` | PostToolUse(Edit\|Write) | Add when lint is configured |
| `pre_compact.sh` | PreCompact | Add for long sessions |
| `enforce_task_tests.sh` | Stop | Add for test-critical domains |
