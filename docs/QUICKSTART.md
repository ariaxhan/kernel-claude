# KERNEL Setup Guide

You don't need technical knowledge. Just follow these steps and KERNEL will handle everything.

---

## What You're Setting Up

**Claude Code** is like having a developer who can read your entire project, write working features, and take real action. But it forgets everything when you close it.

**KERNEL** gives Claude Code permanent memory. It remembers what worked, what broke, and where you left off. Every conversation makes it smarter about YOUR project.

Think of it like this: Claude Code is the worker. KERNEL is the training program that makes the worker better every day.

---

## Installation

Copy this entire block into Claude Code and press Enter. Claude Code will do everything automatically:

```
I want to install the KERNEL plugin and set up memory for this project.

STEP 1: Install the plugin
/install-plugin https://github.com/ariaxhan/kernel-claude

STEP 2: Find the installed plugin location and set KERNEL_PATH
KERNEL_PATH=$(find ~/.claude/plugins/cache -name "kernel-claude" -o -name "kernel" 2>/dev/null | head -1)
echo "Found: $KERNEL_PATH"

STEP 3: Create symlink for the agentdb CLI
sudo ln -sf "$KERNEL_PATH/orchestration/agentdb/agentdb" /usr/local/bin/agentdb

STEP 4: Copy CLAUDE.md to this project
mkdir -p .claude
cp "$KERNEL_PATH/CLAUDE.md" .claude/CLAUDE.md

STEP 5: Initialize memory for this project
Run: agentdb init

STEP 6: Verify it works
Run: agentdb status

DONE. Show me the status when complete.
```

That's it. Claude Code handles all the technical work.

---

## What Just Happened

KERNEL created a small workspace in your project where Claude Code saves:
- Mistakes it should never repeat
- Solutions that work well
- Where you left off last time
- What you're working on now

This workspace stays with your project forever. Close Claude Code, come back tomorrow, and it remembers everything.

---

## Your Daily Workflow

### Starting Work

Open Claude Code in your project. Just describe what you want in plain English:

- "Add a contact form to the homepage"
- "Fix the bug where users can't log in"
- "Make the buttons bigger"

KERNEL reads what's been tried before, checks what broke last time, and picks up where you left off.

### Doing Work

Claude Code builds what you asked for. For small changes, it just does it. For bigger projects, it breaks the work into focused pieces and checks everything works.

You don't need to manage this. Just describe what you want. KERNEL handles the complexity.

### Checking Work

Before sharing your changes, tell Claude Code: "validate my work"

It automatically checks everything is correct and working.

### Saving Progress

Before closing Claude Code, say: "Remember that I finished the contact form and need to style it next"

Claude Code saves this. Tomorrow starts exactly there.

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

## Understanding the Tools

If you're using both Claude Code and Cursor:

**Claude Code (the builder):**
- Handles big projects
- Remembers context across days
- Can think through problems
- Takes real action

**Cursor (the editor):**
- Quick small edits
- Reading through files
- Visual navigation
- Copy-pasting snippets

Use Claude Code for building. Use Cursor for browsing and tiny tweaks.

---

## Your Project Instructions

Your project has a special file that tells Claude Code about your specific project. You can edit this file to add:

- What technologies you're using
- Your preferences
- Things Claude Code should never do
- Things Claude Code should always do

Claude Code reads this file at the start of every conversation. Think of it as standing instructions that persist forever.

---

## If Something Goes Wrong

### "Claude Code says it can't find something"

Claude Code needs the memory system initialized. Say: "Initialize the memory system for this project."

### "Claude Code forgot everything"

You didn't save your progress last time. Always end by saying: "Remember where I stopped and what I was doing."

### "Claude Code keeps making the same mistake"

Say: "Remember this mistake permanently so you never repeat it." Be specific about what went wrong and what you observed.

---

## Next Steps

That's it. You're ready to work.

Just open Claude Code in your project and describe what you want. KERNEL handles everything else.

The more you use it, the smarter Claude Code gets about YOUR project specifically.

---

*Built with KERNEL v6.0.0 | [GitHub](https://github.com/ariaxhan/kernel-claude)*
