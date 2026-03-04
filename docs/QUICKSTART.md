# KERNEL Quickstart for Founders

You don't need to be an engineer. You need to know how to talk to one.
Claude Code is your engineer. KERNEL teaches it how to remember, scope, and ship.

---

## What You Just Installed

**Claude Code** runs in your terminal. It reads your entire project, writes code, runs commands, and takes real actions. It's not a chatbot; it's a developer on your team.

**Cursor** is your code editor. Use it to see files, make quick edits, and navigate your project visually. Think of Cursor as the whiteboard, Claude Code as the builder.

**KERNEL** is the methodology layer. It gives Claude Code persistent memory (AgentDB), scope control (contracts), and quality gates (adversary review). Without it, Claude Code forgets everything between sessions and has no discipline.

---

## The Two-Tool Workflow

| Tool | When to Use | Examples |
|------|-------------|---------|
| Claude Code (terminal) | Heavy lifting, multi-file changes, research, debugging, shipping | "Build me an API endpoint," "Fix the auth bug," "Research payment integrations" |
| Cursor (editor) | Quick edits, reading code, visual navigation, small tweaks | Change a color, fix a typo, read through a file, understand structure |

**Rule of thumb:** If the task touches 3+ files or requires thinking, use Claude Code. If you can point at exactly what to change, use Cursor.

---

## Daily Workflow

### Starting Work

Open your terminal in your project folder:
```
claude
```
Claude Code starts. KERNEL's session hook automatically loads your context (last checkpoint, past failures, active contracts).

### Doing Work

Just describe what you want in plain English:
```
"Add a contact form to the landing page that sends emails via Resend"
```

KERNEL classifies this, counts affected files, and either executes directly (small task) or creates a contract and spawns agents (bigger task).

### Ending Work

Before closing your terminal:
```
agentdb write-end '{"did":"added contact form","next":"style the form","blocked":""}'
```
This saves your progress. Tomorrow's session picks up exactly where you left off.

---

## Commands You'll Actually Use

| Command | What It Does |
|---------|-------------|
| `agentdb read-start` | See where you left off, past mistakes to avoid |
| `agentdb write-end '{"did":"X","next":"Y"}'` | Save your progress before stopping |
| `/kernel:ingest` | Universal entry: describe any task, KERNEL routes it |
| `/kernel:validate` | Check everything before committing (types, lint, tests) |
| `/kernel:ship` | Commit, push, create PR |
| `/compact` | When conversation gets long, compress context |

---

## How KERNEL Thinks

KERNEL uses a tier system based on how many files a task touches:

| Files | Tier | What Happens |
|-------|------|-------------|
| 1-2 | Tier 1 | Claude Code does it directly |
| 3-5 | Tier 2 | Creates a contract, spawns a "surgeon" agent |
| 6+ | Tier 3 | Contract, surgeon, then "adversary" agent to verify |

You don't need to think about tiers. Just describe what you want. KERNEL figures out the complexity.

---

## The Memory System (AgentDB)

AgentDB is a tiny database that lives in your project (`_meta/agentdb/agent.db`). It stores:

- **Failures:** Mistakes Claude made so it never repeats them
- **Patterns:** Things that work well so it keeps doing them
- **Checkpoints:** Where you left off so tomorrow starts clean
- **Contracts:** Scope agreements so Claude doesn't go rogue

This is the superpower. Without it, every session starts from zero. With it, Claude Code gets smarter about YOUR project over time.

---

## When Things Go Wrong

**Claude Code is doing too much:** Say "stop" or press Ctrl+C. Then be more specific about what you want.

**It broke something:** Run `git stash` to save changes, `git stash pop` to bring them back after fixing. Or just `git checkout .` to undo everything since last commit.

**It's confused:** Run `/compact` to compress the conversation, then restate what you need.

**It keeps making the same mistake:** Run `agentdb learn failure "description of what keeps breaking" "evidence"` to permanently record the issue.

---

## Your CLAUDE.md

