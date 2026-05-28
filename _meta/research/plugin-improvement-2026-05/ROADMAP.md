---
name: plugin-improvement-roadmap
description: Merged, deduped, prioritized improvement roadmap for the kernel-claude plugin (v7.13.0). Synthesizes six investigation lenses. Hard constraint: real users already run the plugin; non-disruption is required.
type: reference
date: 2026-05-28
sources:
  - _meta/research/plugin-improvement-2026-05/budget-validation.md
  - _meta/research/plugin-improvement-2026-05/db-audit.md
  - _meta/research/plugin-improvement-2026-05/research-mining.md
  - _meta/research/plugin-improvement-2026-05/email-intel.md
  - _meta/research/plugin-improvement-2026-05/git-sync-design.md
  - _meta/research/plugin-improvement-2026-05/cross-repo-patterns.md
---

# kernel-claude Plugin Improvement Roadmap — 2026-05-28

## Executive Summary

Six investigation lenses (budget, DB correctness, research mining, email-automation
signals, git-sync design, cross-repo patterns) converged on three high-leverage themes
and one urgent bug class.

**The urgent bug class is database migration drift.** It surfaced independently in two
lenses (db-audit AND cross-repo-patterns) and is confirmed against the live DB: migrations
005/008/009 are on disk but unrecorded in `_migrations`, the `execution_traces` table is
missing entirely, and the migration runner is dead code for any user who already has a DB.
This ships broken behavior to every existing user right now — `agentdb trace` silently
fails, and preflight nags forever. This is separated below as **CRITICAL DB FIXES** and
should ship before any enhancement.

**The three convergent enhancement themes:**

1. **Uncommitted-work / git-sync UX** (email-intel P1 + git-sync-design + cross-repo our4cuts).
   The Midday Pulse automation flags dirty-on-main repos daily; users want a one-command save
   and an ambient dirty-state nudge. Fully designed, fully opt-in, zero disruption.
2. **AgentDB as a queryable data source** (email-intel P2-P6 + research-mining 12/15).
   Automations are already treating agentdb as an external API but the surface is fragile
   (no JSON mode, no stable path, no env override, silent path-typo failures). Additive flags
   and a `doctor` subcommand fix this.
3. **Honor-system invariants that should be hooks** (research-mining 3/5/9 + cross-repo 7).
   I0.15 says critical safety lives in hooks, not CLAUDE.md sentences. Several invariants
   (commit-before-move, no-AI-attribution, code-vuln scanning, plugin registration) are still
   honor-system. Each is a small, additive, warn-first hook.

**Budget verdict:** line-count is the wrong axis. The correct distinction is always-loaded
(CLAUDE.md) vs on-demand (commands/agents/skills). Caps below. CLAUDE.md at 308L should be
trimmed to <=250L for adherence, not for token exhaustion.

**Non-disruption posture:** every roadmap item below carries an explicit
`won't disrupt existing users` verification. The only items that change observable behavior
for a do-nothing user are: (a) the migration runner switching from WARN to APPLY (intended
self-heal, tested on a DB copy first), (b) one new PreToolUse commit-message guard hook that
only fires on placeholder messages, and (c) compact-at-60% which triggers compaction earlier.
All three are net-positive and reversible.

---

## CRITICAL DB FIXES (ship first — correctness bugs in front of real users)

These are not enhancements. They are correctness bugs confirmed on the live DB
(`_meta/agentdb/agent.db`, created 2026-03-25). Fix order matters: patch idempotency
BEFORE flipping the runner to apply, or the apply loop will error on 007/008.

