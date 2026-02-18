# KERNEL

**AgentDB-first coding methodology for Claude Code** | v5.2.0

---

## Install

Copy this entire block into Claude Code:

```
I want to install the KERNEL plugin and set up AgentDB for this project.

1. First, run this command to install the plugin:
/install-plugin https://github.com/ariaxhan/kernel-claude

2. Then create the AgentDB directory and SQLite database:
- Create directory: _meta/agentdb/
- Create SQLite database at: _meta/agentdb/agent.db

3. Initialize the database with this exact schema:

PRAGMA journal_mode=WAL;
PRAGMA foreign_keys=ON;

CREATE TABLE IF NOT EXISTS learnings (
  id TEXT PRIMARY KEY,
  ts TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  type TEXT NOT NULL CHECK(type IN ('failure', 'pattern', 'gotcha', 'preference')),
  insight TEXT NOT NULL,
  evidence TEXT,
  domain TEXT,
  hit_count INTEGER DEFAULT 0,
  last_hit TEXT
);

CREATE TABLE IF NOT EXISTS context (
  id TEXT PRIMARY KEY,
  ts TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  type TEXT NOT NULL CHECK(type IN ('contract', 'checkpoint', 'handoff', 'verdict')),
  contract_id TEXT,
  agent TEXT,
  content TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS errors (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  ts TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  tool TEXT NOT NULL,
  error TEXT NOT NULL,
  file TEXT,
  context TEXT
);

CREATE INDEX IF NOT EXISTS idx_learnings_type ON learnings(type);
CREATE INDEX IF NOT EXISTS idx_learnings_domain ON learnings(domain);
CREATE INDEX IF NOT EXISTS idx_context_type ON context(type);
CREATE INDEX IF NOT EXISTS idx_context_contract ON context(contract_id);
CREATE INDEX IF NOT EXISTS idx_context_ts ON context(ts);

4. After setup, verify by running:
sqlite3 _meta/agentdb/agent.db ".tables"

It should show: context  errors  learnings

5. The plugin gives you these commands: /build, /ship, /validate, /contract, /ingest, /tearitapart, /branch, /handoff

6. The core methodology is AgentDB-first:
- At the START of every session: query learnings for past failures to avoid
- At the END of every session: insert a checkpoint into context with what was done
- When you learn something (failure, pattern): insert into learnings immediately

Show me the database tables when done so I know it worked.
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

Every session, Claude should:

```bash
# Start: check what to avoid and where you left off
sqlite3 _meta/agentdb/agent.db "SELECT type, insight FROM learnings ORDER BY ts DESC LIMIT 5;"

# End: save what you did
sqlite3 _meta/agentdb/agent.db "INSERT INTO context (id, ts, type, content) VALUES ('$(date +%s)', datetime('now'), 'checkpoint', '{\"did\":\"X\"}');"

# Learn from failures
sqlite3 _meta/agentdb/agent.db "INSERT INTO learnings (id, ts, type, insight) VALUES ('$(date +%s)', datetime('now'), 'failure', 'what went wrong');"
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