Your project has a CLAUDE.md file that tells Claude Code about your specific project. Edit it in Cursor to add:

- Your tech stack
- Your conventions
- Things Claude should never do
- Things Claude should always do

This file is read at the start of every session. It's your standing instructions.

---

## Understanding the Tools

### Claude Code vs Cursor

Claude Code and Cursor serve different purposes:

| Aspect | Claude Code | Cursor |
|--------|-------------|--------|
| Interface | Terminal | Visual editor |
| Strength | Multi-file changes, complex reasoning | Quick edits, navigation |
| Memory | AgentDB persists across sessions | None |
| Scope | Entire project | Single file at a time |

### When to Use Which

**Use Claude Code when:**
- Building new features
- Debugging complex issues
- Refactoring across files
- Research and decision-making
- Anything requiring context

**Use Cursor when:**
- Reading through code
- Small single-file edits
- Copy-pasting snippets
- Visual diff review

---

## The AgentDB Schema

Three tables. Ultra-lightweight:

```sql
-- Cross-session memory (failures, patterns, gotchas)
learnings: id, ts, type, insight, evidence, domain

-- Agent communication bus (contracts, checkpoints, verdicts)
context: id, ts, type, contract_id, agent, content

-- Auto-captured tool failures
errors: id, ts, tool, error, file
```

You don't need to understand SQL. The `agentdb` CLI handles everything.

---

## CLI Commands Reference

```bash
# Session management
agentdb read-start                    # Load context at session start
agentdb write-end '{"did":"X"}'       # Save checkpoint before stopping

# Learning capture
agentdb learn failure "insight" "evidence"   # Record a mistake
agentdb learn pattern "insight" "evidence"   # Record what works

# Contract management (advanced)
agentdb contract '{"goal":"X",...}'   # Create work contract
agentdb verdict pass|fail '{"..."}'   # QA result

# Maintenance
agentdb status                        # DB health check
agentdb recent 5                      # Last 5 checkpoints
agentdb prune 10                      # Keep only last 10 checkpoints
agentdb export                        # Dump learnings to markdown
```

---

## Plugin Commands Reference

| Command | Purpose |
|---------|---------|
| `/kernel:ingest` | Universal entry — classify, scope, orchestrate |
| `/kernel:validate` | Pre-commit: types, lint, tests |
| `/kernel:ship` | Commit, push, create PR |
| `/kernel:tearitapart` | Critical review before implementing |
| `/kernel:branch` | Create worktree for isolated work |
| `/kernel:handoff` | Generate context brief for continuity |

---

## Quick Reference Card

```
# Start your day
claude                              # Opens Claude Code
                                    # KERNEL auto-loads your context

# Work
"Build X"                           # Describe what you want
/kernel:validate                    # Before committing

# Ship
/kernel:ship                        # Commit + push + PR

# End your day
agentdb write-end '{"did":"X"}'     # Save progress

# If stuck
/compact                            # Compress context
agentdb learn failure "X" "Y"       # Record a mistake
git stash                           # Undo recent changes safely
```

---

## Troubleshooting

### "Command not found: agentdb"

The symlink wasn't created during install. Run:
```bash
KERNEL_PATH=$(find ~/.claude/plugins/cache -name "kernel-claude" -o -name "kernel" 2>/dev/null | head -1)
sudo ln -sf "$KERNEL_PATH/orchestration/agentdb/agentdb" /usr/local/bin/agentdb
```

### "No such table: learnings"

AgentDB wasn't initialized. Run:
```bash
agentdb init
```

### Claude forgot my context

You didn't checkpoint before stopping. Always run:
```bash
agentdb write-end '{"did":"what you did","next":"what's next"}'
```

### Claude keeps repeating the same mistake

Record it as a failure so it never happens again:
```bash
agentdb learn failure "description of the mistake" "what you observed"
```

---

*Built with KERNEL v5.6.0 | [GitHub](https://github.com/ariaxhan/kernel-claude)*
