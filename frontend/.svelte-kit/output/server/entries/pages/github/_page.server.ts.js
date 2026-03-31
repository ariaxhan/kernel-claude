import { execSync } from "node:child_process";
import { a as getProjectRoot } from "../../../chunks/db.js";
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
export {
  load
};
