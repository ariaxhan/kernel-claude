# KERNEL Architecture Proposal

**Date**: 2026-03-04
**Goal**: Benchmarking and evals across versions, proper skill structure, context preservation

---

## Problem Statement

1. **No evaluation system**: Can't measure if changes improve or degrade performance
2. **Reference docs scattered**: General docs buried under skills/build/
3. **Always-on bloat**: 644 lines when <150 recommended
4. **AgentDB unused**: Schema exists, nothing writes to it
5. **Compact hook broken**: Fixed now, but context preservation needs architecture

---

## Proposed Architecture

### 1. Directory Structure

```
kernel-claude/
├── CLAUDE.md                    # Minimal always-on (~100 lines)
├── rules/
│   └── kernel.md                # Core invariants only (~100 lines)
├── commands/                    # User-invoked
│   ├── ingest.md
│   ├── tearitapart.md
│   ├── handoff.md
│   └── eval.md                  # NEW: run evals
├── agents/                      # Spawnable actors
│   ├── surgeon.md
│   ├── adversary.md
│   ├── researcher.md
│   ├── scout.md
│   └── validator.md
├── skills/                      # Methodology (each with SKILL.md + reference/)
│   ├── build/
│   │   ├── SKILL.md
│   │   └── reference/build-research.md
│   ├── debug/
│   │   ├── SKILL.md
│   │   └── reference/debug-research.md
│   ├── design/
│   │   ├── SKILL.md
│   │   ├── reference/design-research.md
│   │   └── variants/
│   ├── testing/
│   │   ├── SKILL.md
│   │   └── reference/testing-research.md
│   └── refactor/
│       ├── SKILL.md
│       └── reference/refactor-research.md
├── reference/                   # NEW: General reference docs (not skill-specific)
│   ├── security-research.md
│   ├── git-research.md
│   ├── architecture-research.md
│   ├── context-research.md
│   ├── performance-research.md
│   └── orchestration-research.md
├── _meta/
│   ├── agentdb/agent.db
│   ├── agents/                  # Agent snapshots + registry
│   ├── context/active.md        # Scout output
│   ├── plans/                   # Implementation plans
│   ├── research/                # Researcher output
│   ├── handoffs/                # Context transfers
│   ├── audit/                   # This directory
│   └── evals/                   # NEW: Evaluation data
│       ├── EVAL-FRAMEWORK.md
│       ├── metrics.jsonl        # Per-session metrics
│       ├── baseline.json        # Version baseline
│       └── results/             # Historical results
└── hooks/
    └── scripts/
```

### 2. Evaluation Framework

**What we measure:**

| Metric | Source | Method |
|--------|--------|--------|
| Routing accuracy | Session logs | Did correct command/skill trigger? |
| Completion rate | AgentDB | Tasks completed vs started |
| Failure categories | AgentDB | Classify by type (scope, blocked, etc.) |
| Token efficiency | Session data | Tokens per task type |
| Agent performance | AgentDB | Per-agent success rate |
| Reference doc utility | Grep session | Were docs read and used? |

**Implementation:**

```bash
# _meta/evals/run-eval.sh
# Reads session data, queries AgentDB, outputs metrics.jsonl

# Hooks that feed data:
# - SessionEnd: append session summary to metrics.jsonl
# - PostToolUse: track tool usage patterns
# - AgentDB writes: track agent outcomes
```

**Baseline format (_meta/evals/baseline.json):**
```json
{
  "version": "6.0.0",
  "date": "2026-03-04",
  "metrics": {
    "always_on_lines": 644,
    "agentdb_entries": 0,
    "routing_accuracy": null,
    "completion_rate": null
  },
  "notes": "Pre-optimization baseline"
}
```

### 3. Skill ↔ Reference Doc Standard

Each skill has ONE reference doc with consistent structure:

```markdown
# {Skill Name} Reference

## Sources
{Cited sources with dates}

## Key Findings
{Numbered list of actionable insights}

## Anti-Patterns
{What NOT to do, with examples}

## KERNEL Integration
{How this applies to the KERNEL workflow}
```

**General reference docs** (not skill-specific) go in `/reference/`, not under skills.

### 4. Always-On Reduction Plan

**Current (644 lines):**
- CLAUDE.md: 333 lines
- rules/kernel.md: 311 lines

**Target (~200 lines):**

| Section | Current Location | Action |
|---------|------------------|--------|
| Philosophy | CLAUDE.md | Keep (10 lines) |
| Tiers | CLAUDE.md | Keep (15 lines) |
| Agents | CLAUDE.md | Summarize (20 lines) |
| AgentDB | CLAUDE.md | Keep (10 lines) |
| Skills | CLAUDE.md | Names only (15 lines) |
| Design principles | CLAUDE.md | Move to design skill |
| Invariants | rules/kernel.md | Keep (50 lines) |
| Heuristics | rules/kernel.md | Keep (40 lines) |
| Conventions | rules/kernel.md | Move to reference/ |
| Parallel rules | rules/kernel.md | Merge with heuristics |
| Context discipline | rules/kernel.md | Keep (20 lines) |
| Output quality | rules/kernel.md | Keep (20 lines) |

**Estimated new total: ~200 lines** (3x reduction)

### 5. AgentDB Usage Protocol

Every session should write to AgentDB:

| Event | Table | Content |
|-------|-------|---------|
| Session start | context | Session ID, project, branch |
| Contract created | context | Contract spec |
| Agent checkpoint | context | What was done, evidence |
| Verdict | context | Pass/fail, tests run |
| Session end | context | Summary, outcome |
| Error | errors | Tool, error, file |
| Learning | learnings | Insight, evidence, domain |

---

## Implementation Priority

### Phase 1: Fix (immediate)
- [x] Create missing directories
- [x] Fix compact hook (AGENT_NAME persistence)
- [ ] Initialize AgentDB with session-start write

### Phase 2: Reorganize
- [ ] Move general reference docs to /reference/
- [ ] Update skill references to new paths
- [ ] Trim CLAUDE.md design_principles → design skill

### Phase 3: Evaluate
- [ ] Create _meta/evals/EVAL-FRAMEWORK.md
- [ ] Add SessionEnd hook to write metrics
- [ ] Capture baseline metrics

### Phase 4: Optimize
- [ ] Reduce always-on to ~200 lines
- [ ] Verify routing accuracy maintained
- [ ] Compare metrics to baseline

---

## Success Criteria

| Metric | Before | Target |
|--------|--------|--------|
| Always-on lines | 644 | <200 |
| AgentDB entries per session | 0 | >5 |
| Reference doc locations | Mixed | Hierarchical |
| Eval data captured | None | Per-session metrics |
| Compact hook | Broken | Working |
