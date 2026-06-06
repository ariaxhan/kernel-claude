---
title: Dream — Fixing Retrieval in the kernel AgentDB Learning Memory
date: 2026-06-06
mode: design-only (no code written)
inputs:
  - _meta/reports/retro-agentdbs.md (data-rot across 5 live DBs)
  - _meta/reports/retrieval-deepdive.md (recall code analysis + ranked fixes)
ground_truth:
  - recall: orchestration/agentdb/agentdb:1427
  - read-start: orchestration/agentdb/agentdb:301
  - learn: orchestration/agentdb/agentdb:444
  - preflight (self-healing column-add path): orchestration/agentdb/agentdb:164
  - run_pending_migrations: orchestration/agentdb/agentdb:111
  - global brain DB (confirmed exists): ~/Documents/Vaults/_meta/agentdb/agent.db
hard_constraints:
  - NO FTS sync triggers (SQLite 3.43 aborts learn insert) — rebuild-on-recall is locked
  - additive, no regression — 5+ live DBs, multi-agent orchestration is core
  - bash + sqlite3 only — no heavy deps unless flagged a bigger bet
---

# Dream — Retrieval Fix

The fault isn't one bug. It's two layers failing together:

- **Garbage in (data rot):** 73% cross-project clone contamination, hit_count blanket-bumped
  into noise, FTS index in only 1 of 5 DBs, GLOBAL scope as a string prefix that propagates
  backwards (noise replicates, signal doesn't).
- **Garbage ranking (recall code):** no dedup, no visibility filter, uncalibrated magic-number
  boosts (failure −5 sledgehammer, hit_count×0.1 rich-get-richer), all-OR matching, filenames
  shattered by the tokenizer.

The code layer is pure-plugin and cascades safely to every DB on next call. The data layer
touches live rows = W8 risk. The whole design fight is *where to draw the line between them.*

---

## Perspective 1 — Minimalist

> Do you actually need a scope column and a global brain right now? No. You need recall to
> stop returning duplicate, irrelevant, human-only junk. That's four clauses in one function.

**The move:** Fix `cmd_recall` (agentdb:1427) only. Touch nothing else. No new columns, no
migration across 5 DBs, no global DB, no data surgery.

1. Dedup: wrap the SELECT in `GROUP BY lower(substr(l.insight,1,60))`, keep `MIN(score)`.
2. Visibility: add `AND l.visibility = 'agent'` to the WHERE (and the hit_count UPDATE).
3. Recalibrate: failure boost `−5 → −1.5`; hit_count term `−(l.hit_count*0.1)` →
   `−(min(l.hit_count,20)*0.05)` so bm25 relevance leads and boosts tie-break.
4. Query hygiene: drop a ~30-word stopword set and 1-char tokens before building MATCH.

The 73% clone contamination *mostly self-cancels* once you stop ranking on fake hit_count —
foreign-project rows don't match the query text, so bm25 already buries them. You don't need
to delete the clones; you need to stop *promoting* them. The clones are a relevance problem
only because the ranker was amplifying them.

**Effort:** ~2 hours. One file, one PR, one function. Eyeball 5–10 real queries before/after.
**What you give up:** cross-project recall stays impossible; the 7 GLOBAL learnings stay
trapped; the data stays dirty (but harmless if recall stops amplifying it).

---

## Perspective 2 — Maximalist

> If we're fixing memory, build the version we'd be proud of: a real two-tier brain. A clean
> global store of generic lessons that propagates everywhere, and lean per-project stores that
> only hold what's actually local. Retrieval that knows the difference.

**The move:** Make scope a first-class concept and the global brain a real participant.

1. **Real `scope` column** (`project | global`), added via the proven preflight path
   (mirror migration 009: marker-only file, preflight detects-and-adds idempotently). Backfill
   the 7 `[GLOBAL]`-prefixed insights → `scope='global'`; everything else `scope='project'`.
2. **Promote-to-global command:** `agentdb promote <id>` copies a learning into the designated
   global brain (`~/Documents/Vaults/_meta/agentdb/agent.db`, confirmed to exist) and marks it
   global. That's how a hard-won SQLite/bash/Cloudflare gotcha learned in our4cuts becomes
   visible in modelmind — *forward* propagation, the way it was supposed to work.
3. **Cross-DB recall:** `recall --global` runs the FTS query against local AND the global brain
   (each has its own `learnings_fts`; rebuild each, tag rows `[local]`/`[global]`, merge, dedup,
   re-sort). Wire it into the NEXUS ingest loop so every recall is two-tier.
4. **Decontaminate the fleet:** a maintenance pass that hashes insights, finds the 328 rows
   cloned into all 5 DBs, lifts the genuinely-generic ones to global, and deletes the
   project-specific clones from the projects that don't own them. ariacam stops storing FunJoin
   camp rules.
5. **Evidence-gated FTS:** index `evidence` properly and forbid slug-only insights at write
   time, so `forge-execution-decisions` (real lesson buried in evidence) actually matches
   "forge timeout".
6. **porter tokenizer** so deploy/deploys/caching/cache collapse — drop+recreate the
   external-content FTS index, lossless.

**Effort:** ~12–16 hours. New schema concept, a promote command, cross-DB recall, a fleet-wide
data migration (the scary part), tokenizer swap. Multiple PRs.
**What you get:** the memory system the philosophy actually claims — "continuity depends on it,"
cross-project signal that compounds. **What it costs:** every one of those steps except the
tokenizer touches live data across 5 real projects. The decontamination pass is irreversible
data surgery on stores you can't easily reconstruct.

---

## Perspective 3 — Pragmatist

> Ship the recall fix now because it's safe and it's 80% of the felt pain. Build the structural
> stuff as a *tool Aria runs deliberately*, not an auto-migration that fires on every DB the
> next time someone opens a session. Defer the irreversible fleet surgery until the tool proves
> the global brain is worth it.

**Ship now (plugin code, cascades safely, no data touched):**
- A1 dedup + A2 visibility filter + A3 recalibrate weights — one PR. (Minimalist's core.)
- A4 query hygiene (stopwords + drop 1-char) — same or next PR.
- A5 stop read-start polluting hit_count: add `load_count` via preflight, move the four
  blanket bumps there, leave hit_count owned solely by recall. This is what makes hit_count a
  *real* signal — A3 compounds it.

**Offer as a tool (opt-in, Aria runs it, never automatic):**
- `scope` column via preflight (additive, safe — it's just a column).
- `recall --global` — OFF by default, degrades to local-only silently if the global DB is
  missing/locked (fallback-first). The NEXUS loop can opt in once it's trusted.
- `agentdb promote <id>` — manual, one learning at a time. Low blast radius.
- `agentdb decontaminate --dry-run` — reports the 328 clones and what it *would* do, writes
  nothing. The destructive `--apply` is a separate W8 ritual with a backup path, never the
  default.

**Defer:**
- porter tokenizer (A6) — its own isolated migration PR after the cheap wins land; nice, not
  urgent.
- incremental FTS rebuild (B2) — premature under ~5k rows (current: 501). Watermark it later.
- embedding/semantic recall (B3) — breaks the no-heavy-deps rule. Only if FTS demonstrably
  plateaus after everything above.

**Upgrade path / tradeoff:** the cheap wins make recall good *today* without risking a single
live row. The structural fix exists as tooling Aria invokes when she's ready, with a dry-run
gate before anything irreversible. If `recall --global` proves the global brain earns its keep,
*then* the decontamination pass is worth the W8 risk — and you'll have a `--dry-run` receipt
proving exactly what it'll do before it does it.

**Effort:** ship-now ~3–4 hours · offer-as-tool ~6–8 hours (built when wanted) · defer = later.

---

## The Council attacks each

### Against Minimalist
- **"The clones self-cancel" is half-true and untested.** bm25 buries foreign rows *that share
  no query terms*. But generic gotchas (bash, sqlite, git) DO share terms across projects —
  those clones will still surface, just now without the hit_count amplifier. You've reduced the
  noise, not characterized it. Verdict: defensible as a first cut, but claim it *measured*, not
  *solved*.
- **It permanently strands the 7 GLOBAL learnings.** The single highest-value lessons
  (`NEVER ask for file locations — search first`) stay invisible cross-project. Minimalist
  fixes ranking and declares victory on a corpus that's structurally missing its best signal.
- **hit_count is still poisoned.** Minimalist recalibrates the *weight* on hit_count but
  read-start keeps blanket-bumping it every session. You've turned down the volume on a signal
  that's still being corrupted upstream. Without A5, A3's hit_count cap is a band-aid.

### Against Maximalist
- **The decontamination pass is the riskiest thing in the whole plan and the least reversible.**
  "Hash insights, lift generic ones to global, delete project clones" — *which* are generic?
  That's a judgment call run as bulk DELETE across 5 live stores you admit are hard to
  reconstruct. One bad heuristic and you've deleted real learnings. This is W8 with a fuzzy
  classifier driving. Disqualifying as an *automatic* step.
- **Forward-propagation creates a new contamination vector.** `promote` copies into the global
  brain → every project now recalls it. Promote the wrong thing (a project-specific rule that
  *looked* generic) and you've recreated the exact backwards-propagation you're fixing, just
  pointed the other way. Needs a human in the loop, which makes it a tool, not a pipeline.
- **Scope as `project|global` is too coarse for the contradiction problem.** retro §6 found
  `keep work on main (local)` vs `feature branch + PR (OSS)` — both true under different
  *profiles*. A binary scope can't disambiguate that. The ambitious version arguably needs
  profile-scoping too, which Maximalist hasn't budgeted. Scope-creep on the scope feature.
- **12–16 hours and multiple live-data PRs for a system one person uses.** Where's the evidence
  the global brain pays for that risk *before* you take it?

### Against Pragmatist
- **"Offer as a tool" can become "never runs."** Half the value (cross-project signal) lives in
  the opt-in column. If Aria never runs `promote`/`decontaminate`, Pragmatist shipped
  Minimalist with extra dead code. The split only works if the tools are genuinely used —
  otherwise it's the worst of both: complexity of Maximalist, payoff of Minimalist.
- **`recall --global` off-by-default means the ingest loop must be edited to opt in** — that's
  a NEXUS-layer change outside the plugin, easy to forget. The unlock exists but stays dark
  until something flips the switch. Name *who* flips it and *when*, or it's deferred-in-disguise.
- **Two hit_count columns (`hit_count` + `load_count`) is mild schema debt.** Justified, but
  it's a permanent cost to fix a self-inflicted blanket-bump. Cleaner would be to just *stop*
  read-start bumping anything — but that loses the "what got shown at cold start" signal. The
  council accepts the column but flags it's debt, not free.

---

## Recommended design (survives the attacks)

Pragmatist's structure wins — but hardened by the council's hits. The line between layers is:
**code that cascades safely ships now; anything touching live rows is opt-in with a dry-run gate
or a human in the loop; irreversible fleet surgery is deferred until the global brain proves its
worth.** Concrete:

### SHIP NOW — one or two plugin PRs, ~3–4 hours, zero live rows touched

All in `cmd_recall` (agentdb:1427) + read-start (agentdb:301) + preflight (agentdb:164):

1. **Dedup** — `GROUP BY lower(substr(l.insight,1,60))`, keep `MIN(score_expr)` for order and a
   pinned representative (`MIN(l.evidence)`). Kills "8 results, 3 unique."
2. **Visibility filter** — `AND l.visibility = 'agent'` in the recall WHERE *and* the hit_count
   UPDATE subquery. Correctness fix (honors migration 009); stops leaking human-only rows to
   agents.
3. **Recalibrate** — failure boost `−5 → −1.5`; hit_count `−(l.hit_count*0.1)` →
   `−(min(l.hit_count,20)*0.05)`; keep recency `−1`. bm25 leads, type/popularity tie-break.
4. **Query hygiene** — strip ~30 stopwords + lone 1-char/single-digit tokens before MATCH.
5. **load_count** — preflight adds `load_count INTEGER DEFAULT 0` (same idempotent path as 009);
   read-start's four `hit_count = hit_count+1` blanket bumps move to `load_count`; **recall
   becomes the sole writer of hit_count.** This is mandatory, not optional — it's what makes
   A3's hit_count term trustworthy. Answers the Minimalist attack directly.

Validation gate before merge: capture `recall` output on 8–10 real cross-domain queries
before and after; diff manually. No errors are possible (ordering-only changes), so the eval is
"is the top of the list more relevant," judged by eye.

### OFFER AS A TOOL — opt-in, ~6–8 hours when wanted, guarded

6. **`scope` column** — preflight adds `scope TEXT DEFAULT 'project'`. Pure additive, safe.
   Backfill only the unambiguous case: rows whose insight starts with `[GLOBAL]` → `scope='global'`.
   Touch nothing else automatically.
7. **`agentdb recall --global`** — unions local + the global brain
   (`AGENTDB_GLOBAL_DB:-$HOME/Documents/Vaults/_meta/agentdb/agent.db`). Each DB rebuilds its own
   `learnings_fts`, results tagged `[local]`/`[global]`, merged, deduped (reuses #1), re-sorted,
   LIMIT 8. **OFF by default; silent local-only fallback** if global DB missing/locked.
   *Council fix:* name the switch — the NEXUS step-1b recall line is updated to pass `--global`
   in the SAME PR that adds the flag, so the unlock isn't dark. That's the "who flips it" answer.
8. **`agentdb promote <id>`** — copies one learning into the global brain, sets `scope='global'`.
   Manual, one at a time, human-judged. *Council fix:* prints the insight + asks the human to
   confirm it's genuinely generic before writing (no silent bulk promote → no new contamination
   vector).

### DEFER — until evidence justifies the risk

9. **`agentdb decontaminate`** — the 328-clone fleet cleanup. Build `--dry-run` FIRST (reports
   what it would lift/delete, writes nothing). The destructive `--apply` is a separate W8 ritual:
   backup path recorded, per-DB row counts before/after, idempotent, rollback plan in
   `_meta/plans/`. **Do not build `--apply` until `recall --global` has run for a while and shown
   the global brain is actually carrying useful cross-project signal.** Evidence before
   irreversible surgery — that's the whole reason it's deferred, not cut.
10. **porter tokenizer** (drop+recreate FTS, lossless) — isolated migration PR after #1–5 land.
11. **incremental FTS rebuild watermark** — premature at 501 rows; revisit past ~5k.
12. **embedding/semantic recall** — only if FTS + stemming + dedup + global demonstrably
    plateaus. Breaks no-heavy-deps; explicitly a separate bigger bet.

### Why this line and not Minimalist's or Maximalist's

- Minimalist alone leaves hit_count poisoned (no A5) and the 7 GLOBAL learnings stranded
  forever. The council's first two attacks on it are fatal to "declare victory."
- Maximalist's decontamination-as-automatic-step is disqualified by the hard constraint
  (irreversible surgery on live DBs that are hard to reconstruct, driven by a fuzzy classifier).
- The recommended split takes Maximalist's *destination* (real scope, a global brain, forward
  propagation) but reaches it through opt-in tools with human/dry-run gates, and makes the
  irreversible part contingent on evidence the cheap unlock (`--global`) generates first.

**The one non-negotiable upgrade over pure Minimalist:** A5 (load_count) ships in the now-bucket.
Without it the cheap recall fix is ranking on a signal that's still being corrupted every session.
