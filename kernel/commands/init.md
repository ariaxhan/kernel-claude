---
description: When starting a project - Initialize or update KERNEL templates
allowed-tools: Read, Write, Glob, Bash, Grep
---

# Initialize or Update KERNEL

**When to use**: First time setting up KERNEL in a project, or updating templates to latest version.
**What it does**: Analyzes project and creates/updates customized configuration with banks, commands, and rules.

## Mode Selection

On invocation, ask user:
- **First time setup?** → Run full initialization
- **Update templates?** → Run template refresh only

## Full Initialization (First Time)

### Step 1: Read Configuration Guide

**CRITICAL**: Before creating ANY artifacts, read CONFIG-TYPES.md from the plugin.

This guide defines WHEN to use:
- AGENTS vs SKILLS vs COMMANDS vs RULES vs HOOKS vs MCP

If CONFIG-TYPES.md doesn't exist in target project, copy it from plugin location.

### Step 2: Analyze Project

Gather intel:
- README.md → purpose, domain
- package.json / pyproject.toml / Cargo.toml / go.mod → stack, dependencies
- Existing tests → testing patterns
- .github/workflows → CI patterns
- Existing .claude/ → prior config (if migrating)

Determine:
- **TIER**: 1 (hackathon), 2 (production - default), or 3 (critical)
- **STACK**: Primary language, framework, tools
- **DOMAIN**: What kind of project (API, CLI, library, app)

### Step 3: Create Directory Structure

```
kernel/
├── banks/       # Methodology banks
├── commands/    # All commands go here
├── hooks/       # Hook templates
├── rules/       # Rule templates
└── state.md     # World model
```

Note: Do NOT create `.claude/` - everything goes in `kernel/`.

### Step 4: Build Customized CLAUDE.md

Create `CLAUDE.md` in project root with:

1. **Header**: Project name, tier, stack, domain
2. **Philosophy**: CORRECTNESS > SPEED, git workflow, etc.
3. **KERNEL Section**: How to use modes and commands
4. **Project Constraints**: Discovered or user-specified

```markdown
# [PROJECT NAME]

TIER: [1-3]
STACK: [detected stack]
DOMAIN: [api/cli/library/app/other]

## Philosophy

**CORRECTNESS > SPEED**
One working implementation beats three debug cycles.

**INVESTIGATE BEFORE IMPLEMENT**
Search for existing patterns first.

**NEVER WORK ON MAIN**
All work happens on intention-focused branches.

---

## KERNEL

**Commands**:
- `/init` - Initialize or update KERNEL
- `/explore` - Map codebase before work
- `/plan` - Plan implementation
- `/debug` - Systematic diagnosis
- `/audit` - Review code and docs before commit
- `/branch` - Create intention-focused branch
- `/ship` - Commit, push, and create PR
- `/parallelize` - Set up git worktrees
- `/handoff` - Generate context handoff
- `/clean` - Show config health and prune stale entries

**Banks**: kernel/banks/ (loaded on-demand)
**State**: kernel/state.md (read first when uncertain)

---

## PROJECT CONSTRAINTS

[Discovered constraints or placeholder for user to fill]
```

### Step 5: Copy Baseline Artifacts

**From plugin kernel/banks/ → project kernel/banks/**:
- PLANNING-BANK.md
- DEBUGGING-BANK.md
- DISCOVERY-BANK.md
- REVIEW-BANK.md
- DOCUMENTATION-BANK.md

**From plugin kernel/commands/ → project kernel/commands/**:
- explore.md
- plan.md
- debug.md
- audit.md
- branch.md
- ship.md
- parallelize.md
- handoff.md
- clean.md

**From plugin kernel/hooks/ → project kernel/hooks/**:
- pattern-capture.md
- post-write.md
- pre-complete.md

**From plugin kernel/rules/ → project kernel/rules/**:
- preferences.md (template)

### Step 6: Create State File

Create `kernel/state.md` with structure:
- Repo Map
- Tooling Inventory
- Conventions
- Last Validation
- Active Preferences
- Git Workflow State
- Documentation State
- Recent Decisions
- Do Not Touch

### Step 7: Create Starter Files

- `.mcp.json` if not exists
- `kernel/rules/preferences.md` with header

### Step 8: Report

Summary of:
- Detected tier, stack, domain
- What was created
- How to use KERNEL commands
- Next steps (run `/explore` to map codebase)

## Template Refresh (Update Only)

When user wants to update templates to latest plugin version:

### Step 1: Preserve Customizations

Identify what NOT to overwrite:
- `CLAUDE.md` - user's tier, stack, project constraints
- `kernel/rules/` - user's project-specific rules
- `kernel/state.md` - current project state

### Step 2: Update Templates

Re-copy from plugin to project:
- `kernel/banks/` - Latest methodology banks
- `kernel/commands/` - Latest commands
- `kernel/hooks/` - Latest hook templates

### Step 3: Report Changes

Show:
- Plugin version (from .claude-plugin/plugin.json)
- Which files were updated
- What was preserved

```
KERNEL Update Complete

Plugin version: 1.1.0

Updated:
✓ kernel/banks/ (5 banks)
✓ kernel/commands/ (10 commands)
✓ kernel/hooks/ (3 hooks)

Preserved:
✓ CLAUDE.md (your customizations)
✓ kernel/rules/ (your project rules)
✓ kernel/state.md (your project state)
```

## Example Output

```
KERNEL Initialization Complete

Detection Summary:
- TIER: 2 (Production-grade)
- STACK: TypeScript, React, Node.js
- DOMAIN: Web Application

Files Created:
- CLAUDE.md (customized with your stack)
- kernel/banks/ (5 methodology banks)
- kernel/commands/ (10 commands)
- kernel/hooks/ (3 hook templates)
- kernel/rules/preferences.md
- kernel/state.md

Next Steps:
1. Review CLAUDE.md and adjust tier/constraints if needed
2. Run /explore to map your codebase
3. Start working - KERNEL will assist throughout workflow
```
