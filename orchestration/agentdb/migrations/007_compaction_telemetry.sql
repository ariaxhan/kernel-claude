-- Migration 007: Compaction telemetry
-- Tracks token counts and retention scores across compaction events.
-- Token estimation uses bytes/4 (±20% margin for mixed code/prose content).

CREATE TABLE IF NOT EXISTS compaction_events (
  id TEXT PRIMARY KEY,
  session_id TEXT,
  tokens_before INTEGER,         -- estimated tokens in pre-compact snapshot (bytes/4)
  tokens_after INTEGER,          -- estimated tokens in post-compact restored content
  compression_ratio REAL,        -- tokens_after / tokens_before
  retention_score REAL,          -- 0.0-1.0: key terms survived / total key terms
  key_terms_total INTEGER,
  key_terms_survived INTEGER,
  trigger TEXT,                  -- what caused compaction (auto, manual, etc)
  agent TEXT,
  created_at TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
);

INSERT INTO _migrations (name) VALUES ('007_compaction_telemetry');
