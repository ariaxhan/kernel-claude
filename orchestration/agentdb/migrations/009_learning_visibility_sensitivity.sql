-- Migration 009: Add visibility + sensitivity to learnings
-- The `agentdb learn` command inserts these columns, but no prior migration
-- created them — script drifted ahead of schema. INSERT fails with:
--   "table learnings has no column named visibility"
--
-- visibility: how a learning is surfaced to future agents
--   agent       — recalled by agents automatically (default)
--   human_only  — surfaced to humans but hidden from agent recall
--   operational — neither; kept for audit only
--
-- sensitivity: data-handling classification
--   low | medium | high

-- Applied programmatically by cmd_preflight (see agentdb: Check 3), exactly like
-- migration 004. Preflight detects-and-adds these columns idempotently, and
-- schema.sql already defines them for fresh DBs — so a raw ALTER here fails with
-- "duplicate column name" on any DB that already has them (which leaks the error
-- into command output). Record the marker only; let preflight own the columns.
INSERT OR IGNORE INTO _migrations (name) VALUES ('009_learning_visibility_sensitivity');
