-- Migration 004: Fix learnings schema drift (applied programmatically by cmd_init)
-- The actual schema fix is handled by cmd_preflight which detects missing columns
-- and applies ALTER TABLE as needed.
INSERT OR IGNORE INTO _migrations (name) VALUES ('004_fix_learnings_schema');
