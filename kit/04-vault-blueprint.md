---
title: "Vault Blueprint — Obsidian Folder Structure & Templates"
type: reference
tags: [portable-setup, white-label, vault, obsidian]
version: "2.0"
created: 2026-02-25
updated: 2026-04-28
---

# Vault Blueprint — Obsidian Folder Structure & Templates

> **What this provides:** The complete Obsidian vault folder structure, note templates, and vault access setup. Create this vault as a **separate repository** alongside your project.

---

## Vault — What It Is and Why

The vault is a standalone Obsidian directory, kept outside the project repo, that acts as the durable knowledge layer for your work. Think of it as long-term memory for Claude Code: anything worth remembering after the current session ends lives here.

### What goes in it

| Folder | Holds | Created by |
|--------|-------|-----------|
| `daily/` | One note per day — sessions, commits, agent findings, decisions made | Hooks (auto) |
| `weekly/` | Rollup summaries aggregated from dailies | `/weekly` command |
| `decisions/` | Architectural Decision Records (ADRs) — why a choice was made, what alternatives were considered | Human + skills |
| `plans/active/` | In-progress implementation plans with status, branch, success criteria | Human + skills |
| `plans/planning/` | Scoped but not started | Human + skills |
| `plans/legacy/completed/` | Shipped plans — kept for historical reference | Moved on completion |
| `plans/legacy/superseded/` | Plans replaced by a better approach | Moved on supersession |
| `bugs/` | Bug post-mortems — symptoms, root cause, fix, verification | Skills (manual) |
| `analysis/` | Investigations, deep dives, profiling reports | Skills (manual) |
| `guides/<tech>/` | Best practices and patterns for a technology (e.g., `react/`, `postgres/`) | Human + skills |
| `workflows/` | Development processes and procedures | Human |
| `reference/` | External references, cheatsheets, links | Human |
| `memory/` | Long-lived personal notes, team context, preferences | Human |
| `templates/` | Note skeletons used by hooks and commands | Setup (once) |

### What does NOT go in it

- Project source code or generated artifacts
- README content meant for the public repo
- Throwaway scratchpads or chat-only context
- Credentials, API keys, NDA-protected content
- Anything that would be confusing to a future you reading it cold

### Why a separate repository

1. **Lifecycle mismatch.** Decisions and bug reports outlive feature branches. Coupling them to code history creates noise on both sides.
2. **Different commit cadence.** Vault notes are appended throughout the day; code commits are per-feature. Mixing the two pollutes history.
3. **Future scaling.** Multiple projects can share one vault later (see *Multi-Vault Scaling* below).
4. **Safety.** A separate repo prevents accidental commits of internal-only notes to a public code repo.

### How Claude Code uses the vault

**At session start** (`session_context.sh` hook):
- Reads `plans/active/` and surfaces the list to Claude
- Reads recent `daily/` notes (last 3 days) for continuity
- Pattern-matches changed files to recommend relevant `guides/<tech>/` notes

**During a session:**
- Skills like `/investigator` and `/vault` search the vault when they need historical context (prior decisions, recurring bugs, established patterns)
- The `--use-opus` exception path consults `decisions/` for production-critical paths

**After tool calls:**
- `track_modified.sh` accumulates edited file paths
- `on_commit.sh` appends a structured commit entry to today's daily note (commit message + file list)
- `on_agent_stop.sh` appends agent findings summaries

**On demand:**
- `/weekly` reads the last 7 daily notes and writes a weekly rollup to `weekly/YYYY-WNN.md`
- The user can read, edit, search, and link notes manually in Obsidian

### What "good vault hygiene" looks like

- One decision = one ADR in `decisions/`. Don't bury decisions in commit messages.
- One bug fix = one bug post-mortem in `bugs/` if the bug was non-obvious or could recur. Skip post-mortems for trivial typo fixes.
- One feature = one plan in `plans/active/<feature>/`, moved to `legacy/completed/<feature>/` when shipped.
- Guides accumulate gradually. Don't try to seed every guide up-front — write them when you've solved the problem twice.
- Move plans between `active/`, `planning/`, `legacy/completed/`, and `legacy/superseded/` as work progresses. Keep `status:` frontmatter in sync.

### Should you skip the vault?

Skip it if any of the following are true:

- This is a 1-week throwaway prototype.
- You already have a working knowledge base (Notion, Linear, Confluence, GitHub wiki) you intend to keep using.
- You are evaluating Claude Code with the kit but do not yet want to commit to a new tool (Obsidian).

