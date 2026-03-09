# KERNEL

**Permanent memory and multi-agent orchestration for Claude Code.**

---

## Install

```
/plugin marketplace add ariaxhan/kernel-claude
/plugin install kernel
```

Then in your project:
```
/kernel:init
```

---

## What It Does

- **Memory** - Claude Code remembers what worked, what broke, where you left off
- **Agents** - Surgeon (builds), Adversary (QA), Reviewer (PR review)
- **Commands** - `/kernel:ingest`, `/kernel:validate`, `/kernel:handoff`

---

## Daily Use

**Start:** Describe what you want in plain English

**Check:** `/kernel:validate` before committing

**Save:** `/kernel:handoff` before closing

---

## Commands

| Command | Purpose |
|---------|---------|
| `/kernel:ingest` | Classify task, determine tier, route to agent |
| `/kernel:validate` | Build, lint, test, security scan |
| `/kernel:handoff` | Save progress for next session |
| `/kernel:review` | Code review |
| `/kernel:tearitapart` | Pre-implementation review |
| `/kernel:init` | Setup (run once per project) |
| `/kernel:help` | Show help |

---

## Troubleshooting

Commands not showing? Run:
```
/plugin marketplace refresh
```

Then restart Claude Code.

---

## Full Guide

See [docs/QUICKSTART.md](docs/QUICKSTART.md) for detailed setup and usage.

---

MIT | [Aria Han](https://github.com/ariaxhan)
