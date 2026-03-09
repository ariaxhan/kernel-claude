---
name: kernel:init
description: "Initialize KERNEL for a project. Creates _meta structure, AgentDB, CLAUDE.md. Run once per project. Triggers: init, setup, initialize."
user-invocable: true
allowed-tools: Read, Write, Bash, Grep, Glob
---

# AUTOMATIC SETUP

**Execute all steps immediately. Do not ask the user - just do it.**

## Step 1: Create all folders

Run this command:
```bash
mkdir -p _meta/{agentdb,context,plans,research,handoffs,reviews,agents} && mkdir -p .claude
```

## Step 2: Initialize AgentDB

Run this command:
```bash
sqlite3 _meta/agentdb/agent.db "
PRAGMA journal_mode=WAL;
CREATE TABLE IF NOT EXISTS learnings (
  id TEXT PRIMARY KEY,
  ts TEXT DEFAULT CURRENT_TIMESTAMP,
  type TEXT CHECK(type IN ('failure','pattern','gotcha','preference')),
  insight TEXT NOT NULL,
  evidence TEXT,
  domain TEXT,
  hit_count INTEGER DEFAULT 0
);
CREATE TABLE IF NOT EXISTS context (
  id TEXT PRIMARY KEY,
  ts TEXT DEFAULT CURRENT_TIMESTAMP,
  type TEXT CHECK(type IN ('contract','checkpoint','handoff','verdict')),
  contract_id TEXT,
  agent TEXT,
  content TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS errors (
  id INTEGER PRIMARY KEY,
  ts TEXT DEFAULT CURRENT_TIMESTAMP,
  tool TEXT,
  error TEXT,
  file TEXT
);
CREATE INDEX IF NOT EXISTS idx_learnings_type ON learnings(type);
CREATE INDEX IF NOT EXISTS idx_context_type ON context(type);
"
```

## Step 3: Create .claude/CLAUDE.md

Use the Write tool to create `.claude/CLAUDE.md` with this exact content:

```markdown
# Project Instructions

## KERNEL Integration

This project uses KERNEL for persistent memory and intelligent task routing.

### How to Work

**Always start with `/ingest`** (or `/kernel:ingest` in terminal)

This reads memory, classifies your task, and routes to the right approach:
- Tier 1 (1-2 files): Execute directly
- Tier 2 (3-5 files): Spawn surgeon agent
- Tier 3 (6+ files): Surgeon + adversary for verification

### Memory

KERNEL remembers across sessions:
- What worked and what broke
- Patterns discovered in this codebase
- Where you left off

Memory lives in `_meta/agentdb/`. Never delete this folder.

### Before Closing

Run `/handoff` (or `/kernel:handoff`) to save progress.

### Commands

| Command | What It Does |
|---------|--------------|
| `/ingest` | Start any task (ALWAYS use this) |
| `/validate` | Pre-commit checks |
| `/handoff` | Save progress |
| `/review` | Code review |
| `/help` | Show help |

## Project-Specific Instructions

<!-- Customize below for your project -->

### Tech Stack
<!-- List your technologies here -->

### Conventions
<!-- List your coding conventions here -->

### Never Do
<!-- List things Claude should avoid -->
```

## Step 4: Create context file

Use the Write tool to create `_meta/context/active.md`:

```markdown
# Project Context

**Initialized**: {current date}
**Status**: Ready

## What This Project Is
<!-- Describe your project -->

## Current Focus
<!-- What are you working on? -->
```

## Step 5: Verify git (optional)

Check if git repo exists:
```bash
git rev-parse --git-dir 2>/dev/null || echo "Not a git repo - consider running: git init"
```

---

# OUTPUT TO USER

After completing ALL steps, tell the user:

```
✓ KERNEL initialized!

Created:
• .claude/CLAUDE.md - Project instructions (customize this!)
• _meta/agentdb/agent.db - Memory database
• _meta/ folders - Context storage

How to use:
1. Start every request with /ingest
2. Run /handoff before closing
3. Run /help if stuck

Next: Open .claude/CLAUDE.md and fill in your project details.
```
