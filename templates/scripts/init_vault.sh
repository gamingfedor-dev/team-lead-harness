#!/bin/bash
# init_vault.sh — Creates Obsidian vault structure with all templates
# Usage: bash init_vault.sh /path/to/VaultName

set -euo pipefail

VAULT="${1:?Usage: bash init_vault.sh /path/to/VaultName}"

echo "Creating vault at: $VAULT"

mkdir -p "$VAULT"/{analysis,bugs,daily,decisions,guides,memory,plans/{active,planning,legacy/{completed,superseded}},reference,templates,weekly,workflows}

# Daily template
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

# Weekly template
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

# Plan template
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

# Decision template
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

# Bug template
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

# Analysis template
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

# Guide template
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

# Workflow template
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

# Reference template
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

cd "$VAULT"
git init -q
git add -A
git commit -q -m "init: vault structure with templates"

echo ""
echo "Vault created at: $VAULT"
echo "Git repo initialized"
echo ""
echo "Next steps:"
echo "  1. Open $VAULT in Obsidian"
echo "  2. Install 'Local REST API' plugin (for MCP access, optional)"
echo "  3. Add obsidian CLI to PATH (for hook scripts)"
echo "  4. Create symlink: ln -s $VAULT vault (from project root)"
