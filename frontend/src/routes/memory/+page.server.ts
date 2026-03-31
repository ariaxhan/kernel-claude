import { getDb } from '$lib/server/db';
import type { Learning, ContextEntry } from '$lib/types';

export function load() {
  const db = getDb();

  const learnings = db.prepare(
    'SELECT * FROM learnings ORDER BY last_hit DESC, hit_count DESC'
  ).all() as Learning[];

  const contracts = db.prepare(
    "SELECT * FROM context WHERE type = 'contract' ORDER BY ts DESC LIMIT 20"
  ).all() as ContextEntry[];

  const verdicts = db.prepare(
    "SELECT * FROM context WHERE type = 'verdict' ORDER BY ts DESC LIMIT 20"
  ).all() as ContextEntry[];

  // Group learnings by type
  const patterns = learnings.filter(l => l.type === 'pattern');
  const failures = learnings.filter(l => l.type === 'failure');
  const gotchas = learnings.filter(l => l.type === 'gotcha');
  const preferences = learnings.filter(l => l.type === 'preference');

  return { patterns, failures, gotchas, preferences, contracts, verdicts };
}