| # | Severity | Bug | Fix | Tier | Disrupts? |
|---|----------|-----|-----|------|-----------|
| D1 | critical | Pending migrations never applied on existing DBs. `cmd_init`'s migration loop fires only when `[ ! -f "$DB" ]`; `cmd_preflight` Check 4 warns but never applies. 005/008/009 unrecorded; `execution_traces` table absent → `agentdb trace` silently fails. | Extract migration loop from `cmd_init` into `run_pending_migrations()`; call it from `cmd_preflight` Check 4 (WARN→APPLY). Test on a copy of the live DB first. | 2 | Behavior changes from warn to self-heal — intended, tested on copy |
| D2 | high | Migration 008 raw `ALTER TABLE errors ADD COLUMN domain` errors with "duplicate column" on re-run (no `IF NOT EXISTS` in SQLite). Will break the moment D1 ships. | Convert 008 to marker-only (matches 009 pattern); add preflight Check 3b that PRAGMA-gates the `errors.domain` add. | 1 | No — pre-deploy fix |
| D3 | high | Migration 007 bare `INSERT INTO _migrations` (no `OR IGNORE`) → UNIQUE constraint error on double-apply. Latent bomb under D1. | Change to `INSERT OR IGNORE`. | 1 | No |
| D4 | high | `init.sh` runs `schema.sql` raw, never calls `agentdb init` → users bootstrapping via init.sh never get migrations 002-009. | Replace raw `sqlite3 < schema.sql` with `(cd "$PROJECT" && agentdb init)`. | 1 | No — fixes a broken onboarding path |
| D5 | high | Live DB: 005 marker absent AND `execution_traces` table absent. | Backfill markers (005/008/009) + re-run 005 (`CREATE TABLE IF NOT EXISTS`, safe). One-time repair. | 1 | No — repairs current breakage |
| D6 | medium | `CURRENT_TIMESTAMP` vs `strftime` timestamp drift; old `errors`/`learnings` rows lack ISO-8601/Z format, break lexicographic sort. | Migration 010: `UPDATE ... SET ts = strftime(...) WHERE ts NOT LIKE '%Z'`. | 1 | No — additive migration |
| D7 | medium | `sync_log` phantom table — no migration, no code references. | Migration 011: `DROP TABLE IF EXISTS sync_log`. | 1 | No |
| D8 | low | `cmd_preflight` Check 2 `break` short-circuits multi-table repair. | Remove `break`; let loop complete all tables. | 1 | No |
| D9 | low | `find_project_root` falls back to `$PWD` silently → orphan DBs (also root cause of the email-intel "VaultsS" typo orphan). | Guard: if root==PWD and neither `_meta` nor `.claude` present, warn + exit 1. Pair with `AGENTDB_ROOT` env override (see R7). | 1 | No — additive guard |

Bundled correctness bugs surfaced by research-mining (ship with nearest item):
- `hooks/scripts/capture-error.sh` uses `.tool`; official PostToolUse schema field is `.tool_name`. Fix with R3.
- `hooks/scripts/guard-bash.sh` regex `.*(-f|--force)` matches `-f` inside branch names like `fix/`/`fallback/`, blocking legit pushes. Standalone ~2L fix.

---

## Budget Verdict

**Line-count is a poor proxy. The real axis is loaded-vs-reference.** CLAUDE.md loads in full
every session with no eviction; commands/agents/skills load only when invoked (zero cost
otherwise). Enforcing one cap across both is a category error. At 308L (~2K tokens) CLAUDE.md
is not a token-exhaustion problem on a 1M window — it's an **adherence** problem (official docs:
"bloated CLAUDE.md files cause Claude to ignore your actual instructions"; target <200L).

Three sources currently disagree because they encode different eras/intents:
- Vault CLAUDE.md table (120L/80L) references `hooks/budget-check.sh` — **a file that does not
  exist on disk.** Unenforced documentation artefact.
- `token-budget-quick-reference.md` (300/250/300/350) — research-era recommendations, pre-dating
  commands-as-workflow-documents.
- `tests/run-tests.sh` (400/1000/250) — the only actual enforcer; reflects current reality.

**Recommended single source of truth = `tests/run-tests.sh`, updated to:**

| File class | Load pattern | Recommended cap | Current test cap | Action |
|------------|-------------|-----------------|------------------|--------|
| Root CLAUDE.md | every session | **250L hard** | 400L | tighten |
| Commands | on invoke | **1000L hard** | 1000L | keep (landing-page 923L is fine) |
| Agents | on spawn | **300L hard** | 250L | loosen |
| Skills (SKILL.md) | on invoke | **400L warn** | none | add test |

Then: update `token-budget-quick-reference.md` with these numbers + a loaded-vs-reference
column, and mark the Vault CLAUDE.md cap table as "(hook not yet built — unenforced)" or
remove it. Trim CLAUDE.md 308→<=250 by cutting anti-pattern blocks that duplicate I0, the agent
description table (duplicates `agents/*.md`), and the `<lsp>` section (already in reference).

---

## Prioritized Enhancement Roadmap

Cross-cutting dedupe notes:
- **Uncommitted-on-main** appears in email-intel (P1) AND git-sync-design — merged into R5 (nudge)
  + R6 (save/pull). They compose: R5 surfaces the dirty state, R6 resolves it.
- **DB path resolution** appears in email-intel (P2) AND db-audit (D9) — merged into R7.
- **Migration drift** appears in db-audit AND cross-repo-patterns — promoted to CRITICAL above.
- **PostToolUse domain validation / session-end validator** appears in cross-repo (5,7) and
  pairs with research-mining's vuln scan (3) — grouped as R3 + R12.

