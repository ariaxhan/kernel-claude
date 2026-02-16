# KERNEL

**The AI Coding OS for Claude Code** | v5.1.0

A plugin that transforms Claude Code from assistant to operating system. Multi-agent orchestration. Contract-first workflow. Zero human relay.

---

## Why KERNEL?

Claude Code is powerful. It's also stateless. Every session starts fresh. Context gets lost. Agents can't communicate. You become the relay.

KERNEL fixes this.

**The problem:** AI coding assistants require humans to copy/paste context between sessions, between agents, between tasks. This is slow and lossy.

**The solution:** A persistent communication bus (AgentDB), contract-scoped work, and disposable subagents that read/write directly to shared state. The orchestrator stays clean. Heavy lifting is delegated. Nothing gets lost.

---

## Quick Start

**1. Install**

```bash
/install-plugin https://github.com/ariaxhan/kernel-claude
```

**2. Initialize**

```bash
cd your-project
/repo-init
```

KERNEL analyzes your codebase and creates tailored configuration:
- `.claude/CLAUDE.md` — Project-specific rules
- `.claude/rules/` — Discovered patterns
- `_meta/` — Session tracking

**3. Work**

Methodology applies automatically. No commands to remember. Just describe what you want.

---

## Architecture

Four tabs. One database. Zero relay.

```
┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐
│  main   │  │  plan   │  │  exec   │  │   qa    │
│orchestr │  │architect│  │ surgeon │  │adversary│
└────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘
     │            │            │            │
     └────────────┴─────┬──────┴────────────┘
                        │
                   ┌────▼────┐
                   │ agentdb │
                   │sqlite   │
                   └─────────┘
```

**Agents poll AgentDB.** No manual context passing. No copy/paste relay. The orchestrator writes directives; subagents read them. Subagents write packets; the orchestrator reads them.

Communication is persistent. Sessions can crash, restart, continue. Nothing is lost.

---

## How It Works

### Contract-First Workflow

No work without a contract.

```
CONTRACT: CR-001
GOAL: User can reset password via email link
CONSTRAINTS: Scope: auth/ | Tier: 2 | No new deps
FAILURE CONDITIONS: Breaks existing login, no tests
```

The contract defines scope before any code is written. This prevents drift, scope creep, and ambiguous deliverables.

### Tier Routing

Complexity determines workflow:

| Tier | Files | Flow |
|------|-------|------|
| 1 | 1-2 | Orchestrator executes directly |
| 2 | 3-5 | Orchestrator spawns surgeon |
| 3 | 6+ | Full pipeline: architect -> surgeon -> adversary |

Tier 1 tasks don't need coordination overhead. Tier 3 tasks need the full system.

### The Communication Bus

```sql
-- Any agent writes
INSERT INTO context_log (tab, type, vn, detail, contract, files)
VALUES ('exec', 'checkpoint', 'CP-001', '...', 'CR-001', '["auth/reset.ts"]');

-- Other agents read
SELECT * FROM context_log WHERE contract = 'CR-001' ORDER BY ts DESC;
```

| Type | Writer | Reader |
|------|--------|--------|
| directive | main | plan, exec, qa |
| packet | plan, exec | main |
| checkpoint | exec | all |
| verdict | qa | main |

This is what eliminates the relay. Agents don't need you to pass context. They read it directly.

---

## Agents

Six specialized agents. Each has a role.

| Agent | Tab | Focus |
|-------|-----|-------|
| **orchestrator** | main | Route, contract, reconcile, decide ship |
| **architect** | plan | Discovery, scoping, risk identification |
| **surgeon** | exec | Minimal diff implementation, commit working state |
| **adversary** | qa | Assume broken, find edge cases, prove with evidence |
| **searcher** | - | Deep code search, trace calls, map dependencies |
| **researcher** | - | Web/docs research, find 3+ sources |

The orchestrator stays context-light. Disposable subagents do the heavy lifting. When work is done, they terminate. The orchestrator remains clean for the next task.

---

## Commands

16 commands organized by workflow.

### Setup
| Command | Purpose |
|---------|---------|
| `/repo-init` | Generate KERNEL config for any codebase |
| `/kernel-user-init` | Set up user-level defaults at `~/.claude/` |
| `/kernel-status` | Show config health and staleness |
| `/kernel-prune` | Remove stale config entries |

