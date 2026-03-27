import { getProjectRoot } from '$lib/server/db';
import { readdirSync, statSync, existsSync } from 'node:fs';
import { join, relative } from 'node:path';
import type { FileNode } from '$lib/types';

export function load() {
  const root = getProjectRoot();
  const metaTree = buildTree(join(root, '_meta'), root, 3);
  const repoTree = buildTree(root, root, 2, ['node_modules', '.git', '_meta', 'frontend']);

  return { metaTree, repoTree, root };
}

function buildTree(dir: string, root: string, maxDepth: number, exclude: string[] = [], depth = 0): FileNode[] {
  if (depth >= maxDepth || !existsSync(dir)) return [];

  try {
    const entries = readdirSync(dir, { withFileTypes: true });
    return entries
      .filter(e => !e.name.startsWith('.') && !exclude.includes(e.name))
      .sort((a, b) => {
        // dirs first, then alpha
        if (a.isDirectory() && !b.isDirectory()) return -1;
        if (!a.isDirectory() && b.isDirectory()) return 1;
        return a.name.localeCompare(b.name);
      })
      .map(entry => {
        const fullPath = join(dir, entry.name);
        const relPath = relative(root, fullPath);
        if (entry.isDirectory()) {
          return {
            name: entry.name,
            path: relPath,
            type: 'directory' as const,
            children: buildTree(fullPath, root, maxDepth, exclude, depth + 1)
          };
        }
        return {
          name: entry.name,
          path: relPath,
          type: 'file' as const
        };
      });
  } catch {
    return [];
  }
}
