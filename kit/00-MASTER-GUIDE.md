---
title: "Claude Code Architecture Kit — Master Guide"
type: guide
tags: [portable-setup, white-label, architecture]
version: "2.0"
created: 2026-02-25
updated: 2026-04-28
---

# Claude Code Architecture Kit — Master Guide

> **What this is:** Architecture overview and design rationale for the kit. Read this once for orientation, then reference it when you need to know *why* something is shaped the way it is.
>
> **Setup entry point:** [`../README.md`](../README.md) is the interactive wizard. This file is the architecture companion.
>
> **Who this is for:** Claude Code users who want a structured skill-based architecture with automated documentation, specialized personas, and an Obsidian vault knowledge base. If you are brand new to Claude Code, read [07-onboarding-quickstart.md](07-onboarding-quickstart.md) first.
>
> **What you get:** A full AI-assisted development environment — specialized skill personas, automated session context injection, commit tracking, lint hooks, and a centralized knowledge vault.
>
> **Read next:** [`08-self-correction.md`](08-self-correction.md) explains the defense-in-depth architecture across 5 layers — the strongest argument for *why* the kit is shaped this way.

---

## Architecture Overview

```
┌──────────────────────────────────────────────────────┐
│                 Your IDE (Claude Code)                 │
│  CLAUDE.md              → project rules & routing      │
│  .claude/skills/NAME/   → progressive-loading personas │
│  .claude/commands/*.md   → simple slash commands        │
│  .claude/agents/*.md     → subagent metadata (Task)    │
│  .claude/hooks/          → automation scripts           │
│  .claude/settings.local.json → permissions & hooks      │
└─────────────────────┬────────────────────────────────┘
                      │ MCP Protocol / Obsidian CLI
┌─────────────────────▼────────────────────────────────┐
│              Vault Access                              │
│  Obsidian CLI (primary)  → obsidian daily:append ...  │
│  obsidian-mcp-server     → legacy REST fallback        │
│  @anthropic/git-mcp      → git ops (hook triggers)    │
└─────────────────────┬────────────────────────────────┘
                      │
┌─────────────────────▼────────────────────────────────┐
│              Obsidian Vault (separate repo)            │
│  daily/ decisions/ guides/ plans/ analysis/            │
│  templates/ weekly/ workflows/ reference/              │
└──────────────────────────────────────────────────────┘
```

### How Layers Connect

| Layer | Purpose | Files |
|-------|---------|-------|
| **CLAUDE.md** | Project rules, build commands, skill routing table, code style | `PROJECT_ROOT/CLAUDE.md` |
| **Skills** | Specialized personas with progressive context loading | `.claude/skills/NAME/SKILL.md` + sub-files |
| **Commands** | Simple slash commands (single file, no sub-context) | `.claude/commands/NAME.md` |
| **Agents** | Subagent metadata used by the Task tool | `.claude/agents/NAME.md` |
| **Hooks** | Session lifecycle automation (13 scripts in a mature setup) | `.claude/hooks/*.sh` + `settings.local.json` |
| **Vault** | Persistent knowledge base, daily logs, plans, decisions | `../ProjectVault/` (separate repo) |
| **Token Strategy** | Budget rules for agent/tool usage | `.claude/token_strategy.md` |

---

## How to Set Up

**The setup wizard lives in [`../README.md`](../README.md).** Open Claude Code in your project, paste the README, follow the question-by-question wizard. Every step is independently skippable.

This file (00-MASTER-GUIDE) is for *understanding* the architecture — why the kit is shaped this way, what each piece is for, and how the layers compose. Use it as the orientation read before customizing, and as a reference when something surprises you. It is **not** the setup entry point.

### Module Map (1-line summaries)

