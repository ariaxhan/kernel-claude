---
description: Review and remove stale KERNEL config entries
allowed-tools: Read, Write, Edit, Glob, Bash
---

Identify stale configuration entries and prompt for removal.

## Steps

1. **Load registry** from `_meta/config_registry.jsonl`

2. **Identify stale entries** (no reference in 30+ days):
   - Commands not invoked
   - Agents not spawned
   - Skills not used
   - Rules not applied
   - MCP servers not called
   - Hooks not triggered

3. **For each stale entry**, present to user:

```
STALE: [type] name
  Created: YYYY-MM-DD
  Last referenced: YYYY-MM-DD (X days ago)
  Reference count: N

  Remove this entry? [Y/n/skip all]
```

4. **On confirmation (Y)**:
   - Delete the artifact file (command, agent, skill, rule)
   - Or remove entry from config file (`.mcp.json`, `settings.json`)
   - Remove entry from `config_registry.jsonl`
   - Log removal to `_meta/logs/kernel-pruning-log.md`

5. **On rejection (n)**:
   - Update `last_referenced` to now (resets staleness timer)
   - Keep the entry

6. **On skip all**:
   - Stop prompting, exit prune mode

7. **Summary**:

```
Prune complete
  Reviewed: X entries
  Removed: N
  Kept: N
  Skipped: N
```

## Safety

- NEVER auto-delete without confirmation
- Always show what will be removed before removing
- Log all removals for audit trail
- Offer undo hint: "Removed files can be restored via git checkout"
