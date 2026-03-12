# Context Graph Architecture Research

**Date:** 2026-03-12
**Sources:** aDNA (Lattice Protocol), kernel-claude, lost-in-the-middle research

---

## Overview

Two approaches to persistent agent context:
1. **File-based** (aDNA) - Obsidian/folder structure, human-editable, git-friendly
2. **SQLite-backed** (kernel) - AgentDB for state, files for artifacts

Neither is strictly better. The question is: when to use which?

---

## aDNA Principles (Lattice Protocol)

**Core: who/what/how triad**
- `who/` - People, teams, governance
- `what/` - Knowledge, decisions, artifacts
- `how/` - Processes, plans, execution

**Governance files:**
- CLAUDE.md → AI master context (always loaded)
- MANIFEST.md → Project identity
- STATE.md → Current operational status
- AGENTS.md → Per-directory guidance

**Convergence model:**
```
Campaign (strategic initiative)
  → Phase (human gates)
    → Mission (multi-session)
      → Objective (session-sized)
```

**Key innovation:** <50% context per work session. Progressive narrowing.

---

## Kernel Principles (AgentDB)

**Core: SQLite + files**
- `learnings` - Cross-session memory (survives forever)
- `context` - Work state (contracts, checkpoints, verdicts)
- `errors` - Automatic failure capture

**File structure:**
- CLAUDE.md → Always loaded (<220 lines)
- skills/ → On-demand methodology
- commands/ → On-invocation workflow
- agents/ → Spawned actors
- _meta/research/ → Knowledge persistence

**Tier system:**
```
Tier 1: 1-2 files → Execute directly
Tier 2: 3-5 files → Contract + surgeon
Tier 3: 6+ files → Contract + surgeon + adversary
```

**Key innovation:** Token budget tests, Big 5 quality skill, lost-in-the-middle awareness.

---

## When Files Work Best

```yaml
strengths:
  - Human readable/editable
  - Git-friendly (versioning, diffs, blame)
  - Universal (no dependencies)
  - IDE/Obsidian integration
  - Easy to share (download folder, done)

use_when:
  - < 500 nodes
  - Content is human-authored or human-reviewed
  - Version history matters
  - Collaboration via git workflows
  - Debugging requires reading raw data
```

---

## When SQLite Works Best

```yaml
strengths:
  - Indexed queries (fast at any scale)
  - Relational joins (cross-reference)
  - Partial reads (SELECT specific columns)
  - Atomic transactions (concurrent safety)
  - Aggregations (COUNT, SUM, trends)

use_when:
  - > 500 nodes
  - Query patterns need joins
  - Multiple agents access same state
  - Need full-text search at scale
  - Token accounting requires precision
  - Historical analytics needed
```

---

## Handoff Criteria: Files → SQLite

| Signal | Threshold | Why |
|--------|-----------|-----|
| Node count | > 500 files | grep/glob becomes slow |
| Query complexity | Need 2+ table joins | Files can't do relational |
| Concurrent access | 2+ agents writing | File locks fail under contention |
| Search latency | > 500ms for typical query | FTS5 is 10-100x faster |
| Token accounting | Need precise tracking | JSON in files doesn't aggregate |
| Deduplication | Same data in 3+ places | Normalization requires DB |

---

## Hybrid Architecture (Recommended)

**Files for:**
- Human-facing artifacts (CLAUDE.md, skills, research docs)
- Content that benefits from git (code, docs, configs)
- Modular components that get "merged" between projects
- Anything users might edit directly

**SQLite for:**
- Session state (contracts, checkpoints, handoffs)
- Cross-session learning (failures, patterns, gotchas)
- Usage metrics (which nodes load together, success rates)
- Full-text search index over file contents
- Relationship/edge tracking between nodes
- Error logs and debugging traces

---

## Proposed Schema Enhancements (Graph Tracking)

```sql
-- Track what gets loaded together
CREATE TABLE context_sessions (
  id TEXT PRIMARY KEY,
  started_at TEXT NOT NULL,
  ended_at TEXT,
  task_type TEXT,  -- bug, feature, refactor, research
  nodes_loaded TEXT,  -- JSON array of paths
  tokens_used INTEGER,
  success BOOLEAN,
  outcome TEXT  -- JSON: what was accomplished
);

-- Track node metadata for smart loading
CREATE TABLE nodes (
  path TEXT PRIMARY KEY,
  type TEXT,  -- skill, command, agent, research, code
  tokens INTEGER,  -- estimated token count
  last_accessed TEXT,
  access_count INTEGER DEFAULT 0,
  avg_session_success REAL  -- success rate when this node is loaded
);

-- Track relationships between nodes
CREATE TABLE edges (
  source_path TEXT,
  target_path TEXT,
  relation TEXT,  -- loads, references, depends_on, conflicts_with
  weight REAL DEFAULT 1.0,  -- strength of relationship
  PRIMARY KEY (source_path, target_path, relation)
);

-- Query: What context should load for a given task type?
-- SELECT n.path, n.tokens
-- FROM nodes n
-- JOIN context_sessions cs ON json_each(cs.nodes_loaded, n.path)
-- WHERE cs.task_type = ? AND cs.success = 1
-- GROUP BY n.path
-- ORDER BY COUNT(*) DESC, n.avg_session_success DESC
-- LIMIT 10;
```

---

## Token Budget Discipline

**From lost-in-the-middle research:**
- LLMs attend most to START and END of context
- Middle 30-40% gets deprioritized
- 70-80% max context usage recommended
- Quality > quantity

**Kernel enforces:**
- CLAUDE.md: <220 lines
- Commands: <180 lines
- Agents: <250 lines
- Critical content at edges (role at top, checklist at bottom)

**aDNA enforces:**
- <50% context per work session
- Convergence narrowing (Campaign → Objective)
- SITREP handoffs between sessions

---

## Context Engineering Patterns

### 1. Progressive Disclosure
Load summary first. Expand on demand. Never front-load everything.

### 2. Edge Placement
Put role/purpose in first 50 lines. Put checklist/summary in last 40 lines.

### 3. Skill Loading
Reference skills/*/SKILL.md. Only load full content when methodology applies.

### 4. AgentDB Offloading
Write verbose findings to DB. Keep one-line summary in conversation.
```bash
agentdb learn pattern "finding" "evidence"
# Conversation keeps: "See AgentDB:patterns for full trace"
```

### 5. Phase Compaction
| Transition | Compact? | Why |
|------------|----------|-----|
| Research → Planning | Yes | Bulk served its purpose |
| Planning → Implementation | Yes | Plan is in contract |
| Debugging → Next feature | Yes | Traces pollute new work |

---

## Next Steps

1. **Add graph tracking tables** to AgentDB schema
2. **Track context_sessions** on each run
3. **Build smart loading** - query successful patterns before loading
4. **Export/import nodes** for merging between projects
5. **Add token counting** to node metadata

---

## Sources

- aDNA: https://github.com/LatticeProtocol/adna
- Lost-in-the-middle: Liu et al. 2023, METR 2025
- kernel-claude: this project
