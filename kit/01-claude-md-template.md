---
title: "CLAUDE.md Template"
type: reference
tags: [portable-setup, white-label, template]
version: "2.0"
created: 2026-02-25
updated: 2026-04-28
---

# CLAUDE.md Template

> **Instructions:** Copy this template to your project root as `CLAUDE.md`. Replace all `{{PLACEHOLDER}}` sections with your project-specific content. Delete sections that don't apply. The comments (`<!-- ... -->`) explain each section — remove them after filling in.

---

```markdown
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

<!-- 2-3 sentences: what the app does, who uses it, core tech -->
{{PROJECT_NAME}} is a {{FRAMEWORK}} {{APPLICATION_TYPE}} that {{WHAT_IT_DOES}}.
It uses {{KEY_TECHNOLOGIES}} and targets {{DEPLOYMENT_TARGET}}.

## Mission-Critical Context

<!-- Delete this section if your project isn't safety/reliability critical -->
<!-- If it IS critical, spell out the operational context so Claude understands the stakes -->

**IMPORTANT:** {{PROJECT_NAME}} is {{CRITICALITY_DESCRIPTION}}.

### Operational Context

- **Purpose:** {{WHAT_USERS_DO_WITH_IT}}
- **Users:** {{WHO_USES_IT}}
- **Criticality:** {{WHAT_HAPPENS_IF_IT_FAILS}}
- **Deployment:** {{WHERE_IT_RUNS}}

### Performance & Reliability Targets

<!-- Define concrete, measurable targets. These become acceptance criteria. -->

| Metric | Target | Critical Threshold |
|--------|--------|--------------------|
| {{METRIC_1}} | {{TARGET}} | {{CRITICAL}} |
| {{METRIC_2}} | {{TARGET}} | {{CRITICAL}} |

**Non-Negotiables:**
- {{RELIABILITY_RULE_1}}
- {{RELIABILITY_RULE_2}}

### Code Quality Implications

When implementing features or fixing bugs:
1. {{QUALITY_RULE_1}}
2. {{QUALITY_RULE_2}}
3. {{QUALITY_RULE_3}}

## Development Principles

- **Root-cause fixes only.** Identify the root cause and apply a proper architectural fix. Never apply bandaid/patch fixes.
- **Scope discipline.** Implement ONLY what was asked. If you think something else should change, mention it but don't do it.

## Agent Selection (Default Behavior)

<!-- This routing table tells Claude which skill to auto-invoke for each request type -->
<!-- Customize skill names and patterns to match YOUR personas -->
<!-- Concrete examples: /o7 = implementer, /devil = reviewer, /hanji = investigator -->

When user requests work without specifying an agent, select the appropriate agent directly:

| Request Pattern | Agent | Default Model (if Task) |
|----------------|-------|------------------------|
| Implement/add feature | /{{IMPLEMENTER_SKILL}} | sonnet |
| Fix bug/crash/error | /{{IMPLEMENTER_SKILL}} | sonnet |
| Code review | /{{REVIEWER_SKILL}} | haiku |
| Memory/safety audit | /{{SAFETY_SKILL}} | haiku |
| Performance issue | /{{PERFORMANCE_SKILL}} | haiku |
| Explain/teach concept | /{{MENTOR_SKILL}} | - (main conv) |
| Investigation/research | /{{INVESTIGATOR_SKILL}} | haiku |
| Complex multi-domain (3+ specialists) | /{{ORCHESTRATOR_SKILL}} | - (main conv) |

**Do NOT auto-invoke for:** Simple questions, direct agent requests, basic file operations, clarifications.

**Model override:** Pass `--use-opus` flag to any skill to force all Task subagents to use Opus. Example: `/{{IMPLEMENTER_SKILL}} --use-opus [task]`

### Tier Assignment (for Orchestrator)

The orchestrator assigns one of three reasoning tiers — **Operator**, **Engineer**, **Lead** — to every subagent. The tier injects cognitive scaffolding into the prompt; it does not change the model. Default to Operator (retrieval). Promote only with written justification. Production-critical adversarial review is the one deliberate exception where Opus may be used.

### When to Use Skill vs Command vs Agent

| Format | Use when |
|--------|----------|
| Skill (`.claude/skills/NAME/SKILL.md`) | Persona needs sub-files (workflow steps, checklists, knowledge bases) |
| Command (`.claude/commands/NAME.md`) | Simple single-page prompt, no reference material needed |
| Agent (`.claude/agents/NAME.md`) | Spawned by orchestrator via Task tool; needs model + memory config |

## Documentation Practices — Vault as Single Source of Truth

**IMPORTANT:** The Obsidian vault at `../{{VAULT_NAME}}/` (accessible via `vault/` symlink) is the **single source of truth** for all project knowledge.

**Vault-first rules:**
- **Never add or update markdown (`.md`) in the project folder.** All documentation goes in the vault.
- **Always update the vault based on chat context** when the conversation produces durable value.
- **Read from the vault first** when starting work: check guides, active plans, and relevant decisions.

**Vault access:**
- **Primary:** Obsidian CLI (`obsidian daily:append content="..." vault={{VAULT_NAME}}`)
- **In Claude Code sessions:** MCP tools (`mcp__obsidian__*`) when REST API is available
- **Direct fallback:** Read/Write tools on `../{{VAULT_NAME}}/`

**Documentation structure:**
- `vault/guides/` — Best practices and how-to guides (organized by technology subdirectory)
- `vault/plans/` — Implementation plans (active/, planning/, legacy/completed/, legacy/superseded/)
- `vault/analysis/` — Post-mortems and investigations
- `vault/reference/` — External references and cheatsheets
- `vault/decisions/` — Architectural decision records
- `vault/daily/` — Auto-populated daily dev logs

### Vault Documentation Protocol

**Automated tracking via hooks:**
- File modifications tracked automatically via PostToolUse hooks
- Commit entries appended to daily notes automatically after git commits
- Session context (branch, active plans, recent dailies) injected at session start
- Agent findings appended via SubagentStop hook

**Git commit requirements:**
- **ALWAYS use MCP git tools** (`mcp__git__git_commit`, `mcp__git__git_add`) instead of bash `git` commands
- PostToolUse hooks are registered on MCP tool matchers — native bash git bypasses hooks entirely
- **Commit message format:** Conventional Commits: `type(scope): subject`

## Build Commands

<!-- Replace with your actual build commands -->

**Full build:**
```bash
{{FULL_BUILD_COMMAND}}
```

**Incremental build:**
```bash
{{INCREMENTAL_BUILD_COMMAND}}
```

**Debug mode:**
```bash
{{DEBUG_BUILD_COMMAND}}
```

## Tech Stack

- **Language:** {{LANGUAGE_AND_VERSION}}
- **Framework:** {{FRAMEWORK_AND_VERSION}}
- **Build System:** {{BUILD_SYSTEM}}

## Architecture

### Key Directories

```
{{DIRECTORY_TREE}}
```

## Code Style, Naming & Organization

### Naming Conventions

| Element | Pattern | Example |
|---------|---------|---------|
| Classes | `PascalCase` | `{{EXAMPLE}}` |
| Methods/Functions | `{{PATTERN}}` | `{{EXAMPLE}}` |
| Variables | `{{PATTERN}}` | `{{EXAMPLE}}` |
| Constants | `{{PATTERN}}` | `{{EXAMPLE}}` |

### Comment Style

Comments explain *why*, not *what*. Bad or stale comments are worse than none.

## Logging

Use {{LOGGING_FRAMEWORK}} for all debug logging.

### Rules
- All debug logs use {{DEBUG_LOG_CALL}} — hidden by default
- All warnings/errors use {{WARNING_LOG_CALL}} — always visible
- Never use raw print/console.log for production output
- No logging in tight loops

## Best Practices

Read the relevant guide before implementing or reviewing code in that area:

| Guide | Covers |
|-------|--------|
| `vault/guides/{{GUIDE_1}}.md` | {{WHAT_IT_COVERS}} |
| `vault/guides/{{GUIDE_2}}.md` | {{WHAT_IT_COVERS}} |

## Token Preservation Strategy

**CRITICAL: Agents are expensive. Direct tools are free.**

### Data Retrieval — NEVER use agents
- **Use Grep/Glob/Read directly** for ALL code searches, file lookups, and data gathering
- Each Task agent costs 30-40k tokens minimum (even Haiku)
- Direct tools cost ~0 extra tokens

### Agent Usage — ONLY for synthesis/judgment
- **DO NOT** spawn agents to find code, read files, or grep patterns
- **Exception:** The investigator skill (/{{INVESTIGATOR_SKILL}}) may do retrieval when it involves web searches or vault searches that direct tools cannot access
- **DO** use agents when you need reasoning over already-gathered data
- **Max budget:** ~5-7k tokens per agent, ~20k total for multi-agent work

### Tests Run Once
- When the orchestrator spawns multiple agents, each individual agent must NOT run tests
- The orchestrator runs the full test suite exactly once after all agents complete

## Skills & Agents

All skills are in `.claude/skills/` and `.claude/commands/`. Subagent metadata lives in `.claude/agents/`.

### Quick Routing

- **Implement/fix:** /{{IMPLEMENTER_SKILL}} | **Review:** /{{REVIEWER_SKILL}} | **Research:** /{{INVESTIGATOR_SKILL}}
- **Safety/memory:** /{{SAFETY_SKILL}} | **Performance:** /{{PERFORMANCE_SKILL}} | **Teach:** /{{MENTOR_SKILL}}
- **Orchestrate:** /{{ORCHESTRATOR_SKILL}} | **Pragmatic:** /{{PRAGMATIST_SKILL}}

### Skill Handoff Protocol

When skills collaborate, use this protocol to maintain traceability:

**Invoking Skill Provides:**
- **From:** [skill name]
- **Original request:** [user's original task, verbatim]
- **Key findings so far:** [2-3 bullets from prior analysis]
- **Files identified:** [file:line references]
- **What I need from you:** [specific question, not "investigate everything"]

**Invoked Skill Returns:**
- **For:** [requesting skill name]
- **Findings:** [structured per skill's report template]
- **Confidence:** [High/Medium/Low]
- **Recommended next:** [which skill should run next, if any]

## Testing

**Run tests:**
```bash
{{TEST_COMMAND}}
```

**Headless / CI:**
```bash
{{HEADLESS_TEST_COMMAND}}
```
```

---

## Customization Notes

### Sections to Always Include
- Project Overview
- Agent Selection routing table (with concrete skill names, not generic "IMPLEMENTER_SKILL")
- Vault Documentation Protocol
- Build Commands
- Tech Stack
- Key Directories
- Token Preservation Strategy
- Skills & Agents quick routing

### Sections to Include If Applicable
- Mission-Critical Context (safety/reliability-critical projects)
- Performance & Reliability Targets (latency-sensitive apps)
- Logging (projects with structured logging)
- Best Practices guide table (link to vault guides)

### Sections to Omit
- Detailed skill descriptions (those live in skill files)
- Vault template content (that's in the vault)
- Hook script content (that's in `.claude/hooks/`)
- Tier definitions in full detail (link to orchestrator skill instead)
