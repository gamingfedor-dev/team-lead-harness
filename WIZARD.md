# harness — Setup Wizard

> **How to use this:** Open Claude Code in your project directory. Paste this file (`WIZARD.md`) into the conversation. Claude follows the wizard below — asks one question at a time, waits for your answer, and only proceeds when you confirm.

> **Brand new to Claude Code?** Read [`kit/07-onboarding-quickstart.md`](kit/07-onboarding-quickstart.md) for a 5-minute primer first. Come back here when you're ready to set up.

> **Want the architecture context first?** [`README.md`](README.md) is the project tour; [`kit/00-MASTER-GUIDE.md`](kit/00-MASTER-GUIDE.md) is the architecture deep-dive; [`kit/08-self-correction.md`](kit/08-self-correction.md) explains the defense-in-depth layers. The wizard below is the setup entry point.

---

## For Claude (read first, do not skip)

You are running an interactive setup wizard for a colleague who may be new to Claude Code. Follow these rules strictly:

1. **One question at a time.** Wait for the user's answer before asking the next one.
2. **Show progress.** After every step, reprint the checklist below with `[x]` for done, `[~]` for skipped, `[ ]` for pending.
3. **Skipping is always valid.** If the user says "skip", "later", or "not now" for any step, mark it `[~]` and move on. Do not lecture about why a step matters.
4. **Stop on demand.** If the user says "stop", "pause", or "exit", checkpoint the current state into a comment and exit gracefully. The user can resume later.
5. **Respect prerequisites.** Never run a step whose prerequisites are unsatisfied. Tell the user what's missing and offer to backfill it (or skip both).
6. **Confirm destructive actions.** Always show a diff or planned-action summary before creating files outside the project root, overwriting existing files, or running `chmod`.
7. **Keep questions short.** One sentence. Use `(option1 / option2 / skip)` format. Avoid open-ended prose questions unless the step explicitly needs prose (e.g., "describe your tech stack").
8. **Reference the kit AND the templates.** When the user picks a module, read the relevant kit file (`kit/0X-*.md`) for context and customization guidance. Then **copy from `templates/` as the canonical source for files**:
   - Personas → copy from `templates/personas/<name>.md` into `.claude/commands/<name>.md`
   - Hook scripts → copy from `templates/scripts/<name>.sh` into `.claude/hooks/<name>.sh`
   - Helper scripts (`skill_context.sh`) → copy into `.claude/scripts/`
   - Vault note templates → copy from `templates/vault/*.md` into the user's `<Vault>/templates/`
   - Substitute placeholders (`{{IMPLEMENTER_NAME}}`, `{{VAULT_NAME}}`, `{{BUILD_COMMAND}}`, etc.) based on user input. Leave persona-flavor placeholders (`{{PERSONA_DESCRIPTION}}`, `{{EXPERTISE_*}}`) as TODO markers if the user picks `generic only` in Q4.3.
9. **No project-specific assumptions.** This kit is generic. Mirror the user's own project terminology back to them.

When ready, greet the user with:
> "Welcome. This wizard sets up Claude Code on your project. Estimated time 5–40 min depending on modules picked. Reply `start` to begin, or `tell me more` for an overview first."

---

## Wizard Checklist

The wizard walks through three layers: orientation → module selection → per-module setup. Every step is independently skippable.

### Step 0 — Orientation

- [ ] **Q0.1** Is this your first time using Claude Code? (yes / no / skip)
  - If yes → recommend reading [`kit/07-onboarding-quickstart.md`](kit/07-onboarding-quickstart.md) before proceeding
- [ ] **Q0.2** Project directory absolute path? (paste path / `cwd` / skip)
- [ ] **Q0.3** Brief project description — tech stack, domain, main goals in 1–2 sentences
- [ ] **Q0.4** Vault folder name and absolute path (used by Module B even if you skip Module A — settings.local.json needs the path) (default name: `MyProjectVault`, default path: parent of project dir)

