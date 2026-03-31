-- Migration 005: Learning system — GEPA execution traces, learning decay, IMMUNE antibodies
-- Applied by cmd_init migration loop

-- GEPA execution traces: goal -> exploration -> plan -> action -> outcome
CREATE TABLE IF NOT EXISTS execution_traces (
  id TEXT PRIMARY KEY,
  ts TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  contract_id TEXT,
  goal TEXT NOT NULL,
  exploration TEXT,
  plan TEXT,
  action TEXT,
  outcome TEXT,
  success INTEGER DEFAULT 0,
  tokens_used INTEGER DEFAULT 0,
  domain TEXT
);

CREATE INDEX IF NOT EXISTS idx_traces_contract ON execution_traces(contract_id);
CREATE INDEX IF NOT EXISTS idx_traces_success ON execution_traces(success);
CREATE INDEX IF NOT EXISTS idx_traces_domain ON execution_traces(domain);

INSERT OR IGNORE INTO _migrations (name) VALUES ('005_learning_system');
