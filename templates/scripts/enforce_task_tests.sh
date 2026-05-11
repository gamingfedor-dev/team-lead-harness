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

OUTSTANDING=""
for test_name in "${!required_tests[@]}"; do
    OUTSTANDING="${OUTSTANDING}  - ${test_name}\n"
done

echo -e "Modified critical files require test verification before completion.\n" >&2
echo -e "Outstanding tests:\n${OUTSTANDING}" >&2
exit 2
