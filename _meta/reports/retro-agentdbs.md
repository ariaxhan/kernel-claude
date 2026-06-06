---
title: Cross-project AgentDB retrospective — retrieval gap analysis
date: 2026-06-06
scope: our4cuts, modelmind, kernel-claude, augur, ariacam
mode: read-only investigation
author: retrospective agent
purpose: feed kernel retrieval-system redesign
---

# AgentDB Retrospective — Retrieval Gaps Across 5 Project DBs

Read-only analysis of the five `_meta/agentdb/agent.db` learning stores. Goal: find
what stops the right learning from surfacing at the right moment. Headline: the stores
are **cross-contaminated clones with a fake usefulness signal and an FTS index that
exists in only 1 of 5 DBs.** Retrieval is largely theater right now.

---

## 0. Totals & schema

| DB | total learnings | distinct insights | dup rows | FTS5 index? |
|---|---|---|---|---|
| our4cuts | 546 | 385 | 322 in dup-groups | **YES (546 rows)** |
| modelmind | 854 | 401 | 748 in dup-groups | **NO** |
| kernel-claude | 501 | 336 | 330 in dup-groups | **NO** |
| augur | 493 | 335 | 316 in dup-groups | **NO** |
| ariacam | 486 | 328 | 316 in dup-groups | **NO** |

Schema drift: `modelmind` allows extra `type` values (`design/test/accessibility`); the
other four use `failure/pattern/gotcha/preference`. Column order for `domain/visibility/
sensitivity` differs (some added via ALTER). Same logical table, inconsistent shape.

---

## 1. Type distribution — the high-value targets barely exist

Failures + gotchas are what you actually want recalled (they stop repeat mistakes).
They are a rounding error.

| DB | pattern | gotcha | failure | other | failure+gotcha % |
|---|---|---|---|---|---|
| our4cuts | 513 | 18 | 15 | 0 | 6.0% |
| modelmind | 782 | 37 | 34 | 1 (design) | 8.3% |
| kernel-claude | 495 | 4 | 2 | 0 | **1.2%** |
| augur | 488 | 4 | 1 | 0 | **1.0%** |
| ariacam | 485 | 1 | 0 | 0 | **0.2%** |

~93–99% of every store is `pattern`. The read-start scorer hands `failure/gotcha` a +50
boost — but there's almost nothing in those buckets to boost. The retrieval ranking is
optimized for a class of learning that the writers almost never create.

---

## 2. Duplication — and worse, cross-DB cloning

**Within-DB dupes:** exact-text repeats are everywhere. modelmind is worst: 748 of 854
rows (88%) sit in a duplicate group; only 401 insights are distinct. Same insight returns
2–3× in one recall, wasting result slots and context budget.

**Cross-DB cloning (the real disaster):** the five DBs are largely the *same* DB.

- 452 distinct insights exist across the whole fleet.
- **328 of them (73%) appear in ALL FIVE DBs.**
- 335 appear in ≥2 DBs.

