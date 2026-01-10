---
description: Initialize KERNEL - builds customized CLAUDE.md from prompt bank + enables artifact creation
allowed-tools: Read, Write, Glob, Bash, Grep
---

# Initialize KERNEL

Build a project-specific CLAUDE.md using CODING-PROMPT-BANK.MD as substrate.

## Step 1: Locate Prompt Bank

Search for CODING-PROMPT-BANK.MD in order:
1. Project root
2. `~/.claude/CODING-PROMPT-BANK.MD`
3. Plugin location

Read the entire bank. This is your substrate for building the project config.

## Step 2: Analyze Project

Gather intel:
- README.md → purpose, domain
- package.json / pyproject.toml / Cargo.toml / go.mod → stack, dependencies
- Existing tests → testing patterns
- .github/workflows → CI patterns
- Existing .claude/ → prior config

Determine:
- **TIER**: 1 (hackathon), 2 (default), or 3 (critical)
- **STACK**: Primary language, framework, tools
- **DOMAIN**: What kind of project (API, CLI, library, app)

## Step 3: Create Directory Structure

```
.claude/
├── commands/
├── agents/
├── skills/
├── rules/
```

## Step 4: Build Customized CLAUDE.md

Create `.claude/CLAUDE.md` by:

1. **Header**: Project name, tier, stack summary
2. **Selected Bank Rules**: Pull ONLY relevant sections from the bank based on:
   - Stack (JS? Python? Go? → different idioms)
   - Tier (T1 lighter, T3 heavier validation)
   - Domain (API → endpoint workflow, CLI → different patterns)
3. **Project Constraints**: Any discovered from existing config
4. **KERNEL Artifact Instructions**: The pattern→artifact mapping

### Template Structure

```markdown
# [PROJECT NAME]

TIER: [1-3]
STACK: [detected stack]
DOMAIN: [api/cli/library/app/other]

---

## CODING RULES

[Selected sections from CODING-PROMPT-BANK.MD relevant to this stack/tier]

---

## PROJECT CONSTRAINTS

[Any discovered constraints, or placeholder for user to fill]

---

## KERNEL: Self-Evolving Configuration

KERNEL progressively builds Claude Code config based on observed patterns.

### Pattern → Artifact Mapping

| When You Notice... | Create This |
|-------------------|-------------|
| Same multi-step workflow repeated 2+ times | `.claude/commands/workflow-name.md` |
| Task needing specialized expertise | `.claude/agents/specialist-name.md` |
| External service integration needed | Entry in `.mcp.json` |
| Pre/post processing on tool usage | Hook in `.claude/settings.json` |
| Domain capability used repeatedly | `.claude/skills/capability.md` |
| User states explicit preference | `.claude/rules/topic.md` |

### Artifact Templates

**COMMAND** (`.claude/commands/name.md`):
```md
---
description: One-line description
allowed-tools: Read, Write, Bash
---
Instructions for Claude when /name is invoked.
```

**AGENT** (`.claude/agents/name.md`):
```md
---
name: agent-name
description: Specialization
tools: Read, Write, Grep, Glob, Bash
model: sonnet
---
You are a specialist in X...
```

**MCP** (`.mcp.json`): `{"mcpServers": {"name": {"command": "npx", "args": ["pkg"]}}}`

**HOOK** (`.claude/settings.json`): `{"hooks": {"PostToolUse": [...]}}`

**SKILL** (`.claude/skills/name.md`): Capability description + examples

**RULE** (`.claude/rules/topic.md`): Imperative rules grouped by topic

### Before Completing Tasks

1. Workflow repeated? → Command
2. Specialized expertise? → Agent
3. External service? → MCP config
4. Pre/post processing? → Hook
5. Explicit preference? → Rule

### Guidelines

- Conservative: Clear, repeated patterns only
- Minimal: Start simple
- Ask first: Confirm if unsure
- Check existing: Avoid duplicates
```

## Step 5: Create Starter Files

- `.claude/rules/preferences.md` with header
- `.mcp.json` if not exists
- `.claude/settings.json` if not exists

## Step 6: Report

Summary of:
- Detected tier, stack, domain
- Which bank sections were included
- What was created
- How KERNEL will evolve the config going forward
