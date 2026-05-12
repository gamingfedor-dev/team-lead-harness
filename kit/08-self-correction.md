---
title: "Self-Correction Architecture"
type: reference
tags: [portable-setup, white-label, self-correction, quality]
version: "2.0"
created: 2026-05-11
updated: 2026-05-11
---

# Self-Correction Architecture

> **What this is:** The kit's defense-in-depth design for catching its own mistakes — at the skill, multi-agent, token, hook, and vault layers. Each layer catches a different failure mode. Read it once to understand what's actually here; reference it when you need to know *which* layer applies to a problem.

LLM-driven engineering fails in characteristic ways: over-confident first-pass code, hidden assumptions, runaway token bills, agents that re-do each other's work, "I forgot what we decided last week." This kit assumes those failures happen and stacks correction at every layer they can be caught.

---

## The Five Layers

```
┌──────────────────────────────────────────────────────────────────┐
│  Layer 5 — Vault           (long-term memory & pattern catch)    │
│      bugs/, decisions/, guides/, /weekly synthesis                │
├──────────────────────────────────────────────────────────────────┤
│  Layer 4 — Hooks           (gate enforcement)                     │
│      lint_precommit, enforce_task_tests, track_modified, on_commit│
├──────────────────────────────────────────────────────────────────┤
│  Layer 3 — Token economy   (cost discipline)                      │
│      direct-tools-first, per-agent budgets, tests-run-once        │
├──────────────────────────────────────────────────────────────────┤
│  Layer 2 — Multi-agent     (cross-skill cross-check)              │
│      tier system, reasoning-budget feedback loop, skip-tests rule │
├──────────────────────────────────────────────────────────────────┤
│  Layer 1 — Skill           (intra-skill discipline)               │
│      persistent memory, Iron Rules, structured handoff            │
└──────────────────────────────────────────────────────────────────┘
```

A bug that slips Layer 1 should hit Layer 2. A token explosion that slips Layer 3 should still be caught in Layer 5's `/weekly` review. The point is that no single layer is load-bearing.

---

## Layer 1 — Skill (intra-skill discipline)

Each skill carries its own correction primitives.

### 1.1 Persistent memory check (always-on)

Every non-trivial skill begins with: *"Check your persistent memory for prior investigations / patterns / decisions in this codebase."* (See [`02-skill-catalog.md`](02-skill-catalog.md) examples.)

**What this corrects:** Re-doing investigations the model already did 3 days ago. Re-inventing decisions already recorded. Re-discovering the same bug.

**Where it fires:** Investigator, implementer, reviewer, safety auditor at the start of every invocation.

### 1.2 Iron Rules (in the mentor)

The mentor has 7 numbered rules including "Never explain unless explicitly asked," "Grade ruthlessly (7/10 means missing details)," "Never give the full answer on first 'I don't know.'" (See [`02-skill-catalog.md` § Mentor](02-skill-catalog.md).)

**What this corrects:** The model's natural tendency to over-explain, to confirm-and-move-on, to grade generously, to capitulate at the first sign of student difficulty.

**Where it fires:** Every mentor invocation, every grading step.

### 1.3 Structured Handoff Protocol

When skills collaborate, they pass a fixed-shape message:
```
From: [calling skill]
Original request: [verbatim user task]
Key findings so far: [bullets]
Files identified: [file:line refs]
What I need from you: [specific question]
```
(See CLAUDE.md template in [`01-claude-md-template.md`](01-claude-md-template.md).)

**What this corrects:** Context loss between skills. Agents asked to "investigate everything" generate 10k-token reports. Agents asked one specific question stay surgical.

**Where it fires:** Every cross-skill invocation.

### 1.4 Forked-context pattern

Investigator, implementer, reviewer, safety, performance use `context: fork` + `agent:` frontmatter. They run in a separate context window and return a structured report. (See [`02-skill-catalog.md` § Forked-Context Pattern](02-skill-catalog.md).)