The rest of the kit still works without the vault — the `/vault` command, the `/weekly` command, and vault-writing hooks become inert (they do not error). You can add the vault later by running Module A on its own.

---

## Folder Structure

```
{{VAULT_NAME}}/
├── analysis/            # Post-mortems, investigations, root cause analyses
│   └── {{feature}}/     # Optional: feature-split subdirs for large projects
├── bugs/                # Bug reports with symptoms, root cause, fix
├── daily/               # Auto-populated daily dev logs (one per day)
├── decisions/           # Architectural Decision Records (ADRs)
│   └── {{feature}}/     # Optional: feature-split subdirs
├── guides/              # Best practices and how-to guides
│   └── {{technology}}/  # Organized by technology (e.g., guides/react/, guides/postgres/)
├── memory/              # Long-lived reference data (personal notes, team context)
├── plans/
│   ├── active/
│   │   └── {{feature}}/ # Currently in-progress plans, feature-split
│   ├── planning/
│   │   └── {{feature}}/ # Proposed but not started
│   └── legacy/
│       ├── completed/
│       │   └── {{feature}}/ # Shipped plans (kept for historical reference)
│       └── superseded/
│           └── {{feature}}/ # Plans replaced by better approaches
├── reference/           # External references, cheatsheets
│   └── {{feature}}/     # Optional: feature-split subdirs
├── templates/           # Note templates (used by hooks and skills)
├── weekly/              # Auto-generated weekly summaries (YYYY-WNN.md)
└── workflows/           # Development processes and procedures
```

### Plans Lifecycle

Plans have a lifecycle axis on top of the feature split:

```
vault/plans/
├── active/<feature>/           # In-progress or design-complete
├── planning/<feature>/         # Scoped but not started
└── legacy/
    ├── completed/<feature>/    # Shipped; kept for historical reference
    └── superseded/<feature>/   # Evaluated but replaced by a better approach
```

Move plans between lifecycle stages as work progresses. The `status:` frontmatter field tracks the same states (`active | planning | completed | superseded`).

### Feature-Split Taxonomy

For large projects, sub-organize `analysis/`, `decisions/`, `plans/`, and `reference/` by feature slug. Use canonical slugs so links stay consistent:

| Example Slug | Scope |
|-------------|-------|
| `auth` | Authentication, sessions, tokens |
| `api` | REST/GraphQL endpoints, contracts |
| `database` | Schema, migrations, queries |
| `frontend` | UI components, state management |
| `devops` | CI/CD, deployment, infra |
| `testing` | Test infrastructure, patterns |

Feature folders are created on first file; empty ones get pruned.

**Not feature-split (by design):** `daily/`, `weekly/`, `guides/`, `memory/`, `templates/`, `workflows/` — organized chronologically, by technology, or by format.

### Folder Purposes

| Folder | Created By | Frequency | Retention |
|--------|-----------|-----------|-----------|
| `daily/` | Hooks (auto) | Every session | Permanent |
| `weekly/` | `/weekly` command | Weekly | Permanent |
| `decisions/` | Skills (manual) | Per decision | Permanent |
| `bugs/` | Skills (manual) | Per bug | Permanent |
| `analysis/` | Skills (manual) | Per investigation | Permanent |
| `guides/` | Human + Skills | As needed | Updated over time |
| `plans/active/` | Human + Skills | Per feature | Moved to legacy when done |
| `reference/` | Human | As needed | Updated over time |
| `workflows/` | Human | Rare | Updated over time |
| `templates/` | Setup (once) | Never auto-modified | Updated manually |

---

## Vault Access Methods

### Primary: Obsidian CLI

The Obsidian CLI is the preferred vault access method for hooks and skills. It works without a running Obsidian instance for most operations.

**Installation:** The `obsidian` binary is bundled with the Obsidian desktop app. Add it to PATH:

```bash
# macOS
export PATH="$PATH:/Applications/Obsidian.app/Contents/MacOS"

# Or create a symlink
ln -s /Applications/Obsidian.app/Contents/MacOS/obsidian /usr/local/bin/obsidian
```

**Common CLI commands:**

