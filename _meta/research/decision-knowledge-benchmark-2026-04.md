# Decision Capture & Knowledge Organization Benchmark

**Date:** 2026-04-07
**Hypotheses tested:** H079, H085, H086
**Dataset:** 356 learnings, 68 errors from kernel-claude AgentDB

---

## Experiment 1: Decision Structure Analysis (H079 vs H085)

### Semantic Classification of All 356 Learnings

| Category | Count | % | Description |
|----------|-------|---|-------------|
| PATTERN | 273 | 76.7% | Conditional: when X, do Y |
| FAILURE | 27 | 7.6% | Post-mortem: X broke because Y |
| GOTCHA | 27 | 7.6% | Warning: watch out for X |
| DECISION | 23 | 6.5% | Chose X over Y because Z |
| RULE | 6 | 1.7% | Imperative: always/never do X |

**Existing type distribution** (before reclassification):
- pattern: 292, failure: 29, gotcha: 28, preference: 7

The 23 decision-type entries are currently stored as `pattern` or `failure` types, losing their decision structure. They contain language like "instead of", "over", "rather than", "use X not Y" but lack explicit rejected-alternative fields.

### Decision Examples Extracted

| # | Chose | Rejected | Why |
|---|-------|----------|-----|
| 1 | Sequential rebase-and-merge | Parallel merge | Shared scope creep causes conflicts (LRN-053) |
| 2 | Server-side progress_history table | Client-only state | Defense against data loss (LRN-055) |
| 3 | Direct execution for tier-1 | Agent spawning | Agent overhead 30-60s for 30s tasks (LRN-101) |
| 4 | Parallel worktrees on non-overlapping files | Serial execution | Zero conflicts, ~5x throughput (LRN-106) |
| 5 | Pure function separation | Monolithic API code | Testability without mocks (retro-1) |
| 6 | Gemini CLI for Korean verification | Apfel | 4K context overflow, Korean char failure (LRN-20260405-002) |
| 7 | Commit/stash before worktrees | Direct worktree create | Lost uncommitted changes (LRN-20260401) |

### H079 vs H085 Verdict

**Token cost comparison:**

| Load strategy | Tokens | % of total |
|--------------|--------|------------|
| All 356 learnings | ~23,562 | 100% |
| Decision-type DB query (`WHERE type='decision'`) | ~1,961 | 8.3% |
| DECISIONS.md file | ~2,651 | 11.2% |

**H079 (DB `decision` type): WINNER**

- **Retrieval**: SQL query `WHERE type='decision'` returns exactly what's needed. DECISIONS.md requires loading entire file.
- **Deduplication**: DB can `SELECT DISTINCT` and detect near-duplicates via text similarity. File requires manual cleanup.
- **Staleness**: DB supports `last_hit` and `hit_count` for automatic aging. File entries just accumulate.
- **Structure**: DB can enforce `chose`, `rejected`, `reason` fields via JSON in evidence column. File relies on formatting discipline.
- **Capture friction**: Slightly higher than file append, but structured capture prevents garbage-in.

**H085 (DECISIONS.md): REJECTED**

