---
description: Initialize KERNEL for this project - enables automatic reflection and rule evolution
---

# Initialize KERNEL

You are setting up KERNEL for this project. Perform these steps:

## Step 1: Check Prerequisites
- Verify `.claude/` directory exists (create if needed)
- Check if KERNEL is already initialized (look for KERNEL section in CLAUDE.md)

## Step 2: Analyze Project
Briefly scan:
- README.md or similar for project purpose
- package.json, pyproject.toml, Cargo.toml for tech stack
- Existing test files for test patterns

## Step 3: Update CLAUDE.md
Append the following section to `.claude/CLAUDE.md` (create file if needed):

```markdown
## KERNEL: Self-Evolving Rules

This project uses KERNEL for automatic rule evolution.

### When to write learnings
Before completing a task, check if the user stated:
- Explicit preferences: "always use X", "prefer Y over Z", "never do W"
- Project decisions: "we're using SQLAlchemy", "tests go in tests/ folder"
- Workflow patterns: "run tests after every change", "format before committing"

### How to persist learnings
If you identified any of the above, write them to `.claude/rules/kernel-learnings.md`:
1. Read the existing file first
2. Append new rules under appropriate headers
3. Keep rules concise (one line each, imperative form)
4. Don't duplicate existing rules

### Example learnings format
```md
# Code Style
- Use type hints for all function parameters
- Prefer dataclasses over dicts for structured data

# Testing
- Run pytest with -v flag for verbose output
- Mock external APIs in unit tests
```

### What NOT to persist
- One-off requests ("fix this bug")
- Context-specific decisions
- Obvious best practices you already know
- Anything already documented in CLAUDE.md
```

## Step 4: Create Rules Directory
- Create `.claude/rules/` if it doesn't exist
- Create empty `.claude/rules/kernel-learnings.md` with header: `# KERNEL Learnings`

## Step 5: Report
Tell the user:
- KERNEL is now active
- Learnings will accumulate in `.claude/rules/kernel-learnings.md`
- They can review/edit learnings anytime with `/memory`
