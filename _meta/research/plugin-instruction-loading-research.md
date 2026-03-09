# Plugin Instruction Loading Research

**Date**: 2026-03-08  
**Topic**: How Claude Code plugins load instructions from CLAUDE.md and plugin.json  
**Confidence**: High (official docs + source investigation)

---

## Executive Summary

- **CLAUDE.md in plugins**: YES—if a plugin includes a `.claude-plugin/plugin.json` manifest, Claude Code does NOT auto-load a CLAUDE.md from the plugin root
- **Plugin.json instructions field**: NO—there is no "instructions" field in plugin.json schema
- **How plugins inject context**: Via progressive disclosure through skills, agents, hooks, and MCP servers; CLAUDE.md is project-level only
- **Key insight**: Plugins use components (skills, agents, hooks) as the mechanism for instruction delivery, not CLAUDE.md files

---

## Question 1: Does a CLAUDE.md inside a plugin get loaded?

**Answer**: NO, with important nuance.

**Evidence**:
- Official Claude Code plugin reference documents the complete `plugin.json` schema
- No mention of CLAUDE.md as a plugin-level configuration mechanism
- Plugin instructions are delivered through **components** (skills, agents, hooks), not a global CLAUDE.md
- CLAUDE.md is documented as **project-level configuration only** (in `.claude/CLAUDE.md`)

**How it works instead**:
1. Plugins define **skills** with `SKILL.md` files (each has frontmatter with name, description)
2. Plugin defines **agents** with markdown files and system prompts
3. Plugin defines **hooks** that inject context at specific events (SessionStart, PreToolUse, etc.)
4. Skills use **progressive disclosure**: Claude only sees name+description at session start (~100 tokens per skill), full SKILL.md loads on-demand when Claude determines it's relevant

---

## Question 2: Does plugin.json have an instructions field?

**Answer**: NO.

**Complete plugin.json Schema** (from official docs):

```json
{
  "name": "plugin-name",
  "version": "1.2.0",
  "description": "Brief plugin description",
  "author": { "name": "Author Name", "email": "author@example.com", "url": "https://github.com/author" },
  "homepage": "https://docs.example.com/plugin",
  "repository": "https://github.com/author/plugin",
  "license": "MIT",
  "keywords": ["keyword1", "keyword2"],
  "commands": ["./custom/commands/special.md"],
  "agents": "./custom/agents/",
  "skills": "./custom/skills/",
  "hooks": "./config/hooks.json",
  "mcpServers": "./mcp-config.json",
  "outputStyles": "./styles/",
  "lspServers": "./.lsp.json"
}
```

**Fields available** (from official schema):
- `name` (required): unique identifier
- `version`: semantic version
- `description`: brief explanation
- `author`, `homepage`, `repository`, `license`, `keywords`: metadata
- `commands`, `agents`, `skills`, `hooks`, `mcpServers`, `outputStyles`, `lspServers`: component paths

**No "instructions" field exists.**

---

## Question 3: How do plugins inject instructions/context?

**Answer**: Via **progressive disclosure through component loading**, NOT via a CLAUDE.md file.

### Mechanism 1: Skills (Primary)

Each skill has a `SKILL.md` file with frontmatter:

```yaml
---
name: code-review
description: Reviews code for best practices and potential issues
---

Full skill instructions here. This loads only when Claude determines it's relevant.
```

At session start, Claude only sees the description (~100 tokens). Full SKILL.md loads on-demand.

### Mechanism 2: Agents

Plugins define custom agents with markdown system prompts:

```markdown
---
name: security-reviewer
description: Reviews code for security vulnerabilities
---

Agent system prompt: comprehensive instructions for this agent.
```

Claude discovers agents through `/agents` and can invoke them or auto-invoke based on task.

### Mechanism 3: Hooks

Plugins define hooks that inject context at specific lifecycle events:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "type": "prompt",
        "prompt": "Load educational context about this plugin"
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [{ "type": "command", "command": "validation-script.sh" }]
      }
    ]
  }
}
```

Hook types:
- `command`: Execute shell scripts
- `prompt`: Evaluate a prompt with an LLM
- `agent`: Run agentic verifier with tools

### Mechanism 4: MCP Servers

Plugins bundle Model Context Protocol servers for external tool integration—these act like dynamic context injection at runtime.

---

## Why No CLAUDE.md in Plugins?

**Design decision rationale**:

1. **Scope separation**: CLAUDE.md is for project-level instructions; plugins are meant to be reusable across projects
2. **Progressive disclosure**: Loading a full CLAUDE.md for every plugin would bloat context
3. **Component-based**: Skills, agents, hooks provide finer-grained control over when context loads
4. **Conflict avoidance**: Multiple plugins shouldn't fight over a global CLAUDE.md

**Official quote**:
> "Skills take a progressive disclosure approach where at session start, Claude only sees each skill's name and one-line description from the YAML frontmatter (around 100 tokens per skill), and the full instructions load only when Claude determines the skill is relevant for the current task."

---

## Key Concepts

### Progressive Disclosure
- **At session start**: Only metadata (name, description) for skills loaded (~100 tokens per skill)
- **On-demand**: Full SKILL.md loads when Claude determines it's relevant
- **Never auto-loaded**: Reference files, scripts stay out of context until explicitly needed

### Plugin Context Loading Order
1. Plugin manifest (`plugin.json`) loads immediately
2. Skill metadata (description) from SKILL.md frontmatter loads
3. Hook configurations load
4. MCP server definitions load
5. Full SKILL.md loads when Claude invokes the skill
6. Agent system prompts load when Claude invokes agents

### Plugin vs Project Configuration

| Aspect | Project (`.claude/CLAUDE.md`) | Plugin (`.claude-plugin/plugin.json`) |
|--------|-------------------------------|---------------------------------------|
| Scope | Single project only | Reusable across projects |
| Instruction mechanism | Single CLAUDE.md file | Components: skills, agents, hooks |
| Context efficiency | Always loads | Progressive disclosure |
| Sharing | Manual copying | Marketplace installation |
| Namespace | No prefix | `/plugin-name:skill-name` |

---

## Implications for Plugin Development

**DO**:
- Use SKILL.md files with brief descriptions + full instructions
- Use hooks for event-driven context injection
- Use agents for complex, specialized workflows
- Let skills load on-demand via progressive disclosure

**DON'T**:
- Create a CLAUDE.md file in a plugin (it won't be loaded)
- Put large instructions in plugin.json (not supported)
- Try to inject a global system prompt (use agents or hooks instead)
- Load all skills into context upfront (defeats progressive disclosure)

---

## Sources

- [Plugins reference - Claude Code Docs](https://code.claude.com/docs/en/plugins-reference)
- [Create plugins - Claude Code Docs](https://code.claude.com/docs/en/plugins)
- [Claude Code plugin system documentation](https://claude.com/blog/claude-code-plugins)
- [How to Build Claude Code Plugins: A Step-by-Step Guide](https://www.datacamp.com/tutorial/how-to-build-claude-code-plugins)
- [Anthropic claude-code repository - plugins README](https://github.com/anthropics/claude-code/blob/main/plugins/README.md)
