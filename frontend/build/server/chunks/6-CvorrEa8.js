import { g as getDb } from './db-DP8A50Zn.js';
import 'better-sqlite3';
import 'node:path';
import 'node:fs';

function load() {
  const db = getDb();
  const learnings = db.prepare(
    "SELECT * FROM learnings ORDER BY last_hit DESC, hit_count DESC"
  ).all();
  const contracts = db.prepare(
    "SELECT * FROM context WHERE type = 'contract' ORDER BY ts DESC LIMIT 20"
  ).all();
  const verdicts = db.prepare(
    "SELECT * FROM context WHERE type = 'verdict' ORDER BY ts DESC LIMIT 20"
  ).all();
  const patterns = learnings.filter((l) => l.type === "pattern");
  const failures = learnings.filter((l) => l.type === "failure");
  const gotchas = learnings.filter((l) => l.type === "gotcha");
  const preferences = learnings.filter((l) => l.type === "preference");
  return { patterns, failures, gotchas, preferences, contracts, verdicts };
}

var _page_server_ts = /*#__PURE__*/Object.freeze({
  __proto__: null,
  load: load
});

const index = 6;
let component_cache;
const component = async () => component_cache ??= (await import('./_page.svelte-DJ1pZB9M.js')).default;
const server_id = "src/routes/memory/+page.server.ts";
const imports = ["_app/immutable/nodes/6.BNXnv58V.js","_app/immutable/chunks/BPazckB7.js","_app/immutable/chunks/CnnHHd9u.js","_app/immutable/chunks/_4VItRTv.js","_app/immutable/chunks/CEZ1KQol.js","_app/immutable/chunks/DMwI42Na.js","_app/immutable/chunks/BfcSgKlm.js","_app/immutable/chunks/CMsK9DGT.js","_app/immutable/chunks/CkLfrO85.js"];
const stylesheets = ["_app/immutable/assets/6.DtN_KqsA.css"];
const fonts = [];

export { component, fonts, imports, index, _page_server_ts as server, server_id, stylesheets };
//# sourceMappingURL=6-CvorrEa8.js.map
