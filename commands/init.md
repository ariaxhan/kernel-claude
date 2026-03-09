---
name: kernel:init
description: "Initialize KERNEL for a project. Creates _meta structure, AgentDB, context file. Run once per project. Triggers: init, setup, initialize."
user-invocable: true
allowed-tools: Read, Write, Bash, Grep, Glob
---

# FOR NON-TECHNICAL USERS

Setting up your project to work with KERNEL. This creates folders to:
- Remember what works and what doesn't
- Save progress automatically
- Track what you're working on

---

# FILE STRUCTURE

```
_meta/
├── agentdb/      # Memory storage (agent.db)
├── context/      # Current state (active.md)
├── plans/        # Implementation plans
├── research/     # Research notes
├── handoffs/     # Session summaries
├── reviews/      # Tear-down reviews
└── agents/       # Active agent registry
```

---

# SETUP STEPS

## Step 1: Create folders
```bash
mkdir -p _meta/{agentdb,context,plans,research,handoffs,reviews,agents}
```

## Step 2: Initialize memory
```bash
agentdb init
```

If agentdb not found:
```bash
sudo ln -sf "$KERNEL_PATH/orchestration/agentdb/agentdb" /usr/local/bin/agentdb
```

## Step 3: Verify git
```bash
git status
# If not a repo: git init
```

## Step 4: Create context file

Create `_meta/context/active.md`:
```markdown
# Project Context

**Last updated**: {date}
**Branch**: {branch}

## What This Project Is
{Ask user}

## Current Focus
{Ask user}
```

---

# CONFIRM SETUP

Output to user:

```
Setup complete!

KERNEL provides:
- Memory: Remembers mistakes, patterns, progress
- Helpers: Surgeon, Adversary, Researcher, Scout, Validator
- Shortcuts: /kernel:ingest, /kernel:handoff, /kernel:help

To start: Describe what you want
To save: /kernel:handoff
Need help: /kernel:help
```

---

# ON END

```bash
agentdb write-end '{"agent":"init","did":"setup_complete"}'
```
