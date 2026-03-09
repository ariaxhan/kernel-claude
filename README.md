# KERNEL

**Permanent memory and multi-agent orchestration for Claude Code.**

Claude Code forgets everything when you close it. KERNEL gives it memory that persists forever—what worked, what broke, where you left off. Every conversation makes Claude Code smarter about YOUR project.

---

## Install

In Claude Code:

```
/plugin marketplace add ariaxhan/kernel-claude
/plugin install kernel
```

Then in your project:

```
/kernel:init
```

See [docs/QUICKSTART.md](docs/QUICKSTART.md) for the full setup guide.

---

## What It Does

### Memory
Claude Code remembers everything across sessions. What worked. What broke. Where you left off. Lessons learned. It's all saved in `_meta/` and persists forever.

### Agents
Specialized helpers for different tasks:
- **Surgeon** - Builds features with minimal changes
- **Adversary** - QA agent, finds edge cases and bugs
- **Reviewer** - Code review with >80% confidence threshold
- **Researcher** - Looks up solutions before building
- **Scout** - Explores and maps your codebase
- **Validator** - Pre-commit checks (tests, lint, security)

### Tiered Routing
KERNEL automatically routes your requests:
- **Tier 1** (1-2 files): Claude executes directly
- **Tier 2** (3-5 files): Spawns Surgeon agent
- **Tier 3** (6+ files): Surgeon + Adversary for verification

---

## Daily Use

**Start every request with `/ingest`**

This is the universal entry point. It reads memory, classifies your task, picks the right approach, and routes to the right agent. Always start here.

```
/ingest add user authentication to the app
```

Or just type `/ingest` and describe what you want on the next line.

> **Note:** In Claude Code terminal, commands use the `kernel:` prefix (`/kernel:ingest`). In Claude Desktop and Cursor, they appear without the prefix (`/ingest`). Same functionality, different naming.

**Check:** `/kernel:validate` before committing

**Save:** `/kernel:handoff` before closing

---

## Commands

| Terminal | Desktop/Cursor | What It Does |
|----------|----------------|--------------|
| `/kernel:ingest` | `/ingest` | Classify task, determine tier, route to agent |
| `/kernel:validate` | `/validate` | Build, lint, test, security scan |
| `/kernel:handoff` | `/handoff` | Save progress for next session |
| `/kernel:review` | `/review` | Code review for PRs |
| `/kernel:tearitapart` | `/tearitapart` | Critical pre-implementation review |
| `/kernel:init` | `/init` | Setup (run once per project) |
| `/kernel:help` | `/help` | Show help |

---

## Troubleshooting

**Commands not showing up?**
```
/plugin marketplace refresh
```
Then restart Claude Code.

**Claude isn't reading memory?**
Start with `/ingest` (or `/kernel:ingest` in terminal). Plain requests skip the memory system.

**Claude forgot everything between sessions?**
Run `/kernel:handoff` before closing. This saves context to AgentDB.

**Same mistake keeps happening?**
Say: "Remember this as a failure pattern." KERNEL will log it and avoid it next time.

**"AgentDB not found" error?**
Run `/kernel:init` first. This creates the `_meta/` folder and database.

**Claude doing too much at once?**
KERNEL routes big tasks (6+ files) to multiple agents. If you want simpler execution, say "Tier 1 only" or "just do it directly."

**Agents not spawning?**
Make sure you're using `/ingest` (or `/kernel:ingest` in terminal). Direct requests bypass the tiering system.

---

## Full Documentation

See [docs/QUICKSTART.md](docs/QUICKSTART.md) for:
- Detailed installation steps
- Daily workflow guide
- All commands explained
- Common situations and fixes
- What's inside KERNEL

---

MIT | [Aria Han](https://github.com/ariaxhan)
