# KERNEL

**The AI Coding OS for Claude Code** | v5.2.0

A plugin that transforms Claude Code from assistant to operating system. Contract-first workflow. AgentDB communication bus. Zero human relay.

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

**2. Set up**

```bash
cd /path/to/kernel-claude
./setup.sh
```

Initializes AgentDB and wires the plugin into your environment.

**3. Work**

Methodology applies automatically. No commands to remember. Just describe what you want.

---

## Architecture

Orchestrator spawns agents. Agents communicate through AgentDB. No manual relay.

```
┌─────────────────────────────┐
│       you (orchestrator)    │
│  route, contract, decide    │
└──────────┬──────────────────┘
           │ spawns
     ┌─────┴──────┐
     │            │
┌────▼────┐  ┌────▼────┐
│ surgeon │  │adversary│
│  impl   │  │   qa    │
└────┬────┘  └────┬────┘
     │            │
     └─────┬──────┘
           │
      ┌────▼────┐
      │ agentdb │
      │ sqlite  │
      └─────────┘
```

You are the orchestrator. Surgeon handles implementation. Adversary handles QA. AgentDB is the communication bus — agents read and write directly, no copy/paste relay.

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
| 3 | 6+ | Full pipeline: surgeon -> adversary |

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
| directive | orchestrator | surgeon, adversary |
| packet | surgeon | orchestrator |
| checkpoint | surgeon | all |
| verdict | adversary | orchestrator |

This is what eliminates the relay. Agents don't need you to pass context. They read it directly.

---

## Agents

Two specialized agents. Each has a role.

| Agent | Focus |
|-------|-------|
| **surgeon** | Minimal diff implementation, commit working state |
| **adversary** | Assume broken, find edge cases, prove with evidence |

The orchestrator (you) stays context-light. Disposable subagents do the heavy lifting. When work is done, they terminate. The orchestrator remains clean for the next task.

---

## Commands

8 commands organized by workflow.

### Development
| Command | Purpose |
|---------|---------|
| `/build` | Full pipeline: research -> plan -> implement -> validate |
| `/contract` | Define scope before work |
| `/ingest` | Universal entry point: classify and route any request |
| `/tearitapart` | Critical review before implementing |
| `/validate` | Pre-commit gate: types, lint, tests |

### Git
| Command | Purpose |
|---------|---------|
| `/branch` | Create worktree for isolated work |
| `/ship` | Commit, push, create PR |
| `/handoff` | Generate context brief for session continuity |

---

## Skills

4 skills loaded on-demand. Triggered when relevant, not stuffed into every conversation.

| Skill | When Loaded |
|-------|-------------|
| **build** | Full implementation pipeline |
| **debug** | When fixing bugs or errors |
| **discovery** | First time in unfamiliar code |
| **research** | Before choosing approaches |

---

## Key Innovations

### 1. AgentDB Bus

SQLite eliminates copy/paste relay between agents. Agents write to shared state. Other agents poll it. The human is removed from the communication loop.

```
_meta/agentdb/kernel.db
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

### 4. Vector-Native Syntax

The core CLAUDE.md is ~200 tokens. Compare to ~2000 for verbose markdown. Every byte costs context window.

```
●relentless|until:code_works,work_done,qa_exhausted
●contract_first|no_work_without_scope
●prove|not:assert
```

Machine-parseable. Human-scannable. Compact.

### 5. Skills from Banks

Methodology isn't always-on. It's loaded when needed. `/build` loads the build pipeline. `/tearitapart` loads the review bank. Context is conserved.

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

Creates `_meta/agentdb/kernel.db` with the communication schema.

### Updating

To update KERNEL to the latest version, you must update both the marketplace and the plugin:

```bash
# Step 1: Update the marketplace cache
claude plugin marketplace update kernel-marketplace

# Step 2: Update the plugin
claude plugin update kernel@kernel-marketplace

# Step 3: Restart Claude Code to apply changes
```

**Note:** Running only `claude plugin update` without updating the marketplace first may report you're already at the latest version when you're not.

---

## Project Structure

```
kernel-claude/
├── CLAUDE.md              # Core config (~200 tokens, vector-native)
├── commands/              # 8 plugin commands
├── agents/                # 2 orchestration agents
├── skills/                # 4 on-demand skills
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
