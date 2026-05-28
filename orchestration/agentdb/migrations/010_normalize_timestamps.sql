-- Migration 010: Normalize legacy CURRENT_TIMESTAMP rows to ISO-8601/Z
-- Tables created before schema.sql adopted strftime('%Y-%m-%dT%H:%M:%fZ','now')
-- carry wall-clock timestamps like '2026-03-26 21:56:21' (no T, no Z, no frac).
-- julianday() tolerates both, but lexicographic sorts and external consumers
-- (daily-digest automations) break on the mixed format. Normalize in place.
-- Idempotent: WHERE ts NOT LIKE '%Z' skips already-normalized rows.
-- Safety: strftime() returns NULL on empty/unparseable ts, and '' / garbage
-- both satisfy NOT LIKE '%Z' — so without the IS NOT NULL guard this UPDATE
-- would silently overwrite a bad-but-present timestamp with NULL (data loss).
-- The guard leaves unparseable rows untouched for manual inspection.
UPDATE errors    SET ts = strftime('%Y-%m-%dT%H:%M:%fZ', ts)
  WHERE ts NOT LIKE '%Z' AND strftime('%Y-%m-%dT%H:%M:%fZ', ts) IS NOT NULL;
UPDATE learnings SET ts = strftime('%Y-%m-%dT%H:%M:%fZ', ts)
  WHERE ts NOT LIKE '%Z' AND strftime('%Y-%m-%dT%H:%M:%fZ', ts) IS NOT NULL;

INSERT OR IGNORE INTO _migrations (name) VALUES ('010_normalize_timestamps');
