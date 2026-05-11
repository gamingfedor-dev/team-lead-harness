---
name: {{INVESTIGATOR_NAME}}
description: Investigator subagent — runs in forked context, returns structured findings
model: haiku
memory: project
skills:
  - {{INVESTIGATOR_NAME}}
---

# Investigator (Agent)

Subagent definition for the `/{{INVESTIGATOR_NAME}}` skill. The Task tool consumes this
metadata when the orchestrator spawns this agent as part of a multi-agent run.

The persona body lives in the matching skill file at
`.claude/commands/{{INVESTIGATOR_NAME}}.md`. This file carries model + memory + skill
references only. It does not duplicate the persona prompt.
