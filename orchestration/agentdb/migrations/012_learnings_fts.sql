-- 012: FTS5 full-text index over learnings → relevance recall (`agentdb recall <query>`).
--
-- WHY: retrieval was weak. read-start dumps the top-N by an age-biased hit_count score
-- once per session; nothing matched learnings to the CURRENT task. With 500+ learnings
-- the relevant one was buried. This adds a text index so `recall` can rank by actual
-- relevance to a query at the moment of need (wired into the ingest CLASSIFY step).
--
-- External-content FTS (content='learnings'): the index stores no duplicate text, just
-- points at learnings.rowid. NO sync triggers — SQLite 3.43 rejects triggers that write
-- to a virtual table ("unsafe use of virtual table"), which ABORTS the learn insert.
-- Instead `recall` runs an FTS 'rebuild' before each query (O(N), a few ms) so the index
-- is always fresh at read time without ever touching the write path.
-- Idempotent: IF NOT EXISTS + DROP TRIGGER cleanup (for any DB that ran an earlier draft).

DROP TRIGGER IF EXISTS learnings_fts_ai;
DROP TRIGGER IF EXISTS learnings_fts_ad;
DROP TRIGGER IF EXISTS learnings_fts_au;

CREATE VIRTUAL TABLE IF NOT EXISTS learnings_fts USING fts5(
  insight, evidence, domain,
  content='learnings', content_rowid='rowid'
);

-- Initial populate (safe to re-run).
INSERT INTO learnings_fts(learnings_fts) VALUES('rebuild');

INSERT OR IGNORE INTO _migrations (name) VALUES ('012_learnings_fts');
