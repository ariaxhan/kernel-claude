---
name: governance-sync
description: "Audit or explicitly synchronize Claude and Codex repository governance without overwriting conflicts. Triggers: governance sync, CLAUDE.md, AGENTS.md, instruction mirror."
user-invocable: true
allowed-tools: Read, Bash
disable-model-invocation: true
kernel:
  kind: operator
  version: 1
  side_effects: writes_repo
  confirmation: always
---

# Governance sync

This explicit-only operator audits native repository instructions and can create a
missing Claude or Codex adapter from one declared source. It never edits a conflict.

## Audit first

Run `python3 scripts/governance-sync.py audit <root> --json`. The audit discovers
canonical Git roots, ignores caches, deduplicates linked worktrees, and reports:
missing both, Claude-only, AGENTS-only, both identical, drift, and scoped `.claude`
states. Missing-both is compliant and remains untouched unless `init` is explicit.

## Writes require confirmation

Show the exact repository, source, target, and backup directory. Continue only after
the user confirms one command:

```text
python3 scripts/governance-sync.py adopt REPO --source CLAUDE.md --backup-dir BACKUPS/adopt
python3 scripts/governance-sync.py generate REPO --backup-dir BACKUPS/generate
python3 scripts/governance-sync.py check REPO
```

`AGENTS.md` and `.claude/CLAUDE.md` are also valid sources. The manifest pins the
source path, source hash, output, output hash, and generator version. Scoped sources
stay where they are; only the missing root-native adapter is generated. A regular
file conflict, unrecorded edit, stale hash, malformed manifest, symlink, or existing
backup with different content stops the operation. Identical backups are idempotent.
Use separate `BACKUPS/adopt` and `BACKUPS/generate` phases so an approved source
update preserves both the pre-adoption state and the adapter it replaces.

Use `init REPO --backup-dir BACKUPS` only when the user explicitly wants governance
created in a repository where both native files are absent.
