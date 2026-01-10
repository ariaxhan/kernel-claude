---
description: When maintaining config - Show config health and prune stale entries
allowed-tools: Read, Write, Edit, Glob, Bash
---

# Clean Configuration

**When to use**: Regular maintenance to check config health and remove unused artifacts.
**What it does**: Shows status of all KERNEL artifacts and prompts to remove stale entries.

## Process

### Step 1: Show Status

Analyze current KERNEL configuration and report health.

**Scan config directories** for all artifacts:
- `kernel/commands/*.md` (excluding this file)
- `kernel/rules/*.md`
- `.mcp.json` entries
- Hook files

**Read registry** from `memory/config_registry.jsonl`:
- Parse each line as JSON
- Build map of {type+name -> entry}

**Cross-reference** artifacts with registry:
- **Active**: referenced within last 7 days
- **Stale**: no reference in 30+ days
- **New**: created within last 7 days
- **Untracked**: exists but not in registry

**Output status report**:
```
KERNEL Config Status
====================

Config entries: X
  Active (referenced last 7 days): N
  Stale (no reference 30+ days): N
  New (< 7 days old): N
  Untracked: N

Commands: X total
  [active] explore (last used: 2 days ago, count: 15)
  [stale] old-workflow (last used: 45 days ago, count: 3)
  ...

Rules: X total
  ...

MCP Servers: X total
  ...

Hooks: X total
  ...
```

### Step 2: Handle Untracked

If untracked entries exist, offer to bootstrap them into the registry:
```
Found 2 untracked entries:
- [command] new-feature
- [rule] testing-conventions

Add to registry? [Y/n]
```

### Step 3: Prompt for Pruning

If stale entries exist (30+ days no reference), ask:
```
Found 3 stale entries.

Review and remove stale entries? [Y/n]
```

If user says no, exit.

### Step 4: Prune Stale Entries

For each stale entry, present details and prompt:

```
STALE: [command] old-workflow
  Created: 2025-11-15
  Last referenced: 2025-12-01 (40 days ago)
  Reference count: 3

  Remove this entry? [Y/n/skip all]
```

**On Y (remove)**:
- Delete the artifact file
- Or remove from config file (`.mcp.json`, etc.)
- Remove from `config_registry.jsonl`
- Log removal to `memory/pruning-log.jsonl`:
  ```json
  {"type": "command", "name": "old-workflow", "removed_at": "2026-01-10T12:00:00Z", "reason": "stale_30d"}
  ```

**On n (keep)**:
- Update `last_referenced` to now (resets staleness timer)
- Keep the entry

**On skip all**:
- Stop prompting, proceed to summary

### Step 5: Summary

```
Clean complete

Status:
  Total entries: 15
  Active: 10
  Stale: 3
  New: 2

Prune results:
  Reviewed: 3 stale entries
  Removed: 1
  Kept: 2

All removals logged to memory/pruning-log.jsonl
```

## Safety Rules

- NEVER auto-delete without confirmation
- Always show what will be removed before removing
- Log all removals for audit trail
- Hint: "Removed files can be restored via git"

## Example Flow

```
> /clean

KERNEL Config Status
====================
Config entries: 12
  Active (last 7 days): 8
  Stale (30+ days): 3
  New (< 7 days): 1

Commands: 10 total
  [active] explore (2d ago, 15 uses)
  [active] plan (1d ago, 8 uses)
  [stale] old-deploy (35d ago, 2 uses)
  [stale] temp-fix (42d ago, 1 use)
  ...

Found 3 stale entries.
Review and remove? [Y/n] Y

---
STALE: [command] old-deploy
  Created: 2025-11-01
  Last referenced: 2025-12-05 (35 days ago)
  Reference count: 2

Remove? [Y/n/skip] Y
✓ Removed old-deploy.md
✓ Logged removal

---
STALE: [command] temp-fix
  Created: 2025-11-15
  Last referenced: 2025-11-28 (42 days ago)
  Reference count: 1

Remove? [Y/n/skip] n
✓ Kept temp-fix (reset timer)

---
Clean complete
  Reviewed: 3 stale
  Removed: 1
  Kept: 2
```

## Notes

- Run this monthly to keep config lean
- Rejecting a stale entry resets its timer (won't prompt again for 30 days)
- All actions are logged for accountability
