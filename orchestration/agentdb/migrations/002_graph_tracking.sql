-- Migration: 002_graph_tracking
-- Purpose: Add graph structure tracking for context optimization
-- Based on: aDNA (Lattice Protocol) + kernel-claude hybrid architecture

BEGIN TRANSACTION;

-- Track context loading sessions for pattern learning
CREATE TABLE IF NOT EXISTS context_sessions (
  id TEXT PRIMARY KEY,
  started_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  ended_at TEXT,
  task_type TEXT,  -- bug, feature, refactor, research, review
  tier INTEGER CHECK(tier IN (1, 2, 3)),
  nodes_loaded TEXT,  -- JSON array of paths loaded
  tokens_used INTEGER,
  success BOOLEAN,
  outcome TEXT  -- JSON: {"did": "...", "learned": [...]}
);

CREATE INDEX IF NOT EXISTS idx_sessions_task ON context_sessions(task_type);
CREATE INDEX IF NOT EXISTS idx_sessions_success ON context_sessions(success);

-- Track node metadata for smart loading decisions
CREATE TABLE IF NOT EXISTS nodes (
  path TEXT PRIMARY KEY,
  type TEXT CHECK(type IN ('skill', 'command', 'agent', 'research', 'code', 'config')),
  tokens INTEGER,  -- estimated token count (lines * 4 rough estimate)
  last_accessed TEXT,
  access_count INTEGER DEFAULT 0,
  avg_success_rate REAL DEFAULT 0.0  -- success rate when node is in context
);

CREATE INDEX IF NOT EXISTS idx_nodes_type ON nodes(type);
CREATE INDEX IF NOT EXISTS idx_nodes_access ON nodes(last_accessed);

-- Track relationships between nodes (graph edges)
CREATE TABLE IF NOT EXISTS edges (
  source_path TEXT NOT NULL,
  target_path TEXT NOT NULL,
  relation TEXT NOT NULL CHECK(relation IN (
    'loads',           -- source loads target (skill_load)
    'references',      -- source mentions target
    'depends_on',      -- source requires target to work
    'conflicts_with',  -- source and target shouldn't load together
    'succeeds_with'    -- source and target correlate with success
  )),
  weight REAL DEFAULT 1.0,  -- strength/frequency
  last_observed TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  PRIMARY KEY (source_path, target_path, relation),
  FOREIGN KEY (source_path) REFERENCES nodes(path),
  FOREIGN KEY (target_path) REFERENCES nodes(path)
);

CREATE INDEX IF NOT EXISTS idx_edges_source ON edges(source_path);
CREATE INDEX IF NOT EXISTS idx_edges_target ON edges(target_path);
CREATE INDEX IF NOT EXISTS idx_edges_relation ON edges(relation);

COMMIT;

-- Migration tracking
INSERT OR IGNORE INTO _migrations (name) VALUES ('002_graph_tracking');

-- Views for common queries

-- What nodes load well together?
CREATE VIEW IF NOT EXISTS v_successful_combos AS
SELECT
  cs.task_type,
  cs.nodes_loaded,
  cs.tokens_used,
  COUNT(*) as times_used,
  AVG(CASE WHEN cs.success THEN 1.0 ELSE 0.0 END) as success_rate
FROM context_sessions cs
WHERE cs.success IS NOT NULL
GROUP BY cs.task_type, cs.nodes_loaded
HAVING COUNT(*) >= 2
ORDER BY success_rate DESC, times_used DESC;

-- Which nodes have best success rates?
CREATE VIEW IF NOT EXISTS v_node_performance AS
SELECT
  n.path,
  n.type,
  n.tokens,
  n.access_count,
  n.avg_success_rate,
  (n.avg_success_rate * n.access_count) as confidence_score
FROM nodes n
WHERE n.access_count >= 3
ORDER BY confidence_score DESC;