| # | Title | Lens | Tier | Risk | Disrupts? | Won't-disrupt verification | Rationale |
|---|-------|------|------|------|-----------|---------------------------|-----------|
| R1 | Cost visibility (SessionEnd hook → costs.jsonl + forge burn-rate alert) | research | 1 | low | No | Additive log only; no behavior change | research-mining Rank 1 / H073 confirmed; `costs.jsonl` referenced in NEXUS, never built; forge loops burn silently |
| R2 | Compact at 60% fill, reframe trigger as reasoning-fidelity | research | 1 | low | Yes (earlier compaction) | Only effect: compaction fires sooner — net-positive, reversible threshold | research-mining Rank 2; 3 independent sources; fidelity shallows pre-limit |
| R3 | PostToolUse code-vuln scan (eval/innerHTML/exec/pickle) + fix capture-error.sh `.tool`→`.tool_name` | research | 1 | low | No | New warn-only hook; bundles a bugfix | research-mining Rank 3 / H070; ~30L bash |
| R4 | COMMIT-BEFORE-MOVE PreToolUse hook (warn on mv/rm with untracked files) | research | 1 | low | No | Warn-only by default; block configurable | research-mining Rank 5; I0.1 is honor-system, I0.15 says hook it; funjoin lost 11 files |
| R5 | `agentdb dirty-check` at read-start (surface modified-uncommitted) | email | 1 | low | No | Read-only diagnostic; never auto-commits; honors I0.8; silent if no git | email-intel P1; Midday Pulse flags dirty-on-main daily |
| R6 | `/kernel:save` + `/kernel:pull` opt-in commands + guard-commit-msg.sh | git-sync | 2 | low | No | Off by default; do-nothing users see only the placeholder-msg guard, which only blocks bad messages | git-sync-design (full design done); our4cuts model; reconciled with I0.4/5/8/9/15 |
| R7 | `AGENTDB_ROOT` env override + `agentdb doctor` subcommand | email | 2 | low | No | Env override additive; doctor read-only | email-intel P2 + db-audit D9; "VaultsS" typo creates orphan DBs silently |
| R8 | `agentdb export --format json --since --out` + `agentdb git-state` + `metrics --format json` / git section | email | 2 | low | No | New flags additive; default behavior unchanged | email-intel P3/P6; automations parse human-readable output today |
| R9 | Plugin registration CI gate (every skill/command ↔ plugin.json) | research | 1 | low | No | Catches future mistakes only; passes current registrations | research-mining Rank 9; v7.12.1→7.12.2 was a silent missing-registration regression |
| R10 | AgentDB persistence health check at SessionStart (WAL/SHM wipe detection) | research | 1 | low | No | Read-only check + log | research-mining Rank 12; silent learning loss cross-cuts 3 projects |
| R11 | Stale-contract detection in session-start (>48h no verdict) | cross-repo | 1 | low | No | Read-only SELECT + output; github check stays profile-gated | cross-repo #3 (modelmind); orphaned contracts currently invisible |
| R12 | Ambient-learnings surface on PostToolUse(Write) + session-end domain-validator pass | cross-repo | 2 | low | No | Async, fast-exit when no DB/match; session-end pass is warn-only | cross-repo #1/#7 (modelmind); kernel logs writes but never retrieves; catches edits that bypass write hook |
| R13 | Spec-completeness gate in `/kernel:tearitapart` | research | 1 | low | No | Adds a phase before existing verdict | research-mining Rank 13; H002/H003 promoted (exact-spec → 100% success); ingest has 4b gate, tearitapart doesn't |
| R14 | Phase A/B split + mandatory file-read verify in `/kernel:forge` | research | 1 | low | No | Template guidance only | research-mining Rank 14; "surgeon claimed drag-drop, only wrote types" is top recurring failure |
| R15 | Effort param + literal-scope guidance in surgeon contract + orchestration SKILL.md | research | 1 | low | No | Additive instructions | research-mining Rank 10; Opus 4.7 literal interpretation suppresses findings under "be conservative" |
| R16 | Blind-evaluator agent (problem+rubric only, never the solution) | research | 2 | low | No | Fires only when spawned / high-stakes detected | research-mining Rank 8; `self_score_high_stakes_eval` anti-pattern promises a tool that doesn't exist (36% inflation) |
| R17 | `kernel:research` skill (Research-Failures-First, empirically ranked channels) | research | 2 | low | Yes (adds pre-impl gate) | The gate is a forcing function NEXUS already mandates; no existing flow removed | research-mining Rank 4; GitHub issues 47% / case studies 78% / anti-pattern web 15% (dropped); reinvented per-project today |
| R18 | AgentRx 4-type failure taxonomy (`failure_type` enum) in errors table + coroner | research | 2 | low | No | Nullable column, additive migration; existing rows unaffected | research-mining Rank 7; free-text failures are unqueryable |
| R19 | userpromptsubmit-router hook (routes.json → inject up to 3 context hints) | research | 2 | low | No | routes.json defaults empty; no-op until configured | research-mining Rank 6; funjoin's most-novel pattern; serves "pre-load over ask" philosophy |
| R20 | First-run detection + guided setup in session-start | cross-repo | 2 | low | No | Only fires when DB absent (fresh install); existing installs unaffected | cross-repo #8 (kernel_systems); fresh installs currently hit read-start and get nothing |
| R21 | `agentdb sync-up` to unified DB at SessionEnd | email | 2 | low | No | Opt-in via `UNIFIED_AGENTDB` env; no-op if unset | email-intel P4; Evening Reflection sees commits but not the why |
| R22 | `agentdb ingest-signal` + signals queue surfaced in `/kernel:ingest` | email | 2 | low | No | New table additive; ingest check is a silent read, skipped if table absent | email-intel P5; RAGEN-2 finding cycles through Sparks with no way to act/dismiss |
| R23 | Reconcile `warn-hardcoded.sh` (add font-family check + component-dir path guard) | cross-repo | 1 | low | No | Adds check + narrows scope → fewer false positives | cross-repo #6 (modelmind); kernel's fires on all .tsx/.css with no path guard |
| R24 | Pre-commit hook enforcing I0.4 (no AI attribution) at commit time | cross-repo | 2 | low | No | New gate; only blocks Co-Authored-By / "Generated with" trailers | cross-repo #7 (our4cuts model); I0.4 currently honor-system |
| R25 | Slot-cap convention (max 15 lines / 10 bullets) in session-state files | cross-repo | 1 | low | No | Convention + soft check; prevents future bloat | cross-repo #9 (kernel-cursor); session state can bloat context |
| R26 | AgentDB entity-relation layer + FTS5 (complete 002_graph_tracking) | research | 3 | low | No | Schema additive; FTS5 is SQLite built-in | research-mining Rank 15 / H075; 002 migration pre-wired; 80% of semantic-search value, no embeddings |
| R27 | MCP ops checklist + quarterly audit ritual in retrospective | research | 1 | low | No | Documentation + checklist only | research-mining Rank 16; no MCP operational guidance today |
| R28 | Cursor port sync process (I0.13/14/15, W9, migrations 005/008/009) + launchd caffeinate reference doc | cross-repo | 2 | low | No | Process/docs; check kernel-cursor usage before investing | cross-repo #10/#12; port last validated 2026-01-10, badly stale |
| R29 | Session-end multi-window guard (refuse auto-commit on shared worktree until confirmed) | research | 2 | medium | Yes (changes session-end for multi-window) | Safe default: warn, not block | research-mining Rank 11; 3 commits ate a parallel window's staged work |

