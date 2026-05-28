---
name: agentdb-correctness-audit
description: Full audit of AgentDB migration application gap, idempotency, schema drift, and other DB error classes in kernel-claude v7.13.0.
type: reference
date: 2026-05-28
---

# AgentDB Correctness Audit

**Audited:** `orchestration/agentdb/agentdb`, `schema.sql`, `init.sh`, all 9 migrations.
**Live DB:** `_meta/agentdb/agent.db` (created 2026-03-25).

---

## BUG 1 (Critical): Pending migrations on existing DBs are never applied

### Root cause

`cmd_init` runs the migration loop, but only fires if `[ ! -f "$DB" ]`. On an existing DB, `agentdb init` skips straight to the `echo "DB exists"` path — **the migration loop is dead code for any user who already has a DB.**

`cmd_preflight` Check 4 (lines ~189–203) iterates migrations and issues `preflight:pending_migration — $name not applied` warnings, but **never applies them**. It increments `warnings` and moves on. This is the explicit gap: preflight knows about the pending migrations but deliberately refuses to act.

### Live DB state (confirmed)

| Migration | In `_migrations` | Table/Column Exists |
|-----------|----------------|--------------------|
| 001_init | ✓ | — |
| 002_graph_tracking | ✓ | ✓ |
| 003_telemetry | ✓ | ✓ |
| 004_fix_learnings_schema | ✓ | handled by preflight |
| 005_learning_system | **MISSING** | `execution_traces` **ABSENT** |
| 006_hypotheses | ✓ | ✓ (applied out-of-order, manually) |
| 007_compaction_telemetry | ✓ | ✓ |
| 008_error_domain | **MISSING** | `errors.domain` **PRESENT** (manually ALTERed, marker never inserted) |
| 009_learning_visibility_sensitivity | **MISSING** | columns present (preflight Check 3 applied them) |

### Consequence

- `agentdb trace` (cmd_trace) inserts into `execution_traces`, which does not exist → silent failure or error depending on `set -e` context.
- `cmd_error` inserts `domain` column (line 647), which *does* exist only because someone manually ALTERed it. But the `_migrations` marker is absent, so preflight perpetually warns. Any user without the manual ALTER would fail on `agentdb error` calls.
- Migration 009's visibility/sensitivity columns exist via preflight Check 3, but the marker is absent, so preflight perpetually warns on all existing DBs.

---

## BUG 2 (High): `init.sh` never runs migrations — second independent gap

`init.sh` (the bootstrap script) only runs `schema.sql` on a fresh DB:

```bash
if [ ! -f "$DB" ]; then
    sqlite3 "$DB" < "$SCRIPT_DIR/schema.sql"
fi
```

It does **not** call `agentdb init` and does not iterate migrations. Any user who bootstraps via `init.sh` (instead of `agentdb init`) gets the base schema only — migrations 002–009 are never applied. Since `schema.sql` has `PRAGMA user_version = 2` and no migration tables beyond 001, those users start with a half-initialized DB.

**Risk:** `init.sh` is likely used by docs/onboarding. Users who follow those docs end up with a structurally incomplete DB.

---

## BUG 3 (High): Idempotency failures on migration re-run

If the fix for Bug 1 naively re-runs all unapplied migrations, two will error:

### 007_compaction_telemetry.sql
```sql
INSERT INTO _migrations (name) VALUES ('007_compaction_telemetry');  -- no OR IGNORE
```
If anything causes 007 to be applied twice, this fails on UNIQUE PRIMARY KEY constraint. Low probability with proper marker checks, but a latent bomb.

