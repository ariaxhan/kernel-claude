-- Migration 011: Drop the phantom sync_log table
-- sync_log was created outside the migration system (no migration creates it,
-- no code in `agentdb` references it). It is dead weight on any DB old enough
-- to have it. DROP IF EXISTS is a no-op on fresh DBs that never had it.
DROP TABLE IF EXISTS sync_log;

INSERT OR IGNORE INTO _migrations (name) VALUES ('011_drop_sync_log');
