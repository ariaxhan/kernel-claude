-- Rollback for 002_graph_tracking
DROP TABLE IF EXISTS edges;
DROP TABLE IF EXISTS nodes;
DROP TABLE IF EXISTS context_sessions;
DELETE FROM _migrations WHERE name = '002_graph_tracking.sql';
PRAGMA user_version = 1;
