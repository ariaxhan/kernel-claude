# KERNEL

**Permanent memory and multi-agent orchestration for Claude Code.**

Claude Code forgets everything when you close it. KERNEL gives it memory that persists forever—what worked, what broke, where you left off. Every conversation makes Claude Code smarter about YOUR project.

---

## Install

### Claude Code (Terminal)

```
/plugin marketplace add ariaxhan/kernel-claude
/plugin install kernel
/kernel:init
```

### Claude Desktop

1. Open **Customize** (sidebar) → **Personal plugins**
2. Click **+** → **Add marketplace from GitHub**
3. Enter: `ariaxhan/kernel-claude`
4. Click the **KERNEL** plugin → **Install**
5. In a project, run `/init` to set up memory

### Cursor

Install via Claude Code or Claude Desktop first. Cursor shares the same plugin configuration automatically.

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

| Tier | Files | Approach |
|------|-------|----------|
| 1 | 1-2 | Execute directly. No subagents needed. |
| 2 | 3-5 | Spawn surgeon agents to implement. |
| 3 | 6+ | Surgeon agents implement; adversary agents verify. |

### Skills
Skills are methodologies that load on-demand. When you mention "debug" or "security," the relevant skill loads automatically. Skills inform HOW agents work.

| Skill | What It Does |
|-------|--------------|
| `debug` | Scientific debugging: reproduce, hypothesize, binary search to root cause |
| `testing` | Test behavior not implementation; edge cases over happy paths |
| `tdd` | Test-driven: red-green-refactor cycle, tests before code |
| `security` | Input validation, auth, secrets management, OWASP top 10 |
| `api` | REST design: resource naming, status codes, pagination, versioning |
| `backend` | Repository pattern, caching, queues, N+1 prevention |
| `e2e` | Playwright: Page Object Model, flaky test strategies |
| `refactor` | Behavior-preserving transforms; tests green before AND after |
| `design` | Frontend aesthetics; break generic AI patterns |
| `architecture` | System design, modules, dependencies, coupling |
| `git` | Atomic commits, conventional messages, branch strategies |
| `context-mgmt` | Token management, compaction strategies, handoffs |
| `orchestration` | Multi-agent coordination, contracts, fault tolerance |
| `performance` | Measure before optimizing; identify real bottlenecks |
| `eval` | Eval-driven development for AI workflows |

Skills live in `skills/{name}/SKILL.md`. Each has a reference doc in `skills/{name}/reference/`.

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
| `/kernel:dream` | `/dream` | Multi-perspective debate before implementation |
| `/kernel:validate` | `/validate` | Build, lint, test, security scan |
| `/kernel:handoff` | `/handoff` | Save progress for next session |
| `/kernel:review` | `/review` | Code review for PRs |
| `/kernel:tearitapart` | `/tearitapart` | Critical pre-implementation review |
| `/kernel:init` | `/init` | Setup (run once per project) |
| `/kernel:help` | `/help` | Show help |

---

## Local Development (For Contributors)

If you're developing KERNEL locally, symlink the cache to avoid stale copies:

```bash
# Remove cached copy
rm -rf ~/.claude/plugins/cache/kernel-marketplace/kernel/7.1.0

# Symlink to your local dev version
ln -s /path/to/your/kernel-claude ~/.claude/plugins/cache/kernel-marketplace/kernel/7.1.0

# Verify
ls -la ~/.claude/plugins/cache/kernel-marketplace/kernel/
```

Now edits to your local copy take effect immediately—no version bumps or reinstalls needed.

**Why this matters:** Claude Code [caches plugins](https://dev.to/wkusnierczyk/claude-code-plugin-cache-1dn) by version. Without the symlink, you'd need to bump version + reinstall after every change.

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

## Built on aDNA

KERNEL's architecture is directly parallel to [**aDNA (Agentic DNA)**](https://github.com/LatticeProtocol/adna) — a universal, open-source knowledge architecture template for AI-native projects. Full credit and deep thanks to the aDNA project for pioneering many of the patterns KERNEL builds on:

| aDNA Concept | KERNEL Parallel |
|-------------|-----------------|
| **Triad** (WHO/WHAT/HOW) | **Agents/Skills/Commands** — actors, methodology, entry points |
| **Execution Hierarchy** (Campaign → Mission → Objective) | **Tiered Routing** (Orchestrator → Surgeon → Adversary) — convergent decomposition |
| **Context Library** with progressive loading | **Skills** with on-demand disclosure — agents load only what they need |
| **Session tracking** with state persistence | **AgentDB** — cross-session memory with telemetry |
| **Skills** (11 agent recipes) | **Skills** (16 methodologies) — both are HOW-knowledge for agents |
| **OODA Cascade** (Observe → Orient → Decide → Act) | **Workflow** (Read → Classify → Research → Scope → Execute → Learn) |
| **Templates** for every entity type | **Agent/command definitions** with structured frontmatter |
| **Coordination** (cross-agent handoffs) | **GitHub Discussions** (agent communication layer) |
| **After-Action Review** (reflection at mission close) | **Dreamer** (multi-perspective debate) + **Coroner** (post-mortem analysis) |
| **Dual-audience design** (humans browse, agents parse) | **Session-start hook** (ambient context) + **GitHub** (human interface) |

Both projects solve the same core problems: agent orientation, cross-session memory, knowledge fragmentation, and human-agent coordination. KERNEL focuses specifically on Claude Code plugin integration; aDNA provides the universal template.

**If you want the full knowledge architecture** — the triad, lattice composition, campaign/mission hierarchy, OODA cascades, the 58K-token context library, and a framework that works with any AI agent and any editor — **go to [aDNA](https://github.com/LatticeProtocol/adna)**. It's the deeper system that KERNEL draws from.

---

MIT | [Aria Han](https://github.com/ariaxhan)