**What this corrects:** Long investigations polluting the main conversation's context budget, making the orchestrator slower and more confused.

---

## Layer 2 — Multi-agent (cross-skill cross-check)

The orchestrator is built around the assumption that any single agent can be wrong.

### 2.1 Tier system (Operator / Engineer / Lead) with mandatory per-agent justification

The harness ladders three named reasoning tiers — **Operator**, **Engineer**, **Lead** — each a purposeful role with its own scaffolding (not a numeric label). Before spawning, the orchestrator writes for each agent:
- **Tier** (Operator retrieval / Engineer analytical / Lead judgment)
- **Why** (one-line justification)
- **↓ Downgrade trigger** (condition that drops the tier)
- **↑ Upgrade trigger** (condition that raises the tier)

Default is **Operator**. Every promotion must be defended in writing. (See [`02-skill-catalog.md` § Orchestrator](02-skill-catalog.md) + [orchestrator template](../templates/personas/orchestrator.md).)

**What this corrects:** Tier inflation — the natural drift toward "everything is Lead because Lead sounds careful." Unjustified Lead wastes tokens; unnoticed Operator-when-Engineer-is-needed produces shallow analyses.

### 2.2 Reasoning Budget Used (mandatory synthesis section)

Every orchestration ends with a **Reasoning Budget Used** report:
- Planned tier → actual tier per agent (with promotion trigger if changed)
- Total token cost
- Unjustified promotions (list, or "none")
- Production-critical opus exception used (yes/no + path)

**What this corrects:** Without this feedback loop, Phase 1.5 silently decays into "Engineer default, Lead whenever in doubt." With it, you see your own drift week-over-week and can adjust.

### 2.3 Mid-flight promotion rule

If an Operator agent's output reveals complexity beyond its rubric (contradictory prior analyses, cross-thread deletion uncovered, etc.), the *next* agent may be promoted one tier (Operator → Engineer, Engineer → Lead) *without* pre-justification — but the promotion gets logged in the synthesis with the trigger that caused it.

**What this corrects:** Rigid planning when evidence in flight should change the plan. Also corrects against the opposite — uncritical sticking to a plan after it has obviously gone sideways.

### 2.4 Skip-tests rule + consolidated test run (Phase 3.5)

Every agent prompt ends with: *"Do NOT run tests — the orchestrator will run the full suite after all agents complete."* Tests run **exactly once** at the end.

**What this corrects:** Three agents each running the same test suite. Token waste plus inconsistent feedback (one agent's tests pass while another's are stale).

### 2.5 Adversarial reviewer as gate

The reviewer is the named adversarial agent. It runs **after** implementation, often in parallel with safety + pragmatist for the same diff. (See [`02-skill-catalog.md` § Reviewer](02-skill-catalog.md).)

**What this corrects:** First-pass code that compiles and runs but misses edge cases, race conditions, missing cleanup, untested assumptions. The reviewer's whole job is to find what the implementer missed.

### 2.6 Pragmatist as over-engineering brake

The pragmatist's mandatory questions (`"Is this solving a problem we have today?"`, `"How many places use this?"`, `"Could I hotfix at 3am?"`) run in parallel with the reviewer on plans and refactors.

**What this corrects:** Speculative generality, premature abstraction, refactors that look clean but make linear reading impossible.

---

## Layer 3 — Token Economy (cost discipline)

Self-correction is meaningless if the act of correcting bankrupts the session.

### 3.1 Direct-tools-first rule

**Hard rule:** never spawn an agent to find code, read files, or grep patterns. Use `Grep`/`Glob`/`Read` directly. Agents are reserved for synthesis over already-gathered data. (See [`05-token-strategy.md`](05-token-strategy.md).)

**What this corrects:** Three agents each loading 30k tokens of context to do what a 0-token Grep would have done.

### 3.2 Per-agent budget caps

**Budget:** ~5–7k tokens per agent, ~20k total for multi-agent work. Agent prompts are 1–2 sentences with specific yes/no questions.

