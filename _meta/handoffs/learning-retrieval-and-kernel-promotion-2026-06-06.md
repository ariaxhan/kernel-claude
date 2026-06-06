# CONTEXT HANDOFF — kernel-claude wrap-up + cascade
Generated: 2026-06-06

**Summary**: Learning-retrieval upgrade (`agentdb recall`, FTS5) is built and live locally but unpushed; next window pushes it + promotes the session's universal lessons from our4cuts-specific config into the kernel/NEXUS shared layer so they cascade to every project.

**Goal**: The kernel plugin is used everywhere (installed via symlink → `kernel-claude/orchestration/agentdb/agentdb`). Put the cross-project improvements IN the plugin / NEXUS layer, push them, so all repos inherit them — instead of re-encoding per project.

**Current state**: Work done + committed locally across 3 repos, NOT pushed (I0.8 needs say-so for non-our4cuts main; Aria now wants them pushed per this handoff's request).

**Branches** (all `main`):
- `our4cuts` — clean, **fully pushed** (origin even). Nothing to do.
- `kernel-claude` — **5 commits ahead of origin**, unpushed. Head = `13685c4` (the recall feature).
- `Vaults` — **29 commits ahead of origin**, unpushed. Head = `e13f0a5` (NEXUS ingest wiring).

**Tier**: 2–3 (shared infra, cross-repo).

---

## What shipped this session (context)

**our4cuts (all live + verified on prod):** church→event revert (migration 0020) + admin venue/event toggle (`/api/admin/client-type`); venues get an admin-only board; admin frame-card thumbnails; iPad pixel-bake filters; Spanish booth i18n (es.json); consent links to Terms/Privacy; two new global frames Hearts+Clouds (portrait staggered); `validate-frames.sh` pre-commit hook; CLAUDE.md rules encoded.

**Cross-project (the cascade work — THIS is the focus):**
- `kernel-claude` `13685c4`: **`agentdb recall <keywords>`** — FTS5 relevance retrieval. Migration `012_learnings_fts.sql` (external-content FTS, **no triggers**), `cmd_recall` (bm25 + failure/recency/hit boosts, self-heals index, rebuild-on-query, bumps hit_count only on matched rows). Tested pos+neg on a scratch copy of a 544-learning DB. Applied to our4cuts' live DB already (544 rows indexed).
- `Vaults` `e13f0a5`: NEXUS ambient-ingest step **1b** now calls `agentdb recall` per task.

## Decisions made (+ rejected alternatives)
- **Relevance recall over fixing read-start** — read-start can't be task-aware (no task at session start); `recall` is the just-in-time lookup. Kept read-start as the generic startup dump.
- **No FTS sync triggers** (REJECTED, critical): SQLite 3.43 throws "unsafe use of virtual table" on trigger writes to an FTS vtab and **ABORTS the `learn` insert** — would break the core learn path everywhere. Chose `rebuild`-on-recall instead (O(N), few ms). *Verified the abort on scratch before any live DB touched.*
- **hit_count blanket-bump in read-start left in place** (deferred): minimized blast radius. recall now provides the real relevance signal (ranks bm25-first), so stale hit_count no longer dominates. Cleanup is optional, see next steps.
- Purely additive to agentdb — existing commands unchanged/retested.

## Artifacts
- `kernel-claude/orchestration/agentdb/agentdb` — `cmd_recall` + dispatch + usage.
- `kernel-claude/orchestration/agentdb/migrations/012_learnings_fts.sql`
- `Vaults/.claude/CLAUDE.md` — ingest step 1b.
- `our4cuts/.claude/hooks/{validate-frames,pre-commit}.sh`, `our4cuts/.claude/CLAUDE.md` (our4cuts-only, already pushed).

## Big 5
- Input validation ✓ (recall sanitizes query → phrase-quoted FTS terms, injection-safe)
- Edge cases ✓ (empty query, no-FTS DB self-heal, LIKE fallback, no matches)
- Error handling ✓ (`|| true` on rebuild, graceful fallback)
- Duplication ✓ (recall reuses run_pending_migrations; no copy)
- Complexity ✓ (additive, ~60 lines)

## Next steps (for the new window)
1. **Push** `kernel-claude` (origin/main, 5 ahead) and `Vaults` (origin/main, 29 ahead). This is the cascade — other machines + plugin marketplace get recall.
2. **Promote universal lessons into the shared layer** (currently only in `our4cuts/.claude/CLAUDE.md`, but they apply to EVERY project):
   - **"Done = LIVE, not committed"** (verify-deploy + curl live URL before claiming done) → belongs in NEXUS (`Vaults/.claude/CLAUDE.md`) or KERNEL invariants.
   - Consider an invariant: "report 'done' only after a verification command, not a commit."
3. **Optional**: fix the `read-start` blanket `hit_count` bump (4 modes in `cmd_read_start`) now that recall is the real signal — makes hit_count purely recall-driven. Test on a scratch DB first.
4. The plugin cache copy (`~/.claude/plugins/.../7.14.0/orchestration/agentdb/agentdb`) is a separate distribution from the symlinked source — confirm whether the marketplace version needs a version bump/sync after push.

## Warnings
- **NEVER add FTS sync triggers** to learnings — aborts `learn` on SQLite 3.43. rebuild-on-recall is the chosen design.
- agentdb is shared infra — keep changes additive; test on a scratch copy (`AGENTDB_ROOT=/tmp/x`) before any live DB.
- our4cuts auto-pushes (Cloudflare); kernel-claude/Vaults do NOT — they need explicit push.

## Continuation prompt
> /kernel:ingest push kernel-claude + Vaults to origin/main, then promote the "Done = LIVE not committed" rule + relevance-recall from our4cuts-specific config into the NEXUS/kernel shared layer so all projects inherit them. Read kernel-claude/_meta/handoffs/learning-retrieval-and-kernel-promotion-2026-06-06.md first. Don't re-add FTS triggers.
