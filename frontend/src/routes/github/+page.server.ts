import { execSync } from 'node:child_process';
import { getProjectRoot } from '$lib/server/db';

export function load() {
  const root = getProjectRoot();
  const remote = getRemote(root);
  if (!remote) return { connected: false, remote: null, issues: [], prs: [], discussions: [] };

  const issues = listIssues(root);
  const prs = listPRs(root);

  return { connected: true, remote, issues, prs, discussions: [] };
}

function getRemote(root: string): string | null {
  try {
    return execSync('git remote get-url origin', { cwd: root, encoding: 'utf-8' }).trim();
  } catch {
    return null;
  }
}

interface Issue {
  number: number;
  title: string;
  state: string;
  labels: string[];
  createdAt: string;
}

function listIssues(root: string): Issue[] {
  try {
    const raw = execSync(
      'gh issue list --limit 15 --json number,title,state,labels,createdAt 2>/dev/null',
      { cwd: root, encoding: 'utf-8', timeout: 10000 }
    );
    const parsed = JSON.parse(raw);
    return parsed.map((i: any) => ({
      number: i.number,
      title: i.title,
      state: i.state,
      labels: (i.labels || []).map((l: any) => l.name),
      createdAt: i.createdAt
    }));
  } catch {
    return [];
  }
}

interface PR {
  number: number;
  title: string;
  state: string;
  headRefName: string;
  createdAt: string;
}

function listPRs(root: string): PR[] {
  try {
    const raw = execSync(
      'gh pr list --limit 10 --json number,title,state,headRefName,createdAt 2>/dev/null',
      { cwd: root, encoding: 'utf-8', timeout: 10000 }
    );
    return JSON.parse(raw);
  } catch {
    return [];
  }
}
