---
title: "settings.local.json — Complete Reference"
type: reference
tags: [portable-setup, white-label, settings, mcp]
version: "2.0"
created: 2026-02-25
updated: 2026-04-28
---

# settings.local.json — Complete Reference

> **Location:** `.claude/settings.local.json` in your project root.
> This file configures Claude Code's permissions, hook registration, MCP servers, and behavior for your project.

---

## Complete Template

The template is split into commented sections for readability. The JSON below is valid as-pasted (no comment lines).

### Section 1 — base permissions (read-only shell operations + Obsidian CLI)

```json
{
  "permissions": {
    "allow": [
      "Bash(ls:*)",
      "Bash(git log:*)",
      "Bash(git checkout:*)",
      "Bash(git mv:*)",
      "Bash(tree:*)",
      "Bash(find:*)",
      "Bash(grep:*)",
      "Bash(cat:*)",
      "Bash(test:*)",
      "Bash(sed:*)",
      "Bash(date:*)",
      "Bash(chmod:*)",
      "Bash(wc:*)",
      "Bash(obsidian:*)"
    ]
  }
}
```

### Section 2 — build & test commands (customise for your project)

Add these to the `allow` array. Replace placeholders with your actual commands.

```json
"Bash({{BUILD_COMMAND}}:*)",
"Bash({{TEST_COMMAND}}:*)"
```

### Section 3 — MCP + Task + WebSearch

```json
"mcp__obsidian__*",
"mcp__git__*",
"Task(*)",
"WebSearch"
```

### Section 4 — vault access (only if Module A ran)

Omit this whole block if you have no vault. Substitute `{{VAULT_ABSOLUTE_PATH}}` with the real absolute path (e.g., `/Users/you/code/MyProjectVault`).

```json
"Write({{VAULT_ABSOLUTE_PATH}}/*)",
"StrReplace({{VAULT_ABSOLUTE_PATH}}/*)",
"Bash(* {{VAULT_ABSOLUTE_PATH}}/*)"
```

Also add to `permissions`:

```json
"additionalDirectories": [
  "../{{VAULT_NAME}}"
]
```

### Section 5 — auto-invocable skill permissions (only for personas you actually created in Module C)

Add a `Skill(<name>)` line for each persona whose frontmatter says `disable-model-invocation: false` (rare — most personas use `true`). Default kit includes only:

```json
"Skill({{PRAGMATIST_NAME}})",
"Skill({{INVESTIGATOR_NAME}})"
```

### Section 6 — full assembled file

When you merge all sections, the file looks like this. Hooks block comes from `kit/03-hooks-kit.md` after Module D runs. MCP servers block is optional (see Section 7).

