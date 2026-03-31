import { a as getProjectRoot } from './db-DP8A50Zn.js';
import { existsSync, readdirSync } from 'node:fs';
import { join, relative } from 'node:path';
import 'better-sqlite3';

function load() {
  const root = getProjectRoot();
  const metaTree = buildTree(join(root, "_meta"), root, 3);
  const repoTree = buildTree(root, root, 2, ["node_modules", ".git", "_meta", "frontend"]);
  return { metaTree, repoTree, root };
}
function buildTree(dir, root, maxDepth, exclude = [], depth = 0) {
  if (depth >= maxDepth || !existsSync(dir)) return [];
  try {
    const entries = readdirSync(dir, { withFileTypes: true });
    return entries.filter((e) => !e.name.startsWith(".") && !exclude.includes(e.name)).sort((a, b) => {
      if (a.isDirectory() && !b.isDirectory()) return -1;
      if (!a.isDirectory() && b.isDirectory()) return 1;
      return a.name.localeCompare(b.name);
    }).map((entry) => {
      const fullPath = join(dir, entry.name);
      const relPath = relative(root, fullPath);
      if (entry.isDirectory()) {
        return {
          name: entry.name,
          path: relPath,
          type: "directory",
          children: buildTree(fullPath, root, maxDepth, exclude, depth + 1)
        };
      }
      return {
        name: entry.name,
        path: relPath,
        type: "file"
      };
    });
  } catch {
    return [];
  }
}

var _page_server_ts = /*#__PURE__*/Object.freeze({
  __proto__: null,
  load: load
});

const index = 3;
let component_cache;
const component = async () => component_cache ??= (await import('./_page.svelte-BxUNqMC2.js')).default;
const server_id = "src/routes/files/+page.server.ts";
const imports = ["_app/immutable/nodes/3.snJ81aX3.js","_app/immutable/chunks/BPazckB7.js","_app/immutable/chunks/CnnHHd9u.js","_app/immutable/chunks/_4VItRTv.js","_app/immutable/chunks/CEZ1KQol.js","_app/immutable/chunks/DMwI42Na.js","_app/immutable/chunks/CkLfrO85.js"];
const stylesheets = ["_app/immutable/assets/3.eQ8HaqgC.css"];
const fonts = [];

export { component, fonts, imports, index, _page_server_ts as server, server_id, stylesheets };
//# sourceMappingURL=3-d92UH3ab.js.map
