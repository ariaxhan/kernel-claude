-- Migration 017: recall alias expansion (query-time synonym table).
--
-- WHY (agentdb hardening lane, 2026-07-24): the recall eval harness
-- (_meta/evals/recall) proved a class of unreachable queries: zero-lexical-overlap
-- paraphrases ("switched laptops" vs "machine move", "memory lookup comes back
-- empty" vs "recall returned no matching learnings"). Pure FTS cannot reach them;
-- the semantic-embed hybrid LOST to FTS on every metric (8.6.2 eval). The cheapest
-- mechanism that wins is a CURATED alias table applied to recall query terms
-- before the FTS match: term (query-side word) -> alias (corpus-side word).
--
-- Data is curated per-vault (like learnings themselves) and IS mirrored to
-- agent.db.json (it is source data, not derived). Directed: add both directions
-- explicitly if you want them. Managed via `agentdb alias add|list|rm`.
-- Kill-switch at query time: AGENTDB_NO_ALIAS=1.
CREATE TABLE IF NOT EXISTS recall_aliases (
  term  TEXT NOT NULL,               -- normalized query-side token ([a-z0-9]+)
  alias TEXT NOT NULL,               -- corpus-side token added to the FTS query
  note  TEXT,                        -- optional provenance / why this mapping exists
  ts    TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  PRIMARY KEY (term, alias)
);
CREATE INDEX IF NOT EXISTS idx_recall_aliases_term ON recall_aliases(term);

INSERT OR IGNORE INTO _migrations (name) VALUES ('017_recall_aliases');
