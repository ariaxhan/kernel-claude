# KERNEL

**AgentDB-first coding methodology for Claude Code** | v5.4.0

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
- agentdb read-start     → Context for starting work
- agentdb write-end JSON → Checkpoint before stopping
- agentdb learn TYPE "insight" "evidence" → Record a learning (failure/pattern/gotcha)
- agentdb contract JSON  → Create a work contract
- agentdb status         → Show DB health
- agentdb recent         → Show last 5 checkpoints

The plugin commands are: /build, /ship, /validate, /contract, /ingest, /tearitapart, /branch, /handoff

Show me `agentdb status` when done.
```

That's it. Claude handles everything.

---

## What It Does

- **AgentDB**: SQLite database at `_meta/agentdb/agent.db` that persists context across sessions
- **Learnings**: Failures and patterns you discover get saved, never repeated
- **Contracts**: Scope work before coding (goal, constraints, failure conditions)
- **Agents**: Spawn surgeon (implementation) and adversary (QA) for complex tasks

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

The plugin commands (`/build`, `/ship`, `/validate`, etc.) do this automatically.

---

## Commands

| Command | Purpose |
|---------|---------|
| `/build` | Research → plan → implement → verify |
| `/validate` | Pre-commit: types, lint, tests |
| `/ship` | Commit, push, create PR |
| `/contract` | Define scope before work |
| `/ingest` | Classify and route any request |
| `/tearitapart` | Critical review before implementing |
| `/branch` | Create worktree for isolated work |
| `/handoff` | Generate context brief for continuity |

---

## Agents

| Agent | When | Focus |
|-------|------|-------|
| surgeon | Tier 2+ (3-5 files) | Minimal diff, commit working state |
| adversary | Before ship | Assume broken, find edge cases |

---

## Schema

```sql
CREATE TABLE learnings (
  id TEXT PRIMARY KEY,
  ts TEXT DEFAULT CURRENT_TIMESTAMP,
  type TEXT CHECK(type IN ('failure','pattern','gotcha','preference')),
  insight TEXT NOT NULL,
  evidence TEXT
);

CREATE TABLE context (
  id TEXT PRIMARY KEY,
  ts TEXT DEFAULT CURRENT_TIMESTAMP,
  type TEXT CHECK(type IN ('contract','checkpoint','handoff','verdict')),
  contract_id TEXT,
  agent TEXT,
  content TEXT NOT NULL
);
```

---

## Philosophy

- **Read before work**: Check learnings to avoid past failures
- **Write before stop**: Save checkpoint so next session can continue
- **Contract before code**: Define scope for anything touching 3+ files
- **Prove, don't assert**: Adversary verifies with evidence

---

MIT | By [Aria Han](https://github.com/ariaxhan)