```bash
# Read today's daily note
obsidian daily:read vault={{VAULT_NAME}}

# Append to today's daily note
obsidian daily:append content="## 14:30 — Session\nWorked on auth module." vault={{VAULT_NAME}}

# Get the path to today's daily note
obsidian daily:path vault={{VAULT_NAME}}

# Read a specific note
obsidian read path="guides/api_best_practices.md" vault={{VAULT_NAME}}

# Search the vault
obsidian search "query" vault={{VAULT_NAME}}

# Set a frontmatter property
obsidian property:set name="status" value="completed" path="plans/active/feature/my-plan.md" vault={{VAULT_NAME}}

# Append to a specific note
obsidian append path="decisions/2026-04-28-auth-approach.md" content="## Addendum\n..." vault={{VAULT_NAME}}
```

### Secondary: MCP REST API (requires Obsidian running)

Install the **Local REST API** plugin from Obsidian Community Plugins. Needed only when using `mcp__obsidian__*` tools in Claude Code sessions.

Setup:
1. Install from Obsidian Community Plugins
2. Enable the plugin
3. Copy the API key from plugin settings (Settings → Local REST API → API Key)
4. Note the port (default: 27124, HTTPS)
5. Add key to `settings.local.json` mcpServers section (see [06-settings-reference.md](06-settings-reference.md))

**Available MCP tools (when REST API is running):**
- `mcp__obsidian__obsidian_global_search` — full-text search
- `mcp__obsidian__obsidian_read_note` — read a specific note
- `mcp__obsidian__obsidian_update_note` — write/overwrite a note
- `mcp__obsidian__obsidian_list_notes` — list notes in a directory

### Fallback: Direct File Read/Write

When neither CLI nor MCP is available, use Claude Code's built-in Read/Write tools directly on the vault files. The vault is just a directory of Markdown files.

```
# Claude Code has access to vault via additionalDirectories in settings.local.json
Read("../{{VAULT_NAME}}/guides/api_best_practices.md")
Write("../{{VAULT_NAME}}/daily/2026-04-28.md", content)
```

---

## Multi-Vault Scaling

To share one vault across multiple projects:

1. Each project gets a feature/project subdirectory:
   ```
   SharedVault/
   ├── daily/project-a/   # Project-specific daily notes
   ├── daily/project-b/
   ├── guides/            # Shared guides (all projects)
   ├── project-a/         # Project-specific plans, decisions, analysis
   └── project-b/
   ```
2. Session context hooks read from project-specific subdirectory
3. `additionalDirectories` in settings points to the shared vault
4. Wikilinks resolve by basename, so cross-project links work naturally

---

## Dataview Plugin (Optional)

Install Dataview from Obsidian Community Plugins to get dashboard queries. Create `dashboards.md` at vault root:

````markdown
---
title: "Dashboards"
type: reference
tags: [dashboard]
---

# Dashboards

## Active Plans
```dataview
TABLE status, priority, branch
FROM "plans/active"
WHERE type = "plan"
SORT priority ASC
```

## Recent Decisions
```dataview
TABLE status, created
FROM "decisions"
WHERE type = "decision"
SORT created DESC
LIMIT 10
```

## Open Bugs
```dataview
TABLE severity, status, branch
FROM "bugs"
WHERE type = "bug" AND status != "closed" AND status != "fixed"
SORT severity ASC
```

## Recent Daily Notes
```dataview
TABLE branch
FROM "daily"
SORT file.name DESC
LIMIT 7
```
````

---

## Templates

### Template 1: Daily.md

Used by `on_commit.sh` hook to create daily notes automatically.

```markdown
---
title: "Daily Log - {{date}}"
type: daily
tags: [daily, {{branch-tag}}]
created: {{date}}
updated: {{date}}
branch: {{branch}}
---

# Daily Log - {{date}}

## Active Branch
- `{{branch}}`

## Sessions

| Time | Persona | Task | Files | Outcome |
|------|---------|------|---------|---------|

---

## Decision Trail

---

## Learning & Decisions

## Blockers & Questions

## Tomorrow's Focus
```

**Placeholders resolved by `on_commit.sh`:**
- `{{date}}` → `2026-04-28`
- `{{branch}}` → `feature/auth`
- `{{branch-tag}}` → `feature-auth`

---

### Template 2: Weekly.md

Used by `/weekly` command to generate summaries.

