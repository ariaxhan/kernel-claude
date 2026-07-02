-- KERNEL AgentDB Schema
-- Location: _meta/agentdb/agent.db (created per-project)
-- Philosophy: Read at start, write at end. 3 core tables: learnings, context, errors.

PRAGMA journal_mode=WAL;
PRAGMA foreign_keys=ON;
PRAGMA busy_timeout=5000;

-- LEARNINGS: Cross-session memory (survives forever)
-- Read these at session start to avoid repeating mistakes
CREATE TABLE IF NOT EXISTS learnings (
  id TEXT PRIMARY KEY,
  ts TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  type TEXT NOT NULL CHECK(type IN ('failure', 'pattern', 'gotcha', 'preference')),
  insight TEXT NOT NULL,
  evidence TEXT,
  domain TEXT,  -- e.g., 'auth', 'database', 'frontend'
  hit_count INTEGER DEFAULT 0,         -- bumped by recall (real relevance feedback)
  load_count INTEGER DEFAULT 0,        -- bumped by read-start (session-open telemetry, never ranked)
  last_hit TEXT,
  visibility TEXT DEFAULT 'agent',     -- agent | human_only | operational
  sensitivity TEXT DEFAULT 'low',      -- low | medium | high
  archived_at TEXT,                    -- migration 014: derived cache of latest archived event (NULL = live)
  archived_reason TEXT                 -- migration 014: reason from that archived event
);

CREATE INDEX IF NOT EXISTS idx_learnings_type ON learnings(type);
CREATE INDEX IF NOT EXISTS idx_learnings_domain ON learnings(domain);
CREATE INDEX IF NOT EXISTS idx_learnings_visibility ON learnings(visibility);

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
  context TEXT,
  domain TEXT  -- migration 008; marker-only there, column lives here for fresh DBs
);

-- Migration tracking
CREATE TABLE IF NOT EXISTS _migrations (
  name TEXT PRIMARY KEY,
  applied_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
);

INSERT OR IGNORE INTO _migrations (name) VALUES ('001_init');

-- Schema version tracking
PRAGMA user_version = 2;  -- Increment with each migration
