---
name: weekly
description: Weekly Summary Generator — aggregates daily notes into weekly summaries with categorized session rollups
model: haiku
disable-model-invocation: true
argument-hint: "[week date range or end-date]"
---

# Weekly Summary Generator

Generate a weekly summary note by aggregating the last 7 daily notes from the Obsidian vault. Replace `<vault>` with your actual vault folder name (e.g., `MyProjectVault`).

## Workflow

### Step 1: Determine Date Range

Today is `{{DATE}}`. Calculate the 7 dates ending today (or the date provided in `$ARGUMENTS`).

Use ISO week numbering to determine the week number (W01–W53). The output filename is `weekly/{YYYY}-W{WW}.md`.

### Step 2: Read Daily Notes

For each of the 7 dates, read the daily note via Obsidian CLI:

```bash
obsidian read path="daily/{YYYY-MM-DD}.md" vault=<vault>
```

For today's date, use the shortcut:
```bash
obsidian daily:read vault=<vault>
```

Skip dates where the note does not exist. Track which dates had notes (used in output).

### Step 3: Parse Sessions

Each daily note has a pipe-delimited session table under `## Sessions`:

```
| Time | Persona | Task | Files | Outcome |
|------|---------|------|-------|---------|
| 14:30 | implementer | Add login flow | auth.ts, login.tsx | success |
```

Parse every session row across the 7 dates. Categorize each session by keywords in the Task column:

| Category | Trigger keywords |
|----------|-------------------|
| **Features** | add, implement, create, build, ship |
| **Bug Fixes** | fix, resolve, repair, patch + bug-related personas |
| **Refactoring** | refactor, improve, clean, restructure, simplify |
| **Analysis** | persona is one of: investigator, safety, performance, reviewer, crash, pragmatist |
| **Other** | anything not matching above |

### Step 4: Collect Linked Notes

Search the daily notes for wikilinks of the form `[[<note-name>]]`. For each link to a decision/bug/plan note, fetch a one-line summary:

```bash
obsidian read path="decisions/{link}.md" vault=<vault>
obsidian read path="bugs/{link}.md" vault=<vault>
obsidian read path="plans/active/{link}.md" vault=<vault>
```

Extract the first non-frontmatter, non-heading line as the summary.

### Step 5: Read Weekly Template

```bash
obsidian read path="templates/Weekly.md" vault=<vault>
```

### Step 6: Generate Weekly Note

Expand the template with aggregated data:

- `{{week-number}}` — ISO week number
- `{{start-date}}`, `{{end-date}}` — boundaries of the 7-day window
- `{{branches}}` — unique branches seen across the dailies (from frontmatter)
- `{{features}}`, `{{bugs}}`, `{{refactoring}}`, `{{analysis}}` — bulleted lists of session entries, each ending with a daily-note backlink
- `{{decisions}}` — bulleted list of decision summaries with `[[link]]`
- `{{learning}}` — concatenated "Learning & Decisions" sections from each daily
- `{{blockers}}` — concatenated "Blockers & Questions" sections
- `{{next-week}}` — concatenated "Tomorrow's Focus" sections (final-day biased)
- `{{daily-links}}` — bullet list `- [[YYYY-MM-DD]]` for each daily found

### Step 7: Write the Weekly Note

```bash
# Via CLI
obsidian write path="weekly/{YYYY}-W{WW}.md" content="..." vault=<vault>

# Or direct write fallback
# Write("../<vault>/weekly/2026-W18.md", content)
```

---

## Rules

- Skip missing daily notes gracefully — note their absence in the output ("Tue, Thu: no daily notes")
- If no daily notes exist in the range, create a minimal weekly note that says so — do not error
- Preserve the template's frontmatter; only fill `{{placeholders}}`
- Do not paraphrase content — copy session-row excerpts verbatim and link back to the source daily
- The weekly is an **index**, not a rewrite

---

## Output Quality Checklist

Before writing, verify:
- [ ] Week number matches ISO calendar
- [ ] Date range spans exactly 7 days
- [ ] Every session row mapped to a category (or "Other")
- [ ] Every wikilink in the source dailies appears at least once in the output
- [ ] Daily-note backlinks present so the reader can drill in
- [ ] No orphan placeholders left in the file