**What this corrects:** "Gather ALL references about X" prompts that return 10k-token essays nobody asked for.

### 3.3 The one retrieval exception

Investigator may use agent spawn — but only for web/vault searches direct tools cannot access. Code lookups still go through Grep.

**What this corrects:** Drift back to "spawn a subagent for everything because it feels safer."

---

## Layer 4 — Hooks (gate enforcement)

The first three layers are conventions. Hooks are enforcement.

### 4.1 `enforce_task_tests.sh` — Stop-event gate

When the task completes, this hook checks: were the required tests for the modified files run? If not, **block completion** and surface the outstanding tests. (See [`03-hooks-kit.md`](03-hooks-kit.md).)

**What this corrects:** "Done!" being claimed before validation. Customizable by mapping source paths → required test binaries.

### 4.2 `lint_precommit.sh` — PreToolUse gate

Runs lint on staged files before `mcp__git__git_commit` fires. Exit non-zero blocks the commit.

**What this corrects:** Commits with formatting violations, unused imports, etc. — corrected at the gate, not in a follow-up cleanup commit.

### 4.3 `lint_on_edit.sh` — synchronous post-edit feedback

After every `Edit` / `Write`, run lint on the file. Surfaces issues to Claude immediately, so the model self-corrects before moving on.

**What this corrects:** Compounding lint errors across a multi-file edit.

### 4.4 `track_modified.sh` + `on_commit.sh` — audit trail

Track every file edited; on commit, write a structured entry to today's daily note with commit message and file list.

**What this corrects:** "What did I actually change last Tuesday?" as a retrospective question. The audit trail is automatic and survives across branches.

### 4.5 `pre_compact.sh` — state snapshot

Before context compaction, snapshot the modified-files tracking list. After compaction, the kit knows what was being worked on.

**What this corrects:** Context-window compaction silently losing in-flight state.

### 4.6 `on_agent_stop.sh` — agent findings logging

When a subagent finishes (especially via `Task`), append its summary to the daily note.

**What this corrects:** Agent findings vanishing into the void when the orchestrator moves on. Now they're recoverable.

### 4.7 `session_context.sh` — session-start grounding

At session start, inject branch, active plans, recent dailies, and recommended guides into the context.

**What this corrects:** Starting cold every session and re-asking the model to figure out where you left off. The context bootstraps from durable state.

---

## Layer 5 — Vault (long-term memory & pattern catch)

The vault is the slow, durable self-correction layer.

### 5.1 Bugs / decisions / analysis — permanent record

Every non-obvious bug gets a post-mortem in `bugs/`. Every architectural choice gets an ADR in `decisions/`. Every investigation gets an `analysis/` entry. (See [`04-vault-blueprint.md`](04-vault-blueprint.md).)

**What this corrects:** Repeat offenders. The investigator's persistent-memory check (Layer 1) only works if the vault has the prior record.

### 5.2 Vault graph traversal as correction tool

`obsidian backlinks file=X` reveals everything that depends on a note — so when a decision changes, you know what to update. `obsidian links file=X` traces outgoing dependencies. `obsidian search:context` finds matches with surrounding lines.

**What this corrects:** Decisions getting orphaned from the code that depends on them. The graph is the audit.

### 5.3 `/weekly` — drift surfacing

The weekly synthesis aggregates 7 dailies, categorizes sessions (features / bugs / refactoring / analysis), surfaces decisions made, blockers raised, learning recorded. (See [`02-skill-catalog.md` § Weekly](02-skill-catalog.md) + [weekly template](../templates/personas/weekly.md).)

**What this corrects:** Drift you cannot see day-to-day. If the same blocker shows up three times in a week's dailies, the weekly surfaces it. If the same persona is consuming 80% of sessions, the rollup makes that visible.

### 5.4 `guides/` — pattern crystallization

