-- AgentDB v1 for kernel-claude
-- Orchestration communication bus

PRAGMA journal_mode=WAL;
PRAGMA foreign_keys=ON;

-- Communication bus between agents
CREATE TABLE context_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  ts TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  tab TEXT NOT NULL,
  type TEXT NOT NULL CHECK(type IN ('directive', 'packet', 'checkpoint', 'verdict')),
  vn TEXT NOT NULL,
  detail TEXT,
  contract TEXT,
  files TEXT
);

CREATE INDEX idx_context_ts ON context_log(ts);
CREATE INDEX idx_context_contract ON context_log(contract);
CREATE INDEX idx_context_type ON context_log(type);

-- Active work agreements
CREATE TABLE contracts (
  id TEXT PRIMARY KEY,
  goal TEXT NOT NULL,
  constraints TEXT NOT NULL,
  failure_conditions TEXT NOT NULL,
  tier INTEGER NOT NULL CHECK(tier IN (1, 2, 3)),
  status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active', 'completed', 'blocked', 'rejected')),
  assigned_to TEXT,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  completed_at TEXT
);

CREATE INDEX idx_contracts_status ON contracts(status);

-- Project-specific learnings
CREATE TABLE rules (
  id TEXT PRIMARY KEY,
  domain TEXT NOT NULL,
  rule TEXT NOT NULL,
  evidence TEXT,
  confidence TEXT DEFAULT 'inferred' CHECK(confidence IN ('proven', 'inferred', 'deprecated')),
  session_count INTEGER DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
);

CREATE INDEX idx_rules_domain ON rules(domain);

-- Session insights
CREATE TABLE learnings (
  id TEXT PRIMARY KEY,
  category TEXT NOT NULL CHECK(category IN ('pattern', 'failure', 'preference', 'tool')),
  summary TEXT NOT NULL,
  detail TEXT,
  source TEXT,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
);

CREATE INDEX idx_learnings_category ON learnings(category);

-- Migration tracking
CREATE TABLE _migrations (
  name TEXT PRIMARY KEY,
  applied_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
);

INSERT INTO _migrations (name) VALUES ('001_init');
