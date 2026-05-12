---
title: "Token Preservation Strategy"
type: reference
tags: [portable-setup, white-label, token-strategy]
version: "2.0"
created: 2026-02-25
updated: 2026-04-28
---

# Token Preservation Strategy

> **Copy this file directly to `.claude/token_strategy.md` in your project.** This is project-agnostic — no customization needed beyond replacing the anti-pattern examples with your own domain names.

---

Apply these strategies to minimize token usage while maintaining quality.

## CRITICAL RULE: Agents Are Expensive, Direct Tools Are Free

**Each Task agent costs 30-40k tokens minimum** (even Haiku) because they load full context, explore broadly, and generate long reports. Three agents = 80-120k tokens = potentially exhausting the session budget in one prompt.

**Direct tools (Grep, Glob, Read) cost ~0 extra tokens** and return the exact same data.

### The Rule
1. **NEVER spawn an agent to find code, read files, or search patterns** — use Grep/Glob/Read directly
2. **ONLY spawn agents for reasoning/synthesis** over data you already gathered
3. **If you must use agents**, keep prompts to 1-2 sentences asking a specific yes/no or short-answer question
4. **Budget:** ~5-7k tokens per agent max, ~20k total for multi-agent work

### The Retrieval vs Reasoning Distinction

This is the key judgment call:

| Task type | Use |
|-----------|-----|
| Find all files matching a pattern | Grep/Glob (0 tokens) |
| Read a specific file | Read (0 tokens) |
| Gather all usages of a function | Grep (0 tokens) |
| "Does this 30-line function have a race condition?" | Agent OK — reasoning required |
| "Given these 3 snippets, what's the threading risk?" | Agent OK — cross-source synthesis |
| "Map ALL lifecycle code in the module" | Grep (0 tokens) — agent would pad this |

The investigator skill (e.g., `/investigator`) is the ONE exception to the no-retrieval-via-agent rule. It may retrieve when the task involves web searches, vault searches, or external documentation that direct tools cannot access. Keep its prompts focused — no "gather all references" tasks.

### Investigation Workflow (Correct)
```
Step 1: Grep for pattern → get file:line locations        (0 tokens)
Step 2: Read specific lines with offset/limit             (0 tokens)
Step 3: You now have the data. Synthesize it yourself.    (0 tokens)
Step 4: ONLY IF complex reasoning needed → 1 agent,       (~5k tokens)
        tight prompt with specific code snippets included
```

### Investigation Workflow (WRONG — burns 80k+ tokens)
```
Step 1: Spawn 3 agents saying "gather ALL references"     (80k tokens)
Step 2: Each agent reads 30+ files and returns 10k report
Step 3: You summarize their reports
```

### Anti-Patterns (NEVER DO)
- "Map ALL lifecycle code in this module" → agent reads entire directory
- "Gather ALL references about X" → agent produces 10k-token report
- "Audit all threading and mutexes" → agent explores every file

### Good Patterns
- "In auth.ts, is the refresh token rotated on every use?" → yes/no
- "Given this 20-line function [pasted], what's the race condition risk?" → focused analysis
- Skip agents entirely — grep + read + your own analysis

## Search & Exploration

**ALWAYS use direct tools first:**
- Use `Grep` for specific text/code searches — this is your primary investigation tool
- Use `Glob` for finding files by pattern (e.g., `**/*.ts`, `**/*.py`)
- Use `Read` with `offset`/`limit` for known file paths

**Only escalate to agents when:**
- You've already gathered data with direct tools
- You need complex reasoning that benefits from a separate context
- The question requires cross-referencing 10+ files (rare)

**Search efficiently:**
- Start with `Grep` in `files_with_matches` mode to find relevant files
- Read only the files that match, not entire directories
- Use `head_limit` parameter to limit results when exploring

## Reading Files

**Selective reading:**
- Read only files relevant to the current task
- Use `offset` and `limit` for large files — read specific sections
- Don't re-read files already in context unless changed

**Prefer specific reads:**
- Read the specific file mentioned, not "all related files"
- Check existing context before reading — file may already be loaded

## Tool Calls

**Parallel execution:**
- Combine independent tool calls in single message
- Example: Read multiple files in parallel, run independent searches together

**Avoid redundant calls:**
- Don't glob for files just read or mentioned in system reminders
- Don't search for code patterns visible in current context
- Check git status output before re-running git commands

## Code Changes

**Minimal diffs:**
- Use `Edit` for targeted changes (preferred)
- Use `Write` only for new files or complete rewrites
- Make surgical edits, not file rewrites

**Batch related changes:**
- Group edits to the same file
- Complete all changes to a file before moving to next

## Response Efficiency

**Concise output:**
- Short confirmations for simple actions
- Summarize findings, don't repeat file contents
- Use code references (`file:line`) instead of quoting code

**Skip unnecessary steps:**
- Don't explain what you're about to do in detail
- Don't summarize what was just read back to user
- Don't ask for confirmation on routine operations

## Agent Delegation

**BEFORE spawning any agent, ask: "Can I get this with Grep/Read?"**
- If yes → use direct tools. Always.
- If no → spawn ONE agent with a 1-2 sentence prompt, budget 5-7k tokens max

**Delegate to subagents ONLY when:**
- The investigator skill needs web searches or vault searches that direct tools can't access
- You already have raw data and need complex cross-referencing reasoning
- The task genuinely requires judgment, not data retrieval

**NEVER delegate to subagents for:**
- Finding files or code patterns (use Grep/Glob)
- Reading file contents (use Read)
- Gathering "all references" to something (use Grep)
- Any task where the output is just "here's what the code says"

**Keep in main context when:**
- Making edits (need to track changes)
- User interaction required
- Simple, targeted operations
- Most investigations — you can grep + read + reason yourself

## Multi-Agent (Orchestrator) Token Rules

When the orchestrator spawns multiple agents:

1. **Gather data with direct tools first** — Grep/Read before spawning agents
2. **Pass gathered data IN the agent prompt** — don't make agents re-read files they don't need
3. **Surgical prompts** — 1-2 sentences, specific questions, not "gather ALL references"
4. **Tests run ONCE at the end** — tell every spawned agent to SKIP running tests. The orchestrator runs the full test suite a single time after all agents complete. Include "Do NOT run tests — [orchestrator name] will run the full suite after all agents complete" in every agent prompt.
5. **Tier assignment** — assign one of Operator / Engineer / Lead reasoning tiers per the orchestrator's Phase 1.5 rules. Default to Operator; every promotion must be justified.
