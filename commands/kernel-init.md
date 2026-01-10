---
description: Initialize KERNEL - builds customized CLAUDE.md from prompt bank + enables artifact creation
allowed-tools: Read, Write, Glob, Bash, Grep
---

# Initialize KERNEL

Build a project-specific CLAUDE.md using CODING-PROMPT-BANK.MD as substrate.

## Step 0: Read Configuration Types Guide

**CRITICAL**: Before creating ANY artifacts, read CONFIG-TYPES.md in the plugin root.

This guide defines WHEN to use:
- AGENTS vs SKILLS vs COMMANDS vs RULES vs HOOKS vs MCP

Understand the distinctions to avoid creating wrong artifact types.

If CONFIG-TYPES.md doesn't exist in the target project, copy it from the plugin location.

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

**REFER TO CONFIG-TYPES.md FOR FULL DECISION TREE**

Quick checklist:
1. Task delegation needing isolation? → Agent
2. Teaching Claude HOW to do something? → Skill
3. Manual workflow invoke? → Command
4. Automatic on event? → Hook
5. General behavior instruction? → Rule (or CLAUDE.md if project-wide)
6. External service? → MCP config

**Critical distinctions**:
- AGENT = Task delegation (runs isolated)
- SKILL = Teaching (Claude auto-discovers)
- COMMAND = Manual prompt (you invoke with /name)
- RULE = Behavioral instruction (modular)
- CLAUDE.md = Project constitution (global fundamentals)

### Guidelines

- Conservative: Clear, repeated patterns only
- Minimal: Start simple
- Ask first: Confirm if unsure
- Check existing: Avoid duplicates
- **Read CONFIG-TYPES.md before creating artifacts**
```

## Step 5: Copy Baseline Artifacts

Copy template files from the kernel plugin to the project.

### Locate Kernel Plugin

Search for kernel in:
1. `~/.claude/plugins/kernel/`
2. Project's parent directories
3. Ask user for location if not found

### Copy Knowledge Banks

**From kernel/banks/ → project root (or .claude/banks/):**
- `PLANNING-BANK.md` - Get-it-right-first-time methodology
- `DEBUGGING-BANK.md` - Systematic debugging process
- `CODE-REVIEW-BANK.md` - Review standards checklist
- `TESTING-BANK.md` - Testing strategy & pyramid
- `SECURITY-BANK.md` - Security review & OWASP
- `FRONTEND-BANK.md` - Frontend baseline patterns

**Note**: Banks are NOT loaded by default (zero token cost until referenced).

### Copy Skills (Lightweight Pointers)

**From kernel/skills/ → .claude/skills/:**
- `planning/SKILL.md` - Points to PLANNING-BANK
- `debugging/SKILL.md` - Points to DEBUGGING-BANK
- `code-review/SKILL.md` - Points to CODE-REVIEW-BANK
- `testing-strategy/SKILL.md` - Points to TESTING-BANK
- `security-review/SKILL.md` - Points to SECURITY-BANK
- `frontend-patterns/SKILL.md` - Points to FRONTEND-BANK
- `worktree-parallelization/SKILL.md` - Worktree detection

**Note**: Skills are ~50-100 tokens each, auto-discovered when context matches.

### Copy Commands (On-Demand)

**From kernel/commands/ → .claude/commands/:**
- `plan.md` - /plan - Planning workflow using PLANNING-BANK
- `review.md` - /review - Code review using CODE-REVIEW-BANK
- `debug.md` - /debug - Debugging workflow using DEBUGGING-BANK
- `parallelize.md` - /parallelize - Git worktree setup

**Note**: Commands only loaded when invoked (zero cost until used).

### Copy Agents (Optional)

**From kernel/agents/ → .claude/agents/:**
- `test-maintainer.md` - Test generation specialist (if applicable to project)

**Note**: Only copy if relevant to project stack.

### Token Cost Summary

After copying baseline artifacts:
- **Banks**: 0 tokens (not loaded)
- **Skills**: ~400-600 tokens (7 skills × ~80 tokens each)
- **Commands**: 0 tokens (loaded on use)
- **Agents**: 0 tokens (isolated context)

**Total baseline cost: ~500 tokens** vs ~6000+ without bank architecture.

## Step 6: Create Starter Files

- `.claude/rules/preferences.md` with header
- `.mcp.json` if not exists
- `.claude/settings.json` if not exists

## Step 7: Report

Summary of:
- Detected tier, stack, domain
- Which bank sections were included
- What was created
- How KERNEL will evolve the config going forward