- Append-only files grow without bound and resist deduplication
- No query capability (can't filter by domain, recency, hit count)
- Staleness invisible without manual review
- Only advantage: human readability at session start (marginal given DB query is equally readable)

**Recommendation**: Add `decision` type to learnings table. Store structure as JSON in evidence field: `{"chose":"X","rejected":["Y","Z"],"reason":"because A"}`. Query at session start: `SELECT insight, evidence FROM learnings WHERE type='decision' AND domain=? ORDER BY last_hit DESC LIMIT 20`.

---

## Experiment 2: Knowledge Organization (H086)

### GSD-2 Scheme vs Kernel Scheme

**GSD-2 classification of 356 learnings:**

| GSD-2 Category | Count | % |
|----------------|-------|---|
| Rules (K-IDs) | 48 | 13.5% |
| Patterns (P-IDs) | 274 | 77.0% |
| Lessons (L-IDs) | 34 | 9.6% |

**Kernel scheme (existing):**

| Kernel Type | Count | % |
|-------------|-------|---|
| pattern | 292 | 82.0% |
| failure | 29 | 8.1% |
| gotcha | 28 | 7.9% |
| preference | 7 | 2.0% |

### Analysis

**Distribution balance**: GSD-2 is slightly more balanced (13.5/77/9.6) vs Kernel (82/8/8/2). Both are pattern-heavy. Neither achieves uniform distribution, which is expected -- most learnings ARE patterns.

**Overlap**: 54 entries (15.2%) fit multiple GSD-2 categories. Example: "Never use parallel worktrees on shared files" is both a Rule (imperative) and a Lesson (learned from failure). Kernel's scheme has less overlap because `gotcha` absorbs the rule-warning boundary.

**Retrieval precision**: Kernel's 4-type scheme is better for retrieval. Searching for "how to handle X" with Kernel types lets you distinguish:
- `pattern`: how it normally works
- `failure`: what went wrong before
- `gotcha`: what to watch out for
- `preference`: style choice

GSD-2's 3-type scheme collapses gotcha+failure into "Lessons", losing the warning-vs-postmortem distinction.

**Stale detection**: Kernel wins again. `hit_count` and `last_hit` fields make staleness quantitative. GSD-2 has no staleness mechanism.

### H086 Verdict

**Kernel's existing scheme is better than GSD-2's for this codebase.** The 4-type system with `hit_count`/`last_hit` metadata provides better retrieval and aging. However, both schemes miss the DECISION category identified in Experiment 1.

**Recommendation**: Keep Kernel scheme, add `decision` as 5th type. Final types: `pattern`, `failure`, `gotcha`, `preference`, `decision`.

---

## Experiment 3: Decision Gap Analysis

### Error-to-Learning Coverage

| Metric | Count | % of 68 errors |
|--------|-------|-----------------|
| Errors with corresponding learning | 16 | 23.5% |
| Errors with decision-type learning | 3 | 4.4% |
| Errors WITHOUT any learning | 52 | 76.5% |
| **Decision gap** (learning exists, no decision) | 13 | 19.1% |

### Interpretation

- **76.5% of errors produced no learning at all.** This is the primary knowledge capture gap. Most errors are encountered, fixed, and forgotten.
- **19.1% have a learning but no decision.** These are cases where the fix was captured ("do X") but the rejected alternative wasn't ("we tried Y, it broke because Z, so we chose X"). Without the rejected path, future agents may re-explore Y.
- **Only 4.4% have full decision capture.** This means ~95% of error-driven decisions are invisible to future sessions.

### Decision gap examples (errors with learning but no decision):

Errors around parallel worktrees, git merge conflicts, and agent coordination all produced learnings like "do sequential merge" but didn't record "we tried parallel merge and it caused 7-way conflicts." The WHY is buried in evidence fields, not structured for retrieval.

---

## Experiment 4: Format Shootout

### Three Candidate Formats

**Format A: DB field extension**
```
agentdb learn decision "Sequential rebase-and-merge for parallel PRs" \
  --evidence '{"chose":"sequential rebase","rejected":["parallel merge","cherry-pick"],"reason":"shared scope creep causes 7-way conflicts"}'
```

**Format B: DECISIONS.md append**
```markdown
| 24 | 2026-04-07 | Parallel PRs | Sequential rebase | Parallel merge, cherry-pick | Scope creep causes 7-way conflicts |
```

**Format C: Tagged learning**
```
agentdb learn pattern "[DECISION] Sequential rebase-and-merge for parallel PRs — rejected: parallel merge (7-way conflicts)"
```

### Scoring

| Criterion | DB field (A) | DECISIONS.md (B) | Tagged (C) |
|-----------|-------------|-------------------|------------|
| Capture friction | 6/10 | 7/10 | 9/10 |
| Retrieval quality | 9/10 | 7/10 | 5/10 |
| Deduplication | 8/10 | 4/10 | 6/10 |
| Staleness detection | 9/10 | 3/10 | 7/10 |
| **Total** | **32/40** | **21/40** | **27/40** |

### Justification

**Format A (DB field) wins at 32/40.**
- Retrieval: `WHERE type='decision'` is precise; JSON evidence enables structured queries
- Dedup: SQL can detect near-duplicates; file-based dedup requires manual intervention
- Staleness: `hit_count`/`last_hit` automatically track relevance
- Friction cost is acceptable because structured capture prevents garbage entries

**Format C (Tagged) is runner-up at 27/40.**
- Lowest friction (just prefix `[DECISION]` to any learning)
- But retrieval requires text search (`LIKE '[DECISION]%'`) instead of type filter
- No structured rejected/reason fields means agents can't programmatically extract alternatives

**Format B (File) loses at 21/40.**
- Append-only files resist cleanup and deduplication
- No programmatic query capability
- Staleness invisible without manual audit
- Only advantage is human scan-ability, which DB query results also provide

---

## Final Recommendations

### Immediate (implement now)

1. **Add `decision` type** to the `CHECK` constraint on learnings.type:
   ```sql
   ALTER TABLE learnings RENAME TO learnings_old;
   CREATE TABLE learnings (
     id TEXT PRIMARY KEY,
     ts TEXT DEFAULT CURRENT_TIMESTAMP,
     type TEXT CHECK(type IN ('failure','pattern','gotcha','preference','decision')),
     insight TEXT NOT NULL,
     evidence TEXT,
     domain TEXT,
     hit_count INTEGER DEFAULT 0,
     last_hit TEXT
   );
   INSERT INTO learnings SELECT * FROM learnings_old;
   DROP TABLE learnings_old;
   ```

2. **Reclassify existing 23 decisions** from `pattern`/`failure` to `decision` type with structured evidence JSON.

3. **Update `agentdb learn`** to accept `decision` type and validate evidence contains `chose`/`rejected`/`reason` fields.

4. **Add to session-start**: `SELECT insight, evidence FROM learnings WHERE type='decision' ORDER BY last_hit DESC LIMIT 20` to preload recent decisions.

### Deferred

5. **Error-to-learning pipeline**: After every error resolution, prompt for learning capture. Target: reduce the 76.5% uncaptured error rate.

6. **Decision decay**: Decisions not hit in 30+ days get flagged for review. Technology and codebase evolve; old decisions may no longer apply.

---

## Hypothesis Verdicts

| Hypothesis | Verdict | Confidence | Evidence |
|------------|---------|------------|----------|
| H079 (DB decision type) | **GRADUATE** | 85% | 23 existing decisions lost in flat types; DB query 92% cheaper than full load; structured evidence enables programmatic retrieval |
| H085 (DECISIONS.md file) | **KILL** | 80% | Scored 21/40 vs DB's 32/40; no query capability, no dedup, no staleness detection |
| H086 (GSD-2 organization) | **KILL** | 75% | Kernel's 4-type scheme already outperforms GSD-2's 3-type; adding `decision` as 5th type is strictly better than reorganizing |
