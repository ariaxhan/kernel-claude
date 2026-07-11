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

15 specialized agents route by complexity (tier = reversibility x silence x blast radius; file count is only a weak hint). Tier 1 executes directly. Tier 2+ spawns surgeons to implement and an adversary to verify. The adversary checks **coordination first** (file overlap, scope drift, duplicate work) because our telemetry proved coordination failures are 4.3x more impactful than code bugs.

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

The experiment engine treats every rule as a hypothesis. It seeds them from your CLAUDE.md, designs experiments, runs them against AgentDB telemetry, and graduates rules that survive or kills rules that don't. 22 rules graduated from 107 hypotheses across 205 experiments. The forge skill uses this: after building, it **tempers** — experiments on its own output, discovers emergent patterns, and self-corrects before shipping.

### One Primitive: Skills That Load On-Demand

Everything is a skill (v8): methodology skills (testing, security, debug, api, backend, architecture, ...) load when relevant, not at startup; workflow skills (`/kernel:ingest`, `/kernel:forge`) orchestrate them; state-transition skills (`/kernel:handoff`, `/kernel:checkpoint`, `/kernel:retrospective`) emit validated YAML manifests so resumed sessions reconstruct bounded task state instead of inheriting whole conversations. Side-effecting skills can never fire ambiently. Details: docs/MIGRATION-8.md.

---

## Daily Use

**Start with `/ingest`** — the universal entry point. Reads memory, classifies your task, routes to the right agent.

```
/ingest add user authentication to the app
```

**Run overnight with `/forge`** — autonomous engine. Generates competing approaches, iterates against tests, adversarial review, experiments on output. Come back to shipped code.

**Save with `/handoff`** before closing. Next session, `/ingest` auto-resumes from where you left off.

**Check with `/validate`** before committing. Tests, lint, types, security.

> **Note:** Everything is a skill (v8 unified architecture; the old commands layer merged into skills). In the Claude Code terminal, skills use the `kernel:` prefix (`/kernel:ingest`). In Claude Desktop and Cursor, they appear without the prefix (`/ingest`). All v7 invocations work unchanged.

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
| `/kernel:handoff` | `/handoff` | Save progress for next session — emits a canonical `kernel.handoff/v1` YAML manifest |
| `/kernel:checkpoint` | `/checkpoint` | Bounded mid-task save — `kernel.checkpoint/v1` manifest for safe context resets |
| `/kernel:landing-page` | `/landing-page` | Guided landing page generator — interview, scaffold, enforce, deploy |
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
rm -rf ~/.claude/plugins/cache/kernel-marketplace/kernel/8.0.0
ln -s /path/to/your/kernel-claude ~/.claude/plugins/cache/kernel-marketplace/kernel/8.0.0
```

Edits take effect immediately — no version bumps or reinstalls needed. Claude Code [caches plugins](https://dev.to/wkusnierczyk/claude-code-plugin-cache-1dn) by version; the symlink bypasses this.

---

## Troubleshooting

**Skills not showing up?** Run the quick update commands above.

**Claude isn't reading memory?** Start with `/ingest`. Plain requests skip the memory system.

**Claude forgot everything?** Run `/kernel:handoff` before closing. Or just run `/ingest` next session — it auto-resumes from the latest handoff.

**Same mistake keeps happening?** Say: "Remember this as a failure pattern." KERNEL logs it to AgentDB and avoids it next time.

**"AgentDB not found" error?** Run `/kernel:init` first.

**Agents not spawning?** Use `/ingest`. Direct requests bypass the tiering system.

---

## Architecture

### AgentDB

SQLite database at `_meta/agentdb/agent.db`. Stores learnings, events, errors, hypotheses, experiments, contracts, checkpoints, verdicts. Graduated retrieval loads the top 75 by weighted score (86% token savings vs loading everything).

### Context Graph (Observational, Receipt-Derived)

Inspired by [aDNA (Agentic DNA)](https://github.com/LatticeProtocol/adna) — but **YAML manifests stay authoritative** for resume, policy, and safety. After `/kernel:ingest` compiles a manifest, the `kernel.context-receipt/v1` YAML records what context was actually loaded. `agentdb graph-project` derives nodes and co-load edges from those receipts (automatic on `kernel-manifest deactivate`). `agentdb graph-suggest` surfaces **shadow-mode** advisory patterns only; it never auto-loads context or overrides manifest selectors until experiment-backed promotion (50+ comparable sessions). The graph observes; manifests decide.

### Experiment Engine

107 hypotheses, 205 experiments, 22 graduated rules. Every rule in CLAUDE.md is a hypothesis until proven by evidence. The engine seeds rules, designs experiments against AgentDB telemetry, issues verdicts (supports/refutes/inconclusive), and graduates or kills rules based on Bayesian confidence scoring. Runs autonomously via `/kernel:experiment`.

### Manifest Runtime (v8)

YAML manifests are the canonical machine-readable representation of resumable state. State-transition skills (`/kernel:handoff`, `/kernel:checkpoint`, `/kernel:retrospective`) emit schema-validated manifests (`schemas/`: `kernel.handoff/v1`, `kernel.checkpoint/v1`, `kernel.retrospective-result/v1`, `kernel.context-receipt/v1`) instead of prose. The CLI at `orchestration/manifest/kernel-manifest` (`validate | latest | divergence | compile | resume | activate | deactivate`) drives resume: a fresh session compiles bounded task state from the manifest rather than inheriting a whole transcript. Context policies — **sealed** (forbidden globs are hook-blocked, fails closed), **bounded** (extra loads are ledgered into a receipt), **advisory** — are enforced by `hooks/scripts/guard-context.sh` reading the activated manifest (I0.15: hooks, not honor-system). Grounding: EXP-L21 showed load-bearing context stays flat (~50–70k tokens/decision) while attended context grows 7–11x per session, so resumes reconstruct minimal state instead of replaying history.

---

## Full Documentation

See [docs/QUICKSTART.md](docs/QUICKSTART.md) for detailed installation, daily workflow, and what's inside KERNEL.

---

MIT | [Aria Han](https://github.com/ariaxhan)