| Module | Time | Depends on | What it gives you |
|--------|------|-----------|-------------------|
| **A — Vault** | 10 min | Obsidian app | Standalone Obsidian knowledge base outside the repo |
| **B — Claude config** | 10 min | nothing | CLAUDE.md + `.claude/` directory + `settings.local.json` |
| **C — Personas** | 20 min | B | Slash commands like `/implementer`, `/reviewer`, `/investigator` |
| **D — Hooks** | 10 min | B (A recommended) | Session, edit, commit, and agent-stop automation |
| **E — Validation** | 5 min | whichever phases you ran | Smoke tests for the modules you installed |

**Minimum viable kit:** Module B alone. **Recommended starter:** B + C. **Full setup:** A + B + C + D + E. Each module is documented in its own kit file (linked in the table below).

---

## Kit Contents

| File | Purpose | When to Use |
|------|---------|-------------|
| [`../README.md`](../README.md) | Interactive setup wizard | The setup entry point |
| `00-MASTER-GUIDE.md` | This file — architecture, design decisions, scaling | Read once for orientation; reference later |
| [`01-claude-md-template.md`](01-claude-md-template.md) | CLAUDE.md skeleton with placeholder sections | Generate project CLAUDE.md |
| [`02-skill-catalog.md`](02-skill-catalog.md) | Persona templates + persona-identity pattern + forked-context pattern | Choose and customize skills |
| [`03-hooks-kit.md`](03-hooks-kit.md) | Hook scripts + settings.json hook configuration (13-hook layout) | Set up automation |
| [`04-vault-blueprint.md`](04-vault-blueprint.md) | Vault folder structure + note templates + Obsidian CLI setup | Initialize knowledge vault |
| [`05-token-strategy.md`](05-token-strategy.md) | Agent budgeting and tool-selection rules | Copy as-is to `.claude/` |
| [`06-settings-reference.md`](06-settings-reference.md) | `settings.local.json` complete reference | Configure permissions & hooks |
| [`07-onboarding-quickstart.md`](07-onboarding-quickstart.md) | 5-minute intro for colleagues new to Claude Code | First read for newcomers |
| **[`08-self-correction.md`](08-self-correction.md)** | **Self-correction architecture across 5 layers** — defense in depth, worked example, accepted failure modes | Read to understand *why* the kit is shaped this way |

---

## Key Design Decisions

### Why Three Delivery Formats: Skills vs Commands vs Agents?

| Feature | Skills (`.claude/skills/`) | Commands (`.claude/commands/`) | Agents (`.claude/agents/`) |
|---------|---------------------------|-------------------------------|---------------------------|
| Progressive loading | Yes — sub-files on demand | No — entire file at once | No — metadata only |
| Sub-context files | `workflow.md`, `patterns.md`, etc. | Not supported | Not applicable |
| Frontmatter | Full (model, allowed-tools, disable-model-invocation) | Basic | Full agent config (model, memory, skills) |
| Used by | `/skill-name` slash command | `/command-name` slash command | Task tool (agent spawning) |
| Best for | Complex personas with reference material | Single-page prompts | Subagents spawned by orchestrators |

**Rule of thumb:**
- If a persona needs reference material (checklists, knowledge bases), make it a skill.
- If it's a single-page prompt, make it a command.
- If it's spawned by an orchestrator via Task tool, give it an agent file in `.claude/agents/`.

### Why Obsidian Vault as Separate Repo?

- Vault contains knowledge that **outlives branches** (decisions, guides, daily logs)
- Vault grows independently of code (different commit cadence)
- Multiple projects can share one vault (future scaling)
- No risk of accidentally committing vault files to code repo

### Why Obsidian CLI Over MCP REST API?

The Obsidian CLI (`obsidian daily:append ...`) is the preferred vault access method because:
- No running Obsidian instance required for basic operations
- Works reliably in hooks without network round-trips
- REST API (obsidian-mcp-server) still works but requires Obsidian to be running with Local REST API plugin enabled — useful for MCP tools in Claude Code but not reliable for hook scripts

### Why MCP Git Instead of Bash Git?

