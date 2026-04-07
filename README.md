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
| `/kernel:ingest` | `/ingest` | Guided flow — classify, scope, execute with human confirmation |
| `/kernel:forge` | `/forge` | Autonomous engine — heat/hammer/quench/anneal until antifragile |
| `/kernel:dream` | `/dream` | Creative exploration — 3 perspectives, 4-persona stress test |
| `/kernel:diagnose` | `/diagnose` | Systematic debugging + refactor analysis before fixing |
| `/kernel:retrospective` | `/retrospective` | Cross-session learning synthesis + pattern promotion |
| `/kernel:metrics` | `/metrics` | Observability dashboard — sessions, agents, hooks, learnings |
| `/kernel:validate` | `/validate` | Pre-commit quality gates |
| `/kernel:tearitapart` | `/tearitapart` | Critical pre-implementation review |
| `/kernel:review` | `/review` | Code review for PRs |
| `/kernel:handoff` | `/handoff` | Save progress for next session |
| `/kernel:init` | `/init` | Setup (run once per project) |
| `/kernel:help` | `/help` | Show help |

---

## Updating KERNEL

### Quick Update (CLI)

```
/plugin marketplace update kernel-marketplace
/plugin update kernel@kernel-marketplace
/reload-plugins
```

### Interactive Update

1. Type `/plugin` and go to the **Installed** tab
2. Select **KERNEL**
3. Choose **Update to latest**
4. Run `/reload-plugins` to apply without restarting

### Enable Auto-Update (Recommended)

So you never get stuck on an old version:

1. Type `/plugin` and go to the **Marketplaces** tab
2. Select **kernel-marketplace**
3. Toggle **Enable auto-update**

With auto-update on, KERNEL updates itself whenever a new version is published.

### Stuck on an Old Version?

If commands are missing or behaving unexpectedly, you may be on a stale version. Run the CLI update commands above, or uninstall and reinstall:

```
/plugin uninstall kernel@kernel-marketplace
/plugin install kernel@kernel-marketplace
/reload-plugins
/kernel:init
```

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
/plugin marketplace update kernel-marketplace
/plugin update kernel@kernel-marketplace
/reload-plugins
```

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

## Graph Architecture — Built on aDNA

KERNEL's context graph system is directly inspired by [**aDNA (Agentic DNA)**](https://github.com/LatticeProtocol/adna) from Lattice Protocol. Full credit and thanks.

AgentDB's graph tracking (migration 002, added in v7.0.0) models context as **nodes, edges, and sessions** — the same directed-graph-of-connected-components pattern that aDNA uses for lattice composition. Specifically:

| aDNA | KERNEL (AgentDB graph) |
|------|----------------------|
| **Lattices** — directed graphs of modules + datasets | **Nodes + Edges** — directed graph of skills, commands, agents, research |
| **`context_graph`** lattice type — knowledge retrieval + reasoning | **`context_sessions`** — tracks which nodes loaded together and whether they succeeded |
| **Edge relations** (input/output between modules) | **Edge relations** (`loads`, `references`, `depends_on`, `conflicts_with`, `succeeds_with`) |
| **Success correlation** across lattice executions | **`v_successful_combos`** view — which node combinations correlate with success |
| **Node performance** tracking | **`v_node_performance`** view — access count × success rate = confidence score |

The graph learns over time: which skills load well together for bug fixes? Which agent+skill combinations succeed? Which nodes conflict? This is aDNA's lattice composition concept applied to Claude Code's context window.

**If you want the full graph architecture** — lattice YAML schemas, directed-graph composition, context libraries with progressive loading, multi-project federation, and a framework that works with any AI agent — **go to [aDNA](https://github.com/LatticeProtocol/adna)**. It's the deeper, more general system.

---

MIT | [Aria Han](https://github.com/ariaxhan)
