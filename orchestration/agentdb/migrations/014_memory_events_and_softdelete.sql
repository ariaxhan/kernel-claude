-- Migration 014: memory-lifecycle event spine + soft-delete columns.
--
-- WHY (memory observatory, design 2.1 / 3.7 / 6.2): the pre-existing `events`
-- table (migration 003) is hook/session/command telemetry only, with a closed
-- CHECK enum that structurally cannot record a memory verb (created / imported /
-- merged / retrieved / surfaced / reinforced / archived / ...). This migration
-- adds a dedicated APPEND-ONLY `memory_events` table that IS the observation
-- ground truth for the memory lifecycle. Derived caches (hit_count, archived_at)
-- are reconciled against it; interpretations never enter it.
--
-- APPEND-ONLY CONTRACT: never UPDATE, never DELETE a row here. A correction is a
-- new event (kind='superseded', object_id pointing at the corrected row). The
-- `kind` column is deliberately OPEN vocabulary (no CHECK): live data already
-- carries out-of-vocabulary verbs and a closed enum would force a schema
-- migration for every new verb. Known verbs are validated advisory-only in code.
CREATE TABLE IF NOT EXISTS memory_events (
  event_id         TEXT PRIMARY KEY,           -- <db-short>-<ts>-<pid>-<rand>, globally unique across dbs
  ts               TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  schema_version   INTEGER NOT NULL DEFAULT 1, -- bump only on shape change; old rows keep their number
  kind             TEXT NOT NULL,              -- OPEN vocabulary, no CHECK (advisory validation in code)
  actor            TEXT,                       -- session id | script name | hook name | 'human' | import name
  -- provenance (immutable observation of origin):
  source_db        TEXT,                       -- logical name or realpath of the db the action touched
  source_row_id    TEXT,                       -- id of the row in its ORIGIN db (survives import)
  import_batch_id  TEXT,                       -- set on imported/merged events; null for in-place events
  -- affected records:
  subject_id       TEXT,                       -- the learning/hypothesis this event is about
  object_id        TEXT,                       -- the OTHER row, for merged/superseded/graduated
  -- the why + the rest:
  reason           TEXT,                       -- why this happened (required by convention)
  inference_method TEXT,                       -- null = directly observed; set = derived/inferred/seed
  payload          TEXT                        -- JSON: query text, candidate/surfaced ids, observed_hit_count, domain from/to, etc.
);
CREATE INDEX IF NOT EXISTS idx_mevents_subject ON memory_events(subject_id);
CREATE INDEX IF NOT EXISTS idx_mevents_kind    ON memory_events(kind);
CREATE INDEX IF NOT EXISTS idx_mevents_ts      ON memory_events(ts);

-- Soft-delete columns on learnings (design 3.7 / 3.10). These are DERIVED CACHES
-- of the latest archived/resurrected memory_event, not authoritative state. Like
-- migrations 004 / 009 / 013, the ADD COLUMN is delegated to cmd_preflight
-- (_ensure_softdelete_cols) and defined in schema.sql for fresh DBs: a raw ALTER
-- here would throw "duplicate column name" when preflight force-re-reads every
-- migration to repair a dropped table. Record the marker only; let the code own
-- the column so this file stays idempotent under a force re-read.
INSERT OR IGNORE INTO _migrations (name) VALUES ('014_memory_events_and_softdelete');
