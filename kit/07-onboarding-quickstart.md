---
title: "Onboarding Quickstart — New to Claude Code"
type: guide
tags: [portable-setup, onboarding, quickstart]
version: "2.0"
created: 2026-04-28
updated: 2026-04-28
---

# Onboarding Quickstart — New to Claude Code

> **For:** A colleague who has used Claude.ai chat but has never worked with Claude Code. This guide gets you productive in 5 minutes.

---

## What is Claude Code?

Claude.ai chat is a conversational interface — you type, Claude responds, you start fresh next time.

Claude Code is different. It is a CLI tool that runs inside your project directory and has direct access to your files, terminal, and git history. It can read every file in your codebase, run shell commands, edit code, and commit — all in the same conversation.

Key differences:

| Claude.ai chat | Claude Code |
|---------------|-------------|
| Stateless — fresh each time | Persistent — context stays across a session |
| Cannot touch files | Can read, write, and run anything in your project |
| One model, one conversation | Multiple agents can run in parallel |
| Generic assistant | Configured per-project via CLAUDE.md |

---

## What This Kit Gives You

This portable-setup kit configures Claude Code with a structured system on top of the bare CLI. When set up, you get:

1. **Specialized personas** — Instead of one generic Claude, you have named skill agents: an implementer, a reviewer, an investigator, a mentor, etc. You invoke them with slash commands like `/implementer add login flow`.

2. **Session context injection** — Every Claude Code session starts with a summary of your current branch, active plans, and recent work. Claude knows where you left off.

3. **Automatic commit tracking** — When you commit via Claude Code, the commit message and changed files are automatically appended to today's note in your knowledge vault.

4. **Knowledge vault** — An Obsidian folder (separate from your code repo) where decisions, daily logs, plans, and guides accumulate over time. Claude Code reads from it and writes to it automatically.

5. **Token budget discipline** — Rules that prevent Claude from spawning expensive sub-agents when a simple file search would do the same job for free.

---

## First-Day Checklist — Pick Your Depth

Three onboarding paths. Each step is independently skippable; do as much as you want today.

### Path 1 — Bare Minimum (5 min)

Just get Claude Code running with this kit's CLAUDE.md.

- [ ] Install Claude Code: `npm install -g @anthropic-ai/claude-code`
- [ ] Verify it works: `cd your-project && claude`
- [ ] Check that CLAUDE.md exists at the project root
- [ ] Start a session: `claude` — should not error

You can stop here and use Claude Code as a vanilla CLI. Everything below is enhancement.

### Path 2 — Productive Setup (15 min)

Add personas + session context.

Prerequisites: Path 1 done.

- [ ] Check that `.claude/` exists with `skills/`, `commands/`, and at least one persona file
- [ ] Try a skill: `/implementer hello world` — should load and respond
- [ ] Try a command: `/mentor explain the routing table in CLAUDE.md`
- [ ] (Optional) Verify the SessionStart context banner shows current branch + recent work

If the banner does not appear, hooks are not running. Skip this and continue — you can revisit Path 3.

### Path 3 — Full Experience (30 min total)

Add the vault + hooks for persistent knowledge tracking.

Prerequisites: Path 2 done.

- [ ] Confirm the vault exists at `../YourProjectVault/` (or set one up — see [04-vault-blueprint.md](04-vault-blueprint.md))
- [ ] Test Obsidian CLI: `obsidian daily:read vault=<your-vault-name>` — should print today's note (or an empty result, not an error)
- [ ] Make `.claude/hooks/*.sh` executable: `chmod +x .claude/hooks/*.sh`
- [ ] Verify `settings.local.json` exists and lists the hooks
- [ ] Make a test commit via `mcp__git__git_commit` — check that today's daily note in the vault gains an entry

> **Diving into one specific module?** Each kit file is self-contained. Skip the path above and jump straight to:
> - **Just hooks** → [03-hooks-kit.md](03-hooks-kit.md)
> - **Just personas** → [02-skill-catalog.md](02-skill-catalog.md)
> - **Just vault layout** → [04-vault-blueprint.md](04-vault-blueprint.md)
> - **Just settings** → [06-settings-reference.md](06-settings-reference.md)

---

## How to Think About Skills, Commands, and Agents

These three terms sound similar but are distinct:

### Skills

A skill is a specialized persona you invoke with a slash command. It lives in `.claude/skills/NAME/SKILL.md`. When you type `/implementer [task]`, Claude Code loads that file and adopts the implementer persona for that task.

Skills can have sub-files (`workflow.md`, `checklist.md`, `patterns.md`) that are loaded progressively — only when the skill needs them. This keeps the initial token cost low.

Example invocation:
```
/implementer add dark mode toggle to the settings page
/reviewer check the dark mode implementation for edge cases
/investigator find all places that read the theme setting
```

### Commands

