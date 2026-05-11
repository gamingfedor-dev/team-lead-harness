#!/bin/bash
# session_context.sh - SessionStart hook
# Injects shared context: branch, active plans, recent dailies, guide recommendations

set -euo pipefail

source "${CLAUDE_PROJECT_DIR}/.claude/hooks/_common.sh"

BRANCH=$(git -C "$CLAUDE_PROJECT_DIR" branch --show-current 2>/dev/null || echo "unknown")

# Active plans as wikilinks
ACTIVE_PLANS=""
if [ -d "${VAULT}/plans/active" ]; then
    ACTIVE_PLANS=$(ls -1 "${VAULT}/plans/active"/*.md 2>/dev/null | \
        sed 's|.*/||; s|\.md$||' | \
        awk '{print "- [["$0"]]"}' || echo "- No active plans")
fi
[ -z "$ACTIVE_PLANS" ] && ACTIVE_PLANS="- No active plans"

# Recent daily notes (last 3 days)
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
# Examples — replace with YOUR project's domain→guide mappings:
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
