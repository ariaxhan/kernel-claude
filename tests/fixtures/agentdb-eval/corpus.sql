-- Portable eval fixture: a small synthetic learnings corpus with stable ids.
-- Loaded into a fresh agentdb, embedded with the deterministic `hash` backend, and
-- queried by gold.json. Proves the hybrid-recall MECHANISM (fusion runs, ids flow,
-- never regresses vs FTS) with NO model download — CI-safe. Real semantic-quality
-- gains are proven separately on the live corpus with fastembed (see the chronicle).
INSERT INTO learnings (id, ts, type, insight, evidence, domain, visibility) VALUES
 ('L01','2026-01-01T00:00:00Z','pattern','Serialize concurrent git commits with an fcntl.flock advisory mutex so a killed writer never orphans index.lock','flock auto-releases on death','git','agent'),
 ('L02','2026-01-01T00:00:00Z','gotcha','A SessionStart hook exited 141 because head closed the pipe early under pipefail; drain with awk instead','SIGPIPE','hooks','agent'),
 ('L03','2026-01-01T00:00:00Z','pattern','Fuse bm25 keyword ranking with cosine semantic ranking using reciprocal rank fusion for hybrid retrieval','RRF k=60','retrieval','agent'),
 ('L04','2026-01-01T00:00:00Z','failure','A safety guard that auto-disables itself when its scanner fails is worse than no guard; fail closed','fail-open incident','security','agent'),
 ('L05','2026-01-01T00:00:00Z','gotcha','Never commit a binary sqlite database to git; track a deterministic JSON mirror and rebuild on restore','blob bloat','database','agent'),
 ('L06','2026-01-01T00:00:00Z','pattern','Replace a forgeable DANGER_OK env substring with a one-time nonce the human relays out of band','prompt injection cannot forge it','security','agent'),
 ('L07','2026-01-01T00:00:00Z','pattern','Spawn a subagent only to protect context or buy real parallel wall clock, never for independence alone','cost test','orchestration','agent'),
 ('L08','2026-01-01T00:00:00Z','gotcha','macOS launchd jobs fail with exit 126 when Full Disk Access is missing on the bash interpreter','TCC','automation','agent'),
 ('L09','2026-01-01T00:00:00Z','failure','Reporting a task done off a commit hash instead of a live verification wasted repeated rounds','committed is not deployed','process','agent'),
 ('L10','2026-01-01T00:00:00Z','pattern','Before deleting an empty submodule folder, check the git index mode 160000; it is uninitialized not junk','submodule investigation','git','agent'),
 ('L11','2026-01-01T00:00:00Z','gotcha','Codex treats hook stdout starting with a bracket as JSON; side-effect hooks must log to stderr','JSON contract','hooks','agent'),
 ('L12','2026-01-01T00:00:00Z','pattern','Scan tool output for invisible unicode tag characters and instruction-override phrasing as an injection tripwire','warn only','security','agent');
