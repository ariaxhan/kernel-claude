-- Migration 003: Telemetry events
-- Tracks session lifecycle, agent spawns, hook executions, command usage

CREATE TABLE IF NOT EXISTS events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  ts TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  category TEXT NOT NULL CHECK(category IN ('session','agent','hook','command','error','learning')),
  event TEXT NOT NULL,
  duration_ms INTEGER,
  metadata TEXT,
  agent TEXT,
  session_id TEXT
);

CREATE INDEX IF NOT EXISTS idx_events_category ON events(category);
CREATE INDEX IF NOT EXISTS idx_events_ts ON events(ts);
CREATE INDEX IF NOT EXISTS idx_events_session ON events(session_id);

INSERT OR IGNORE INTO _migrations (name) VALUES ('003_telemetry');
