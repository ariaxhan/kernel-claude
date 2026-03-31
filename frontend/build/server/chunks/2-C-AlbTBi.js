import { g as getDb, a as getProjectRoot } from './db-DP8A50Zn.js';
import { execSync } from 'node:child_process';
import { existsSync, readdirSync } from 'node:fs';
import { join } from 'node:path';
import 'better-sqlite3';

function load() {
  const health = getSystemHealth();
  const recentCheckpoints = getRecentCheckpoints();
  const git = getGitInfo();
  const activeContract = getActiveContract();
  return { health, recentCheckpoints, git, activeContract };
}
function getSystemHealth() {
  const db = getDb();
  const learningCounts = db.prepare(`
    SELECT
      COUNT(*) as total,
      SUM(CASE WHEN type = 'pattern' THEN 1 ELSE 0 END) as patterns,
      SUM(CASE WHEN type = 'failure' THEN 1 ELSE 0 END) as failures,
      SUM(CASE WHEN type = 'gotcha' THEN 1 ELSE 0 END) as gotchas
    FROM learnings
  `).get();
  const errorTotal = db.prepare("SELECT COUNT(*) as c FROM errors").get().c;
  const errorRecent = db.prepare(
    "SELECT COUNT(*) as c FROM errors WHERE ts > datetime('now', '-7 days')"
  ).get().c;
  let sessions = { total: 0, recent: 0, successRate: 0 };
  try {
    const sessionTotal = db.prepare("SELECT COUNT(*) as c FROM context_sessions").get().c;
    const sessionRecent = db.prepare(
      "SELECT COUNT(*) as c FROM context_sessions WHERE started_at > datetime('now', '-7 days')"
    ).get().c;
    const successCount = db.prepare(
      "SELECT COUNT(*) as c FROM context_sessions WHERE success = 1"
    ).get().c;
    sessions = {
      total: sessionTotal,
      recent: sessionRecent,
      successRate: sessionTotal > 0 ? Math.round(successCount / sessionTotal * 100) : 0
    };
  } catch {
  }
  const lastCheckpoint = db.prepare(
    "SELECT ts FROM context WHERE type = 'checkpoint' ORDER BY ts DESC LIMIT 1"
  ).get();
  const root = getProjectRoot();
  let agentCount = 0;
  const agentsDir = join(root, "_meta", "agents");
  if (existsSync(agentsDir)) {
    agentCount = readdirSync(agentsDir).filter((f) => !f.startsWith(".")).length;
  }
  return {
    learnings: learningCounts,
    errors: { total: errorTotal, recent: errorRecent },
    sessions,
    lastCheckpoint: lastCheckpoint?.ts ?? null,
    agents: { total: agentCount }
  };
}
function getRecentCheckpoints() {
  const db = getDb();
  return db.prepare(
    "SELECT * FROM context WHERE type = 'checkpoint' ORDER BY ts DESC LIMIT 8"
  ).all();
}
function getGitInfo() {
  const root = getProjectRoot();
  try {
    const branch = execSync("git branch --show-current", { cwd: root, encoding: "utf-8" }).trim();
    const log = execSync("git log --oneline -8", { cwd: root, encoding: "utf-8" }).trim().split("\n").map((line) => {
      const [hash, ...rest] = line.split(" ");
      return { hash, message: rest.join(" ") };
    });
    const status = execSync("git status --short", { cwd: root, encoding: "utf-8" }).trim();
    const uncommitted = status ? status.split("\n").length : 0;
    return { branch, log, uncommitted };
  } catch {
    return { branch: "unknown", log: [], uncommitted: 0 };
  }
}
function getActiveContract() {
  const db = getDb();
  const row = db.prepare(
    "SELECT * FROM context WHERE type = 'contract' ORDER BY ts DESC LIMIT 1"
  ).get();
  if (!row) return null;
  try {
    return { ...row, parsed: JSON.parse(row.content) };
  } catch {
    return { ...row, parsed: null };
  }
}

var _page_server_ts = /*#__PURE__*/Object.freeze({
  __proto__: null,
  load: load
});

const index = 2;
let component_cache;
const component = async () => component_cache ??= (await import('./_page.svelte-BzYDP9Bb.js')).default;
const server_id = "src/routes/+page.server.ts";
const imports = ["_app/immutable/nodes/2.Bltf4kwv.js","_app/immutable/chunks/BPazckB7.js","_app/immutable/chunks/CnnHHd9u.js","_app/immutable/chunks/_4VItRTv.js","_app/immutable/chunks/CEZ1KQol.js","_app/immutable/chunks/DMwI42Na.js","_app/immutable/chunks/BfcSgKlm.js","_app/immutable/chunks/CMsK9DGT.js","_app/immutable/chunks/CkLfrO85.js"];
const stylesheets = ["_app/immutable/assets/2.DZLz_caX.css"];
const fonts = [];

export { component, fonts, imports, index, _page_server_ts as server, server_id, stylesheets };
//# sourceMappingURL=2-C-AlbTBi.js.map
