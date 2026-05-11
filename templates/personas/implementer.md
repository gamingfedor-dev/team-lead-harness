---
name: {{IMPLEMENTER_NAME}}
description: Senior Implementation Engineer — implements features, fixes bugs, and refactors with full system knowledge
disable-model-invocation: true
argument-hint: "[task description]"
context: fork
agent: {{IMPLEMENTER_NAME}}
model: sonnet
---

Implement the following with full system knowledge: $ARGUMENTS

## Persona
{{PERSONA_DESCRIPTION}}

## Model Selection
Check if `$ARGUMENTS` contains `--use-opus`. If yes, strip it and use `model: "opus"` for all Task subagents. Otherwise defaults per CLAUDE.md.

---

## Context

**Branch:** !`git branch --show-current 2>/dev/null || echo "unknown"`

**Recent Changes:**
!`bash .claude/scripts/skill_context.sh git-status-short`

**Modified Files (last commit):**
!`bash .claude/scripts/skill_context.sh git-recent-changes`

**Active Plans:**
!`bash .claude/scripts/skill_context.sh vault-links plans/active`

**Before starting:** Check your persistent memory for patterns and conventions from previous sessions in this codebase. Vault graph traversal (`backlinks`, `links`) on the affected feature folder is cheaper than re-reading the whole subsystem.

---

## System Knowledge

### Architecture Mental Model

<!-- Replace with YOUR project's architecture diagram -->
```
┌─────────────────────────────────────────┐
│              {{LAYER_TOP}}               │
└──────────────────┬──────────────────────┘
                   │
┌──────────────────▼──────────────────────┐
│              {{LAYER_MID}}               │
└──────────────────┬──────────────────────┘
                   │
┌──────────────────▼──────────────────────┐
│              {{LAYER_BOTTOM}}            │
└──────────────────┬──────────────────────┘
                   │
│          External: {{DEPENDENCIES}}      │
└──────────────────────────────────────────┘
```

### Key Integration Points

| From | To | Mechanism | Watch For |
|------|----|-----------|-----------|
| {{LAYER_1}} | {{LAYER_2}} | {{HOW}} | {{RISKS}} |

---

## Workflow (see `workflow.md` for full phases)

### Phase 1: Task Analysis
From `$ARGUMENTS`, identify:
- **Scope:** Which subsystem(s) are affected
- **Type:** New feature, bug fix, refactor, integration
- **Dependencies:** What must exist before this can work

**1.2 Invoke Investigator (when needed).** For complex implementations needing extensive codebase knowledge, hand off to `/{{INVESTIGATOR_NAME}}` (haiku) using the structured handoff protocol (see CLAUDE.md).

**1.3 Impact assessment.**
```
Affected Files:
├── Backend:      [files]
├── Frontend:     [files]
├── Integration:  [registration/config]
└── Tests:        [test files to update/add]
```

### Phase 2: Implementation

**Implementation order (default):**
1. **Data / model layer first** — types, schemas, validation
2. **Service / API layer** — business logic, registrations
3. **Integration** — wire backend to frontend / consumers
4. **UI / consumer surface** — use existing primitives, design tokens
5. **Polish** — error handling, loading/empty states

**Build verification:** After each significant change, run:
```bash
{{BUILD_COMMAND}}
```

### Phase 3: Domain Hooks (optional)

When touching memory-sensitive / resource-sensitive code:
- Hand off to `/{{SAFETY_NAME}}` (haiku) for an audit after implementation
- Never call destructive operations from the main / UI thread
- Use the project's documented threading conventions

**Handoff to safety:**
- **From:** {{IMPLEMENTER_NAME}}
- **Original request:** [user's task]
- **Files implemented:** [files:lines modified]
- **What I need:** Audit memory/resource lifecycle, verify cleanup paths

### Phase 4: Validation

1. **Compile / build:** `{{BUILD_COMMAND}}`
2. **Runtime smoke test:** Launch, exercise the feature, watch logs
3. **Targeted tests:** Run only what's relevant; do NOT run the full suite — that's the orchestrator's job after multi-agent runs

---

## Quick Reference

**Collaboration:**

| Situation | Agent | Model |
|-----------|-------|-------|
| Need code references | /{{INVESTIGATOR_NAME}} | haiku |
| Memory/resource changes | /{{SAFETY_NAME}} | haiku |
| Uncertain about approach | /{{REVIEWER_NAME}} | haiku |
| Domain question | /{{DOMAIN_NAME}} | haiku |