When you have solved the same problem twice, write a guide. The third time, the investigator finds it in `obsidian search:context query="X" path="guides"` and the model doesn't re-derive it from scratch.

**What this corrects:** Recurring "how do we do X here?" cycles. Guides accumulate so the answer becomes findable.

### 5.5 Plans lifecycle (active → completed / superseded)

Plans move through `planning/` → `active/` → `legacy/completed/` or `legacy/superseded/` with `superseded_by` / `supersedes` frontmatter links.

**What this corrects:** Stale plans masquerading as current direction. Superseded plans are explicit, not silently abandoned.

---

## How the layers compose — one task, all layers firing

Worked example: *"Fix the intermittent crash on shutdown that we saw last week."*

1. **Layer 5 (vault).** Investigator checks `obsidian search:context query="shutdown crash" path="bugs"` — finds two prior post-mortems with matching symptoms but different fixes.
2. **Layer 1 (skill).** Investigator's persistent-memory check surfaces a relevant pattern note. Reports findings with structured handoff to safety auditor.
3. **Layer 2 (multi-agent).** Orchestrator's Phase 1.5 assigns: investigator Operator → safety Engineer (cross-thread potentially involved) → implementer Engineer → reviewer Lead (this is a production-critical path — opus exception applies).
4. **Layer 3 (tokens).** Each agent gets a 1-2 sentence prompt with the gathered file:line refs in the prompt, not as a "go re-read it yourself" instruction.
5. **Layer 1 (skill).** Safety auditor maps the ownership chain. Hands off to implementer with the gap identified.
6. **Layer 1 (skill).** Implementer ships the fix. Hands off back to safety for verification (Operator mode).
7. **Layer 4 (hooks).** `lint_on_edit.sh` runs after each file edit. `track_modified.sh` accumulates the file list. The reviewer runs in parallel and signs off. `enforce_task_tests.sh` blocks completion until the relevant unit tests have been run. `lint_precommit.sh` runs on staged files.
8. **Layer 4 (hooks).** `on_commit.sh` appends the commit entry + file list to today's daily note.
9. **Layer 2 (multi-agent).** Orchestrator's Phase 4 synthesis includes the **Reasoning Budget Used** — captures that the reviewer was promoted to opus under the production-critical exception, with the path justification.
10. **Layer 5 (vault).** A new post-mortem lands in `bugs/`. If this pattern recurs once more, a `guides/<tech>/<topic>.md` gets written.

No single layer is doing the work. They compose.

---

## Failure modes the architecture explicitly accepts

This is not a proof of correctness. It's defense in depth, and depth has gaps. Things this architecture **does not** catch:

- **Bad user requirements.** A correctly-implemented wrong feature is still wrong.
- **Vault rot.** If the operator stops writing post-mortems, Layer 5 starves. Hooks help but cannot enforce content quality.
- **Hook drift.** A `lint_precommit.sh` that no longer matches the project's lint config is dead weight that creates false confidence.
- **Persona drift.** If you customize a persona too far from its core role, the cross-skill assumptions in Layer 2 stop holding.
- **Adversary that mirrors the reviewer.** If your codebase has a failure mode the reviewer's expertise areas do not name (e.g., a new class of security bug), nothing in the kit will surface it. You add the expertise area or accept the gap.

The architecture is a multiplier on operator judgment, not a substitute for it.

---

## Where to read next

- [`02-skill-catalog.md`](02-skill-catalog.md) — full persona templates (the cross-skill handoff protocol lives here)
- [`03-hooks-kit.md`](03-hooks-kit.md) — every hook script + the settings.local.json wiring
- [`05-token-strategy.md`](05-token-strategy.md) — direct-tools-first rule and budget rationale
- [`04-vault-blueprint.md`](04-vault-blueprint.md) — vault folder structure + templates
- [Orchestrator persona template](../templates/personas/orchestrator.md) — Phase 1.5 and Reasoning Budget Used in full
- [Mentor persona template](../templates/personas/mentor.md) — Iron Rules + grading discipline
