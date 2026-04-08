-- H103: Bridge error-learning taxonomy disconnect
-- Errors use tool names (Bash/unknown), learnings use topic domains.
-- Add domain field to errors so they can be linked to learnings.

ALTER TABLE errors ADD COLUMN domain TEXT;

INSERT INTO _migrations (name) VALUES ('008_error_domain');
