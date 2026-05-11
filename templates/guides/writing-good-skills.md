---
title: "Writing Good Skills"
type: guide
tags: [guide, skills, claude-code]
created: 2026-04-28
updated: 2026-04-28
---

# Writing Good Skills

A skill is a specialized persona. Good skills compose; bad skills duplicate the work the user would do anyway.

## Rules

1. **One responsibility per skill.** "Investigator gathers evidence" is one skill. "Investigator gathers evidence and writes the fix" is two skills mashed together.
2. **Defaults to direct tools.** A skill that always spawns Task agents is expensive and slow. Spawn agents only for genuine cross-source reasoning.
3. **Output format is part of the contract.** Define what the skill returns. Other skills (and humans) rely on the shape, not the prose.
4. **Frontmatter is the API.** `name`, `description`, `model`, `allowed-tools`, `argument-hint`, `disable-model-invocation` — choose deliberately. Default to `disable-model-invocation: true` for skills that should never auto-fire.
5. **Persona flavor is decorative, not structural.** A "no nonsense engineer" persona is fine. Do not let personality replace concrete workflow steps.

## Skill vs Command vs Agent

| Format | Use when |
|--------|----------|
| Skill (`.claude/skills/NAME/SKILL.md`) | Needs reference sub-files (`workflow.md`, `patterns.md`, `checklist.md`) loaded progressively |
| Command (`.claude/commands/NAME.md`) | Single-page prompt, no sub-files |
| Agent (`.claude/agents/NAME.md`) | Spawned by an orchestrator via Task — needs model/memory config |

A persona can exist as both Skill (for user invocation) and Agent (for orchestrator spawning). Same name, same persona block, different file.

## Examples

**Good:** `/reviewer src/auth/session.ts` — reads the file, runs the audit checklist, returns findings in the defined format.

**Bad:** `/reviewer` (no target) producing a generic "here are some review tips" essay — the skill should default to a sensible target (active plan, last commit, recent analysis) or refuse.

## Anti-Patterns

- **Skills that always escalate.** If every invocation spawns 3 Task agents, the skill is a router, not a worker. Rename it.
- **Skills with hidden prerequisites.** A skill that errors when a vault folder is missing should either create the folder, fall back, or refuse with a clear message — never just crash.
- **Skills written for one project but added to the generic kit.** Strip project-specific terminology before sharing. Use `{{PLACEHOLDERS}}`.
- **Skills with model: opus by default.** Opus is the exception, not the default. Set `model: haiku` and let the orchestrator promote when justified.

## References

- See `kit/02-skill-catalog.md` for full persona templates
- See `kit/05-token-strategy.md` for agent budget rules
