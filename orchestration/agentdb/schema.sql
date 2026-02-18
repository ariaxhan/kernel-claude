-- KERNEL AgentDB Schema
-- Location: _meta/agentdb/kernel.db (created per-project)
-- Philosophy: Read at start, write at end. 2 core tables.

PRAGMA journal_mode=WAL;
PRAGMA foreign_keys=ON;

-- LEARNINGS: Cross-session memory (survives forever)
-- Read these at session start to avoid repeating mistakes
CREATE TABLE IF NOT EXISTS learnings (
  id TEXT PRIMARY KEY,
  ts TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  type TEXT NOT NULL CHECK(type IN ('failure', 'pattern', 'gotcha', 'preference')),
  insight TEXT NOT NULL,
  evidence TEXT,
  domain TEXT,  -- e.g., 'auth', 'database', 'frontend'
  hit_count INTEGER DEFAULT 0,
  last_hit TEXT
);

CREATE INDEX IF NOT EXISTS idx_learnings_type ON learnings(type);
CREATE INDEX IF NOT EXISTS idx_learnings_domain ON learnings(domain);

-- CONTEXT: Work state (ephemeral per-contract)
-- Types: contract, checkpoint, handoff, verdict
CREATE TABLE IF NOT EXISTS context (
  id TEXT PRIMARY KEY,
  ts TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  type TEXT NOT NULL CHECK(type IN ('contract', 'checkpoint', 'handoff', 'verdict')),
  contract_id TEXT,  -- links context entries to a contract
  agent TEXT,  -- which agent wrote this (orchestrator, surgeon, adversary)
  content TEXT NOT NULL  -- JSON blob
);

CREATE INDEX IF NOT EXISTS idx_context_type ON context(type);
CREATE INDEX IF NOT EXISTS idx_context_contract ON context(contract_id);
CREATE INDEX IF NOT EXISTS idx_context_ts ON context(ts);

-- ERRORS: Automatic capture of failures
CREATE TABLE IF NOT EXISTS errors (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  ts TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  tool TEXT NOT NULL,
  error TEXT NOT NULL,
  file TEXT,
  context TEXT
);

-- Migration tracking
CREATE TABLE IF NOT EXISTS _migrations (
  name TEXT PRIMARY KEY,
  applied_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
);

INSERT OR IGNORE INTO _migrations (name) VALUES ('001_init');