A command is a simpler slash command that lives in a single file at `.claude/commands/NAME.md`. No sub-files, no progressive loading — the whole prompt loads at once. Commands are used for simpler personas (mentor, pragmatist, vault navigator, weekly summary generator).

Example invocation:
```
/mentor explain how React context propagation works
/vault recent 5
/weekly
```

### Agents

An agent file at `.claude/agents/NAME.md` is not directly invoked by you. It is metadata consumed by the orchestrator (the `/otto` skill) when it spawns a multi-agent team via Claude Code's Task tool. Agent files configure model, memory scope, and which skills are loaded into the spawned agent.

You interact with agents indirectly:
```
/otto refactor the auth module, review for security issues, and run tests
```
Otto reads the task, decides which agents to spawn (e.g., investigator + implementer + reviewer), assigns reasoning tiers, and dispatches them.

### Summary

| You type | Mechanism | When |
|----------|-----------|------|
| `/skill-name [args]` | Skill or Command | Direct work: implement, review, investigate, teach |
| `/otto [complex task]` | Orchestrator (Command) | Multi-domain work needing 3+ specialists |
| *(nothing)* | Agent files | Never invoked directly — used by Otto's Task tool |

---

## When to Ask Claude vs Do It Yourself

Claude Code is a power tool. It works best when you are specific about what you want and maintain judgment over the result.

**Let Claude Code handle:**
- Writing boilerplate, wiring up registrations, generating tests
- Searching for all usages of a function across 40 files
- Reformatting a large block of code to a new style
- Researching the vault for prior decisions on a topic
- Committing with a well-formed conventional commit message

**Keep judgment yourself:**
- Whether an architectural decision is the right one
- Whether a code review finding is actually a problem in context
- Whether the implementation matches the user's intent (not just the spec)
- When to stop iterating and ship

**The routing table in CLAUDE.md** tells Claude Code which skill to auto-invoke for common request patterns. When you say "fix the login bug", Claude Code checks the routing table and runs the implementer skill directly, without waiting for you to type `/implementer`. You can always override by typing the skill explicitly.

---

## Glossary

| Term | Definition |
|------|-----------|
| **CLAUDE.md** | Project instructions file in the repo root. Read by Claude Code at every session. Contains routing table, code style rules, build commands, tech stack. |
| **Skill** | Specialized persona in `.claude/skills/NAME/SKILL.md`. Invoked with `/name`. Supports sub-files for progressive context loading. |
| **Command** | Single-file slash command in `.claude/commands/NAME.md`. Simpler than a skill, no sub-files. |
| **Agent** | Subagent metadata in `.claude/agents/NAME.md`. Used by the Task tool when an orchestrator spawns a team. Not invoked directly. |
| **Hook** | A shell script that fires automatically on Claude Code events (session start, file edit, git commit, etc.). Configured in `settings.local.json`. |
| **Vault** | An Obsidian folder at `../YourProjectVault/`. Separate git repo. The knowledge base where decisions, daily logs, plans, and guides accumulate. |
| **Obsidian CLI** | Command-line tool bundled with Obsidian. Used by hooks to write to the vault (`obsidian daily:append ...`) without a running Obsidian instance. |
| **MCP** | Model Context Protocol. Lets Claude Code talk to external tools (git, Obsidian REST API) via a standardized interface. |
| **Session context banner** | A text block injected at session start by the `session_context.sh` hook, showing current branch, active plans, and recent daily notes. |
| **Routing table** | A table in CLAUDE.md mapping request patterns to skills. E.g., "fix bug" → `/implementer`. |
| **Otto** | The orchestrator skill. Spawns a multi-agent team for complex multi-domain tasks. |
| **Tier (Operator / Engineer / Lead)** | Reasoning tier assigned by Otto to each agent. Controls the cognitive scaffolding in the agent's prompt — not the model. Operator=retrieval, Engineer=analysis, Lead=judgment. |
| **`--use-opus`** | Flag you can pass to any skill to force all Task subagents to use the Opus model. Expensive — use sparingly. |
| **`mcp__git__git_commit`** | The MCP git commit tool. Always use this instead of `bash git commit` so the `on_commit.sh` hook fires and logs to the daily note. |
| **`additionalDirectories`** | A `settings.local.json` field that grants Claude Code access to directories outside the project root (e.g., the vault at `../VaultName`). |

---

## Quick Reference: Most Common Actions

```bash
# Start a session
claude

# Implement something
/implementer [description of task]

# Review what was implemented
/reviewer [file or "the last change"]

# Research the codebase
/investigator [symbol, file, or question]

# Ask a technical question
/mentor [concept to explain]

# Multi-agent complex task
/otto [describe the full task]

# Search the vault
/vault [query]

# Generate weekly summary
/weekly
```

The routing table in CLAUDE.md automates most of these — for common patterns (implement, fix, review) you can just describe the task and Claude Code will pick the right skill automatically.
