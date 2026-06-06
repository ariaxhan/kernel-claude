---
title: AgentDB Retrieval Deep-Dive + Additive Improvement Plan
date: 2026-06-06
scope: orchestration/agentdb (recall, read-start, FTS5 index)
status: analysis — no code written yet
constraints: NO FTS sync triggers · additive only · bash + sqlite3 only
db_state: 501 learnings in kernel-claude/_meta/agentdb/agent.db, 7 tagged global
---

# AgentDB Retrieval Deep-Dive

## 0. System as it stands (ground truth from the source)

- **Schema** (`schema.sql:11`): `learnings(id, ts, type, insight, evidence, domain, hit_count, last_hit, visibility, sensitivity)`. `type` ∈ failure|pattern|gotcha|preference. `visibility` ∈ agent|human_only|operational. B-tree indexes on type, domain, visibility.
- **FTS index** (`migrations/012_learnings_fts.sql`): external-content FTS5 `learnings_fts(insight, evidence, domain)`, `content='learnings'`, `content_rowid='rowid'`. **No `tokenize=` clause → defaults to `unicode61`** (lowercases, strips diacritics, splits on non-alphanumeric, no stemming). No sync triggers by design — `recall` runs `INSERT INTO learnings_fts(learnings_fts) VALUES('rebuild')` before every query.
- **recall** (`agentdb:1427`): lowercase query → keep `[a-z0-9]` → quote each token → OR them → `MATCH` → order by a bm25-minus-boosts formula → LIMIT 8. Bumps hit_count on surfaced rows.
- **read-start** (`agentdb:301`): four modes. Default `--weighted` dumps top-75 by an additive `hit_count*10 + failure_bonus + recency` score, then blanket-bumps hit_count on all 75. No task awareness.
- **learn** (`agentdb:444`): dedup via `insight LIKE '%<first 40 chars>%' AND type=` → reinforce or insert. domain auto-inferred from `basename $PWD`.

---

## 1. How recall ranks today — the formula and its failure modes

```sql
ORDER BY (
  bm25(learnings_fts)
  - (CASE WHEN l.type IN ('failure','gotcha') THEN 5 ELSE 0 END)
  - (l.hit_count * 0.1)
  - (CASE WHEN julianday('now') - julianday(l.ts) < 14 THEN 1 ELSE 0 END)
) ASC
```

bm25 in SQLite returns a **negative** score where more-negative = more relevant (default magnitudes for short docs typically land in roughly the −0.5 to −8 range). Lower sorts first, so subtracting the boosts (pushing the score more negative) ranks boosted rows earlier. The intent is right. The magnitudes are the problem.

**Are weights 5 / 0.1 / 1 sane? Mostly no — they're guessed, not calibrated against bm25's actual scale.**

- **failure bonus = −5** is *enormous* relative to bm25. A failure/gotcha that barely matches one rare term (bm25 ≈ −1.5) beats a pattern that's a near-perfect multi-term match (bm25 ≈ −5) → final −6.5 vs −5. So a marginally-relevant failure outranks a highly-relevant pattern. Given ~60%+ of useful learnings are failures/gotchas, this means **type, not relevance, often decides the top of the list.** That's arguably acceptable as a deliberate "failures-first" thumb on the scale, but at −5 it's a sledgehammer, not a thumb.
- **hit_count × 0.1** is a slow rich-get-richer loop. Every recall bumps surfaced rows; over time popular learnings accrue hit_count and float up *regardless of query*. At hit_count=50 that's −5, equal to the failure bonus — a stale-but-popular learning can dominate a query it only weakly matches. This is the same age/popularity bias 012's comment criticized read-start for, leaking into recall.
- **recency < 14d = −1** is small and fine; it just nudges fresh learnings up a notch.

