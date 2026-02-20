# KERNEL

**AgentDB-first coding methodology for Claude Code** | v5.5.0

---

## Install

Copy this entire block into Claude Code:

```
I want to install the KERNEL plugin and set up AgentDB for this project.

STEP 1: Install the plugin
/install-plugin https://github.com/ariaxhan/kernel-claude

STEP 2: Find the installed plugin location and set KERNEL_PATH
KERNEL_PATH=$(find ~/.claude/plugins/cache -name "kernel-claude" -o -name "kernel" 2>/dev/null | head -1)
echo "Found: $KERNEL_PATH"

STEP 3: Create symlink for the agentdb CLI
sudo ln -sf "$KERNEL_PATH/orchestration/agentdb/agentdb" /usr/local/bin/agentdb

STEP 4: Copy CLAUDE.md to this project (plugin CLAUDE.md isn't auto-loaded)
mkdir -p .claude
cp "$KERNEL_PATH/CLAUDE.md" .claude/CLAUDE.md

STEP 5: Initialize AgentDB for this project
Run: agentdb init

This creates _meta/agentdb/agent.db with the schema.

STEP 6: Verify it works
Run: agentdb status

It should show the DB path and table counts.

DONE. The plugin includes:
- SessionStart hook that outputs KERNEL philosophy + runs agentdb read-start
- PostToolUseFailure hook that captures errors automatically
- CLAUDE.md copied to your project for persistent philosophy

The agentdb CLI commands are:
- agentdb init                          → Initialize DB in current project
- agentdb read-start                    → Context for starting work (failures, patterns, checkpoint)
- agentdb write-end <json> [agent]      → Checkpoint before stopping
- agentdb learn <type> <insight> [evidence] [domain] → Record a learning (failure/pattern/gotcha/preference)
- agentdb contract <json>               → Create a work contract
- agentdb verdict <pass|fail> <evidence> [contract_id] → QA result
- agentdb status                        → DB health, counts, last checkpoint time
- agentdb recent [N]                    → Show last N checkpoints (default 5)
- agentdb prune [N]                     → Delete old checkpoints, keep last N (default 10)
- agentdb export                        → Dump learnings to markdown file
- agentdb query <sql>                   → Raw SQL query

The plugin commands are: /kernel:ingest, /kernel:validate, /kernel:ship, /kernel:tearitapart, /kernel:branch, /kernel:handoff

Show me `agentdb status` when done.
```

That's it. Claude handles everything.

---

## What It Does

- **AgentDB**: SQLite database (3 tables: learnings, context, errors) that persists across sessions
- **Orchestration**: For Tier 2+ work, you become the orchestrator — spawn agents, don't write code
- **Contracts**: Scope work before coding (goal, constraints, failure conditions)
- **Agent Communication**: Agents write to AgentDB (checkpoints, verdicts), you read from it
- **Self-Improving**: Failures and patterns get saved, never repeated

---

## Usage

Every session:

```bash
# START of session - see failures to avoid and where you left off
agentdb read-start

# END of session - save what you did
agentdb write-end '{"did":"implemented auth","next":"add tests","blocked":""}'

# When you learn something - save immediately
agentdb learn failure "API returns 500 when token expired" "saw in logs"
agentdb learn pattern "always validate token before API call" "fixed 3 bugs"
```

The plugin commands (`/kernel:build`, `/kernel:ship`, etc.) do this automatically.

---

## Commands

| Command | Purpose |
|---------|---------|
| `/kernel:ingest` | Universal entry — classify, scope, orchestrate |
| `/kernel:validate` | Pre-commit: types, lint, tests |
| `/kernel:ship` | Commit, push, create PR |
| `/kernel:tearitapart` | Critical review before implementing |
| `/kernel:branch` | Create worktree for isolated work |
| `/kernel:handoff` | Generate context brief for continuity |

---

## Agents

| Agent | Role | Writes To |
|-------|------|-----------|
| surgeon | Minimal diff implementation | checkpoint → AgentDB |
| adversary | QA — assume broken, prove | verdict → AgentDB |

**You = orchestrator** for Tier 2+. Create contracts, spawn agents, read their AgentDB output.

---

## Schema (3 tables)

```sql
-- Cross-session memory (failures, patterns, gotchas)
CREATE TABLE learnings (
  id TEXT PRIMARY KEY,
  ts TEXT DEFAULT CURRENT_TIMESTAMP,
  type TEXT CHECK(type IN ('failure','pattern','gotcha','preference')),
  insight TEXT NOT NULL,
  evidence TEXT,
  domain TEXT
);

-- Agent communication bus (contracts, checkpoints, verdicts)
CREATE TABLE context (
  id TEXT PRIMARY KEY,
  ts TEXT DEFAULT CURRENT_TIMESTAMP,
  type TEXT CHECK(type IN ('contract','checkpoint','handoff','verdict')),
  contract_id TEXT,    -- links entries to a contract
  agent TEXT,          -- orchestrator, surgeon, adversary
  content TEXT NOT NULL
);

-- Auto-captured tool failures
CREATE TABLE errors (
  id INTEGER PRIMARY KEY,
  ts TEXT DEFAULT CURRENT_TIMESTAMP,
  tool TEXT NOT NULL,
  error TEXT NOT NULL,
  file TEXT
);
```

**That's it.** Three tables. Ultra-lightweight.

---

## Philosophy

- **Read before work**: Check learnings to avoid past failures
- **Write before stop**: Save checkpoint so next session can continue
- **Contract before code**: Define scope for anything touching 3+ files
- **Prove, don't assert**: Adversary verifies with evidence

---

MIT | By [Aria Han](https://github.com/ariaxhan)
