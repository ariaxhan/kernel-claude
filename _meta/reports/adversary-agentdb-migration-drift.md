# Adversary findings — AgentDB migration-drift fix

Branch: `fix/agentdb-migration-drift` (uncommitted working tree)
Reviewer: fresh-context adversary. Threshold: >80% confidence.
Live DB never written — all tests in `mktemp -d` with `AGENTDB_ROOT`. Temp dirs cleaned.

## Scope verification (coordination)

`git diff --name-only -- orchestration/agentdb/ tests/run-tests.sh` matches the contract exactly:
agentdb (CLI), init.sh, schema.sql, migrations 007/008, new 010/011, tests/run-tests.sh.
No scope drift. Claimed functions verified present in the file (not just receipts):
`find_project_root` (AGENTDB_ROOT override + fallback warning), `run_pending_migrations`
(with `force` arg), `cmd_init`, `cmd_preflight` (Check 2 no-break loop, Check 3b errors.domain,
Check 4 self-heal), `cmd_error` (explicit ts). All read and confirmed in source.

## Attacks run (10)

| # | Attack | Expected | Observed | Verdict |
|---|--------|----------|----------|---------|
| 1 | Idempotency on fresh DB (preflight x3) | run2/3 = preflight:ok | preflight:ok all 3 | PASS |
| 2 | Full legacy v1 DB self-heal + data preservation + idempotency | tables/cols added, sync_log dropped, ts→Z, counts unchanged, run2 ok | events created, visibility/sensitivity/domain added, sync_log dropped, ts normalized, counts 2/1/2 unchanged, 11 migrations, run2/3 = 0 repairs | PASS |
| 2b | Migration 010 ts edge cases (NULL/empty/malformed/already-Z) direct | normalize without corrupting | **empty + malformed ts → NULL (data field lost)** | **FAIL** |
| 2c | _migrations table absent | recover to 11, preserve data | learnings=1 preserved, 11 migrations, events created, run2 ok | PASS |
| 2d | DB file absent | init fresh | DB created, 11 migrations, run2 ok | PASS |
| 2e | Empty 0-byte DB | heal to full schema | 11 migrations, run2 ok | PASS |
| 2f | 2b corruption via REAL preflight path | — | confirmed: empty/malformed ts → NULL through self-heal | **FAIL (same root cause as 2b)** |
| 3 | Data loss before/after counts | nothing lost/duplicated | all counts stable; row CONTENT preserved everywhere | PASS (rows) |
| 4 | find_project_root: AGENTDB_ROOT override / fallback warning / subdir | pin location, warn, no orphan | override pins (no /tmp orphan), warning emitted on bare tmp, subdir walks up clean | PASS |
| 5 | cmd_error legacy table + SQL injection | inject neutralized, ts=Z | `'; DROP TABLE errors;--` stored literally, table intact, ts=...Z | PASS |
| 6 | Concurrency: two preflights racing | no deadlock/corrupt/dup | both exit 0, integrity ok, 11 distinct (no dup), settles ok | PASS |
| 7 | Fresh init path | 11 migrations + events/nodes/edges/errors.domain + integrity ok | all present, integrity ok | PASS |
| 8 | events dropped, marker 003 kept (force-reread) | recreate via force, no phantom loop | events recreated, run2/3 = preflight:ok | PASS |
| 8b | Re-read EVERY migration twice directly | zero errors | all 11 re-read x2, zero errors, integrity ok | PASS |
| — | Full suite `bash tests/run-tests.sh` | green | **233 passed, 0 failed** | PASS |

## FAIL — migration 010 corrupts malformed/empty timestamps

File: `orchestration/agentdb/migrations/010_normalize_timestamps.sql:7-8`

```sql
UPDATE errors    SET ts = strftime('%Y-%m-%dT%H:%M:%fZ', ts) WHERE ts NOT LIKE '%Z';
UPDATE learnings SET ts = strftime('%Y-%m-%dT%H:%M:%fZ', ts) WHERE ts NOT LIKE '%Z';
```