---

### Step 1 — Pick Your Modules

- [ ] **Q1.1** Which modules do you want today? Pick any combination of letters:

| Letter | Module | Time | Why |
|--------|--------|------|-----|
| **A** | Vault | 10 min | Obsidian knowledge base outside the repo |
| **B** | Claude config | 10 min | CLAUDE.md + settings.local.json (recommended starting point) |
| **C** | Personas | 20 min | Slash commands like `/implementer`, `/reviewer`, `/otto` |
| **D** | Hooks | 10 min | Session/commit/edit automation |
| **E** | Validation | 5 min | Smoke test |

  - Reply with letters (e.g., `B C D`) or shortcuts: `all` (everything), `minimum` (B only), `productive` (B C), `full` (A B C D E)

> Claude: only run the steps below for modules the user picked. Mark unselected modules `[~]` (skipped) up front.

---

### Step 2 — Module B: Claude Config

> Prerequisites: none. Recommended baseline.

- [ ] **Q2.1** Tell me about your tech stack — languages, frameworks, build system, key directories
- [ ] **Q2.2** Generate `CLAUDE.md` from [`kit/01-claude-md-template.md`](kit/01-claude-md-template.md), filling tech stack. **Leave `{{*_SKILL}}` placeholders in the routing table for Module C to fill.** (yes / skip)
- [ ] **Q2.3** Generate `.claude/settings.local.json` from [`kit/06-settings-reference.md`](kit/06-settings-reference.md), substituting vault path from Q0.4. **Generate without the `hooks:` block — Module D inserts it.** (yes / skip)
- [ ] **Q2.4** Copy [`kit/05-token-strategy.md`](kit/05-token-strategy.md) content (strip frontmatter) to `.claude/token_strategy.md`? (yes / skip)
- [ ] **Q2.5** Create `.claude/` directory tree (`skills/`, `commands/`, `agents/`, `hooks/`, `scripts/`, `sessions/`)? (yes / skip)

---

### Step 3 — Module A: Vault

> Prerequisites: Obsidian app installed. If you skipped Module B, settings.local.json edits in this step are inert until you run Module B later.

#### What the vault is (read first)

The vault is a separate Obsidian folder that lives **outside your code repo**. It is the durable knowledge layer that survives across branches, sessions, and conversations.

- **What it stores:** decisions (ADRs), bug post-mortems, implementation plans, daily session logs, guides, workflows, weekly summaries, long-lived reference notes.
- **What it is not:** It is not project source code. It is not documentation that belongs in the repo's README. It is not a chat scratchpad.
- **Why a separate repo:** Knowledge outlives feature branches. Vault commit cadence is different from code. Multiple projects can later share one vault. No risk of accidentally committing vault notes to the code repo.

**How Claude Code uses it:**

- **Reads from it** at session start (hooks inject active plans, recent dailies, recommended guides into the prompt) and on demand (the `/vault` and `/investigator` skills search it).
- **Writes to it** automatically — `on_commit.sh` appends commit entries to today's daily note; `on_agent_stop.sh` appends agent findings; the `/weekly` command generates rollup summaries.
- **Skills consult it** before producing answers — when a bug recurs, the second-session investigator finds the prior post-mortem; when you start a feature, the planner finds the active plan.

**Default size assumption:** light to medium. A solo engineer accumulates ~5–50 notes per active feature. The vault scales by feature, not by codebase.

**Skip Module A if:** You do not want persistent knowledge tracking. The rest of the kit still works — only the `/vault` command, the `/weekly` command, and vault-writing hooks become inert.

> **Want a deeper tour before setting up?** Read [`kit/04-vault-blueprint.md`](kit/04-vault-blueprint.md) section *Vault — What It Is and Why* first.

