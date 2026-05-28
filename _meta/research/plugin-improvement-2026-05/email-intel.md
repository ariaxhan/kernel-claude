---
name: email-intel
description: Plugin features and fixes derived from daily email automation signals (2026-05-21..28)
type: reference
date: 2026-05-28
source: orchestrator-recon
---

# Plugin Improvements: Email Automation Intelligence

## Context

Six daily email automations (Morning Briefing, Midday Pulse, Research Digest, Spark, Evening
Reflection, and a runner template) run against the vault and CodingVault. Their recurring
complaints and structural assumptions expose gaps in the plugin that no internal test can catch
— these automations are real consumers, not test harnesses.

---

## Pain → Feature Map (prioritized)

### P1 — Uncommitted work flagged daily by Midday Pulse

**Signal:** Midday Pulse (12pm) explicitly calls out repos where work is "sitting on main,
uncommitted." Observed: "intelligence-architecture is modified and sitting on main, uncommitted
— the work exists, it just hasn't been committed." This is the most recurring, most specific
complaint in the corpus.

**Root cause:** The plugin has no ambient uncommitted-state nudge. session-end.sh commits on
SessionEnd, but mid-session, the agent can write 20 files and stop without triggering that hook
if the session is just closed or compacted.

**Candidate feature:** `agentdb dirty-check` — a lightweight query against `git status --short`
that surfaces files modified-but-uncommitted at session-start (alongside read-start). Output
format: repo name + file count + oldest mtime. Pair with a W6-reminder injected into
`cmd_read_start` when dirty > 0.

**Tier:** T1 (single script addition, no schema changes)

**Non-disruption:** Read-only diagnostic. Never auto-commits. Honors I0.8. Falls back silently
if git is absent.

---

### P2 — Unified AgentDB path typo breaks runner

**Signal:** The runner template has a path typo "VaultsS" instead of "Vaults", pointing at
`/Users/ariaxhan/Vaults/_meta/agentdb/unified.db` (wrong) instead of the real vault root. Every
automation that reads the unified DB is silently broken on that runner.

**Root cause:** `find_project_root()` in agentdb uses heuristic walk-up (`_meta/` or `.claude/`),
not an explicit env var. When called from a runner with a wrong CWD or a typo in a path
variable, it silently falls back to `$PWD` and creates a new orphan DB.

**Candidate feature:** Two changes:
1. `AGENTDB_ROOT` env var override in `find_project_root()` — if set, use it, no walk. Automations
   set `AGENTDB_ROOT=/Users/ariaxhan/Documents/Vaults` and the typo becomes irrelevant.
2. `agentdb doctor` subcommand — verifies that `DB` path resolves, that `_migrations` table
   exists, and that expected tables (execution_traces, errors.domain) are present. Exits non-zero
   with a plain-English repair command on failure. The runner can call this before reading.

**Tier:** T1 for env var override; T2 for `agentdb doctor` (touches schema check logic, migration
verification, 3-4 files)

**Non-disruption:** `AGENTDB_ROOT` is additive. `agentdb doctor` is read-only. Neither changes
existing command behavior.

---

### P3 — `agentdb export` output is not automation-consumable

**Signal:** Morning Briefing and Midday Pulse consume learnings and git state. Research Digest
consumes papers + AI signals. These automations need structured data, not the current markdown
dump that `agentdb export` produces (narrative headings, no frontmatter, no JSON mode).

**Current state:** `cmd_export` writes
`learnings-export-<timestamp>.md` with `## Failures / ## Patterns / ## Gotchas` headings.
No JSON. No filtering by recency or type. No stable output path. Automations can't reliably
parse it.

**Candidate feature:** `agentdb export --format json|md --since 24h|7d --type failure|pattern
--out <path>`. JSON format emits a flat array of `{id, type, insight, evidence, hit_count, ts}`
objects. Stable `--out` path allows automations to write to a known location and diff it.
Add `agentdb git-state` — outputs `{repo, branch, dirty_files, last_commit_ts, last_commit_msg}`
as JSON, one object per repo found under `$VAULTS_ROOT`.

**Tier:** T2 (modifies `cmd_export`, adds `cmd_git_state`, touches CLI dispatch, 3-4 files)

**Non-disruption:** New flags are additive. Default `agentdb export` behavior unchanged.
`agentdb git-state` is new, no existing callers.

---

### P4 — Cross-repo commit tracking requires plugin cooperation

**Signal:** Midday Pulse scans "all 35 CodingVault repos" and tracks commits. It can see git
history externally, but it has no access to per-repo AgentDB context (what task generated those
commits, what tier, what learning was produced). The digest says "two automated session-end
commits, the vault keeping its own heartbeat" — it sees the commits but not the why.

**Root cause:** Session context lives in each repo's `_meta/agentdb/agent.db`. The unified DB at
`/Users/ariaxhan/Documents/Vaults/_meta/agentdb/unified.db` (if it existed correctly) would
aggregate, but there is no plugin mechanism to push per-repo session summaries into the unified DB.

