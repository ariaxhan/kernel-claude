# KERNEL Architecture

**Version:** 5.2.0
**Deep-dive into system internals**

---

## Agent Model

KERNEL uses two specialized agents spawned by the orchestrator (main session).

```
┌─────────────────────────────────────┐
│         orchestrator (you)          │
│         main session                │
└────────────┬───────────┬────────────┘
             |           |
      ┌──────▼──────┐ ┌──▼──────────┐
      │   surgeon   │ │  adversary  │
      │ minimal diff│ │  break it   │
      └──────┬──────┘ └──────┬──────┘
             |               |
             └───────┬───────┘
                     |
              ┌──────▼──────┐
              │   agentdb   │
              │  kernel.db  │
              └─────────────┘
```

### Agent Responsibilities

| Agent | Frame | Writes |
|-------|-------|--------|
| surgeon | minimal_diff | checkpoints |
| adversary | break_it | verdicts |

---

## AgentDB Schema

SQLite database at `_meta/agentdb/kernel.db`.

### learnings (Cross-Session Memory)

```sql
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
```

**Indexes:** type, domain

### context (Work State)

```sql
CREATE TABLE IF NOT EXISTS context (
  id TEXT PRIMARY KEY,
  ts TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  type TEXT NOT NULL CHECK(type IN ('contract', 'checkpoint', 'handoff', 'verdict')),
  contract_id TEXT,
  agent TEXT,
  content TEXT NOT NULL
);
```

**Indexes:** type, contract_id, ts

Contracts are entries with `type='contract'`. Checkpoints, handoffs, and verdicts link to a contract via `contract_id`.

### errors (Automatic Failure Capture)

```sql
CREATE TABLE IF NOT EXISTS errors (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  ts TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  tool TEXT NOT NULL,
  error TEXT NOT NULL,
  file TEXT,
  context TEXT
);
```

---

## Contract Flow

### Context Entry Types

| Type | Writer | Reader | Purpose |
|------|--------|--------|---------|
| contract | orchestrator | surgeon, adversary | Work assignment and scope |
| checkpoint | surgeon | adversary, orchestrator | Working state after commit |
| handoff | any | next session | Continuity context |
| verdict | adversary | orchestrator | Pass/fail result |

### Flow Sequence

```
1. orchestrator: CONTRACT created
   └── INSERT INTO context (type='contract', content={goal, constraints, failure_conditions, tier})

2. surgeon: Reads contract, implements, commits
   └── INSERT INTO context (type='checkpoint', contract_id={id}, content={commit, files})

3. adversary: Verifies checkpoint
   └── INSERT INTO context (type='verdict', contract_id={id}, content={result, evidence})

4. orchestrator: Reads verdict
   └── SHIP or iterate
```

### Contract Format

```
CONTRACT: {id}
─────────────
GOAL: {outcome}
CONSTRAINTS: {scope, tier, no_deps}
FAILURE CONDITIONS: {rejected_if}
TIER: {1|2|3}
```

---

## Tier Routing

| Tier | File Count | Orchestration Flow |
|------|------------|-------------------|
| 1 | 1-2 files | orchestrator executes directly |
| 2 | 3-5 files | orchestrator -> surgeon |
| 3 | 6+ files | orchestrator -> surgeon -> adversary |

### Tier Detection

Automatic based on scope analysis:
- File count in change set
- Dependency depth
- Risk assessment

### Override

User can force tier:
```
"This is Tier 1 - just a config change"
"Treat this as Tier 3 - needs full review"
```

---

## Vector Native Notation

Vector native notation for token-efficient agent communication.

### Symbols

| Symbol | Meaning | Example |
|--------|---------|---------|
| `●` | Action/state | `●commit\|immediately` |
| `→` | Flow/direction | `●checkpoint\|→adversary` |
| `≠` | Negation/anti-pattern | `≠assume_silently` |
| `Ψ` | Section/frame | `Ψ:surgeon` |
| `Ω` | Definition/structure | `Ω:AGENTS` |
| `Δ` | Change/evolution | `Δ:ROUTING` |
| `\|` | Separator | `type:checkpoint\|contract:{id}` |

### Examples

**Checkpoint:**
```
●checkpoint|contract:{id}|commit:{hash}|files:3|→adversary
```

**Verdict:**
```
●verdict|contract:{id}|result:pass|→orchestrator
```

---

## Directory Structure

```
kernel-claude/
├── CLAUDE.md              # vector native config (~200 tokens)
├── agents/                # 2 agent definitions
│   ├── surgeon.md         # minimal diff implementation
│   └── adversary.md       # verification and edge cases
├── commands/              # 8 slash commands
├── skills/                # 4 on-demand skills
│   └── {name}/SKILL.md
├── orchestration/
│   └── agentdb/
│       ├── schema.sql
│       └── init.sh
├── hooks/
│   └── hooks.json
├── _meta/
│   ├── agentdb/kernel.db  # created per-project
│   ├── context/active.md
│   └── _learnings.md
└── docs/                  # You are here
```

---

## Model Routing

| Tier | Model | Use Case |
|------|-------|----------|
| 1 | ollama | Drafts, brainstorm, variations (free, unlimited) |
| 2 | gemini | Web search, bulk read, research (2M context, free tier) |
| 3 | sonnet | Secondary impl, synthesis ($3/1M) |
| 4 | opus | Core impl, planning, orchestrate (quality > cost) |
| 5 | haiku | Test exec, lint, typecheck (trivial only) |

---

## Anti-Patterns

Encoded in CLAUDE.md under `≠:ANTI`:

```
●skip_agentdb_read      -> will repeat past failures
●skip_agentdb_write     -> context lost on resume
●assume_silently        -> extract+confirm
●implement_before_investigate -> search_first
●serial_when_parallel   -> 2+_tasks=parallel
●swallow_errors         -> fail_fast
●guess_APIs             -> LSP_goToDefinition
●rediscover_known       -> check_memory_first
```
