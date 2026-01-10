---
description: Show KERNEL config health and staleness report
allowed-tools: Read, Glob, Bash
---

Analyze the current KERNEL configuration and report health status.

## Steps

1. **Scan config directories** for all artifacts:
   - `.claude/commands/*.md` (excluding this file)
   - `.claude/agents/*.md`
   - `.claude/skills/*.md`
   - `.claude/rules/*.md`
   - `.mcp.json` entries
   - `.claude/settings.json` hooks

2. **Read registry** from `memory/config_registry.jsonl`:
   - Parse each line as JSON
   - Build map of {type+name -> entry}

3. **Cross-reference** artifacts with registry:
   - **Active**: referenced within last 7 days
   - **Stale**: no reference in 30+ days
   - **New**: created within last 7 days
   - **Untracked**: exists but not in registry (bootstrap candidate)

4. **Output report**:

```
KERNEL Config Status
====================

Config entries: X
  Active (referenced last 7 days): N
  Stale (no reference 30+ days): N
  New (< 7 days old): N
  Untracked: N

Commands: X total
  [status] command-name (last used: date, count: N)
  ...

Agents: X total
  ...

Skills: X total
  ...

Rules: X total
  ...

MCP Servers: X total
  ...

Hooks: X total
  ...
```

5. **If untracked entries exist**, offer to bootstrap them into the registry.

6. **If stale entries exist**, suggest running `/kernel:prune` for cleanup review.