---

## Quick Wins (Tier 1, zero-disruption — do immediately)

These touch 1-2 files, are purely additive, and a do-nothing user sees no behavior change:

1. **R1** — Cost visibility: SessionEnd hook appends token/cost to `costs.jsonl`; forge burn-rate alert.
2. **R3** — PostToolUse code-vuln scan (~30L, warn-only) + fix `capture-error.sh` `.tool`→`.tool_name`.
3. **R5** — `agentdb dirty-check` surfaced at read-start (read-only, honors I0.8).
4. **R9** — Plugin registration CI gate (skill/command ↔ plugin.json).
5. **R10** — AgentDB persistence health check at SessionStart (WAL wipe detection).
6. **R11** — Stale-contract detection in session-start.
7. **R13** — Spec-completeness gate in `/kernel:tearitapart`.
8. **R14** — Phase A/B split + file-read verify in `/kernel:forge`.
9. **R15** — Effort param + literal-scope guidance in surgeon contract.
10. **R23** — Reconcile `warn-hardcoded.sh` (font-family + path guard — fewer false positives).
11. **guard-bash.sh** regex fix (`-f` matching `fix/`/`fallback/` branch names) — ~2L.

R4 (commit-before-move) is Tier 1 and warn-only, so also safe immediately if desired.

---

## Suggested sequencing

1. **CRITICAL DB fixes first** — D2, D3 (idempotency) → D4 → then D1 (flip runner) → D5 (live repair) → D6-D9. One T2 batch via contract → surgeon → adversary, tested on a DB copy.
2. **Quick-wins batch** — R1, R3, R5, R9, R10, R11, R13, R14, R15, R23 + the guard-bash fix. Mostly parallelizable (separate files).
3. **AgentDB-as-API batch** — R7, R8 (one T2, 4-6 files).
4. **Git-sync** — R6 (its own T2, fully designed in git-sync-design.md).
5. **Tier-2/3 enhancements** — R12, R16-R22, R24-R29 as separate passes, each with its own contract.