### 008_error_domain.sql
```sql
ALTER TABLE errors ADD COLUMN domain TEXT;  -- raw ALTER, no IF NOT EXISTS guard
```
SQLite does not support `ALTER TABLE ... ADD COLUMN IF NOT EXISTS`. If the column already exists (as it does on this DB — manually added), re-running 008 will error: `duplicate column name: domain`. The current workaround (migration 009's approach) is to record only the marker and delegate the actual column add to preflight — but 008 was written before that pattern was established and does the raw ALTER.

**Migration idempotency scorecard:**

| Migration | CREATE IF NOT EXISTS | INSERT OR IGNORE | Raw ALTER | Safe to re-run? |
|-----------|---------------------|-----------------|-----------|----------------|
| 002 | ✓ | ✓ | — | Yes |
| 003 | ✓ | ✓ | — | Yes |
| 004 | marker only | ✓ | — | Yes |
| 005 | ✓ | ✓ | — | Yes |
| 006 | ✓ | ✓ | — | Yes |
| 007 | ✓ | **bare INSERT** | — | **No — fails on dup** |
| 008 | — | **bare INSERT** | **raw ALTER** | **No — fails on dup col** |
| 009 | marker only | ✓ | — | Yes |

---

## BUG 4 (Medium): `CURRENT_TIMESTAMP` vs `strftime` drift between schema.sql and live tables

`schema.sql` defines all `ts` columns as:
```sql
ts TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
```

But the live `errors` and `learnings` tables (created by the initial `schema.sql` at DB creation time on 2026-03-25) use:
```sql
ts TEXT DEFAULT CURRENT_TIMESTAMP
```

This means:
- Old rows in `errors`/`learnings` have timestamps like `2026-03-26 21:56:21` (SQLite wall-clock, no Z, no fractional seconds).
- New rows from `cmd_learn` use explicit `strftime(...)` — those are ISO 8601 with Z.
- Mixed formats in the same column. The scoring queries in `cmd_read_start` (`julianday('now') - julianday(ts) < 7`) still work because `julianday()` accepts both formats, but any external tools or lexicographic sorts on `ts` are wrong for old rows.

The drift happened because `schema.sql` was updated at some point to use `strftime()` but existing tables were not migrated. `NOT NULL` was also added to `ts` in schema.sql but is absent in live tables (col 1, notnull=0).

---

## BUG 5 (Medium): `sync_log` table with no migration, no code references

The live DB contains a `sync_log` table:
```sql
CREATE TABLE sync_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  ts TEXT DEFAULT CURRENT_TIMESTAMP,
  source_db TEXT,
  records_synced INTEGER DEFAULT 0,
  direction TEXT
)
```

No migration creates it. No code in `agentdb` references it. No migration file on disk references it. It was created outside the migration system (likely by a REPL session or an experimental script that was never committed) and is now a phantom table — taking up space, showing up in `.tables`, and carrying the same `CURRENT_TIMESTAMP` timestamp smell.

---

## BUG 6 (Low): `cmd_preflight` Check 2 migration re-run has a `break` that short-circuits

Check 2 (lines ~140–167) iterates required tables. If any is missing, it re-applies schema and migrations, then `break`s. This means if the first required table (`learnings`) is missing but subsequent ones (`context`, `errors`, `_migrations`) are also missing, only one repair attempt fires before breaking out. For a badly corrupted DB this is tolerable, but it also means the repair is only triggered once per `preflight` call even if multiple tables need work.

---

## BUG 7 (Low): `find_project_root` PWD foot-gun for subagents

```bash
PROJECT_ROOT=$(find_project_root)
DB_DIR="$PROJECT_ROOT/_meta/agentdb"
DB="$DB_DIR/agent.db"
```

`find_project_root` walks up from `$PWD`. If an agent is spawned and its working directory is a sub-path (e.g., `frontend/` or `src/`), it will still find the right root as long as `_meta/` or `.claude/` exists on the walk path. But if run from `/` or a temp dir, the fallback is `$PWD` — pointing to the wrong location. The CLAUDE.md already warns about this (`AgentDB — Always use absolute paths`) but the script itself has no guard.

---

## Fix: Apply pending migrations in `cmd_preflight`

Replace the warn-only Check 4 in `cmd_preflight` with an apply-and-record loop. This makes `agentdb preflight` (called by session-start hook) the self-healing path for all existing users.

### Patch for `cmd_preflight` Check 4 (lines ~189–203)

```bash
  # Check 4: All migrations applied — APPLY any that are pending
  if [ -d "$SCHEMA_DIR/migrations" ]; then
    for migration in "$SCHEMA_DIR/migrations"/*.sql; do
      [ -f "$migration" ] || continue
      [[ "$migration" == *.down.sql ]] && continue
      local mig_name
      mig_name=$(basename "$migration" .sql)
      local mig_applied
      mig_applied=$(db_exec "SELECT 1 FROM _migrations WHERE name='$mig_name' LIMIT 1;" 2>/dev/null || echo "")
      if [ -z "$mig_applied" ]; then
        echo "preflight:applying_migration — $mig_name"
        if sqlite3 "$DB" ".timeout 5000" ".read $migration" 2>/dev/null; then
          repairs=$((repairs + 1))
        else
          echo "preflight:migration_error — $mig_name failed, see stderr"
          warnings=$((warnings + 1))
        fi
      fi
    done
  fi
```

This slots in at line ~189, replacing the existing Check 4 block. The `2>/dev/null` suppresses the "duplicate column name" error from 008 on DBs that already have the column — the `INSERT OR IGNORE` at the end of 008 still records the marker. For 007's bare `INSERT`, the UNIQUE constraint violation is suppressed by the same redirect, but the marker is already present so the migration is skipped anyway.

**However**, to be truly safe, fix the two non-idempotent migrations before deploying:

### Patch 008_error_domain.sql

```sql
-- H103: Bridge error-learning taxonomy disconnect
-- Errors use tool names (Bash/unknown), learnings use topic domains.
-- Add domain field to errors so they can be linked to learnings.
-- Column add delegated to preflight (ADD COLUMN IF NOT EXISTS not supported in SQLite).
-- Preflight Check 3 is extended to cover errors.domain below.
INSERT OR IGNORE INTO _migrations (name) VALUES ('008_error_domain');
```

And extend `cmd_preflight` Check 3 to also cover `errors.domain`:

```bash
  # Check 3b: errors schema has domain column (migration 008)
  local has_errors_domain
  has_errors_domain=$(db_exec "SELECT 1 FROM pragma_table_info('errors') WHERE name='domain' LIMIT 1;" 2>/dev/null || echo "")
  if [ -z "$has_errors_domain" ]; then
    echo "preflight:missing_column — errors.domain not found, adding"
    db_exec "ALTER TABLE errors ADD COLUMN domain TEXT;" 2>/dev/null || true
    repairs=$((repairs + 1))
  fi
```

### Patch 007_compaction_telemetry.sql

```sql
-- Change bare INSERT to INSERT OR IGNORE for re-run safety:
INSERT OR IGNORE INTO _migrations (name) VALUES ('007_compaction_telemetry');
```

---

## Fix: `init.sh` — call `agentdb init` instead of raw sqlite3

```bash
#!/bin/bash
# AgentDB bootstrap - single command setup
# Usage: ./init.sh [project_path]

set -e

PROJECT="${1:-.}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Use agentdb init — applies schema + all migrations in correct order
AGENTDB="$SCRIPT_DIR/agentdb"
if [ -x "$AGENTDB" ]; then
  # Temporarily set PWD to project root so find_project_root locates it
  (cd "$PROJECT" && "$AGENTDB" init)
else
  echo "Error: agentdb script not found at $SCRIPT_DIR/agentdb" >&2
  exit 1
fi
```

---

## Fix: `_migrations` marker backfill for the live DB

For the current live DB, three markers are absent despite their effects being present. Run once:

```sql
INSERT OR IGNORE INTO _migrations (name) VALUES ('005_learning_system');
INSERT OR IGNORE INTO _migrations (name) VALUES ('008_error_domain');
INSERT OR IGNORE INTO _migrations (name) VALUES ('009_learning_visibility_sensitivity');
```

And since `execution_traces` is absent despite 005 being "applied" (the table was never created), 005 must be re-run as a repair:

```bash
sqlite3 _meta/agentdb/agent.db ".read orchestration/agentdb/migrations/005_learning_system.sql"
```

This is safe because 005 uses `CREATE TABLE IF NOT EXISTS`.

---

## Ranked Fix List

| # | Severity | Issue | Fix | Risk |
|---|----------|-------|-----|------|
| 1 | Critical | Pending migrations never applied on existing DBs | Replace warn-only preflight Check 4 with apply loop | Low — migration files are `IF NOT EXISTS` safe (after patching 007/008) |
| 2 | High | `init.sh` never runs migrations | Replace raw `sqlite3 < schema.sql` with `agentdb init` call | Low |
| 3 | High | 008 raw ALTER fails on re-run | Convert to marker-only + preflight Check 3b for `errors.domain` | Low |
| 4 | High | 005 marker absent AND table absent (execution_traces missing) | Backfill marker + re-run 005 on live DB | Low (IF NOT EXISTS) |
| 5 | Medium | 007 bare INSERT will fail on double-apply | Change to `INSERT OR IGNORE` | Trivial |
| 6 | Medium | `CURRENT_TIMESTAMP` vs `strftime` timestamp format drift in old rows | Add migration 010 to normalize: `UPDATE errors SET ts = strftime('%Y-%m-%dT%H:%M:%fZ', ts) WHERE ts NOT LIKE '%Z'` | Low |
| 7 | Medium | `sync_log` phantom table — no migration, no code | Add migration 011 `DROP TABLE IF EXISTS sync_log` | Low |
| 8 | Low | `cmd_preflight` Check 2 `break` stops multi-table repair | Remove `break`; let the loop complete all tables | Low |
| 9 | Low | `find_project_root` falls back to `$PWD` with no warning | Add guard: if `$PROJECT_ROOT == $PWD` and neither `_meta` nor `.claude` exists there, emit warning and exit 1 | Low |