```markdown
---
title: "Weekly Summary - Week {{week-number}}"
type: weekly
tags: [weekly, summary]
created: {{date}}
week: {{week-number}}
---

# Weekly Summary - Week {{week-number}}

## Week Overview
- **Dates:** {{start-date}} to {{end-date}}
- **Active Branch(es):** {{branches}}

## Work Completed

### Features & Implementations
{{features}}

### Bug Fixes
{{bugs}}

### Refactoring & Improvements
{{refactoring}}

### Analysis & Research
{{analysis}}

## Key Decisions
{{decisions}}

## Learning & Insights
{{learning}}

## Blockers & Challenges
{{blockers}}

## Next Week Focus
{{next-week}}

## Daily Notes
{{daily-links}}
```

---

### Template 3: Plan.md

For tracking implementation plans.

```markdown
---
type: plan
title: "{{title}}"
status: active
category: ""
priority: p2
tags: [plan]
created: {{date}}
updated: {{date}}
branch: ""
superseded_by: ""
supersedes: ""
version: 1.0
---

# {{title}}

## Problem Statement
[What problem does this solve?]

## Solution Overview
[High-level approach]

## Success Criteria
- [ ]
- [ ]

## Related Plans
-

## References
-
```

**Status values:** `active` | `planning` | `completed` | `superseded`
**Priority values:** `p0` (critical) | `p1` (high) | `p2` (normal) | `p3` (low)

---

### Template 4: Decision.md

Architectural Decision Records (ADRs).

```markdown
---
title: "ADR: {{title}}"
type: decision
status: accepted
tags: [decision, adr]
created: {{date}}
branch: {{branch}}
---

# ADR: {{title}}

## Context
[What is the situation that requires a decision?]

## Decision
[What was decided?]

## Alternatives Considered
[What other options were evaluated?]

## Consequences
**Positive:** [benefits]
**Negative:** [tradeoffs]

## Implementation
[How will this be implemented?]

## Related
- Daily: [[{{daily-note}}]]
```

**Status values:** `proposed` | `accepted` | `rejected` | `deprecated`

---

### Template 5: Bug.md

Bug reports with structured root cause analysis.

```markdown
---
title: "{{title}}"
type: bug
status: {{status}}
severity: {{severity}}
tags: [bug]
created: {{date}}
branch: {{branch}}
---

# {{title}}

## Symptoms
[What went wrong? Observable behavior.]

## Root Cause
[Why did it happen? Code-level explanation.]

## Fix Applied
[What was changed to fix it?]

## Verification
[How was the fix verified?]

## Related
- Daily: [[{{daily-note}}]]
```

**Status values:** `open` | `investigating` | `fixed` | `closed` | `wontfix`
**Severity values:** `critical` | `major` | `minor` | `cosmetic`

---

### Template 6: Analysis.md

For investigations, post-mortems, and deep dives. Filename convention: `YYYY-MM-DD-topic.md`.

```markdown
---
title: "{{title}}"
type: analysis
tags: [analysis]
created: {{date}}
updated: {{date}}
---

# {{title}}

## Summary
[1-2 sentence overview of findings]

## Investigation
[Detailed analysis with evidence]

## Findings
[Structured results]

## Recommendations
[What to do based on findings]

## Related
- Plan: [[related-plan]]
- Daily: [[{{daily-note}}]]
```

---

### Template 7: Guide.md

Best practices and how-to guides.

```markdown
---
title: "{{title}}"
type: guide
tags: [guide]
created: {{date}}
updated: {{date}}
---

# {{title}}

## Overview
[What this guide covers and when to reference it]

## Rules
[Key rules — numbered, actionable]

## Examples
[Code examples with explanations]

## Anti-Patterns
[What NOT to do, with reasons]

## References
[Links to external docs, related guides]
```

---

### Template 8: Workflow.md

Development processes and procedures.

```markdown
---
title: "{{title}}"
type: workflow
tags: [workflow]
created: {{date}}
updated: {{date}}
---

# {{title}}

## When to Use
[Trigger conditions for this workflow]

## Steps
1. [Step with details]
2. [Step with details]

## Checklist
- [ ] [Verification item]

## Notes
[Edge cases, exceptions, tips]
```

---

### Template 9: Reference.md

External references and cheatsheets.

```markdown
---
title: "{{title}}"
type: reference
tags: [reference]
created: {{date}}
updated: {{date}}
source: ""
---

# {{title}}

## Summary
[What this reference covers]

## Content
[Reference material]

## Source
[Where this came from]
```

---

## Vault Initialization Script

Run this to create the complete vault structure:

