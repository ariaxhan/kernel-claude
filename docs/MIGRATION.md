# Migration Guide: v4.x to v5.2.0

**From:** KERNEL v4.x (25 agents, verbose config)
**To:** KERNEL v5.2.0 (2 agents, AgentDB-first)

---

## Overview

v5 is a complete rewrite. The old structure is incompatible.

| Aspect | v4.x | v5.2.0 |
|--------|------|--------|
| Agents | 25 specialized | 2 (surgeon, adversary) |
| Commands | 16+ | 8 |
| Skills | 11 | 4 |
| Config | Verbose CLAUDE.md | Compact (~200 tokens) |
| Memory | File-based | AgentDB (SQLite) |

---

## What Changed

### Agents: 25 → 2

All specialized agents consolidated into two:

| v5.2 Agent | Absorbs |
|------------|---------|
| **surgeon** | executor, refactorer, implementer, lint-fixer, type-fixer |
| **adversary** | validator, tester, reviewer, qa |

The orchestrator is YOU (the main session). No separate orchestrator agent.

### Commands: 8 Total

| Command | Purpose |
|---------|---------|
| `/branch` | Create worktree for isolated work |
| `/build` | Full pipeline: research → plan → implement → verify |
| `/contract` | Create scoped work agreement |
| `/handoff` | Generate context brief for session continuity |
| `/ingest` | Universal entry point (classify → route) |
| `/ship` | Commit, push, create PR |
| `/tearitapart` | Critical review before implementing |
| `/validate` | Pre-commit gate: types, lint, tests |

### Skills: 4 Total

| Skill | When Used |
|-------|-----------|
| **build** | Full implementation pipeline |
| **debug** | Bug investigation and fixing |
| **discovery** | First time in unfamiliar codebase |
| **research** | Before choosing approaches |

### AgentDB Schema

```sql
-- learnings: failures, patterns, gotchas
CREATE TABLE learnings (
  id TEXT PRIMARY KEY,
  ts TEXT DEFAULT CURRENT_TIMESTAMP,
  type TEXT CHECK(type IN ('failure','pattern','gotcha','preference')),
  insight TEXT NOT NULL,
  evidence TEXT,
  domain TEXT,
  hit_count INTEGER DEFAULT 0
);

-- context: contracts, checkpoints, handoffs, verdicts
CREATE TABLE context (
  id TEXT PRIMARY KEY,
  ts TEXT DEFAULT CURRENT_TIMESTAMP,
  type TEXT CHECK(type IN ('contract','checkpoint','handoff','verdict')),
  contract_id TEXT,
  agent TEXT,
  content TEXT NOT NULL
);

-- errors: tool failures
CREATE TABLE errors (
  id INTEGER PRIMARY KEY,
  ts TEXT DEFAULT CURRENT_TIMESTAMP,
  tool TEXT,
  error TEXT,
  file TEXT
);
```

---

## Migration Steps

### 1. Remove Old Config

```bash
rm -rf .claude/
rm -f CLAUDE.md  # if project-specific
```

### 2. Install Plugin

```bash
/install-plugin https://github.com/ariaxhan/kernel-claude
```

### 3. Run Setup

```bash
cd ~/.claude/plugins/kernel@kernel-marketplace
./setup.sh
```

This creates:
- `_meta/agentdb/agent.db`
- `_meta/plans/`
- `_meta/logs/`
- Symlinks `agentdb` to `/usr/local/bin/`

### 4. Start Working

Every session:
```bash
agentdb read-start   # at start
agentdb write-end '{"did":"X"}'  # at end
```

---

## Breaking Changes

1. **No project CLAUDE.md** - Plugin provides all config
2. **No `.claude/` directory** - Removed entirely
3. **25 agents → 2 agents** - Specialized agents consolidated
4. **File memory → SQLite** - AgentDB replaces markdown
5. **16 commands → 8** - Consolidated
6. **11 skills → 4** - Consolidated

---

## Compatibility

| Feature | v4.x Projects | Action |
|---------|--------------|--------|
| Existing code | Compatible | No change |
| `.claude/` | Incompatible | Delete |
| `_meta/memory/` | Incompatible | Delete |
| Project CLAUDE.md | Ignored | Delete |
