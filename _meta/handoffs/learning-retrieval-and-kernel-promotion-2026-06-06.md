# CONTEXT HANDOFF — kernel-claude retrieval pass + cascade (COMPLETE)
Generated: 2026-06-06 · Updated: 2026-06-06 (session 2 — shipped)

**Status: DONE.** v7.15.0 shipped, all three repos pushed + synced (0/0), plugin cache symlinked to source, 245/245 tests green, adversary PASS. This file now records what shipped + the deferred work for a future session.

---

## What shipped this session (v7.15.0)

**Retrieval quality pass** — `agentdb recall` (FTS5, added 7.14) had correctness + ranking holes, all fixed additively (verified on scratch copies of live DBs, no live data touched):
1. **Dedup** — recall returned duplicate insights (DBs carry many clones). Now over-fetches `LIMIT*5` ranked rows and dedups by 200-char insight key in awk. *bm25() cannot live inside GROUP BY/an aggregate — the optimizer flattens the subquery → "unable to use function bm25 in the requested context" — so dedup is post-query, not SQL.*
2. **Visibility filter** — recall leaked `human_only`/`operational` learnings to agents. Both FTS + LIKE paths now filter `visibility='agent'` (NULL=agent for pre-009 rows); feedback bump too.
3. **Recalibrated ranking** — failure boost was a −5 sledgehammer vs bm25's ~−0.5..−8 range. Now failure/gotcha −1.5, `MIN(hit_count,20)*0.05` (capped), recency −0.5. Relevance leads.
4. **hit_count split** — read-start blanket-bumped hit_count on every dumped row each session, poisoning the signal recall ranks on. New `load_count` column (migration 013, preflight-owned like 009) takes the session-open telemetry. **hit_count is now earned only via recall** = trustworthy "answered a real task" signal.
5. **Query hygiene** — strip 1-char tokens + stopwords, raw-terms fallback.

**Rule promotion** — universal **"Done = verified live, not committed"** rule promoted to the shared layer:
- NEXUS: `Vaults/.claude/rules/invariants.md` → new **Verification** invariant (committed + pushed in Vaults repo).
- KERNEL plugin: `hooks/scripts/session-start.sh` SHIP step + `<rule>` (the ONLY delivery path for plugin users — CLAUDE.md is not loaded for them), plus a CLAUDE.md anti-pattern for source-of-truth.
- The "always push immediately" half was independently hardened in I0.8 + NEXUS session-flow (linter/user edit this session).

**Version + distribution**
- 7.14.0 → 7.15.0 across all canonical declarations (`scripts/bump-version.sh`; `test_version_sync_all` green) + AGENTS.md (manual) + description highlight + CHANGELOG.
- Plugin cache synced: `~/.claude/plugins/cache/kernel-marketplace/kernel/7.15.0` → symlink to source, `current` → 7.15.0 (7.14.0 real dir kept as backup). `agentdb` CLI was already symlinked via `~/.local/bin` so retrieval fixes were live immediately.

## Source analysis (in `_meta/reports/`)
- `retro-agentdbs.md` — cross-DB retrospective (5 live DBs). **The headline rot: 73% of distinct insights (328/452) are clones across ALL 5 project DBs** (ariacam stores FunJoin camp rules). hit_count poisoned. FTS in only 1 of 5 DBs (self-heals on preflight).
- `retrieval-deepdive.md` — recall code analysis + ranked fixes.
- `dream-retrieval.md` — minimalist/maximalist/pragmatist + council; the ship/offer/defer split below.

## Medium content (Aria's own writing) that backed the design
`structured-metadata-beats-rag.md` (Vercel 100% vs 53% RAG), `stop-writing-markdown-start-writing-memory.md` (ambient > retrieval), `self-learning-agentic-system.md` (evidence-gating, hit-count signal), `knowledge-base-decay.md` (consistency linting). NOTE: a draft idea to "deprecate multi-agent orchestration" was **explicitly NOT acted on** — speculative + would regress core kernel functionality.

---

## DEFERRED — next session (the structural unlock, intentionally not shipped)

The dream's verdict: code that cascades safely ships now; anything touching live rows is opt-in with a dry-run or human gate; irreversible fleet surgery waits until the cheap unlock proves the global brain is worth it. Deferred, in order:

1. **`scope` column** (project | global) — additive, safe. Backfill only the unambiguous `[GLOBAL]`-prefixed rows. Makes cross-project filtering queryable instead of a string prefix.
2. **`recall --global`** — unions local + a shared brain DB (`~/Documents/Vaults/_meta/agentdb/agent.db`, confirmed exists), off by default, silent local-only fallback. The real structural unlock for the siloing problem. *Wire the `--global` flag into NEXUS step-1b in the SAME change so it isn't dark.* Caveat: only 7 GLOBAL learnings exist today → would ship near-empty until the brain is populated. Populate first (via #1 promote), then enable.
3. **`agentdb promote <id>`** — manual, one-at-a-time, human-confirmed lift of a generic lesson to the global brain.
4. **`agentdb decontaminate --dry-run`** — writes nothing; reports the 328 clones. The destructive `--apply` is a separate W8 ritual (backup + rollback) and **must not be built until `--global` proves the global brain carries signal.**
5. **Porter tokenizer** (isolated migration: drop+recreate FTS, lossless since external-content) — fixes stemming (deploy≠deploys). Own PR.
6. **Capture-side quality**: failures/gotchas are 0.2–1.2% of rows (93–99% is "pattern") — the high-value bucket is nearly empty. Worth nudging the `learn` flow to capture more failures/gotchas.

## Dormant bugs (adversary-found, zero current incidence — note only)
- recall dedup key is a 200-char prefix; two genuinely distinct lessons sharing a 200-char head would false-merge (0 real cases today; was 60 chars, hardened to 200).
- A literal 0x1F (US char) inside an insight would corrupt the awk-split output line (0 real rows contain it).

## Warnings (still apply)
- **NEVER add FTS sync triggers** to learnings — aborts `learn` on SQLite 3.43. rebuild-on-recall is the design.
- agentdb is shared infra — keep additive; test on a scratch copy (`AGENTDB_ROOT=/tmp/x`) before any live DB.
- 9 GitHub dependabot alerts on kernel-claude (2 high, 6 moderate, 1 low) — surfaced on push, unrelated to this work; worth a look.
