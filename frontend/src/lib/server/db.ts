import Database from 'better-sqlite3';
import { resolve, join } from 'node:path';
import { existsSync } from 'node:fs';

let db: Database.Database | null = null;

function findAgentDb(): string {
  // Walk up from frontend/ to find _meta/agentdb/agent.db
  let dir = resolve(import.meta.dirname, '..', '..', '..');
  for (let i = 0; i < 5; i++) {
    const candidate = join(dir, '_meta', 'agentdb', 'agent.db');
    if (existsSync(candidate)) return candidate;
    dir = resolve(dir, '..');
  }
  throw new Error('AgentDB not found. Expected _meta/agentdb/agent.db in project root.');
}

export function getDb(): Database.Database {
  if (!db) {
    const dbPath = findAgentDb();
    db = new Database(dbPath, { readonly: true });
    db.pragma('journal_mode = WAL');
    db.pragma('busy_timeout = 5000');
  }
  return db;
}

export function getProjectRoot(): string {
  let dir = resolve(import.meta.dirname, '..', '..', '..');
  for (let i = 0; i < 5; i++) {
    if (existsSync(join(dir, '_meta'))) return dir;
    dir = resolve(dir, '..');
  }
  throw new Error('Project root not found');
}
