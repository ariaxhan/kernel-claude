-- Migration: 014_graph_receipt_projection
-- Purpose: Dedup table for context graph projected from kernel.context-receipt/v1 YAML.
-- Graph telemetry is derived from manifest receipts (observational); YAML remains authoritative.

BEGIN TRANSACTION;

CREATE TABLE IF NOT EXISTS graph_receipts (
  receipt_path TEXT PRIMARY KEY,
  session_id TEXT NOT NULL UNIQUE,
  manifest_path TEXT,
  projected_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
);

CREATE INDEX IF NOT EXISTS idx_graph_receipts_session ON graph_receipts(session_id);

COMMIT;

INSERT OR IGNORE INTO _migrations (name) VALUES ('014_graph_receipt_projection');