- [ ] **Q3.0** Did you read the "What the vault is" block above and want to proceed? (yes / tell me more / skip Module A)
- [ ] **Q3.1** Confirm vault path from Q0.4 (or override now). Default: `../MyProjectVault`.
- [ ] **Q3.2** Is Obsidian CLI on PATH? Run `which obsidian` and report the result. (found / not found / skip)
  - If not found → offer the install steps from [`kit/04-vault-blueprint.md`](kit/04-vault-blueprint.md)
- [ ] **Q3.3** Create vault folder structure. Recommended approach: `bash templates/scripts/init_vault.sh ../<vault-name>`. This creates `analysis/`, `bugs/`, `daily/`, `decisions/`, `guides/`, `memory/`, `plans/{active,planning,legacy/{completed,superseded}}/`, `reference/`, `templates/`, `weekly/`, `workflows/`, copies all 9 vault note templates from `templates/vault/`, and initialises a git repo. (yes — use script / yes — manual / skip)
- [ ] **Q3.4** *(skip if Q3.3 used the script — already done.)* Initialize the vault as its own git repo? (yes / skip)
- [ ] **Q3.5** Symlink `vault -> ../<vault>` in project root? (yes / skip)
- [ ] **Q3.6** Verify `additionalDirectories` entry in `settings.local.json` points at the actual vault path (Q2.3 already pre-filled from Q0.4 — confirm it's correct). (yes / fix it / skip — only valid if Module B ran)

---

### Step 4 — Module C: Personas

> Prerequisites: Module B (CLAUDE.md must exist so the routing table can reference personas).

- [ ] **Q4.1** Which starter personas? Pick a tier (templates live in `templates/personas/`):
  - `minimum` — implementer + reviewer + investigator (3 personas)
  - `productive` — minimum + mentor + pragmatist (5)
  - `extended` — productive + orchestrator + vault + weekly (7)
  - `full` — all 12 personas (implementer, investigator, reviewer, safety, performance, crash, mentor, pragmatist, orchestrator, vault, weekly, domain-skill)
  - `custom` — list specific names from `templates/personas/` ([`kit/02-skill-catalog.md`](kit/02-skill-catalog.md) explains the pattern)
- [ ] **Q4.2** For each chosen persona, pick delivery format. Default rule: skills with sub-files go to `.claude/skills/NAME/SKILL.md`; single-file personas go to `.claude/commands/NAME.md`. **Five personas (implementer, investigator, reviewer, safety, performance) use the forked-context pattern: `context: fork` + matching `.claude/agents/NAME.md` file** — see [`kit/02-skill-catalog.md` § The Forked-Context Pattern](kit/02-skill-catalog.md). (auto / let me decide each / skip)
- [ ] **Q4.3** Customize each persona's domain language to match your project? (yes / generic only / skip)
- [ ] **Q4.4** Replace `{{*_SKILL}}` placeholders in CLAUDE.md routing table with the persona names you picked. (yes / skip)
- [ ] **Q4.5** Create `.claude/agents/<name>.md` subagent metadata for the forked-context skills (default: implementer, investigator, reviewer, safety, performance). Required for the orchestrator to spawn them via Task. (yes — required for orchestrator / skip if not using orchestrator)

---

### Step 5 — Module D: Hooks

> Prerequisites: Module B (settings.local.json must exist). Module A recommended — vault-writing hooks are inert without a vault but do not error.

- [ ] **Q5.1** Pick starter hook set (copy from `templates/scripts/` into `.claude/hooks/`):
  - `minimum` — `session_context.sh` + `track_modified.sh` + `on_commit.sh` + `session_cleanup.sh`
  - `productive` — minimum + `lint_on_edit.sh` + `pre_compact.sh`
  - `full` — productive + `enforce_task_tests.sh` + `on_agent_stop.sh` + `lint_precommit.sh` + project-specific hooks
- [ ] **Q5.2** Copy `templates/scripts/_common.sh` to `.claude/hooks/_common.sh`. (yes — required for any hook)
- [ ] **Q5.3** Copy `templates/scripts/skill_context.sh` to `.claude/scripts/skill_context.sh` — referenced by every persona's `## Context` block. (yes — required)
- [ ] **Q5.4** Substitute `{{VAULT_NAME}}` in `_common.sh` and `skill_context.sh` with the vault name from Q0.4. (yes — required)
- [ ] **Q5.5** Make all hook + helper scripts executable (`chmod +x .claude/hooks/*.sh .claude/scripts/*.sh`). (yes — required)
- [ ] **Q5.6** Insert `hooks:` block into existing `settings.local.json` with correct event matchers (SessionStart, PostToolUse Edit|Write, PostToolUse mcp__git__git_commit, SessionEnd, plus `Stop` and `SubagentStop` for `full` tier). See `kit/06-settings-reference.md` § hooks for the full layout. (yes — required)

---

### Step 6 — Module E: Validation

> Run only the questions for modules you completed.

- [ ] **Q6.1** *(after B)* Start a session: `claude` from project root — completes without errors? (yes / error)
- [ ] **Q6.2** *(after B + D)* SessionStart context banner appears with branch + recent dailies? (yes / no)
- [ ] **Q6.3** *(after A)* `obsidian daily:read vault=<your-vault-name>` prints today's note (or empty result, not error)? (yes / no)
- [ ] **Q6.4** *(after C)* `/<your-implementer-name> hello world` loads the persona and responds? Replace `<your-implementer-name>` with the actual command name (default: `/implementer`). (yes / no)

---

### Step 7 — Wrap-up

- [ ] **Q7.1** Save the completed checklist as a vault note in `daily/` for future reference? (yes / no)
- [ ] **Q7.2** Want first-week customization suggestions? (yes / not now)
  - Customize `on_commit.sh` `auto_tag()` for your directory layout
  - Add 1 project-specific skill from a recurring pattern you've noticed
  - Write your first vault guide in `vault/guides/<tech>/`
- [ ] **Q7.3** Anything unclear or broken? (describe / no — done)

---

## Self-Correction Architecture (short version)

This kit assumes LLM-driven engineering fails in predictable ways: over-confident first-pass code, hidden assumptions, runaway token bills, agents re-doing each other's work, "I forgot what we decided last week." It stacks correction at every layer those failures can be caught.

**Five layers, compounding:**

| Layer | What catches it | Examples |
|-------|-----------------|----------|
| **1. Skill** | Intra-skill discipline | persistent-memory check, mentor's Iron Rules, structured handoff protocol, `context: fork` for expensive skills |
| **2. Multi-agent** | Cross-skill cross-check | orchestrator tier system (L1/L2/L3) with mandatory justification, Reasoning Budget Used feedback loop, adversarial reviewer in parallel with safety + pragmatist |
| **3. Token economy** | Cost discipline | direct-tools-first rule, per-agent budget caps, tests-run-once at end |
| **4. Hooks** | Gate enforcement | `enforce_task_tests.sh` blocks completion, `lint_precommit.sh` blocks commits, `track_modified.sh` + `on_commit.sh` audit trail, `pre_compact.sh` state snapshot |
| **5. Vault** | Long-term memory & pattern catch | `bugs/` post-mortems, ADRs in `decisions/`, `/weekly` drift synthesis, `guides/` crystallization once a pattern recurs |

No single layer is load-bearing. A bug that slips Layer 1 should hit Layer 2; a token explosion that slips Layer 3 still surfaces in Layer 5's weekly review.

**Full doc:** [`kit/08-self-correction.md`](kit/08-self-correction.md) — covers every layer with concrete examples, a worked end-to-end task showing all layers firing, and the failure modes this architecture explicitly does not catch.

---

## Reference Material

The wizard above is the entry point. The reference below is for skimming.

### Kit Files

| File | Purpose |
|------|---------|
| [`kit/00-MASTER-GUIDE.md`](kit/00-MASTER-GUIDE.md) | Architecture overview, design decisions, scaling guide |
| [`kit/01-claude-md-template.md`](kit/01-claude-md-template.md) | CLAUDE.md skeleton |
| [`kit/02-skill-catalog.md`](kit/02-skill-catalog.md) | Skill/command/agent persona templates + persona-identity pattern |
| [`kit/03-hooks-kit.md`](kit/03-hooks-kit.md) | 13-hook layout + `_common.sh` |
| [`kit/04-vault-blueprint.md`](kit/04-vault-blueprint.md) | Vault folder structure + Obsidian CLI |
| [`kit/05-token-strategy.md`](kit/05-token-strategy.md) | Token budget rules (copy as-is) |
| [`kit/06-settings-reference.md`](kit/06-settings-reference.md) | `settings.local.json` reference |
| [`kit/07-onboarding-quickstart.md`](kit/07-onboarding-quickstart.md) | 5-minute newcomer intro |
| [`kit/08-self-correction.md`](kit/08-self-correction.md) | **Self-correction architecture — defense in depth across 5 layers** |

### Final Layout

```
project/
├── CLAUDE.md
├── .claude/
│   ├── skills/        # Progressive-loading personas
│   ├── commands/      # Single-file slash commands
│   ├── agents/        # Subagent metadata for Task tool
│   ├── hooks/         # Automation (3–13 scripts)
│   ├── scripts/       # Helpers (skill_context.sh, etc.)
│   ├── sessions/      # Transient state (gitignore)
│   ├── settings.local.json
│   └── token_strategy.md
└── vault -> ../MyProjectVault    # Symlink (if Module A ran)

MyProjectVault/                  # Separate repo
├── templates/
├── daily/  weekly/
├── plans/{active,planning,legacy/{completed,superseded}}/
├── analysis/  bugs/  decisions/  reference/   # Feature-split subdirs
├── guides/<tech>/
├── workflows/  memory/
└── .obsidian/
```

### Prerequisites

| Tool | Required For | Install |
|------|-------------|---------|
| Node.js 18+ | Claude Code, MCP servers | `brew install node` / `apt install nodejs` |
| Claude Code | The CLI itself | `npm install -g @anthropic-ai/claude-code` |
| Obsidian | Vault UI + CLI (Module A only) | [obsidian.md](https://obsidian.md) |
| Obsidian CLI | Hook vault access (Module D + A) | Bundled with Obsidian |
| jq | JSON parsing in hooks (recommended — hooks degrade gracefully without it) | `brew install jq` / `apt install jq` |

### Architecture

```
┌──────────────────────────────────────────────┐
│              Claude Code CLI                   │
│  CLAUDE.md         → project rules             │
│  .claude/skills/   → progressive personas      │
│  .claude/commands/ → simple slash commands     │
│  .claude/agents/   → subagent metadata         │
│  .claude/hooks/    → automation                │
└──────────────┬───────────────────────────────┘
               │ Obsidian CLI / MCP
┌──────────────▼───────────────────────────────┐
│          Vault Access Layer                    │
│  Obsidian CLI (primary)                        │
│  obsidian-mcp-server (optional REST API)       │
│  Git MCP (optional)                            │
└──────────────┬───────────────────────────────┘
               │
┌──────────────▼───────────────────────────────┐
│          Obsidian Vault (separate repo)        │
└──────────────────────────────────────────────┘
```

---

## Alternative: auto-detect script

For a non-interactive setup, `setup_ai_workspace.sh` scans the project and generates everything in one command:

```bash
./setup_ai_workspace.sh --project-dir . --vault-dir ../MyProjectVault --ide claude
```

The script is the fast path. The wizard above is the flexible path. Pick whichever fits.

---

## After Setup

See [`README.md` § After Setup](README.md) for the post-install workflow and first-week customisation tips.
