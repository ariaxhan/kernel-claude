-- H103: Bridge error-learning taxonomy disconnect
-- Errors use tool names (Bash/unknown), learnings use topic domains.
-- Add domain field to errors so they can be linked to learnings.
--
-- The column add is delegated to cmd_preflight (Check 3b), which PRAGMA-gates
-- it — SQLite has no `ADD COLUMN IF NOT EXISTS`, so a raw ALTER here dup-fails
-- on any DB that already has the column (and leaks the error into output).
-- Same pattern as migration 004/009: record the marker only.
INSERT OR IGNORE INTO _migrations (name) VALUES ('008_error_domain');
