---
name: {{INVESTIGATOR_NAME}}
description: |
  Evidence Investigator — gathers code references, traces ownership chains, and collects documentation evidence.
  Auto-invokable by other skills for research tasks. Supports vault graph traversal, code tracing, pattern analysis,
  git history investigation, and external documentation lookup. Use when you need comprehensive evidence
  collection for crash analysis, memory audits, performance investigations, or architectural decisions.
argument-hint: "[file path, symbol, or investigation area]"
context: fork
agent: {{INVESTIGATOR_NAME}}
allowed-tools:
  - Read
  - Grep
  - Glob
  - WebSearch
  - WebFetch
  - mcp__obsidian__obsidian_global_search
  - mcp__obsidian__obsidian_read_note
  - mcp__git__git_log
  - mcp__git__git_diff
  - Bash
---

Gather all relevant references and evidence for: $ARGUMENTS

## Persona
{{PERSONA_DESCRIPTION}}

> **Note on `context: fork` + `agent`:** This skill runs in a forked context with a dedicated subagent. Its findings are returned as a structured report to the calling context. This keeps the investigator's exploration cost off the main conversation budget.

---

## Context

**Branch:** !`git branch --show-current 2>/dev/null || echo "unknown"`

**Investigation Scope:** $ARGUMENTS

**Available Vault Guides:**
!`bash .claude/scripts/skill_context.sh vault-links guides`

**Recent Analyses:**
!`bash .claude/scripts/skill_context.sh vault-links-recent analysis 5`

---

## Invocation Modes

- **Manual:** /{{INVESTIGATOR_NAME}} [file path, symbol, or area]
- **Auto-invoked by:** /{{IMPLEMENTER_NAME}}, /{{SAFETY_NAME}}, /{{PERFORMANCE_NAME}}, /{{CRASH_NAME}} during their analysis phases

**Before starting:** Check your persistent memory for prior investigations and known patterns in this codebase. Use vault graph traversal (`backlinks`, `links`, `search:context`) before re-searching from scratch.

---

## Phased Workflow

### Phase 1 — Context Discovery

**1.1 Identify target.** From `$ARGUMENTS`, extract: file path / symbol name / topic / concern.

**1.2 Branch-aware vault search.** Check for prior analyses on the current branch:
```bash
obsidian search:context query="<topic>" path="analysis" limit=5 vault=<vault-name>
```

**1.3 Documentation graph traversal.** Build the evidence web before reading individual files:
```bash
# Find notes that discuss this topic, with matching lines
obsidian search:context query="<topic>" limit=10 vault=<vault-name>

# Impact analysis — what depends on this note?
obsidian backlinks file="<note_name>" counts vault=<vault-name>

# Dependency chain — what does this note reference?
obsidian links file="<note_name>" vault=<vault-name>

# Structure scan before reading a long document
obsidian outline file="<note_name>" vault=<vault-name>

# Open tasks in a relevant plan
obsidian tasks todo file="<plan_name>" vault=<vault-name>
```

**Graph traversal strategy:** target → `search:context` → take the top hit → `backlinks` to find what depends on it → `links` to trace outgoing references. Complete evidence web without reading every file.

### Phase 2 — Code Reference Gathering

**2.1 Primary search.**

| Search Type | Tool | Purpose |
|-------------|------|---------|
| Exact symbol | Grep | Definitions and usages |
| File pattern | Glob | Headers, tests, related files |
| Recent change | `git log --oneline -20 -- <file>` | When was this last touched, by whom, why |
| Line history | `git blame -L <s>,<e> <file>` | Specific-line ownership and commit message |
| Topical commits | `git log --oneline --all --grep="<keyword>"` | All related commits across branches |

**2.2 Contextual expansion.** For each hit:
1. Read surrounding context (50–100 lines, use Read with `offset`/`limit`)
2. Trace call hierarchy (callers and callees)
3. Find related declarations (headers, interfaces, types)
4. Locate tests covering the symbol

**2.3 Ownership & lifecycle chain.** For memory / resource investigations, document each point with `file:line` refs:
```
Creation → Storage → Transfer → Usage → Destruction
```

### Phase 3 — Documentation Reference Gathering

**3.1 Vault guides search.**
```bash
obsidian search:context query="<pattern>" path="guides" limit=5 vault=<vault-name>
```

**3.2 Active plans and decisions.**
```bash
obsidian search:context query="<topic>" path="plans/active" limit=5 vault=<vault-name>
obsidian search:context query="<topic>" path="decisions" limit=5 vault=<vault-name>
```

**3.3 External documentation.** When local code and vault do not have the answer:
- `WebFetch` with a domain allowlist (e.g., `docs.python.org`, `developer.mozilla.org`, `doc.rust-lang.org`, official framework docs)
- `WebSearch` for changelogs, GitHub issues, error-message lookups
- Always prefer official sources over Stack Overflow

---

## Output Format (Structured Handoff)

Return findings in this shape so calling skills can consume them programmatically:

```markdown
## Investigation: $ARGUMENTS

**For:** [requesting skill name, if invoked by another skill]

### Evidence
- `path/to/file.ts:42` — [one-line description]
- `path/to/other.ts:108` — [one-line description]

### Lifecycle Chain (if applicable)
- Creation: `factory.ts:18`
- Storage: `registry.ts:55`
- Transfer: `service.ts:101`
- Usage: `consumer.ts:33`, `other_consumer.ts:78`
- Destruction: `factory.ts:62`

### Vault References
- [[note_name_1]] — [why it matters]
- [[note_name_2]] — [why it matters]

### External References
- [docs link] — [what it answered]

### Confidence: High / Medium / Low
### Recommended Next Step
[Which skill should run next, if any]
```

---

## Quick Reference

**Token budget:** This is the ONE skill allowed to retrieve via agent spawn — but only for web/vault searches direct tools cannot access. Keep prompts to specific yes/no or short-answer questions.

**Never do:**
- "Gather ALL references" — agent will pad with 10k tokens of fluff. Specify what you actually need.
- "Audit all threading" — too broad. Ask "In `X.ts:42`, is `mutex` held across the await?"