```bash
#!/bin/bash
# init_vault.sh — Creates Obsidian vault structure with all templates
# Usage: bash init_vault.sh /path/to/VaultName

set -euo pipefail

VAULT="${1:?Usage: bash init_vault.sh /path/to/VaultName}"

echo "Creating vault at: $VAULT"

# Create directory structure
mkdir -p "$VAULT"/{analysis,bugs,daily,decisions,guides,memory,plans/{active,planning,legacy/{completed,superseded}},reference,templates,weekly,workflows}

# Create templates (heredocs for each)
# Daily
cat > "$VAULT/templates/Daily.md" << 'TEMPLATE'
---
title: "Daily Log - {{date}}"
type: daily
tags: [daily, {{branch-tag}}]
created: {{date}}
updated: {{date}}
branch: {{branch}}
---

# Daily Log - {{date}}

## Active Branch
- `{{branch}}`

## Sessions

| Time | Persona | Task | Files | Outcome |
|------|---------|------|---------|---------|

---

## Learning & Decisions

## Blockers & Questions

## Tomorrow's Focus
TEMPLATE

# Weekly
cat > "$VAULT/templates/Weekly.md" << 'TEMPLATE'
---
title: "Weekly Summary - Week {{week-number}}"
type: weekly
tags: [weekly, summary]
created: {{date}}
week: {{week-number}}
---

# Weekly Summary - Week {{week-number}}

## Week Overview
- **Dates:** {{start-date}} to {{end-date}}
- **Active Branch(es):** {{branches}}

## Work Completed

### Features & Implementations
{{features}}

### Bug Fixes
{{bugs}}

## Key Decisions
{{decisions}}

## Next Week Focus
{{next-week}}

## Daily Notes
{{daily-links}}
TEMPLATE

# Plan
cat > "$VAULT/templates/Plan.md" << 'TEMPLATE'
---
type: plan
title: "{{title}}"
status: active
priority: p2
tags: [plan]
created: {{date}}
updated: {{date}}
branch: ""
---

# {{title}}

## Problem Statement

## Solution Overview

## Success Criteria
- [ ]

## References
TEMPLATE

# Decision
cat > "$VAULT/templates/Decision.md" << 'TEMPLATE'
---
title: "ADR: {{title}}"
type: decision
status: accepted
tags: [decision, adr]
created: {{date}}
branch: {{branch}}
---

# ADR: {{title}}

## Context

## Decision

## Alternatives Considered

## Consequences
**Positive:**
**Negative:**

## Related
TEMPLATE

# Bug
cat > "$VAULT/templates/Bug.md" << 'TEMPLATE'
---
title: "{{title}}"
type: bug
status: open
severity: major
tags: [bug]
created: {{date}}
branch: {{branch}}
---

# {{title}}

## Symptoms

## Root Cause

## Fix Applied

## Verification
TEMPLATE

# Analysis
cat > "$VAULT/templates/Analysis.md" << 'TEMPLATE'
---
title: "{{title}}"
type: analysis
tags: [analysis]
created: {{date}}
updated: {{date}}
---

# {{title}}

## Summary

## Investigation

## Findings

## Recommendations
TEMPLATE

# Guide
cat > "$VAULT/templates/Guide.md" << 'TEMPLATE'
---
title: "{{title}}"
type: guide
tags: [guide]
created: {{date}}
updated: {{date}}
---

# {{title}}

## Overview

## Rules

## Examples

## Anti-Patterns
TEMPLATE

# Workflow
cat > "$VAULT/templates/Workflow.md" << 'TEMPLATE'
---
title: "{{title}}"
type: workflow
tags: [workflow]
created: {{date}}
updated: {{date}}
---

# {{title}}

## When to Use

## Steps

## Checklist

## Notes
TEMPLATE

# Reference
cat > "$VAULT/templates/Reference.md" << 'TEMPLATE'
---
title: "{{title}}"
type: reference
tags: [reference]
created: {{date}}
updated: {{date}}
source: ""
---

# {{title}}

## Summary

## Content

## Source
TEMPLATE

# Initialize git repo
cd "$VAULT"
git init
git add -A
git commit -m "init: vault structure with templates"

echo ""
echo "Vault created at: $VAULT"
echo "Git repo initialized"
echo ""
echo "Next steps:"
echo "  1. Open $VAULT in Obsidian"
echo "  2. Install 'Local REST API' plugin (for MCP access)"
echo "  3. Add obsidian CLI to PATH (for hook scripts)"
echo "  4. Create symlink: ln -s $VAULT vault (from project root)"
```
