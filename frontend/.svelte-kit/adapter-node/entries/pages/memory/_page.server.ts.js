import { g as getDb } from "../../../chunks/db.js";
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
export {
  load
};
