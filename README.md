# KERNEL

**AgentDB-first coding methodology for Claude Code** | v5.2.0

---

## Install

Copy this into Claude Code:

```
Install the kernel plugin and set up AgentDB for this project. Run /install-plugin https://github.com/ariaxhan/kernel-claude then create _meta/agentdb/agent.db with tables for learnings (id, ts, type, insight, evidence) and context (id, ts, type, contract_id, agent, content). Show me the agentdb status when done.
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

MIT | [github.com/ariaxhan/kernel-claude](https://github.com/ariaxhan/kernel-claude)