### Development
| Command | Purpose |
|---------|---------|
| `/build` | Full pipeline: research -> plan -> implement -> validate |
| `/iterate` | Continuous improvement loop |
| `/tearitapart` | Critical review before implementing |
| `/validate` | Pre-commit gate: types, lint, tests in parallel |
| `/design` | Design mode with philosophy enforcement |
| `/docs` | Documentation mode |
| `/orchestrate` | Enter multi-agent coordination |
| `/contract` | Define scope before work |

### Git
| Command | Purpose |
|---------|---------|
| `/branch` | Create worktree for isolated work |
| `/ship` | Commit, push, create PR |
| `/parallelize` | Set up multiple worktrees |
| `/handoff` | Generate context brief for session continuity |

---

## Skills

11 skills loaded on-demand. Not always present. Triggered when relevant.

| Skill | When Loaded |
|-------|-------------|
| **planning** | Before implementing features |
| **debug** | When fixing bugs |
| **research** | Before choosing approaches |
| **review** | Before completing work |
| **discovery** | First time in unfamiliar code |
| **iteration** | When refactoring |
| **tearitapart** | Before implementing complex plans |
| **docs** | Documentation tasks |
| **build** | Full implementation pipeline |
| **rules** | Rule management |
| **coding-prompt-bank** | Core AI coding philosophy |

This is methodology loaded from banks. The skill files contain full instructions. They're read when needed, not stuffed into every conversation.

---

## Key Innovations

### 1. AgentDB Bus

SQLite eliminates copy/paste relay between agents. Agents write to shared state. Other agents poll it. The human is removed from the communication loop.

```
_meta/agentdb/agent.db
├── context_log    # Communication bus
├── contracts      # Active work agreements
├── rules          # Project learnings
└── learnings      # Session insights
```

### 2. Contract-First

GOAL, CONSTRAINTS, FAILURE_CONDITIONS before any work. This prevents:
- Scope creep (constraints are explicit)
- Ambiguous deliverables (goal is specific)
- Invisible failures (failure conditions are defined)

### 3. Disposable Subagents

The orchestrator stays clean by delegating to subagents that terminate after their work is done. No context accumulation. No pollution.

### 4. VN-Native Syntax

The core CLAUDE.md is ~200 tokens. Compare to ~2000 for verbose markdown. Every byte costs context window.

```
●relentless|until:code_works,work_done,qa_exhausted
●contract_first|no_work_without_scope
●prove|not:assert
```

Machine-parseable. Human-scannable. Compact.

### 5. Skills from Banks

Methodology isn't always-on. It's loaded when needed. `/debug` loads the debugging bank. `/build` loads the build pipeline. Context is conserved.

### 6. Zero Human Relay

Agents read AgentDB on startup. They don't need you to summarize what happened. They don't need handoff documents. They read the log.

---

## Philosophy

### Correctness Over Speed

Mental simulation catches 80% of bugs before execution. Think before typing. Get it right on the first attempt.

### Every Line Is Liability

Config over code. Native over custom. Existing over new. Delete what doesn't earn its place.

### Investigate Before Implement

Never assume. Find existing patterns first. Copy what works. Adapt minimally.

### Memory Before Discovery

Check `_meta/` before re-learning what the project already knows. Memory check takes 10 seconds. Re-discovery takes 10 minutes.

---

## Installation

### Requirements

- Claude Code CLI v1.0.33+
- macOS, Linux, or Windows

### Plugin Installation

```bash
/install-plugin https://github.com/ariaxhan/kernel-claude
```

### AgentDB Initialization

For orchestration mode (Tier 3 tasks):

```bash
./orchestration/agentdb/init.sh
```

Creates `_meta/agentdb/agent.db` with the communication schema.

---

## Project Structure

```
kernel-claude/
├── CLAUDE.md              # Core config (~200 tokens, VN-native)
├── commands/              # 16 plugin commands
├── agents/                # 6 orchestration agents
├── skills/                # 11 on-demand skills
├── hooks/                 # Automatic triggers
└── orchestration/
    └── agentdb/
        └── init.sh        # Database bootstrap
```

---

## Contributing

Issues and PRs welcome at [github.com/ariaxhan/kernel-claude](https://github.com/ariaxhan/kernel-claude).

---

## License

MIT

---

## Author

Aria Han — [github.com/ariaxhan](https://github.com/ariaxhan)
