# KERNEL Architecture

**Version:** 5.1.0
**Deep-dive into system internals**

---

## Multi-Tab Model

KERNEL operates across 4 primary tabs, each with a specialized agent.

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
                   │context  │
                   │  _log   │
                   └─────────┘
```

### Tab Responsibilities

| Tab | Agent | Frame | Writes |
|-----|-------|-------|--------|
| main | orchestrator | coordinate | directives |
| plan | architect | discovery | packets |
| exec | surgeon | minimal_diff | checkpoints |
| qa | adversary | break_it | verdicts |

### Support Tabs

| Tab | Agent | Frame | Purpose |
|-----|-------|-------|---------|
| search | searcher | code_discovery | Deep codebase search |
| research | researcher | external | Web docs, APIs |

---

## AgentDB Schema

SQLite database at `_meta/agentdb/agent.db`.

### context_log (Communication Bus)

```sql
CREATE TABLE context_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  ts TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  tab TEXT NOT NULL,
  type TEXT NOT NULL CHECK(type IN ('directive', 'packet', 'checkpoint', 'verdict')),
  vn TEXT NOT NULL,
  detail TEXT,
  contract TEXT,
  files TEXT
);
```

**Indexes:** ts, contract, type

### contracts (Work Agreements)

```sql
CREATE TABLE contracts (
  id TEXT PRIMARY KEY,
  goal TEXT NOT NULL,
  constraints TEXT NOT NULL,
  failure_conditions TEXT NOT NULL,
  tier INTEGER NOT NULL CHECK(tier IN (1, 2, 3)),
  status TEXT NOT NULL DEFAULT 'active'
    CHECK(status IN ('active', 'completed', 'blocked', 'rejected')),
  assigned_to TEXT,
  created_at TEXT,
  completed_at TEXT
);
```

### rules (Project Learnings)

```sql
CREATE TABLE rules (
  id TEXT PRIMARY KEY,
  domain TEXT NOT NULL,
  rule TEXT NOT NULL,
  evidence TEXT,
  confidence TEXT DEFAULT 'inferred'
    CHECK(confidence IN ('proven', 'inferred', 'deprecated')),
  session_count INTEGER DEFAULT 0,
  created_at TEXT,
  updated_at TEXT
);
```

### learnings (Session Insights)

```sql
CREATE TABLE learnings (
  id TEXT PRIMARY KEY,
  category TEXT NOT NULL
    CHECK(category IN ('pattern', 'failure', 'preference', 'tool')),
  summary TEXT NOT NULL,
  detail TEXT,
  source TEXT,
  created_at TEXT
);
```

---

## Contract Flow

### Message Types

| Type | Writer | Reader | Purpose |
|------|--------|--------|---------|
| directive | main | plan, exec, qa | Work assignment |
| packet | plan, exec | main | Status/findings |
| checkpoint | exec | all | Working state |
| verdict | qa | main | Pass/fail |

### Flow Sequence

```
1. main: CONTRACT created
   ├── goal, constraints, failure_conditions
   └── INSERT INTO contracts

2. main: DIRECTIVE written
   └── INSERT INTO context_log (type='directive')

3. plan: Reads directive, discovers scope
   └── INSERT INTO context_log (type='packet')

4. main: Reads packet, approves
   └── INSERT INTO context_log (type='directive', assign='exec')

5. exec: Implements, commits
   └── INSERT INTO context_log (type='checkpoint')

6. qa: Verifies checkpoint
   └── INSERT INTO context_log (type='verdict')

7. main: Reads verdict
   └── SHIP or iterate
```

### Contract Format

```
CONTRACT: {id}
─────────────
GOAL: {outcome}
CONSTRAINTS: {scope, tier, no_deps}
FAILURE CONDITIONS: {rejected_if}
ASSIGN: {plan|exec|qa}
```

---

## Tier Routing

| Tier | File Count | Orchestration Flow |
|------|------------|-------------------|
| 1 | 1-2 files | main executes directly |
| 2 | 3-5 files | main → exec |
| 3 | 6+ files | main → plan → exec → qa |

### Tier Detection

Automatic based on scope analysis:
- File count in change set
- Dependency depth
- Risk assessment from architect

### Override

User can force tier:
```
"This is Tier 1 - just a config change"
"Treat this as Tier 3 - needs full review"
```

---

## VN Notation

Vector-native notation for token-efficient agent communication.

### Symbols

| Symbol | Meaning | Example |
|--------|---------|---------|
| `●` | Action/state | `●commit\|immediately` |
| `→` | Flow/direction | `●packet\|→main` |
| `≠` | Negation/anti-pattern | `≠assume_silently` |
| `Ψ` | Section/frame | `Ψ:orchestrator` |
| `Ω` | Definition/structure | `Ω:AGENTS` |
| `Δ` | Change/evolution | `Δ:ROUTING` |
| `\|` | Separator | `type:directive\|contract:{id}` |

### Examples

**Directive:**
```
●directive|contract:{id}|assign:exec|→implement
```

**Packet:**
```
●packet|contract:{id}|status:ready|tier:2|→main
```

**Checkpoint:**
```
●checkpoint|contract:{id}|commit:{hash}|files:3|→qa
```

**Verdict:**
```
●verdict|contract:{id}|result:pass|→main
```

---

## Directory Structure

```
kernel-claude/
├── CLAUDE.md              # VN-native config (~200 tokens)
├── agents/                # 6 agent definitions
│   ├── orchestrator.md    # main tab
│   ├── architect.md       # plan tab
│   ├── surgeon.md         # exec tab
│   ├── adversary.md       # qa tab
│   ├── searcher.md        # search tab
│   └── researcher.md      # research tab
├── commands/              # 16 slash commands
├── skills/                # 11 on-demand skills
│   └── {name}/SKILL.md
├── orchestration/
│   └── agentdb/
│       ├── init.sh
│       └── migrations/
│           └── 001_init.sql
├── hooks/
│   └── hooks.json
├── _meta/
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
●assume_silently        → extract+confirm
●implement_before_investigate → search_first
●serial_when_parallel   → 2+_tasks=parallel
●swallow_errors         → fail_fast
●manual_git             → @git-sync
●work_on_main           → branch/worktree
●guess_APIs             → LSP_goToDefinition
●rediscover_known       → check_memory_first
```
