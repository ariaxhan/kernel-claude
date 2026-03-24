# Tear Down: Issue Plan #19-#34
reviewed: 2026-03-24T00:35:00Z
tier: 3
scope: 16 issues, 20+ files across hooks, agentdb, skills, CLAUDE.md

## Big 5
input_validation: FAIL — #20 dedup uses unescaped substring in SQL LIKE, #25 needs init guard
edge_cases: FAIL — #33 uses PID-scoped marker (wrong PID after compaction), #21 breakers leak across sessions
error_handling: PASS (conditional on #19 landing first)
duplication: FAIL — #22 creates third copy of methodology alongside CLAUDE.md and ingest.md
complexity: PASS

## Verdict: REVISE

The plan is sound in structure and priority, but 4 specific implementation details need revision before execution:

## Action Items

1. **#20 dedup SQL injection** — `${safe_insight:0:40}` must go through `sql_escape` before LIKE clause. Also require exact type match to prevent cross-type false dedup.

2. **#33 marker scope** — Change from `/tmp/kernel-compact-marker-$$` to `$PROJECT_ROOT/_meta/.compact-marker`. PID changes between hook invocations.

3. **#21 breaker namespace** — Change from `/tmp/kernel-breakers/` to `/tmp/kernel-breakers-${PPID:-0}/` or project-scoped path. Prevents cross-session leakage.

4. **#22 + #24 dedup conflict** — Workflow skills must REPLACE ingest.md methodology, not supplement. Define shared `context_payload()` function for both session-start and post-compact-restore hooks.

5. **#32 cycle detection** — Add `LIMIT 100` to recursive CTE and test with cyclic edge graph.

6. **#31 expansion cap** — Add `MAX_CHILDREN=5` per learning. Prevent runaway clonal expansion.

## Execution Order (revised)

### Wave 1: P0 fixes (no dependencies, all tiny)
#19 → #27 → #23 (parallel-safe, independent)

### Wave 2: P1 reliability (sequential where noted)  
#29 → #21 → #20 → #33 → #34 (sequential: #21 before #33 because circuit breaker protects new hooks)

### Wave 3: P2 optimization
#22 + #24 together (resolve duplication holistically) → #25 (depends on #19) → #30

### Wave 4: P3 innovation (sequential dependency chain)
#26 → #28 → #31 → #32

## Risk Assessment
- Wave 1: LOW risk (bug fixes, well-scoped)
- Wave 2: MEDIUM risk (#33 is novel hook pattern, #34 could change behavior)
- Wave 3: MEDIUM risk (#24 touches session-start which is THE delivery mechanism)
- Wave 4: HIGH risk (novel patterns, no prior art in bash CLI plugins)
