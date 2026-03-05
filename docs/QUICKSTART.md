# KERNEL Setup Guide

You don't need technical knowledge. Just follow these steps and KERNEL will handle everything.

---

## What You're Setting Up

**Claude Code** is like having a developer who can read your entire project, write working features, and take real action. But it forgets everything when you close it.

**KERNEL** gives Claude Code permanent memory. It remembers what worked, what broke, and where you left off. Every conversation makes it smarter about YOUR project.

Think of it like this: Claude Code is the worker. KERNEL is the training program that makes the worker better every day.

---

## Installation

Copy this entire block into Claude Code and paste it. Claude Code will perform all steps automatically:

```
Set up KERNEL for this project. Perform these steps in order:

1. Install the plugin:
   /install-plugin https://github.com/ariaxhan/kernel-claude

2. Find the plugin location, then run:
   KERNEL_PATH=$(find ~/.claude/plugins/cache -name "kernel-claude" -o -name "kernel" 2>/dev/null | head -1)
   echo "Found: $KERNEL_PATH"

3. Make agentdb available and copy CLAUDE.md:
   sudo ln -sf "$KERNEL_PATH/orchestration/agentdb/agentdb" /usr/local/bin/agentdb
   mkdir -p .claude
   cp "$KERNEL_PATH/CLAUDE.md" .claude/CLAUDE.md

4. Initialize the project: create _meta/{agentdb,context,plans,research,handoffs,reviews,agents}, run agentdb init, and create _meta/context/active.md if it doesn't exist. (This is /kernel:init—follow commands/init.md from the plugin if available.)

5. Verify: run agentdb status

Report completion and show status.
```

That's it. Claude Code handles all the technical work.

**What /kernel:init does:** Creates the `_meta/` folder structure, initializes AgentDB (memory), and prepares the project. You only run this once per project. See [commands/init.md](../commands/init.md) for details.

---

## What Just Happened

KERNEL created a `_meta/` folder in your project where Claude Code saves everything:

| Folder | Technical | Plain |
|--------|-----------|-------|
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

Open Claude Code in your project. Just describe what you want in plain English:

- "Add a contact form to the homepage"
- "Fix the bug where users can't log in"
- "Make the buttons bigger"

Behind the scenes, KERNEL runs **/ingest**: it classifies your request (bug, feature, refactor, question), decides scope by file count (1–2 files = Tier 1 direct, 3–5 = Tier 2 surgeon, 6+ = Tier 3 surgeon + adversary), and routes accordingly. In plain terms: it figures out what you need, how big it is, and the best way to do it. It reads what's been tried before, checks what broke last time, and picks up where you left off.

### Doing Work

Claude Code builds what you asked for. For small changes (Tier 1), it executes directly. For bigger projects (Tier 2+: contract → surgeon → adversary), it breaks the work into steps, gets it done, and verifies everything works. In plain terms: you just describe what you want.

### Checking Work

Before sharing your changes, tell Claude Code: "validate my work"

It runs the **Validator** agent: checks for secrets, types, lint, and tests. In plain terms: no accidental secrets, everything looks correct, nothing's broken.

### Saving Progress

Before closing Claude Code, type: `/kernel:handoff`

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

| Component | Technical | Plain |
|-----------|-----------|-------|
| **Memory** | AgentDB + `_meta/` | Remembers what worked, what broke, where you left off |
| **Helpers** | Surgeon, Adversary, Researcher, Scout, Validator | Builds, checks work, finds solutions, explores project, pre-commit gate |
| **Commands** | `/kernel:ingest`, `/kernel:handoff`, `/kernel:init`, `/kernel:help` | Start, save progress, setup, help |

---

## Claude Code vs Cursor

If you're using both:

**Claude Code (the builder):**
- Handles big projects via /ingest (classify → tier → route)
- Remembers context across days (AgentDB)
- Spawns surgeon/adversary for 3+ file changes
- Takes real action

**Cursor (the editor):**
- Quick small edits
- Reading through files
- Visual navigation
- Copy-pasting snippets

Use Claude Code for building. Use Cursor for browsing and tiny tweaks.

---

## Your Project Instructions

The file `.claude/CLAUDE.md` (copied during installation) tells Claude Code about KERNEL. You can extend it or add project-specific rules:

- What technologies you're using
- Your preferences
- Things Claude Code should never do
- Things Claude Code should always do

Claude Code reads this at the start of every conversation. Think of it as standing instructions that persist forever.

---

## If Something Goes Wrong

### "Claude Code says it can't find something"

Run `/kernel:init` to create the `_meta/` folders and initialize AgentDB (memory). If the `agentdb` command is missing, the plugin may not be installed—see Installation above.

### "Claude Code forgot everything"

You didn't save your progress last time. Always end by typing `/kernel:handoff` or saying: "Remember where I stopped and what I was doing."

### "Claude Code keeps making the same mistake"

Say: "Remember this mistake permanently so you never repeat it." Be specific about what went wrong and what you observed. KERNEL saves it to AgentDB (memory) so it never happens again.

---

## Next Steps

That's it. You're ready to work.

Just open Claude Code in your project and describe what you want. KERNEL handles everything else.

The more you use it, the smarter Claude Code gets about YOUR project specifically.

---

*Built with KERNEL v6.0.0 | [GitHub](https://github.com/ariaxhan/kernel-claude)*
