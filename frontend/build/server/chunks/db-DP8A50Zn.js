import Database from 'better-sqlite3';
import { resolve, join } from 'node:path';
import { existsSync } from 'node:fs';

let db = null;
function findAgentDb() {
  let dir = resolve(import.meta.dirname, "..", "..", "..");
  for (let i = 0; i < 5; i++) {
    const candidate = join(dir, "_meta", "agentdb", "agent.db");
    if (existsSync(candidate)) return candidate;
    dir = resolve(dir, "..");
  }
  throw new Error("AgentDB not found. Expected _meta/agentdb/agent.db in project root.");
}
function getDb() {
  if (!db) {
    const dbPath = findAgentDb();
    db = new Database(dbPath, { readonly: true });
    db.pragma("journal_mode = WAL");
    db.pragma("busy_timeout = 5000");
  }
  return db;
}
function getProjectRoot() {
  let dir = resolve(import.meta.dirname, "..", "..", "..");
  for (let i = 0; i < 5; i++) {
    if (existsSync(join(dir, "_meta"))) return dir;
    dir = resolve(dir, "..");
  }
  throw new Error("Project root not found");
}

export { getProjectRoot as a, getDb as g };
//# sourceMappingURL=db-DP8A50Zn.js.map
