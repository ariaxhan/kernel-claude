# KERNEL Setup Guide

---

## What You're Setting Up

**Claude Code** is like having a developer who can read your entire project, write working features, and take real action. But it forgets everything when you close it.

**KERNEL** gives Claude Code permanent memory. It remembers what worked, what broke, and where you left off.

---

## Installation

### Step 1: Add the marketplace

In Claude Code, run:
```
/plugin marketplace add ariaxhan/kernel-claude
```

### Step 2: Install the plugin

```
/plugin install kernel
```

### Step 3: Initialize your project

In your project directory:
```
/kernel:init
```

This creates the `_meta/` folder structure and initializes memory.

**Done.** That's it.

---

## Verify Installation

Type `/kernel:` and you should see:
- `/kernel:ingest` - Start working on a task
- `/kernel:validate` - Pre-commit checks
- `/kernel:handoff` - Save progress
- `/kernel:help` - Show help

If commands don't appear, try:
```
/plugin marketplace refresh
```

---

## What Got Created

KERNEL created a `_meta/` folder in your project:

| Folder | Purpose |
|--------|---------|
| `agentdb/` | Memory - what went wrong, what works |
| `context/` | Project notes |
| `plans/` | Step-by-step plans for changes |
| `handoffs/` | Saved progress |
| `reviews/` | Pre-implementation reviews |

---

## Your Daily Workflow

### Starting Work

Just describe what you want:
- "Add a contact form to the homepage"
- "Fix the bug where users can't log in"
- "Make the buttons bigger"

KERNEL classifies your request, decides scope, and routes appropriately.

### Before Committing

```
/kernel:validate
```

Runs build, types, lint, tests, security scan.

### Saving Progress

Before closing:
```
/kernel:handoff
```

Saves where you left off so you can pick up exactly there tomorrow.

---

## Commands

| Command | What it does |
|---------|--------------|
| `/kernel:ingest` | Universal entry - classify task, route to agent |
| `/kernel:init` | Set up _meta structure (run once per project) |
| `/kernel:handoff` | Save progress before stopping |
| `/kernel:validate` | Pre-commit checks |
| `/kernel:review` | Code review for PRs |
| `/kernel:tearitapart` | Critical review before implementation |
| `/kernel:help` | Show help |

---

## Troubleshooting

### "Commands don't show up"

```
/plugin marketplace refresh
/plugin install kernel
```

Then restart Claude Code.

### "Claude Code forgot everything"

You didn't save progress. Always end with `/kernel:handoff`.

### "Same mistake keeps happening"

Tell Claude Code: "Remember this mistake permanently." It saves to memory.

---

## Updating

```
/plugin marketplace refresh
```

Then in the plugin menu, select "Update now" for kernel.

---

*KERNEL v6.1.4 | [GitHub](https://github.com/ariaxhan/kernel-claude)*
