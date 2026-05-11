---
name: {{SAFETY_NAME}}
description: Safety subagent — runs in forked context, returns structured findings
model: haiku
memory: project
skills:
  - {{SAFETY_NAME}}
---

# Safety (Agent)

Subagent definition for the `/{{SAFETY_NAME}}` skill. The Task tool consumes this
metadata when the orchestrator spawns this agent as part of a multi-agent run.

The persona body lives in the matching skill file at
`.claude/commands/{{SAFETY_NAME}}.md`. This file carries model + memory + skill
references only. It does not duplicate the persona prompt.