Hooks are registered on MCP tool matchers (`mcp__git__git_commit`). If you use `bash git commit`, the PostToolUse hook never fires → commit tracking breaks. Always use MCP git tools for operations that need hook integration.

### Why Haiku for Analysis, Sonnet for Implementation?

- **Haiku** ($0.25/MTok input): Fast, cheap — perfect for read-only analysis, code review, evidence gathering. Most skills use Haiku.
- **Sonnet** ($3/MTok input): Better at multi-file code generation — used only for implementation skills.
- **Opus** ($15/MTok input): Reserve for complex multi-domain reasoning — invoked via `--use-opus` flag or as a deliberate production-critical exception for adversarial review.

### Orchestrator Tier System (Phase 1.5)

The orchestrator skill assigns reasoning tiers to each spawned agent — not to change models, but to inject appropriate cognitive scaffolding into prompts. The harness ladders three tiers — **Operator**, **Engineer**, **Lead**:

| Tier | Scaffolding injected | When |
|------|---------------------|------|
| **Operator** | "Report what you find. Stick to evidence." | Data lookup, file gathering, grep-and-report |
| **Engineer** | "Think carefully. Synthesize across sources." | Cross-file analysis, code review, risk assessment |
| **Lead** | "High-stakes decision. Reason step by step." | Architectural decisions with ambiguous trade-offs |

Default to Operator. Every promotion must be defended in writing. See [02-skill-catalog.md](02-skill-catalog.md) for the full orchestrator template.

---

## Scaling This Architecture

### Adding a New Skill

1. Create `skills/NAME/SKILL.md` with frontmatter
2. Optionally add sub-files (`workflow.md`, `patterns.md`, etc.)
3. Add to CLAUDE.md routing table
4. Add an agent file in `.claude/agents/NAME.md` if the orchestrator will spawn it via Task

### Adding a New Hook

There are 7 supported hook events. Multiple hooks can fire for the same event with different matchers:

| Event | Common uses |
|-------|------------|
| `SessionStart` | Context injection, branch display |
| `SessionEnd` | Cleanup, flush tracking files |
| `PostToolUse` | Track edits, log commits, lint on save |
| `PreToolUse` | Block commits (lint, test enforcement) |
| `Stop` | Block task completion (test enforcement) |
| `PreCompact` | Snapshot state before context compaction |
| `SubagentStop` | Log agent findings to daily note |

Add hook scripts to `.claude/hooks/`, register in `settings.local.json`, and source `_common.sh` for shared utilities (logging, vault access, daily note helpers).

### Adding a New MCP Server

1. Add server config to `settings.local.json` mcpServers section
2. Add blanket permission: `"mcp__servername__*"`
3. Reference tools in skill `allowed-tools` lists

### Multi-Project Vault

To share one vault across projects:
1. Each project gets its own vault subdirectory (`vault/project-a/`, `vault/project-b/`)
2. Shared guides live at vault root (`vault/guides/`)
3. Daily notes use project prefix: `daily/project-a/2026-04-28.md`
4. Session context hook reads from project-specific subdirectory

---

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| Session context not showing | Hook not registered | Check `settings.local.json` SessionStart section |
| Commit not logged to daily note | Using bash git | Switch to `mcp__git__git_commit` |
| Skills not loading | Wrong directory structure | Must be `skills/NAME/SKILL.md` (capital SKILL) |
| Obsidian CLI not found | CLI not in PATH | Add `obsidian` binary path to hook scripts |
| Vault note not created | Template missing | Check `templates/Daily.md` exists |
| Hook permission denied | Script not executable | `chmod +x .claude/hooks/*.sh` |

---

## Next Steps After Setup

1. **Write your first guide** — Document your project's key patterns in `vault/guides/`
2. **Create an active plan** — Track current work in `vault/plans/active/`
3. **Run `/weekly`** — After a week of daily notes, generate your first weekly summary
4. **Review token usage** — After a few sessions, check if agent budgets need tuning
5. **Add domain skills** — As patterns emerge, extract them into dedicated skills
