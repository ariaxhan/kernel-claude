# KERNEL Setup Guide

You don't need technical knowledge. Just follow these steps and KERNEL will handle everything.

---

## What You're Setting Up

**Claude Code** is like having a developer who can read your entire project, write working features, and take real action. But it forgets everything when you close it.

**KERNEL** gives Claude Code permanent memory. It remembers what worked, what broke, and where you left off. Every conversation makes it smarter about YOUR project.

Think of it like this: Claude Code is the worker. KERNEL is the training program that makes the worker better every day.

---

## Installation

### Step 1: Add the KERNEL marketplace

In Claude Code, type this command and press Enter:

```
/plugin marketplace add ariaxhan/kernel-claude
```

This tells Claude Code where to find KERNEL.

### Step 2: Install the plugin

```
/plugin install kernel
```

This downloads and activates KERNEL.

### Step 3: Set up your project

Navigate to your project folder, then run:

```
/kernel:init
```

This creates the memory folders and prepares your project.

**That's it.** You're ready to work.

---

## Verify It Worked

Type `/kernel:` in Claude Code. You should see these commands appear:

- `/kernel:ingest` - Start working on a task
- `/kernel:validate` - Check your work before committing
- `/kernel:handoff` - Save your progress
- `/kernel:help` - Get help

If the commands don't appear, try:
```
/plugin marketplace refresh
```
Then restart Claude Code.

---

## What Just Happened

KERNEL created a `_meta/` folder in your project where Claude Code saves everything:

| Folder | What It's For (Technical) | What It's For (Plain English) |
|--------|---------------------------|-------------------------------|
| `agentdb/` | AgentDB storage | Memory—what went wrong, what works, where you left off |
| `context/` | active.md | Project notes—what your project does and what you're working on now |
| `plans/` | Build pipeline output | Step-by-step plans for bigger changes |
| `research/` | Researcher agent output | Notes when Claude looks up how to do something |
| `handoffs/` | Session handoff briefs | Saved progress when you stop for the day |
| `reviews/` | Tear-down reviews | A detailed look before making big changes |
| `agents/` | Agent registry | List of helpers working on your project |

These folders stay with your project forever. Close Claude Code, come back tomorrow, and it remembers everything.

---

## Your Daily Workflow

### Starting Work

**Always start with `/kernel:ingest`**

This is the universal entry point. Type `/kernel:ingest` followed by what you want:

```
/kernel:ingest add a contact form to the homepage
```

Or type `/kernel:ingest` first, then describe your task on the next line.

**Why this matters:** `/kernel:ingest` reads memory, classifies your request, and routes to the right approach. Without it, Claude Code skips the memory system entirely.

Behind the scenes, it classifies your request (bug, feature, refactor, question), decides scope by file count (1–2 files = Tier 1 direct, 3–5 = Tier 2 surgeon, 6+ = Tier 3 surgeon + adversary), reads what's been tried before, checks what broke last time, and picks up where you left off.

### Doing Work

Claude Code builds what you asked for. For small changes (Tier 1), it executes directly. For bigger projects (Tier 2+: contract → surgeon → adversary), it breaks the work into steps, gets it done, and verifies everything works. In plain terms: you just describe what you want.

### Checking Work

Before sharing your changes, type:

```
/kernel:validate
```

Or say: "validate my work"

It runs the **Validator** agent: checks for secrets, types, lint, and tests. In plain terms: no accidental secrets, everything looks correct, nothing's broken.

### Saving Progress

Before closing Claude Code, type:

```
/kernel:handoff
```

Or say: "Remember that I finished the contact form and need to style it next"

Claude Code saves a handoff brief to `_meta/handoffs/`. In plain terms: a short summary of where you left off so tomorrow you can pick up exactly there.

---

## Common Situations

### "Claude Code is doing too much"

Say "stop" and be more specific. Instead of "improve the website," try "make the homepage header bigger."

### "Something broke"

Your work is saved automatically. You can undo recent changes or go back to any earlier version. Just ask Claude Code: "undo my recent changes."

### "Claude Code is confused"

Restate what you want more clearly. Focus on one thing at a time. "Fix the login" is clearer than "improve user experience."

### "Same mistake keeps happening"

Tell Claude Code: "Remember this keeps breaking and why."

It saves this permanently so the mistake never happens again.

---

## What's Inside KERNEL