**Candidate feature:** `agentdb sync-up` — at SessionEnd (after session-end.sh), push a summary
row to `$UNIFIED_AGENTDB` if the env var is set. Row: `{repo_path, session_id, task_type, tier,
commit_sha, learnings_count, ts}`. The unified DB gets a `cross_repo_sessions` table. Automations
query it for the digest.

**Tier:** T2 (new table migration for unified DB, new `cmd_sync_up`, hook integration, 3-5 files)

**Non-disruption:** Entirely opt-in via `UNIFIED_AGENTDB` env var. No-op if unset. session-end.sh
gains one conditional tail call; existing behavior unchanged.

---

### P5 — Research Digest consumes AI signals but plugin has no feed contract

**Signal:** Research Digest scans ~70-600 papers daily. It specifically tracks AI/ML signals and
the RAGEN-2 "template collapse" finding recurs across multiple Spark emails — meaning the automation
found it interesting enough to re-surface, but the plugin has no mechanism to acknowledge or act on
recurring external research signals.

**Candidate feature:** `agentdb ingest-signal <source> <title> <summary>` — a thin write path
that records external research signals into a `signals` table (`id, source, title, summary, ts,
acted_on`). `/kernel:ingest` checks `agentdb query "SELECT * FROM signals WHERE acted_on=0
ORDER BY ts DESC LIMIT 5"` at start and surfaces relevant unacted signals before coding. The
RAGEN-2 finding would have been acted on (or dismissed) rather than cycling through digests
indefinitely.

**Tier:** T2 (new migration for `signals` table, new CLI command, ingest command integration)

**Non-disruption:** `signals` table is additive. `ingest-signal` is new. The ingest command
check is a silent read that adds ~50ms; skipped if table absent.

---

### P6 — `agentdb metrics` missing git-activity dimension

**Signal:** Evening Reflection narrative includes commits, file changes, and session context
together. The current `agentdb metrics` output has Sessions, Agents, Hooks, Commands, Learnings,
Adversary Verdicts, Compaction — but no git activity column. Automations stitch this from two
sources (git log + AgentDB), which means they can diverge.

**Candidate feature:** Add `## Git Activity` section to `cmd_metrics` output: last N commits
(sha, msg, ts), dirty file count, branch, files changed in window. Backed by direct git calls,
not a new table. Keeps metrics self-contained for automation consumption.

**Tier:** T1 (additive section in `cmd_metrics`, no schema changes)

**Non-disruption:** Purely additive output section. Fails gracefully if git absent.

---

## API / Export Contract Gaps

The automations are clearly treating agentdb as an external data source. The current surface is
fragile for that use case:

| Current state | Needed |
|---|---|
| `agentdb export` writes to a timestamped file | Stable `--out` path + JSON mode |
| No git-state command | `agentdb git-state --format json` |
| No env var override for DB path | `AGENTDB_ROOT` override |
| No cross-repo aggregation | `agentdb sync-up` to unified DB |
| `agentdb metrics` is terminal-formatted | `agentdb metrics --format json` flag |
| No inbound signal channel | `agentdb ingest-signal` |

These six gaps mean every automation that wants structured data from the plugin must parse
human-readable output or call raw sqlite3 directly — both fragile.

---

## What should feed the digests (plugin side)

The "Email design principles" learning in the DB is about output aesthetics. That's the
automation's concern. What the plugin should supply:

1. **Learning feed** — `agentdb export --since 24h --format json` returning new/reinforced
   learnings since last digest run.
2. **Git state feed** — `agentdb git-state` returning per-repo dirty/clean + last commit for all
   repos under `$VAULTS_ROOT`.
3. **Session summary feed** — `agentdb query "SELECT repo_path, task_type, tier, commit_sha, ts
   FROM cross_repo_sessions WHERE ts > datetime('now', '-1 day')"` on the unified DB (requires P4).
4. **Signal queue** — `agentdb query "SELECT * FROM signals WHERE acted_on=0"` so digests can
   surface research the plugin hasn't processed yet.

---

## Priority Order

| Rank | Feature | Tier | Effort | Disruption |
|---|---|---|---|---|
| 1 | `AGENTDB_ROOT` env var + `agentdb doctor` (P2) | T1/T2 | ~1h | None |
| 2 | `agentdb dirty-check` at read-start (P1) | T1 | ~30min | None |
| 3 | `agentdb export --format json --out` (P3) | T2 | ~1.5h | None |
| 4 | `agentdb metrics` git-activity section (P6) | T1 | ~30min | None |
| 5 | `agentdb sync-up` to unified DB (P4) | T2 | ~2h | Opt-in only |
| 6 | `agentdb ingest-signal` (P5) | T2 | ~2h | Additive |

Items 1-4 can ship in a single T2 batch (4-6 files touched total). Items 5-6 are separate
passes — each needs a migration and a new table.
