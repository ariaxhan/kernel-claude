-- Migration 006: Hypotheses and experiments — structured hypothesis testing for kernel learnings
-- Applied by cmd_init migration loop

CREATE TABLE IF NOT EXISTS hypotheses (
  id TEXT PRIMARY KEY,                -- H001, H002, etc.
  statement TEXT NOT NULL,             -- the rule being tested
  source TEXT,                         -- where it came from (file:line)
  domain TEXT,                         -- methodology, coordination, testing, git, security, etc.
  status TEXT CHECK(status IN ('unproven','testing','supported','refuted','inconclusive','graduated')) DEFAULT 'unproven',
  confidence REAL DEFAULT 0.0,         -- 0.0 to 1.0
  evidence_for INTEGER DEFAULT 0,
  evidence_against INTEGER DEFAULT 0,
  created_at TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  updated_at TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  graduated_at TEXT
);

CREATE INDEX IF NOT EXISTS idx_hypotheses_domain ON hypotheses(domain);
CREATE INDEX IF NOT EXISTS idx_hypotheses_status ON hypotheses(status);

CREATE TABLE IF NOT EXISTS experiments (
  id TEXT PRIMARY KEY,                -- EXP-001, EXP-002, etc.
  hypothesis_id TEXT NOT NULL,
  method TEXT NOT NULL,                -- how the experiment was conducted
  measurement TEXT NOT NULL,           -- what was measured
  pass_criteria TEXT,                  -- what constitutes pass
  result TEXT,                         -- what happened
  verdict TEXT CHECK(verdict IN ('supports','refutes','inconclusive')),
  evidence TEXT,                       -- raw data, metrics, observations
  duration_ms INTEGER,
  created_at TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  FOREIGN KEY (hypothesis_id) REFERENCES hypotheses(id)
);

CREATE INDEX IF NOT EXISTS idx_experiments_hypothesis ON experiments(hypothesis_id);
CREATE INDEX IF NOT EXISTS idx_experiments_verdict ON experiments(verdict);

INSERT OR IGNORE INTO _migrations (name) VALUES ('006_hypotheses');