```json
{
  "permissions": {
    "allow": [
      "Bash(ls:*)",
      "Bash(git log:*)",
      "Bash(git checkout:*)",
      "Bash(git mv:*)",
      "Bash(tree:*)",
      "Bash(find:*)",
      "Bash(grep:*)",
      "Bash(cat:*)",
      "Bash(test:*)",
      "Bash(sed:*)",
      "Bash(date:*)",
      "Bash(chmod:*)",
      "Bash(wc:*)",
      "Bash(obsidian:*)",
      "Bash({{BUILD_COMMAND}}:*)",
      "Bash({{TEST_COMMAND}}:*)",
      "mcp__obsidian__*",
      "mcp__git__*",
      "Write({{VAULT_ABSOLUTE_PATH}}/*)",
      "StrReplace({{VAULT_ABSOLUTE_PATH}}/*)",
      "Bash(* {{VAULT_ABSOLUTE_PATH}}/*)",
      "Task(*)",
      "WebSearch",
      "Skill({{PRAGMATIST_NAME}})",
      "Skill({{INVESTIGATOR_NAME}})"
    ],
    "additionalDirectories": [
      "../{{VAULT_NAME}}"
    ]
  },
  "enableAllProjectMcpServers": false,
  "enabledMcpjsonServers": [],
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/session_context.sh",
            "timeout": 3
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/track_modified.sh",
            "timeout": 5,
            "async": true
          }
        ]
      },
      {
        "matcher": "mcp__git__git_commit",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/on_commit.sh",
            "timeout": 10,
            "async": true
          }
        ]
      }
    ],
    "SessionEnd": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/session_cleanup.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

### Section 7 — Optional `mcpServers` block (legacy REST API path)

Primary vault access is via the Obsidian CLI (`obsidian daily:append ...`). The REST API path below is needed only if you want `mcp__obsidian__*` tools available inside Claude Code sessions. Add this object as a top-level sibling of `permissions` and `hooks` in the final JSON.

```json
"mcpServers": {
  "obsidian": {
    "command": "npx",
    "args": [
      "-y",
      "obsidian-mcp-server"
    ],
    "env": {
      "OBSIDIAN_API_KEY": "{{YOUR_OBSIDIAN_API_KEY}}",
      "VERIFY_SSL": "false",
      "OBSIDIAN_PROTOCOL": "https",
      "OBSIDIAN_HOST": "127.0.0.1",
      "OBSIDIAN_PORT": "27124",
      "REQUEST_TIMEOUT": "3000",
      "MAX_CONTENT_LENGTH": "52428800",
      "MAX_BODY_LENGTH": "52428800",
      "RATE_LIMIT_WINDOW_MS": "900000",
      "RATE_LIMIT_MAX_REQUESTS": "200",
      "TOOL_TIMEOUT_MS": "10000"
    }
  }
}
```

---

## Section-by-Section Reference

### permissions.allow

Controls which tools Claude can use without asking for permission each time.

| Pattern | What it allows | Why |
|---------|---------------|-----|
| `Bash(ls:*)` | List directory contents | Basic exploration |
| `Bash(git log:*)` | View git history | Context gathering |
| `Bash(obsidian:*)` | Obsidian CLI commands | Vault access in hooks |
| `mcp__obsidian__*` | All Obsidian MCP tools | Vault read/write without prompts (when REST API is running) |
| `mcp__git__*` | All Git MCP tools | Commit, add, diff without prompts |
| `Write({{PATH}}/*)` | Write to vault directory | Hook-driven note creation via direct tools |
| `Task(*)` | Spawn any Task agent | Skills that use agents |
| `WebSearch` | Web search | Investigation skills |
| `Skill(name)` | Invoke specific skill | Auto-invocable skills |

**Security note:** `Task(*)` is broad. For tighter control, use `Task(description:*implement*:*)` patterns to allow only specific task descriptions.

### permissions.additionalDirectories

Grants Claude Code access to directories outside the project root. **This is required for vault access.**

```json
"additionalDirectories": [
  "../{{VAULT_NAME}}"
]
```

Without this, Claude cannot read or write vault files even if the vault symlink exists in the project root. The vault must be a sibling directory (`../VaultName`).

For multiple vaults or shared knowledge bases:

```json
"additionalDirectories": [
  "../ProjectVault",
  "../SharedKnowledge"
]
```

### hooks

See [03-hooks-kit.md](03-hooks-kit.md) for detailed hook documentation.

**Key configuration rules:**
- `matcher` uses regex — `Edit|Write` matches both tool names
- Multiple hooks can fire for the same event matcher (array of hook objects)
- `async: true` for PostToolUse tracking hooks (don't block editing)
- `timeout` in seconds — keep short to avoid session hangs
- `$CLAUDE_PROJECT_DIR` is auto-set by Claude Code
- Gate hooks (lint-precommit, enforce-tests) must be sync and exit non-zero to block

**All supported hook events:**

| Event | When it fires |
|-------|--------------|
| `SessionStart` | Session starts or resumes |
| `SessionEnd` | Session ends |
| `PostToolUse` | After any tool call |
| `PreToolUse` | Before any tool call |
| `Stop` | When Claude finishes responding (task completion) |
| `PreCompact` | Before context compaction |
| `SubagentStop` | When a Task subagent finishes |

### mcpServers

MCP server configuration. Two approaches for vault access:

**Approach 1: Obsidian CLI (preferred)**
No MCP server needed. Use `Bash(obsidian:*)` permission and the `obsidian` binary from the Obsidian app. Works without Obsidian running for most operations.

**Approach 2: obsidian-mcp-server (REST API)**
Requires Obsidian running with Local REST API plugin. Provides `mcp__obsidian__*` tools in Claude Code sessions.

```json
"obsidian": {
  "command": "npx",
  "args": ["-y", "obsidian-mcp-server"],
  "env": {
    "OBSIDIAN_API_KEY": "{{YOUR_OBSIDIAN_API_KEY}}",
    "VERIFY_SSL": "false",
    "OBSIDIAN_PROTOCOL": "https",
    "OBSIDIAN_HOST": "127.0.0.1",
    "OBSIDIAN_PORT": "27124"
  }
}
```

**Optional MCP Servers:**

```json
"git": {
  "command": "npx",
  "args": ["-y", "@anthropic/git-mcp-server"],
  "env": {
    "GIT_DIR": "{{PROJECT_ABSOLUTE_PATH}}"
  }
}
```

```json
"figma-desktop": {
  "command": "/path/to/figma-mcp-server",
  "args": []
}
```

```json
"mermaid": {
  "command": "npx",
  "args": ["-y", "@mseep/mermaid-mcp-server"]
}
```

### Other Settings

```json
{
  "outputStyle": "Explanatory",
  "prefersReducedMotion": false,
  "enableAllProjectMcpServers": false,
  "enabledMcpjsonServers": ["server-name"]
}
```

`enableAllProjectMcpServers: false` + explicit `enabledMcpjsonServers` gives you fine-grained control over which `.mcp.json` servers are loaded per project.

---

## Environment Variables Available to Hooks

| Variable | Value | Available In |
|----------|-------|-------------|
| `CLAUDE_PROJECT_DIR` | Absolute path to project root | All hooks |
| `CLAUDE_TOOL_RESULT` | JSON string of tool output | PostToolUse hooks |
| `CLAUDE_TOOL_INPUT` | JSON string of tool input | PostToolUse, PreToolUse hooks |
| `OSTYPE` | OS identifier (darwin*, linux*) | All hooks (shell built-in) |

---

## Setup Checklist

```bash
# 1. Create settings file
cat > .claude/settings.local.json << 'EOF'
{
  ... (paste template above, fill placeholders)
}
EOF

# 2. Set vault absolute path
# Replace {{VAULT_ABSOLUTE_PATH}} with the real path, e.g.:
# /Users/you/projects/MyProjectVault

# 3. (Optional) Get Obsidian API key for MCP
# Open Obsidian → Settings → Local REST API → Copy API Key

# 4. Verify hooks are registered
# Start Claude Code session → check for session context banner

# 5. Test vault access
# obsidian daily:read vault={{VAULT_NAME}}
```

---

## Common Customizations

### Adding build command permissions

```json
"Bash(npm run build:*)",
"Bash(cargo build:*)",
"Bash(make:*)",
"Bash(./gradlew:*)",
"Bash(cmake --build:*)"
```

### Adding test command permissions

```json
"Bash(npm test:*)",
"Bash(cargo test:*)",
"Bash(pytest:*)",
"Bash(ctest:*)"
```

### Restricting Task agents

Instead of `"Task(*)"`, use targeted patterns:
```json
"Task(description:Document*:*)",
"Task(description:Investigate*:*)",
"Task(description:Review*:*)"
```

### Adding WebFetch domain allowlists (for investigation skills)

```json
"WebFetch(domain:docs.python.org)",
"WebFetch(domain:developer.mozilla.org)",
"WebFetch(domain:doc.rust-lang.org)"
```