| Component | Technical Name | Plain English |
|-----------|----------------|---------------|
| **Memory** | AgentDB + `_meta/` | Remembers what worked, what broke, where you left off |
| **Helpers** | Surgeon, Adversary, Researcher, Scout, Validator, Reviewer | Builds features, checks work, finds solutions, explores project, pre-commit checks, reviews code |
| **Commands** | `/kernel:ingest`, `/kernel:validate`, `/kernel:handoff`, `/kernel:review`, `/kernel:tearitapart`, `/kernel:init`, `/kernel:help` | Start work, check work, save progress, review code, critical review, setup, help |

### The Agents (Helpers)

KERNEL includes specialized helpers that Claude Code can use:

- **Surgeon** - Builds features with minimal changes. Focuses on doing one thing well.
- **Adversary** - QA agent. Assumes code is broken until proven otherwise. Finds edge cases.
- **Reviewer** - Reviews code for quality, security, and best practices.
- **Researcher** - Looks up solutions before building. Finds packages, reads docs.
- **Scout** - Explores your codebase. Maps structure, finds patterns.
- **Validator** - Pre-commit checks. Runs tests, lint, security scans.

---

## Using KERNEL with Cursor

If you have KERNEL installed in Claude Code and also use Cursor with Claude, KERNEL works automatically—no extra setup needed.

### How It Works

Cursor uses the same Claude configuration as Claude Code. When you installed KERNEL in Claude Code, it registered globally. Cursor picks this up automatically.

### Verify It's Working

In Cursor's Claude chat, type `/kernel:` and you should see the commands appear. If not:

1. Make sure you ran `/plugin install kernel` in Claude Code first
2. Restart Cursor
3. The `_meta/` folder from `/kernel:init` must exist in your project

### Best Practice

- **Use Claude Code** for `/kernel:ingest` tasks (building features, multi-file changes)
- **Use Cursor** for quick edits and file navigation
- Both share the same AgentDB memory in `_meta/`

### If Commands Don't Appear in Cursor

The plugin system is Claude Code-specific. In Cursor, you can still reference KERNEL's memory by telling Claude to read `_meta/agentdb/` or by describing your task—Claude will see the KERNEL instructions in your project's CLAUDE.md.

---

## All Commands

| Command | What It Does |
|---------|--------------|
| `/kernel:ingest` | Universal entry point. Classifies your task, determines scope, routes to the right agent. |
| `/kernel:validate` | Pre-commit verification. Runs build, types, lint, tests, security scan. Blocks if anything fails. |
| `/kernel:handoff` | Saves your progress. Creates a summary so you can pick up exactly where you left off. |
| `/kernel:review` | Code review for PRs or staged changes. Reports issues with >80% confidence. |
| `/kernel:tearitapart` | Critical pre-implementation review. Finds problems before you write code. |
| `/kernel:init` | Sets up KERNEL for your project. Run once when starting a new project. |
| `/kernel:help` | Shows help and available commands. |

---

## Your Project Instructions

KERNEL loads instructions from your project's `.claude/CLAUDE.md` file. You can add your own rules:

- What technologies you're using
- Your preferences
- Things Claude Code should never do
- Things Claude Code should always do

Claude Code reads this at the start of every conversation. Think of it as standing instructions that persist forever.

---

## If Something Goes Wrong

### "Commands don't show up"

Run these commands:
```
/plugin marketplace refresh
```

Then restart Claude Code. If still not working, try:
```
/plugin install kernel
```

### "Claude Code says it can't find something"

Run `/kernel:init` to create the `_meta/` folders and initialize memory.

### "Claude Code forgot everything"

You didn't save your progress last time. Always end by typing `/kernel:handoff` or saying: "Remember where I stopped and what I was doing."

### "Claude Code keeps making the same mistake"

Say: "Remember this mistake permanently so you never repeat it." Be specific about what went wrong and what you observed. KERNEL saves it to memory so it never happens again.

---

## Updating KERNEL

To get the latest version:

```
/plugin marketplace refresh
```

Then go to `/plugin`, find KERNEL, and select "Update now".

---

## Next Steps

That's it. You're ready to work.

Just open Claude Code in your project and describe what you want. KERNEL handles everything else.

The more you use it, the smarter Claude Code gets about YOUR project specifically.

---

*Built with KERNEL v6.1.5 | [GitHub](https://github.com/ariaxhan/kernel-claude)*
