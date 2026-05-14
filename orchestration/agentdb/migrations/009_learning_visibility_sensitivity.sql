-- Migration 009: Add visibility + sensitivity to learnings
-- The `agentdb learn` command inserts these columns, but no prior migration
-- created them — script drifted ahead of schema. INSERT fails with:
--   "table learnings has no column named visibility"
--
-- visibility: how a learning is surfaced to future agents
--   agent       — recalled by agents automatically (default)
--   human_only  — surfaced to humans but hidden from agent recall
--   operational — neither; kept for audit only
--
-- sensitivity: data-handling classification
--   low | medium | high

ALTER TABLE learnings ADD COLUMN visibility TEXT DEFAULT 'agent';
ALTER TABLE learnings ADD COLUMN sensitivity TEXT DEFAULT 'low';

CREATE INDEX IF NOT EXISTS idx_learnings_visibility ON learnings(visibility);

INSERT INTO _migrations (name) VALUES ('009_learning_visibility_sensitivity');