**The all-OR matching is the bigger ranking problem.** Query `cloudflare pages deploy timeout` becomes `"cloudflare" OR "pages" OR "deploy" OR "timeout"`. A learning matching only the common word "pages" gets returned and bm25-scored. bm25 does down-weight common terms via IDF, so a rare-term single match (e.g. only "timeout") scores *better* than a common-term single match — but it still floods the candidate set with junk that only shares one stopword-ish token, and there is **no AND requirement and no phrase/proximity boost** for documents that match *several* of the query terms together. The doc that matches 3 of 4 terms is not structurally preferred over the one matching 1 rare term.

**Filename matching is effectively dead.** NEXUS step 1b passes "task keywords + touched filenames" (e.g. `cmd_recall.sh agentdb retrieval`). Filenames rarely appear verbatim inside `insight`/`evidence`/`domain` text, and even when they do, `unicode61` splits `cmd_recall.sh` into `cmd`, `recall`, `sh` — so the dotted/underscored token never matches as a unit. Filenames contribute near-zero signal today.

---

## 2. Query construction problems

`fts_query` = lowercase → `tr -cs 'a-z0-9' ' '` → each token phrase-quoted → joined with ` OR `.

1. **No AND / no multi-term boost.** Pure OR. A doc hitting one term ranks alongside one hitting all of them (bm25 helps but doesn't enforce). Should at minimum *boost* docs matching more terms.
2. **No stopword removal.** "the", "a", "to", "is", "error" all become MATCH terms. Common terms inflate the candidate set and dilute ranking. (bm25 IDF partly compensates, but the candidate explosion still hurts the LIMIT-8 cutoff.)
3. **Filenames can't match** (see §1). The split on non-alphanumeric shatters `foo_bar.ts` and the pieces are too generic.
4. **Single-char / numeric noise.** `tr -cs 'a-z0-9'` keeps lone digits and single letters as their own quoted terms (`"5"`, `"v"`), which match noisily.
5. **No domain/scope filter.** recall never restricts to the current `domain`, so a query in project A surfaces project A's learnings only because they're the only ones in that DB — not by design. Cross-domain precision is unmanaged.
6. **recall does NOT filter `visibility`.** `human_only` and `operational` learnings are returned to agents by recall, even though 009's whole point is that those should be hidden from agent recall. read-start's modes don't filter visibility either, but recall is the one wired into the agent ingest loop — this is a real correctness gap, not just quality.

---

## 3. What FTS indexes + tokenizer

- **Columns indexed: `insight, evidence, domain`** — all three, good. (Not `type`, `ts`, `hit_count` — correct, those are structured filters, not text.)
- **Tokenizer: `unicode61` (default, no `tokenize=` given).** Pros: lowercasing + diacritic folding for free. Cons for *this* corpus:
  - **No stemming** → "deploys" ≠ "deploy", "caching" ≠ "cache", "timed out" ≠ "timeout". A `porter` tokenizer would fix the morphological misses, which are common in natural-language insights.
  - **Hard splits on `.`, `_`, `-`, `/`** → code tokens and filenames fragment. `n+1`, `cmd_recall`, `wrangler.toml`, `useEffect` (camelCase is *not* split by unicode61, so `useEffect` stays whole — actually fine) all lose meaning. The dotted/underscored/slashed ones are the casualties.
  - `trigram` tokenizer would make filename/code-substring matching work (and enable LIKE-style partials) but balloons index size and changes bm25 behavior — too invasive to swap on a shared live index.

Net: `unicode61` is a reasonable default but it's the worst fit exactly for the "touched filenames" signal NEXUS feeds it. `porter` (built on unicode61) is a low-cost upgrade for the natural-language half.

---

## 4. rebuild-on-recall cost

`INSERT INTO learnings_fts(learnings_fts) VALUES('rebuild')` re-tokenizes **every row** on **every recall**. It's O(N).

- At 501 rows: a few ms. Genuinely fine.
- The cost scales with corpus size *and* recall frequency. NEXUS step 1b says "do it for every non-trivial task" → recall runs many times per session. At ~5–10k learnings (plausible after a year across a busy project, or after a cross-DB union), full rebuild on every call becomes tens-to-hundreds of ms each, and you're re-tokenizing the entire corpus to answer one 8-row query. That's wasteful but not yet painful.
- **Inflection point:** ~5k rows OR recall-in-a-tight-loop. Below that, leave it alone — premature optimization. The fix when it matters is incremental: track a "last rebuilt" watermark (max rowid or a stored count) and only `rebuild` when learnings changed since last recall. Cheap, additive, deferrable.

---

## 5. The siloing problem (cross-project recall)

Each project has its own `_meta/agentdb/agent.db`. `find_project_root` walks up to the nearest `_meta`/`.claude`. `[GLOBAL]`-tagged learnings (7 of them here) live in whatever DB they were written to and **cannot cross project boundaries**. There is **no cross-DB recall today** — recall only ever touches the one resolved `$DB`.

This is the single biggest *structural* retrieval gap: a hard-won failure learned in `our4cuts` is invisible when working in `modelmind`, even if it's a generic SQLite/Cloudflare/bash gotcha.

**Additive fix (no schema change, no regression):** add an opt-in `--global` flag (or `AGENTDB_GLOBAL_DB` env) that, after the local recall, runs the same FTS query against a designated global DB and merges results. SQLite `ATTACH DATABASE` makes this a one-liner per query — but FTS `MATCH` across attached DBs needs the attached DB to have its own `learnings_fts`, so the clean approach is: run recall twice (local + global), tag each result with its source, dedup by insight, merge by score. Keep it **off by default** so existing behavior is untouched; the ingest loop opts in. Designating the global DB: a stable path like `~/Documents/Vaults/_meta/agentdb/agent.db` (the `_meta` brain) or a new `AGENTDB_GLOBAL_DB` env var.

---

## 6. Dedup at retrieval time

recall returns N copies if the table has N copies. The learn-time dedup (`insight LIKE '%<first 40>%'`) is weak — paraphrases, different first-40-chars, or cross-DB duplicates all slip through, and there are already near-dupes in real DBs. recall has **zero** dedup.

**Additive fix:** `GROUP BY l.insight` (or a normalized key) in the recall SELECT, taking `MIN(score)` / `MAX(hit_count)`. Pure presentation-layer change, no schema impact, no write-path impact. Collapses exact-insight dupes immediately. For near-dupes, group on `lower(substr(insight,1,60))` as a cheap normalization. This is the highest value-per-effort change in the whole report.

---

## 7. read-start vs recall

read-start has no task at session start, so it *can't* do query-relevance recall — there's nothing to match against. Its blanket top-75 dump + blanket hit_count bump is the right shape for "cold start, no query," but the **blanket bump is a known pollutant**: it inflates hit_count on 75 rows every single session start regardless of whether they were used, which then feeds the `hit_count × 0.1` term in recall's ranking → systematic popularity bias toward whatever happened to be top-75 historically. The 012 comment already flags this as deferred cleanup.

**The real answer:** read-start should *stop* bumping hit_count (or bump a separate `load_count` column), and let **recall** be the only thing that increments hit_count — because recall bumps are the only ones that reflect actual query relevance. That decouples "shown at session start" from "proven relevant to a real task." This is the cleanest way to make hit_count a trustworthy ranking signal again. (Additive: add `load_count` column via preflight, move read-start's bump there; recall keeps owning hit_count.)

read-start could *optionally* read the active task from `_meta/context/active.md` (which `cmd_active` already maintains: it has a `task:` line) and, if present, run a recall-style relevance pass as a fifth section. That turns "cold start" into "warm start" when a task is known. Nice-to-have, medium effort.

---

# Improvement Plan — prioritized

## SAFE ADDITIVE WINS (do these)

### A1. Dedup recall results by insight  ★ top pick
- **What:** collapse duplicate/near-duplicate insights in recall output.
- **Sketch:** wrap the SELECT — `GROUP BY lower(substr(l.insight,1,60))` keeping `MIN(<score_expr>)` for ordering and one representative row. Or `SELECT DISTINCT` on insight if you only care about exact dupes.
- **Risk/regression:** presentation-only; no schema, no write path. Risk that GROUP BY picks a non-deterministic evidence snippet — pin with `MIN(l.evidence)` or an aggregate. Low.
- **Effort:** S.
- **Gain:** High. Immediately stops the "8 results, 3 unique" failure. Especially big once cross-DB union (B1) lands.

### A2. Filter visibility in recall  ★ correctness, not just quality
- **What:** add `AND l.visibility = 'agent'` to the recall WHERE. Honors migration 009's contract that human_only/operational are hidden from agent recall.
- **Sketch:** one clause in the WHERE of both the SELECT and the hit_count UPDATE subquery.
- **Risk/regression:** could hide learnings someone expected to see — but 009 explicitly says that's correct behavior. Low.
- **Effort:** S.
- **Gain:** Medium (correctness fix; prevents leaking human-only/audit notes into agent context).

### A3. Recalibrate the boost weights
- **What:** shrink the failure bonus, cap/curve the hit_count term, so bm25 relevance leads and boosts tie-break.
- **Sketch:** failure bonus `−5 → −1.5`; hit_count term `−(l.hit_count*0.1)` → `−(min(l.hit_count,20)*0.05)` (cap the rich-get-richer at −1.0); keep recency −1. Net: relevance dominates, type/popularity become tie-breakers.
- **Risk/regression:** changes result ordering for everyone — but strictly toward more-relevant results; no errors possible. Validate by eyeballing recall output on 5–10 real queries before/after. Low-medium.
- **Effort:** S.
- **Gain:** High. This is the core "recall returns the *right* thing" fix.

### A4. Query hygiene: stopwords + drop 1-char tokens + multi-term boost
- **What:** strip a small stopword list and lone single chars before building the MATCH; reward docs that match more query terms.
- **Sketch:** in the awk/tr pipeline, filter a ~30-word stopword set and tokens of length 1. For multi-term boost, the cheapest approach in pure SQL: add `+ (number of distinct query terms matched)` is hard without per-term MATCH; pragmatic alt — keep OR for recall but also run the full phrase as a quoted bonus term and `-2` any row matching it. Lowest-risk subset: just stopwords + drop-1-char now, defer multi-term boost.
- **Risk/regression:** stopword list must be conservative (don't strip domain words). Low if list is tiny.
- **Effort:** S (stopwords) / M (multi-term boost).
- **Gain:** Medium. Cleaner candidate set, less flooding.

### A5. Stop read-start from polluting hit_count
- **What:** add `load_count` column (preflight, like 009 did), move read-start's blanket bump to `load_count`, leave hit_count owned solely by recall.
- **Sketch:** preflight Check 3 adds `load_count INTEGER DEFAULT 0`. read-start's four `UPDATE ... SET hit_count = hit_count+1` become `load_count = load_count+1`. recall unchanged.
- **Risk/regression:** additive column via the existing self-healing preflight path (proven pattern). Existing hit_count values stay; they just stop inflating from session starts. Low.
- **Effort:** M (touches 4 read-start branches + preflight).
- **Gain:** Medium-high. Makes hit_count a real relevance signal, which compounds A3.

### A6. Switch FTS tokenizer to porter (stemming)
- **What:** `tokenize='porter unicode61'` so deploy/deploys/deployed and cache/caching collapse.
- **Sketch:** **cannot ALTER an FTS tokenizer in place.** Additive path: new migration drops+recreates `learnings_fts` with porter and runs `rebuild`. Because it's external-content (stores no text, just rowid pointers), drop+recreate is cheap and lossless — the source `learnings` table is untouched. Idempotent guard like 012.
- **Risk/regression:** any DB mid-recall during the migration is fine (recall self-heals/rebuilds). Changes match results (more recall, slightly less precision) — generally a win for NL insights. Medium (it's a live-index swap across many DBs, but the data is regenerable).
- **Effort:** M.
- **Gain:** Medium. Fixes the morphology misses that silently drop relevant learnings.

## BIGGER BETS (flag, decide later)

### B1. Cross-DB / global recall  ★ biggest structural gain
- **What:** opt-in `agentdb recall --global` (or `AGENTDB_GLOBAL_DB` env) that unions the local DB's results with a designated global brain DB.
- **Sketch:** resolve `GLOBAL_DB=${AGENTDB_GLOBAL_DB:-$HOME/Documents/Vaults/_meta/agentdb/agent.db}`. Run the existing recall query against `$DB`, then again against `$GLOBAL_DB` (each has its own `learnings_fts`; rebuild each), tag rows `[local]`/`[global]`, merge, dedup (A1), re-sort by score, LIMIT. Off by default — existing single-DB behavior unchanged.
- **Risk/regression:** global DB may be missing/locked → must degrade to local-only silently (fallback-first). Path resolution is the foot-gun (the CLAUDE.md "VaultsS typo orphan" lesson). Keep it strictly opt-in. Medium-high.
- **Effort:** M-L.
- **Gain:** High. Unlocks the 7 `[GLOBAL]` learnings + every generic gotcha across projects. This is what "siloing" was costing.

### B2. Incremental FTS rebuild (watermark)
- **What:** only `rebuild` when learnings changed since last recall.
- **Sketch:** store `MAX(rowid)`+`COUNT(*)` (or a learn-time counter) in a tiny `_fts_state` row; recall compares, rebuilds only on change. Or use FTS5 incremental `'rebuild'`-free delete+insert by diffing rowids.
- **Risk/regression:** stale index if the watermark logic misses an edit path (e.g. the learn-time reinforce UPDATE changes text? it doesn't — only hit_count). Verify all text-mutating paths bump the watermark. Medium.
- **Effort:** M.
- **Gain:** Low *now* (501 rows = few ms), High *later* (>5k rows or tight recall loops). Defer until §4's inflection point.

### B3. Semantic / embedding recall
- **What:** vector recall to catch paraphrase misses FTS can't (e.g. "auth token expired" ↔ "credential rotation needed").
- **Sketch:** would need embeddings + a vector store. Pure-sqlite option: `sqlite-vec` extension (no external service, but a new C extension dependency — flag it). Embedding generation needs a model call (local or API). This breaks the "bash + sqlite3 only, no heavy deps" constraint → explicitly a bigger bet.
- **Risk/regression:** new dependency, new failure surface, embedding drift. High.
- **Effort:** L.
- **Gain:** High ceiling, but only worth it after A1–A6 + B1 are exhausted. FTS5 + stemming + dedup + global gets most of the way.

### B4. Warm-start read-start from active.md
- **What:** if `_meta/context/active.md` has a `task:`, run a relevance pass in read-start.
- **Sketch:** read the `task:` line, feed it to the recall pipeline as a 5th "## Relevant to current task" section.
- **Risk/regression:** active.md may be stale/missing → guard and skip. Low-medium.
- **Effort:** M.
- **Gain:** Medium. Turns cold session starts warm when a task is already known.

---

# Recommended sequence

1. **A1 (dedup)** + **A2 (visibility)** + **A3 (recalibrate)** — one small PR, all presentation/ordering, biggest quality jump per line changed.
2. **A4 stopwords** + **A5 load_count** — second PR, cleans the inputs and the popularity signal.
3. **A6 porter** — its own migration PR (live-index swap, isolate it).
4. **B1 global recall** — the structural unlock, opt-in, its own PR.
5. **B2 / B4** when the corpus grows or warm-start is wanted. **B3** only if FTS-based recall demonstrably plateaus.
