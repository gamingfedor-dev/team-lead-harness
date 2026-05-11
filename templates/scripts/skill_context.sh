#!/bin/bash
# skill_context.sh — Shared context helper for .claude/skills/ !`command` blocks
# Single-command invocation avoids pipe-permission issues in skill preprocessing
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
