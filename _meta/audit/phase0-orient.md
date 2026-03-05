# Phase 0: Orient

**Date**: 2026-03-04
**Context tokens at start**: ~51k

---

## File Inventory

### Core (Always-On)
| File | Lines | Purpose |
|------|-------|---------|
| CLAUDE.md | 333 | Main kernel config |
| rules/kernel.md | 311 | Invariants, heuristics, conventions |
| **Total always-on** | **644** | Way over 150-line recommendation |

### Commands
| File | Lines | Purpose |
|------|-------|---------|
| commands/ingest.md | 420 | Universal entry point |
| commands/tearitapart.md | 285 | Critical review |
| commands/handoff.md | 232 | Context transfer |

### Agents
| File | Lines | Purpose |
|------|-------|---------|
| agents/surgeon.md | 200 | Implementation |
| agents/adversary.md | 261 | Verification |
| agents/researcher.md | 117 | Research |
| agents/scout.md | 121 | Discovery |
| agents/validator.md | 96 | Pre-commit |

### Skills
| Skill | SKILL.md Lines | Reference Docs |
|-------|---------------|----------------|
| build | 105 | 7 (misplaced general docs) |
| debug | 122 | 1 |
| design | 100 | 1 |
| testing | 56 | 1 |
| refactor | 72 | 1 |

### Reference Docs (11 total)
Located under skills/*/reference/:
- build-research.md (353), orchestration-research.md (202), security-research.md (165), git-research.md (165), architecture-research.md (139), performance-research.md (135), context-research.md (126)
- debug-research.md (350)
- design-research.md (265)
- testing-research.md (174)
- refactor-research.md (375)

---

## What's Missing

1. **_meta/agents/** - Created now. Compact hook couldn't save snapshots.
2. **_meta/context/** - Created now. Scout has nowhere to write active.md.
3. **_meta/plans/** - Created now. Plans have no destination.
4. **_meta/research/** - Created now. Researcher has no destination.
5. **AGENT_NAME env var** - Session-start.sh never sets it. Compact hook uses `unknown-$$`.
6. **AgentDB data** - Schema exists, 0 rows. Never actually used.

---

## What's Broken

### Compact Hook Failure Chain
1. `session-start.sh` doesn't export `AGENT_NAME`
2. `pre-compact-commit.sh` uses `${AGENT_NAME:-unknown-$$}`
3. `_meta/agents/` directory didn't exist
4. Result: Snapshots can't be saved, agent registry can't update

### AgentDB is Referenced But Empty
- CLAUDE.md mentions `agentdb read-start` and `agentdb write-end`
- Session-start.sh calls `agentdb read-start`
- **But nothing ever writes to it** - 0 rows in context table
- The whole orchestration system is designed around AgentDB but it's unused

### Skills ↔ Reference Docs Architecture Issue
- `skills/build/reference/` contains 7 docs that are GENERAL PURPOSE:
  - security-research.md (relevant to all code, not just "build")
  - git-research.md (relevant to all workflows)
  - architecture-research.md (system design)
  - context-research.md (context management)
  - performance-research.md (optimization)
  - orchestration-research.md (multi-agent patterns)
  - build-research.md (actually build-specific)
- These should be reorganized: general docs separate from skill-specific docs

---

## Token Budget Analysis

**Always-on content:**
- CLAUDE.md: ~333 lines × ~4 tokens/line = ~1,332 tokens
- rules/kernel.md: ~311 lines × ~4 tokens/line = ~1,244 tokens
- Session-start hook output: ~50 lines = ~200 tokens
- **Estimated always-on: ~2,800 tokens**

**Recommendations:**
- Anthropic: CLAUDE.md under 150 lines
- HumanLayer: Under 60 lines for guaranteed adherence
- Current: 644 lines (4x-10x over recommendations)

**Duplication:**
- CLAUDE.md and rules/kernel.md have overlapping content
- CLAUDE.md design_principles duplicates design skill content
- Tier tables appear in multiple places

---

## Proposed Architecture Changes

### 1. Fix Compact Hook (immediate)
- Set AGENT_NAME in session-start.sh
- Directories now exist

### 2. Reorganize Reference Docs
**Current:** skills/build/reference/ has general docs
**Proposed:**
```
_meta/reference/
  ├── security-research.md
  ├── git-research.md
  ├── architecture-research.md
  ├── context-research.md
  ├── performance-research.md
  └── orchestration-research.md
skills/
  ├── build/reference/build-research.md
  ├── debug/reference/debug-research.md
  ├── design/reference/design-research.md
  ├── testing/reference/testing-research.md
  └── refactor/reference/refactor-research.md
```

### 3. Reduce Always-On Content
- Move design_principles from CLAUDE.md to design skill
- rules/kernel.md conventions → reference doc (load on demand)
- Target: 150 lines always-on

### 4. Implement AgentDB Writes
- Session-start: write session context entry
- Compact hook: write checkpoint
- Agents: write their output
- Currently nothing writes to AgentDB

---

## Metrics Baseline (for evaluation)

| Metric | Current | Target |
|--------|---------|--------|
| Always-on lines | 644 | <150 |
| AgentDB entries | 0 | >0 per session |
| Compact hook status | Broken | Working |
| Missing directories | 4 | 0 |
| Reference doc organization | Scattered | Hierarchical |