Root cause: `strftime()` returns NULL for any value it cannot parse (empty string `''`,
or non-date text like `'garbage-ts'`). The guard `WHERE ts NOT LIKE '%Z'` matches those
rows, so the UPDATE overwrites the original value with NULL. The original timestamp string
is irreversibly lost. NULL-ts rows and already-`...Z` rows are correctly skipped — only
non-empty, non-Z, unparseable values are clobbered. The migration's own header claims
"Normalize in place ... Idempotent" but does not guarantee "without corrupting valid rows."

Reproduction (run through the REAL preflight self-heal, attack 2f):
```
T=$(mktemp -d); mkdir -p "$T/_meta/agentdb"; DB="$T/_meta/agentdb/agent.db"
sqlite3 "$DB" "CREATE TABLE _migrations(id INTEGER PRIMARY KEY, name TEXT UNIQUE);
  INSERT INTO _migrations(name) VALUES('001_init');
  CREATE TABLE learnings(id INTEGER PRIMARY KEY, ts TEXT, type TEXT, insight TEXT, evidence TEXT, domain TEXT, hit_count INTEGER DEFAULT 0, last_hit TEXT);
  CREATE TABLE context(id INTEGER PRIMARY KEY, ts TEXT, type TEXT, contract_id TEXT, data TEXT);
  CREATE TABLE errors(id INTEGER PRIMARY KEY, ts TEXT, tool TEXT NOT NULL, error TEXT NOT NULL, file TEXT, context TEXT);
  INSERT INTO errors(id,ts,tool,error) VALUES(1,'','B','keep'),(2,'garbage-ts','B','keep');"
AGENTDB_ROOT="$T" orchestration/agentdb/agentdb preflight >/dev/null 2>&1
sqlite3 "$DB" "SELECT id, quote(ts) FROM errors;"   # => 1|NULL  2|NULL  (was '' and 'garbage-ts')
rm -rf "$T"
```

Suggested fix: only normalize rows strftime can actually parse — preserve the rest.
```sql
UPDATE errors    SET ts = strftime('%Y-%m-%dT%H:%M:%fZ', ts)
  WHERE ts NOT LIKE '%Z' AND strftime('%Y-%m-%dT%H:%M:%fZ', ts) IS NOT NULL;
UPDATE learnings SET ts = strftime('%Y-%m-%dT%H:%M:%fZ', ts)
  WHERE ts NOT LIKE '%Z' AND strftime('%Y-%m-%dT%H:%M:%fZ', ts) IS NOT NULL;
```
This keeps the migration idempotent and makes it a true no-op on unparseable/empty values.

Live-DB exposure (read-only check): 0 rows in the live `errors`/`learnings` would be touched
(all already `...Z`), so this defect is currently inert on the live DB. It is a latent
data-integrity bug for any legacy DB containing a malformed or empty `ts`.

## Lower-severity notes (not blocking)

- `cmd_init` leaks `5000` / `wal` to stdout (from `.timeout`/`PRAGMA journal_mode` dot-command
  echoing). PRE-EXISTING on `main` (HEAD's cmd_init does the same). The hook-called `preflight`
  path invokes cmd_init with `>/dev/null` and itself emits only `preflight:ok` — clean. Cosmetic.
- `agentdb error` on a legacy `errors` table lacking the `domain` column fails ("no column named
  domain") if called before preflight heals it. PRE-EXISTING — HEAD's cmd_error already inserted
  `domain`. Preflight runs at session start and heals it, so normal flow is unaffected.

## What works (high confidence)

- The headline fix is correct: dropped migration-created tables (events) are recreated via the
  force-reread path despite a lingering marker, and the second preflight is clean (no phantom
  repair loop). Verified attacks 2, 8, 8b.
- Self-heal of every drift state tested (missing tables, missing columns, absent _migrations,
  absent/empty DB) converges to 11 migrations and is idempotent on re-run.
- Row CONTENT is never lost or duplicated in any tested state; counts stable.
- SQL injection in cmd_error is neutralized; explicit ts writes correct `...Z` on fresh and
  healed tables.
- Concurrency-safe (busy_timeout 5000 + INSERT OR IGNORE): no deadlock, corruption, or dup markers.
- All 11 migrations re-read twice with zero errors. Full suite 233/0.

VERDICT: FAIL — confidence 90%
