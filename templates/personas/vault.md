---
name: vault
description: Navigate the Obsidian vault — search, graph traversal, health checks, tasks, and daily notes
model: haiku
user-invocable: true
argument-hint: "[recent | daily | guide:X | plan:X | decision:X | bug:X | analysis:X | backlinks:X | links:X | outline:X | tags | tasks | recents | health | search query]"
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
---

# Vault Navigator

Fast vault navigation using the Obsidian CLI. Routes queries by pattern for quick access to project knowledge, graph traversal, and vault health.

## CLI Reference

All vault operations use the Obsidian CLI with `vault=<your-vault-name>`. Replace `<your-vault-name>` with your actual vault folder (e.g., `MyProjectVault`).

```bash
# ── Content ───────────────────────────────────────────────────────────
obsidian search:context query="X" path="folder" limit=N vault=<vault>  # Search with matching lines
obsidian read path="path.md" vault=<vault>                              # Read a note
obsidian outline file="name" vault=<vault>                              # Heading tree

# ── Graph traversal ──────────────────────────────────────────────────
obsidian backlinks file="name" counts vault=<vault>                     # What links TO this note
obsidian links file="name" vault=<vault>                                # Outgoing links FROM this note

# ── Listing ──────────────────────────────────────────────────────────
obsidian files folder="dir" vault=<vault>                               # List files in folder
obsidian recents vault=<vault>                                          # Recently opened in Obsidian
obsidian tags vault=<vault> counts sort=count                           # All tags by frequency
obsidian tags file="name" vault=<vault>                                 # Tags for a specific note
obsidian tasks todo vault=<vault>                                       # Open tasks across vault
obsidian tasks todo file="name" vault=<vault>                           # Open tasks in a specific note

# ── Metadata ──────────────────────────────────────────────────────────
obsidian property:read name="prop" path="path" vault=<vault>            # Read frontmatter property
obsidian property:set  name="prop" value="X" path="path" vault=<vault>  # Write frontmatter property

# ── Health ────────────────────────────────────────────────────────────
obsidian orphans vault=<vault>                                          # Notes with no incoming links
obsidian unresolved vault=<vault>                                       # Broken wikilinks
obsidian deadends vault=<vault>                                         # Notes with no outgoing links

# ── Daily ─────────────────────────────────────────────────────────────
obsidian daily:read vault=<vault>                                       # Today's daily note
obsidian daily:path vault=<vault>                                       # Path to today's daily
obsidian daily:append content="..." vault=<vault>                       # Append to today's daily
```

---

## Query Patterns

Parse `$ARGUMENTS`:

### `recent [N]`
Show N most recent daily notes (default 5).
```bash
ls -1t ../<vault>/daily/*.md 2>/dev/null | head -N
```

### `daily`
Read today's daily note.
```bash
obsidian daily:read vault=<vault>
```

### `guide:X`
Search guides for X (returns matches with surrounding lines).
```bash
obsidian search:context query="X" path="guides" limit=10 vault=<vault>
```

### `plan:X` / `decision:X` / `bug:X` / `analysis:X`
Search the matching folder, ordered by recency.
```bash
obsidian search:context query="X" path="<folder>" limit=10 vault=<vault>
```

### `backlinks:X`
What notes reference X? (impact analysis)
```bash
obsidian backlinks file="X" counts vault=<vault>
```

### `links:X`
What does X reference? (dependency chain)
```bash
obsidian links file="X" vault=<vault>
```

### `outline:X`
Heading tree for X — useful before reading a long note.
```bash
obsidian outline file="X" vault=<vault>
```

### `tags`
All tags by frequency.
```bash
obsidian tags vault=<vault> counts sort=count
```

### `tasks`
Open tasks across the vault.
```bash
obsidian tasks todo vault=<vault>
```

### `recents`
Recently opened in Obsidian (different from filesystem mtime — uses Obsidian's history).
```bash
obsidian recents vault=<vault>
```

### `health`
Vault hygiene check — orphans, unresolved wikilinks, deadends.
```bash
obsidian orphans vault=<vault>
obsidian unresolved vault=<vault>
obsidian deadends vault=<vault>
```

### Free-text search
If `$ARGUMENTS` does not match any pattern above, run a full-vault search:
```bash
obsidian search:context query="$ARGUMENTS" limit=15 vault=<vault>
```

---

## Output Format

- Brief match context (1-2 lines per hit)
- File path for each result
- Group by folder when results span multiple folders
- Keep total output <15 lines per query — paginate with `more <pattern>` if needed

---

## When CLI Is Unavailable

If the Obsidian CLI is not on PATH, fall back to direct file tools:
```
Read("../<vault>/daily/2026-04-28.md")
Grep("pattern", path="../<vault>/guides/")
Glob("../<vault>/plans/active/**/*.md")
```

Functional but slower and without graph traversal.
