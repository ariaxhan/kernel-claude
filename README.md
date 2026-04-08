# KERNEL

**Claude Code learns from itself.**

Your agent forgets everything when you close it. KERNEL gives it persistent memory, multi-agent orchestration, and a scientific experiment engine that proves which rules actually work. Every session makes it smarter about YOUR project.

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

### Memory That Compounds

AgentDB remembers what worked, what broke, and where you left off — across every session. Not just logs. Weighted retrieval surfaces the learnings that matter (top 7% deliver 80% of value) while pruning what doesn't. Your agent stops repeating the same mistakes.

### Agents That Coordinate

13 specialized agents route by complexity. Tier 1 (1-2 files) executes directly. Tier 2+ spawns surgeons to implement and an adversary to verify. The adversary checks **coordination first** (file overlap, scope drift, duplicate work) because our telemetry proved coordination failures are 4.3x more impactful than code bugs.

| Agent | Role |
|-------|------|
| **Surgeon** | Minimal-diff implementation. Checkpoints to AgentDB. |
| **Adversary** | Coordination verification + code quality. Assumes broken until proven. |
| **Reviewer** | 11-phase code review, >80% confidence threshold. |
| **Researcher** | Finds solutions before building. Anti-patterns first. |
| **Scout** | Maps codebase structure, detects tooling, identifies risk. |
| **Validator** | Pre-commit: tests, lint, types, security scan. |
| **Triage** | Fast complexity classifier before expensive work. |

### Rules That Prove Themselves

The experiment engine treats every rule as a hypothesis. It seeds them from your CLAUDE.md, designs experiments, runs them against AgentDB telemetry, and graduates rules that survive or kills rules that don't. 22 rules graduated from 107 hypotheses across 205 experiments. The forge command uses this: after building, it **tempers** — experiments on its own output, discovers emergent patterns, and self-corrects before shipping.

### Skills That Load On-Demand

19 skills (testing, security, debug, api, backend, architecture, etc.) load when relevant — not at startup. Each is a methodology: HOW to approach a problem, not just tools to use.

---

## Daily Use

**Start with `/ingest`** — the universal entry point. Reads memory, classifies your task, routes to the right agent.

```
/ingest add user authentication to the app
```

**Run overnight with `/forge`** — autonomous engine. Generates competing approaches, iterates against tests, adversarial review, experiments on output. Come back to shipped code.

**Save with `/handoff`** before closing. Next session, `/ingest` auto-resumes from where you left off.

**Check with `/validate`** before committing. Tests, lint, types, security.

> **Note:** In Claude Code terminal, commands use the `kernel:` prefix (`/kernel:ingest`). In Claude Desktop and Cursor, they appear without the prefix (`/ingest`).

---

## Commands

| Terminal | Desktop/Cursor | What It Does |
|----------|----------------|--------------|
| `/kernel:ingest` | `/ingest` | Guided flow — classify, scope, execute. Auto-resumes from handoffs. |
| `/kernel:forge` | `/forge` | Autonomous — heat/hammer/quench/temper/anneal until antifragile |
| `/kernel:experiment` | `/experiment` | Run the hypothesis engine — seed, test, graduate, kill rules |
| `/kernel:dream` | `/dream` | Creative exploration — 3 perspectives, 4-persona stress test |
| `/kernel:diagnose` | `/diagnose` | Systematic debugging + refactor analysis before fixing |
| `/kernel:retrospective` | `/retrospective` | Cross-session learning synthesis + pattern promotion |
| `/kernel:metrics` | `/metrics` | Observability — sessions, agents, hooks, learnings |
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

### Enable Auto-Update (Recommended)

1. Type `/plugin` and go to the **Marketplaces** tab
2. Select **kernel-marketplace**
3. Toggle **Enable auto-update**

### Stuck on an Old Version?

```
/plugin uninstall kernel@kernel-marketplace
/plugin install kernel@kernel-marketplace
/reload-plugins
/kernel:init
```

---

## Local Development (For Contributors)

Symlink the cache to avoid stale copies:

```bash
rm -rf ~/.claude/plugins/cache/kernel-marketplace/kernel/7.12.1
ln -s /path/to/your/kernel-claude ~/.claude/plugins/cache/kernel-marketplace/kernel/7.12.1
```

Edits take effect immediately — no version bumps or reinstalls needed. Claude Code [caches plugins](https://dev.to/wkusnierczyk/claude-code-plugin-cache-1dn) by version; the symlink bypasses this.

---

## Troubleshooting

**Commands not showing up?** Run the quick update commands above.

**Claude isn't reading memory?** Start with `/ingest`. Plain requests skip the memory system.

**Claude forgot everything?** Run `/kernel:handoff` before closing. Or just run `/ingest` next session — it auto-resumes from the latest handoff.

**Same mistake keeps happening?** Say: "Remember this as a failure pattern." KERNEL logs it to AgentDB and avoids it next time.

**"AgentDB not found" error?** Run `/kernel:init` first.

**Agents not spawning?** Use `/ingest`. Direct requests bypass the tiering system.

---

## Architecture

### AgentDB

SQLite database at `_meta/agentdb/agent.db`. Stores learnings, events, errors, hypotheses, experiments, contracts, checkpoints, verdicts. Graduated retrieval loads the top 75 by weighted score (86% token savings vs loading everything).

### Graph Layer (Built on aDNA)

Context graph inspired by [aDNA (Agentic DNA)](https://github.com/LatticeProtocol/adna) from Lattice Protocol. Models context as nodes + edges — which skills load well together, which agent combinations succeed, which nodes conflict. The graph learns over time.

### Experiment Engine

107 hypotheses, 205 experiments, 22 graduated rules. Every rule in CLAUDE.md is a hypothesis until proven by evidence. The engine seeds rules, designs experiments against AgentDB telemetry, issues verdicts (supports/refutes/inconclusive), and graduates or kills rules based on Bayesian confidence scoring. Runs autonomously via `/kernel:experiment`.

---

## Full Documentation

See [docs/QUICKSTART.md](docs/QUICKSTART.md) for detailed installation, daily workflow, and what's inside KERNEL.

---

MIT | [Aria Han](https://github.com/ariaxhan)