So `ariacam`'s store contains FunJoin camp business rules (`8 active funbox types:
DAY_CAMPS, OVERNIGHT_CAMPS…`), modelmind interpretability findings (`mean_activation
least confounded with length, AUC 0.830`), and agency-agents persona inventories — none
of which have anything to do with a drone candid-photo taste model. A recall in any
project returns mostly other projects' content. Domain pollution confirms it: the
our4cuts DB lists domains `heynunchi-api`, `nunchi`, `kernel-claude`, `mypy` — all
foreign projects.

This is catastrophic for relevance: the signal-to-noise floor is ~27% project-relevant
before ranking even runs.

---

## 3. hit_count is a fake signal (blanket-bumped, partly copied)

This is the most damaging finding for ranking quality.

`agentdb read-start` (default `--weighted`, and the legacy path at line 321 of
`orchestration/agentdb/agentdb`) runs:

```sql
UPDATE learnings SET hit_count = hit_count + 1, last_hit = now()   -- on EVERY row
```

Every session start bumps **every learning**, not the ones actually used. Consequences:

- ~90% of rows have `hit_count > 0` (our4cuts 450/546, modelmind 751/854, etc.) — but
  that just means "the DB has been opened ~N times," not "this learning was useful."
- hit_counts cluster at the session count (max 126–127 in every DB; tight band 62–127).
- **Identical insights carry identical hit_counts across cloned DBs** (e.g. the
  `paraphrase logit_entropy` row = `hit_count 2` in our4cuts, modelmind, AND ariacam) —
  proving the value was *copied with the clone*, not earned by use.

The new `recall` command bumps only returned rows (correct design), but read-start's
blanket bump drowns that signal entirely. **hit_count cannot currently distinguish a
genuinely useful learning from a never-read one.** Any ranking that weights it (the
scorer multiplies `hit_count * 10`) is ranking on noise.

---

## 4. Vague / low-value slug learnings

A recurring anti-pattern: the `insight` field holds a *slug* and the real content is
buried in `evidence`. Examples (all present in every DB):

- `forge-execution-decisions` (evidence 446 chars)
- `forge-preflight-questions` (evidence 239 chars)
- `orchestration_research`, `context_research` (evidence ~150 chars)
- `unified-branch-merge-strategy`, `claude-zombie-cleanup`, `adna_external_repo`

18 such slug-style insights per DB (30 in modelmind). FTS5 indexes `insight` primarily;
a query like "forge timeout" will never match a slug like `forge-execution-decisions`,
so the actual lesson (in `evidence`) stays invisible. These are the learnings most likely
to silently never surface.

Evidence quality is otherwise OK: 0 rows with empty evidence, only ~8–11 rows/DB with
evidence under 20 chars. The problem is *where* the searchable content lives, not whether
it exists.

---

## 5. Domain tagging present; GLOBAL scope broken

- `domain` is populated on ~88% of rows (60–77 null/empty per DB). But values are
  polluted by foreign projects (see §2), so domain can't be trusted as a project filter.
- **GLOBAL scope is convention-only and leaks:** exactly **7** `[GLOBAL]`-tagged insights
  in our4cuts/modelmind/kernel-claude/augur — and **0 in ariacam**. So the
  cross-project lessons that *should* be everywhere (`[GLOBAL] NEVER ask for file
  locations — search first`; `[GLOBAL] Security via deterministic hooks, not behavioral
  trust`) are missing from one project entirely, while 328 *project-specific* insights
  wrongly live in all five. The propagation is exactly backwards: noise replicates,
  signal doesn't.
- There is no real scope column. `[GLOBAL]` is a string prefix in `insight`, not a
  queryable field. `visibility`/`sensitivity` exist but aren't used for cross-project
  routing.

---

## 6. Contradictions

Same-DB conflicting guidance with no scope to disambiguate:

- our4cuts: `"Agents on feature branches cause merge headaches. Keep all work on main
  for local profile."` vs `"OSS repos require feature branch + PR workflow — never
  commit to main."` Both true under different profiles, but stored flat — a recall
  returns whichever FTS ranks higher, with no signal which regime applies.

Beyond that, most apparent "contradictions" are actually the cross-project clones (§2):
business rules from FunJoin sitting next to ML interpretability claims. They don't
contradict so much as pollute.

---

## 7. Recency — still being written, unevenly

- Global ts floor is identical across all DBs: `2026-02-22 19:42:01` — a shared seed/import
  point, consistent with the cloning story.
- Writes are ongoing but lopsided. Last 30 days (after 2026-05-06):
  our4cuts 65, kernel-claude 20, modelmind 17, augur 12, ariacam 12.
- Most-recent ts: our4cuts 2026-06-06 (today), modelmind 2026-06-05, the other three
  frozen at 2026-06-01. ariacam/augur are nearly write-dead. Learning capture is healthy
  only where active work happens; the quieter projects' stores are stagnating.

---

## Summary: what's actually broken about retrieval

1. **FTS exists in 1 of 5 DBs** — `recall` self-heals on first call but until then 4/5
   projects silently fall back to `LIKE` (substring, no ranking, no relevance).
2. **73% of every store is foreign-project clone noise** — relevance floor ~27%.
3. **hit_count is blanket-bumped** — the primary ranking signal measures session count,
   not usefulness.
4. **High-value types (failure/gotcha) are 0.2–8% of rows** — ranking optimizes a near-
   empty bucket.
5. **GLOBAL propagation is backwards** — 7 genuinely-global lessons under-propagate
   (0 in ariacam); 328 project-specific ones over-propagate to all five.

Redesign implications (not implemented — read-only run): add `scope` (project|global) as a
real column; stop blanket-bumping hit_count (bump only on recall return); dedup on write;
index `evidence` in FTS, not just `insight`, or forbid slug-only insights; run migration
012 on all DBs; and physically separate per-project rows from a shared global store.
