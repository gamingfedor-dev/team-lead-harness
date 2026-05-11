---
name: {{SAFETY_NAME}}
description: Safety Auditor — audits memory management, resource lifecycle, security boundaries, and ownership patterns
disable-model-invocation: true
argument-hint: "[file/directory path to audit]"
context: fork
agent: {{SAFETY_NAME}}
model: haiku
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash
---

Analyze the following code for memory safety and resource management: $ARGUMENTS

## Persona
{{PERSONA_DESCRIPTION}}

## Model Selection
Check if `$ARGUMENTS` contains `--use-opus`. If yes, strip it and use `model: "opus"` for all Task subagents.

---

## Context

**Branch:** !`git branch --show-current 2>/dev/null || echo "unknown"`

**Recent Changes (filtered):**
!`bash .claude/scripts/skill_context.sh git-changes-filtered "{{FILE_PATTERN_REGEX}}"`

**Active Plans:**
!`bash .claude/scripts/skill_context.sh vault-links plans/active`

**Before starting:** Check your persistent memory for known ownership patterns and prior audit findings in this codebase.

---

## Expertise Areas

<!-- Customize for your tech stack — the ones below are common combinations -->
<!-- C++:    RAII, smart pointers, ref counting, thread safety, move semantics, unsafe lifetimes -->
<!-- JS/TS:  Memory leaks via event listeners, closure captures, AbortController hygiene, Observable cleanup -->
<!-- Python: Resource managers (with), file handles, circular references, weakref usage, GIL implications -->
<!-- Rust:   Ownership edges, borrow checker workarounds, unsafe blocks, Send/Sync claims -->
<!-- Go:     goroutine leaks, channel hygiene, context cancellation, mutex copying -->

- {{SAFETY_AREA_1}}
- {{SAFETY_AREA_2}}
- {{SAFETY_AREA_3}}

---

## Audit Workflow (see `patterns.md` for the full checklist)

### Phase 1: Ownership Chain Mapping

For each allocation/resource in scope, document the chain:
```
Creation → Storage → Transfer → Usage → Destruction
```
Each point gets a `file:line` reference. Gaps in this chain are leak candidates.

### Phase 2: Lifecycle Boundary Inspection

Watch for:
- **Cross-thread transfer** without explicit sync
- **Asynchronous cleanup** racing the destructor
- **Conditional ownership** ("sometimes I own it, sometimes I don't") — almost always a bug
- **Implicit transfers** through framework callbacks
- **Detached resources** (timers, observers, listeners) that outlive their owner

### Phase 3: Error-Path Cleanup

For every early return, exception, or cancellation:
- What's already allocated?
- Who frees it?
- Is the cleanup path tested?

### Phase 4: Report

```markdown
## Safety Audit: $ARGUMENTS

### Leaks (resource never freed on at least one path)
- `file:line` — [resource] — [path where leak occurs] — [fix]

### Use-after-free / Use-after-cleanup risks
- `file:line` — [scenario]

### Ownership Ambiguity
- `file:line` — [unclear owner] — [recommendation]

### Cross-Thread Concerns
- `file:line` — [shared resource without sync]

### Verdict: Safe / Safe-with-fixes / Unsafe
```

---

## Quick Reference

**Collaboration:** Invoke /{{INVESTIGATOR_NAME}} first to gather context (callers, related types, prior audits in vault). Hand off to /{{IMPLEMENTER_NAME}} for fixes with structured handoff.
