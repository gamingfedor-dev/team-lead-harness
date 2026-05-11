# harness

A production-tested workspace for running Claude Code as serious engineering work, not chat.

Built over four months of daily use across three production codebases — React 19, Angular 20, and C++/Qt6 — by an engineer who measures every primitive and ships code reviewed by humans. Five engineers across two teams adopted it.

This repository is the sanitized, generic version. Drop it onto any project, run the wizard, get a working setup in 5–40 minutes.

---

## What it is

A team-lead sandbox for one human commanding a virtual multi-agent team.

> One operator. Many specialised agents. Five layers of self-correction. Hook-level gates that cannot be talked around. Reasoning-budget feedback loop that measures its own drift.

Inside the kit:

| Component | What it does |
|-----------|--------------|
| **Skills + personas** | 12 specialised slash commands (`/implementer`, `/reviewer`, `/investigator`, `/safety`, `/performance`, `/crash`, `/mentor`, `/pragmatist`, `/orchestrator`, `/vault`, `/weekly`, `/domain-skill`) — each with persistent memory check, structured handoff protocol, and the forked-context pattern for expensive operations |
| **Multi-agent orchestrator** | L1/L2/L3 reasoning tier system with mandatory written justification, mid-flight promotion rule, and the **Reasoning Budget Used** synthesis section that measures drift week-over-week |
| **Hooks** | 10 scripts: `enforce_task_tests` gates Stop, `lint_precommit` gates commit, `track_modified` + `on_commit` build the audit trail, `pre_compact` snapshots state, `on_agent_stop` logs findings, `session_context` grounds every session |
| **Vault** | Obsidian as a queryable knowledge graph — decisions, bugs, plans, analyses, daily notes, weekly synthesis. Investigator does graph traversal (`backlinks`, `links`, `search:context`), not blind grep |
| **Token economy** | Direct-tools-first hard rule; per-agent budget caps; tests-run-once at end. ~40% measured token saving on typical multi-agent runs |

Five layers compose into a defense-in-depth architecture: **skill → multi-agent → token → hooks → vault**. A failure that slips one layer should hit the next. See [`kit/08-self-correction.md`](kit/08-self-correction.md) for the full breakdown.

---

## Why it exists

Most "AI workflow" content stops at "install Claude Code and write a system prompt." That is configuration, not workflow.

A workflow survives:

- A 30-bullet feature plan drifting from the code over three weeks
- A merge request the model approves but a human would have flagged
- A token bill doubling because every agent dispatches three subagents
- A vault of past decisions the model never reads
- A polyglot codebase where the same primitive means different things in JS, C++, and Python

This kit handles those failure modes. The README is a tour; the kit underneath is the runbook.

---

## Results in production

Numbers from real engagements, sanitized.

- **Build time reduced from 1.5h to 15–20 minutes** on a legacy monolith decoupling project — planning driven by the investigator + planner personas.
- **Document extraction pipeline accuracy 70% → 90–95%** over 12 months, with iteration plans authored and reviewed via the adversarial review.
- **MCP → CLI migration cut tool round-trip token cost ~40%** after measurement; the workspace defaults to CLIs (`gh`, `glab`, `obsidian`) for high-frequency calls.
- **Five engineers across two teams adopted the workspace** after onboarding from this kit. One of them is a non-engineer PM.

---

## Quickstart

### Option 1 — Auto-detect script (fast)

```bash
git clone <this-repo> ~/harness
cd /path/to/your/project
~/harness/setup_ai_workspace.sh \
  --project-dir . \
  --vault-dir ../MyProjectVault \
  --ide claude
```

The script detects your tech stack, generates `CLAUDE.md`, copies all 12 persona templates + 10 hooks + the subagent metadata + a stack-aware `settings.local.json`, and initialises your Obsidian vault.

### Option 2 — Interactive wizard (flexible)

```bash
cd /path/to/your/project
claude
```

Then paste [`WIZARD.md`](WIZARD.md) into the session. The wizard asks one question at a time. Every step is independently skippable.

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                Claude Code CLI                      │
│  CLAUDE.md         → project rules + routing        │
│  .claude/skills    → progressive-load personas      │
│  .claude/commands  → single-file slash commands     │
│  .claude/agents    → subagent metadata (Task)       │
│  .claude/hooks     → session/edit/commit gates      │
└─────────────────┬───────────────────────────────────┘
                  │  CLI-first (gh/glab/obsidian), MCP fallback
                  ▼
