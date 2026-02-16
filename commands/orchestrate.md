---
description: Enter orchestration mode for complex multi-file tasks (Tier 3)
---

# Orchestrate Mode

Entering ORCHESTRATION mode for complex tasks.

## When to Use

- 6+ files to change
- Complex debugging (multi-component)
- Architectural changes
- User says "orchestrate", "coordinate", "multi-agent"

## Initialize

```bash
./kernel/orchestration/agentdb/init.sh
```

## Pattern

**Orchestrator (you) stays context-light.** Spawn disposable subagents for heavy lifting. All communicate via AgentDB.

## Flow

1. **Create CONTRACT** (GOAL, CONSTRAINTS, FAILURE_CONDITIONS)
2. **Spawn parallel** search/research agents
3. **Read packets**, route to architect if Tier 3
4. **Architect** discovers scope, returns packet
5. **Surgeon** implements, writes checkpoint
6. **Adversary** QA verifies, writes verdict
7. **Orchestrator** ships or iterates

## Tier Routing

| Tier | Files | Flow |
|------|-------|------|
| 1 | 1-2 | Execute directly (no orchestration needed) |
| 2 | 3-5 | main → surgeon |
| 3 | 6+ | main → architect → surgeon → adversary |

## Agents

Load from `kernel/orchestration/agents/`:

| Agent | Focus | Writes to AgentDB |
|-------|-------|-------------------|
| orchestrator | route, contract, reconcile | directives |
| searcher | code search | packets |
| researcher | web/docs | packets |
| architect | discovery, scope, risk | packets |
| surgeon | minimal diff, commit | checkpoints |
| adversary | QA, break it | verdicts |

## Contract Format

```
CONTRACT: {id}
─────────────
GOAL: {observable_outcome}
CONSTRAINTS: {scope, tier, no_deps, no_schema}
FAILURE CONDITIONS: {rejected_if}
ASSIGN: {architect|surgeon|adversary}
```

## AgentDB Commands

**Write directive:**
```bash
sqlite3 _meta/agentdb/agent.db \
  "INSERT INTO context_log (tab, type, vn, detail, contract)
   VALUES ('main', 'directive', '●directive|contract:{id}|assign:{tab}|→{next}', '{json}', '{id}');"
```

**Read packets:**
```bash
sqlite3 -readonly _meta/agentdb/agent.db \
  "SELECT tab, vn, detail FROM context_log
   WHERE contract = '{id}' AND type IN ('packet', 'verdict')
   ORDER BY ts DESC;"
```

## Context Discipline

- **Orchestrator:** Stay clean. Route and decide only.
- **Subagents:** Disposable context containers. Do heavy lifting.
- **AgentDB:** Persistent communication bus. Survives session restarts.

## Integration

- Works with `/build` for Tier 3 tasks (auto-detected)
- Works with `/tearitapart` for critical review phase
- Works with `/validate` before shipping

**Core insight:** One orchestrator, many disposable agents, SQLite as the bus.
