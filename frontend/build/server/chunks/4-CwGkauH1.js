import { execSync } from 'node:child_process';
import { a as getProjectRoot } from './db-DP8A50Zn.js';
import 'better-sqlite3';
import 'node:path';
import 'node:fs';

function load() {
  const root = getProjectRoot();
  const remote = getRemote(root);
  if (!remote) return { connected: false, remote: null, issues: [], prs: [], discussions: [] };
  const issues = listIssues(root);
  const prs = listPRs(root);
  return { connected: true, remote, issues, prs, discussions: [] };
}
function getRemote(root) {
  try {
    return execSync("git remote get-url origin", { cwd: root, encoding: "utf-8" }).trim();
  } catch {
    return null;
  }
}
function listIssues(root) {
  try {
    const raw = execSync(
      "gh issue list --limit 15 --json number,title,state,labels,createdAt 2>/dev/null",
      { cwd: root, encoding: "utf-8", timeout: 1e4 }
    );
    const parsed = JSON.parse(raw);
    return parsed.map((i) => ({
      number: i.number,
      title: i.title,
      state: i.state,
      labels: (i.labels || []).map((l) => l.name),
      createdAt: i.createdAt
    }));
  } catch {
    return [];
  }
}
function listPRs(root) {
  try {
    const raw = execSync(
      "gh pr list --limit 10 --json number,title,state,headRefName,createdAt 2>/dev/null",
      { cwd: root, encoding: "utf-8", timeout: 1e4 }
    );
    return JSON.parse(raw);
  } catch {
    return [];
  }
}

var _page_server_ts = /*#__PURE__*/Object.freeze({
  __proto__: null,
  load: load
});

const index = 4;
let component_cache;
const component = async () => component_cache ??= (await import('./_page.svelte-CIWZlLYv.js')).default;
const server_id = "src/routes/github/+page.server.ts";
const imports = ["_app/immutable/nodes/4.aISIIRAy.js","_app/immutable/chunks/BPazckB7.js","_app/immutable/chunks/CnnHHd9u.js","_app/immutable/chunks/_4VItRTv.js","_app/immutable/chunks/CEZ1KQol.js","_app/immutable/chunks/DMwI42Na.js"];
const stylesheets = ["_app/immutable/assets/4.D2qIuICl.css"];
const fonts = [];

export { component, fonts, imports, index, _page_server_ts as server, server_id, stylesheets };
//# sourceMappingURL=4-CwGkauH1.js.map