┌─────────────────────────────────────────────────────┐
│             Tooling Layer                           │
│   Obsidian CLI (graph traversal)                    │
│   gh / glab (git platform ops)                      │
│   Anthropic / OpenAI / Azure OpenAI                 │
└─────────────────┬───────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────┐
│         Obsidian Vault (separate git repo)          │
│   guides/  decisions/  analysis/  workflows/        │
│   bugs/  plans/  memory/  daily/  weekly/           │
└─────────────────────────────────────────────────────┘
```

---

## Modules

| Letter | Module | Time | What it gives you |
|--------|--------|------|-------------------|
| **A** | Vault | 10 min | Obsidian knowledge base outside the repo, wired as a queryable graph |
| **B** | Claude config | 10 min | `CLAUDE.md` + `.claude/` directory + `settings.local.json` (recommended baseline) |
| **C** | Personas | 20 min | Slash commands for the 12 specialised agents |
| **D** | Hooks | 10 min | Session, edit, commit, agent-stop, pre-compact gates |
| **E** | Validation | 5 min | Smoke test for the modules you ran |

Modules are independent. Minimum viable: B alone. Recommended starter: B + C. Full setup: A + B + C + D + E.

Each module is documented in its own kit file ([`kit/00-MASTER-GUIDE.md`](kit/00-MASTER-GUIDE.md) has the contents table).

---

## Kit Files

| File | Purpose |
|------|---------|
| [`WIZARD.md`](WIZARD.md) | Interactive setup wizard (paste into Claude Code) |
| [`kit/00-MASTER-GUIDE.md`](kit/00-MASTER-GUIDE.md) | Architecture overview, design decisions, scaling |
| [`kit/01-claude-md-template.md`](kit/01-claude-md-template.md) | CLAUDE.md skeleton |
| [`kit/02-skill-catalog.md`](kit/02-skill-catalog.md) | Persona templates + persona-identity pattern + forked-context pattern |
| [`kit/03-hooks-kit.md`](kit/03-hooks-kit.md) | 13-hook layout + `_common.sh` |
| [`kit/04-vault-blueprint.md`](kit/04-vault-blueprint.md) | Vault structure + Obsidian CLI |
| [`kit/05-token-strategy.md`](kit/05-token-strategy.md) | Token budget rules (copy as-is) |
| [`kit/06-settings-reference.md`](kit/06-settings-reference.md) | `settings.local.json` reference |
| [`kit/07-onboarding-quickstart.md`](kit/07-onboarding-quickstart.md) | 5-minute newcomer intro |
| **[`kit/08-self-correction.md`](kit/08-self-correction.md)** | **Self-correction architecture across 5 layers** — defense in depth, worked example, accepted failure modes |

---

## Design principles

1. **Direct tools before agents.** Agents are expensive and lossy. If a CLI call answers the question, use it.
2. **Cheap models do retrieval, stronger models do synthesis.** Multi-model dispatch is configured per persona.
3. **One human merges code.** The workspace never auto-merges. Reviews surface conflicts; humans resolve.
4. **State lives in the vault, not the conversation.** Long-running context goes to Obsidian, not chat history.
5. **Token economy is a written rule, not a vibe.** Per-agent budget caps live in `token_strategy.md`.
6. **Tier discipline.** Default to L1. Every promotion above L1 must be defended in writing.
7. **Skipping is always valid.** Modular setup — you do not need the whole stack to get value.

---

## Persona identity

The kit ships with 12 named slash commands. The operator's own deployment uses character handles drawn from anime / film — `/o7`, `/devil`, `/hanji`, `/loid`, `/pylyp`, `/otto`, etc. This is documented in [`kit/02-skill-catalog.md`](kit/02-skill-catalog.md) as a creative pattern with three concrete purposes: reflexive routing, behavioural anchor, memorability. You can keep generic role names or pick your own characters — the kit works either way.

---

## Status

- **Battle-tested** across React 19, Angular 20, C++/Qt6, Python. Daily use since early 2026.
- **Sanitized** — no client, project, or proprietary content. Wizard prompts for project terminology.
- **Open to feedback.** Issues and PRs welcome.

## License

MIT.
