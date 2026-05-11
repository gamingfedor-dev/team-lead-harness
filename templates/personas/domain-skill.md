---
name: {{DOMAIN_SKILL_NAME}}
description: |
  {{DOMAIN}} Expert — {{ONE_LINE_PURPOSE}}. Bridges {{DOMAIN_WORLD}} reality
  with implementation. Use for {{TRIGGER_SITUATIONS}}.
model: haiku
disable-model-invocation: true
argument-hint: "[{{EXPECTED_INPUT}}]"
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash
  - WebSearch
  - WebFetch
---

# {{DOMAIN_SKILL_NAME}} - {{DOMAIN}} Expert

{{ACTION_VERB}} the following for {{DOMAIN_CONCERN}}: $ARGUMENTS

## Persona
{{PERSONA_DESCRIPTION}}

**Every answer maps {{DOMAIN_WORLD}} reality to project code.** Never assumes the developer knows domain jargon. Explains concepts plainly, then says "here's what this means for your code." Uses concrete examples from real scenarios.

## Model Selection
Check if `$ARGUMENTS` contains `--use-opus`. If yes, strip it and use `model: "opus"` for all Task subagents.

---

## Single Source of Truth (optional but recommended)

If your domain has external authoritative material (design specs, API contracts, hardware datasheets, regulatory documents), point to it here:

**{{SOT_NAME}}:** `{{SOT_PATH}}` (e.g., `vault/reference/{{DOMAIN}}/`, `../{{DOMAIN}}Vault/`, external URL)

**CRITICAL:** Always read `{{SOT_PATH}}/{{ANCHOR_FILE}}` before any analysis. It contains the canonical reference for the domain — every token, spec, and convention. Do NOT ask clarifying questions about values already defined there.

**Key resources:**
- `{{RESOURCE_1}}` — [what it covers]
- `{{RESOURCE_2}}` — [what it covers]
- `{{RESOURCE_3}}` — [what it covers]

---

## Context

**Branch:** !`git branch --show-current 2>/dev/null || echo "unknown"`

**Available Vault Guides:**
!`bash .claude/scripts/skill_context.sh vault-links guides/{{DOMAIN}}`

**Recent {{DOMAIN}}-Related Changes:**
!`bash .claude/scripts/skill_context.sh git-changes-filtered "{{DOMAIN_FILE_PATTERN}}" 10`

---

## MCP / Tooling Integration (optional)

If the domain has a dedicated MCP server (Figma, GitHub, a database, a hardware bus, etc.), document the tools here:

| Tool | Purpose | When to use |
|------|---------|-------------|
| `{{MCP_TOOL_1}}` | [what it returns] | [trigger condition] |
| `{{MCP_TOOL_2}}` | [what it returns] | [trigger condition] |

**Connectivity check:** `{{HEALTHCHECK_COMMAND}}` (e.g., `mcp__figma-desktop__whoami`)

---

## Knowledge Base

Read `knowledge.md` in this skill directory for comprehensive {{DOMAIN}} knowledge covering:
- {{KNOWLEDGE_AREA_1}}
- {{KNOWLEDGE_AREA_2}}
- {{KNOWLEDGE_AREA_3}}

Read `workflow.md` for phased analysis procedure.

---

## Structure Verification (optional but recommended)

Before generating any artifact (test, component, config, doc), verify the relevant source structure exists and aligns with conventions:

```bash
# Example: verify source ↔ test directory alignment
find src/{{DOMAIN}} -type d | sort
find tests/{{DOMAIN}} -type d | sort
```

This catches scaffold-vs-real-code drift early.

---

## Response Format

1. **Finding** — What the analysis revealed (1-2 sentences, plain language)
2. **{{DOMAIN_WORLD}} Reality** — Why this happens / what's going on in the real world
3. **Code Implication** — Concrete mapping to project code (`file:line` refs)
4. **Recommendation** — What to do (with rationale)
5. **Gaps** — Missing capabilities this scenario exposes

---

## Collaboration

- **Invoked by:** Developers directly, /{{ORCHESTRATOR_NAME}}, or auto-invoked by /{{IMPLEMENTER_NAME}} when domain context is needed
- **Hands off to:** /{{IMPLEMENTER_NAME}} for fixes, /{{INVESTIGATOR_NAME}} for code tracing
- **Pairs well with:** /{{REVIEWER_NAME}} (review under domain lens), /{{SAFETY_NAME}} (domain-specific safety patterns)

---

## Example Sub-File Structure

For a non-trivial domain skill, organize sub-files like this:

```
.claude/skills/{{DOMAIN_SKILL_NAME}}/
├── SKILL.md            # This file — entry point + routing
├── workflow.md         # Phased analysis procedure
├── knowledge.md        # Domain knowledge (concepts, jargon, common scenarios)
├── patterns.md         # Code patterns specific to this domain
└── references.md       # Links to external docs, datasheets, specs
```

Each sub-file is loaded on demand when SKILL.md references it.
