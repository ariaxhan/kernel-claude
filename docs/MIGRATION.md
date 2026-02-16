# Migration Guide: v4.x to v5.x

**From:** KERNEL v4.x (25 agents, verbose config)
**To:** KERNEL v5.1.0 (6 agents, VN-native, AgentDB)

---

## Overview

v5 is a complete rewrite. The old structure is incompatible.

| Aspect | v4.x | v5.x |
|--------|------|------|
| Agents | 25 specialized | 6 orchestration |
| Config | Verbose CLAUDE.md | VN-native (~200 tokens) |
| Memory | File-based | AgentDB (SQLite) |
| Rules | `.claude/rules/` | `skills/rules/` |
| Banks | `banks/` | `skills/` |
| Communication | Direct | Via AgentDB bus |

---

## Structure Changes

### Directory Mapping

| v4.x | v5.x | Notes |
|------|------|-------|
| `kernel/` | (root) | Flattened |
| `.claude/` | (deleted) | Plugin IS config |
| `.claude/rules/` | `skills/rules/SKILL.md` | Merged |
| `banks/` | `skills/` | Renamed |
| `agents/` (25) | `agents/` (6) | Consolidated |
| `_meta/memory/` | `_meta/agentdb/` | SQLite |

### Agent Consolidation

**Removed agents** (functionality absorbed):

| Old Agent | Now Handled By |
|-----------|---------------|
| test-runner | `/validate` command |
| lint-fixer | `/validate` command |
| type-checker | `/validate` command |
| doc-writer | `/docs` command |
| refactorer | surgeon agent |
| debugger | `/debug` skill |
| reviewer | `/tearitapart` command |
| planner | architect agent |
| researcher | researcher agent (kept) |
| searcher | searcher agent (kept) |
| executor | surgeon agent |
| validator | adversary agent |

**New agent mapping:**

| v5 Agent | Absorbs |
|----------|---------|
| orchestrator | coordinator, router, decider |
| architect | planner, scopper, risk-assessor |
| surgeon | executor, refactorer, implementer |
| adversary | validator, tester, reviewer |
| searcher | code-searcher, tracer |
| researcher | doc-reader, api-finder |

---

## Config Migration

### Old CLAUDE.md (v4.x)

```markdown
# KERNEL

## Agents
- test-runner: Run tests
- lint-fixer: Fix lint errors
- type-checker: Verify types
... (hundreds of lines)
```

### New CLAUDE.md (v5.x)

```markdown
# KERNEL v5.1.0

tokens: ~200 | vn-native | plugin | agentdb-bus

## Ψ:ARCHITECTURE
4 orchestration agents + 1 agentdb = zero relay
...
```

**No migration needed.** Delete old project CLAUDE.md. Plugin provides everything.

---

## New Patterns

### AgentDB (Replaces File Memory)

**Old (v4.x):**
```markdown
# _meta/memory/session.md
Last action: implemented auth
Files touched: user.py, auth.py
```

**New (v5.x):**
```sql
INSERT INTO context_log (tab, type, vn, detail, contract)
VALUES ('exec', 'checkpoint', '●checkpoint|commit:abc123', '{"files":["user.py"]}', 'auth-001');
```

### Contracts (Replaces Implicit Work)

**Old:** Start working immediately
**New:** Create contract first

```
CONTRACT: auth-001
─────────────
GOAL: Add JWT authentication
CONSTRAINTS: Tier 2, no new deps
FAILURE CONDITIONS: Breaks existing auth
ASSIGN: exec
```

### Tier Routing (Replaces Ad-Hoc)

**Old:** Manual decision on complexity
**New:** Auto-detected, explicit tiers

| Tier | Files | Flow |
|------|-------|------|
| 1 | 1-2 | main executes |
| 2 | 3-5 | main → exec |
| 3 | 6+ | main → plan → exec → qa |

---

## Command Changes

### Renamed

| v4.x | v5.x |
|------|------|
| `/test` | `/validate` |
| `/lint` | `/validate` |
| `/typecheck` | `/validate` |
| `/init` | `/repo-init` |
| `/plan` | `/build --plan-only` |
| `/review` | `/tearitapart` |

### New Commands

| Command | Purpose |
|---------|---------|
| `/contract` | Create explicit work agreement |
| `/orchestrate` | Full multi-agent coordination |
| `/kernel-status` | Config health check |
| `/kernel-prune` | Remove stale entries |
| `/handoff` | Session continuation brief |

### Removed Commands

| v4.x | Replacement |
|------|-------------|
| `/spawn-agent` | Automatic via tiers |
| `/memory` | Query AgentDB directly |
| `/rules` | `skills/rules/SKILL.md` |

---

## Path Changes

| v4.x | v5.x |
|------|------|
| `kernel/CLAUDE.md` | `CLAUDE.md` (root) |
| `kernel/agents/` | `agents/` |
| `kernel/banks/` | `skills/` |
| `.claude/rules/` | `skills/rules/SKILL.md` |
| `.claude/plans/` | `_meta/plans/` |
| `_meta/memory/` | `_meta/agentdb/` |

---

## Migration Steps

### 1. Remove Old Config

```bash
rm -rf .claude/
rm -f CLAUDE.md  # if project-specific
```

### 2. Install Plugin

```bash
/install-plugin https://github.com/ariaxhan/kernel-claude
```

### 3. Initialize New Project

```bash
/repo-init
```

This creates:
- `_meta/context/active.md`
- `_meta/_learnings.md`
- `_meta/agentdb/` (on first contract)

### 4. Migrate Project Rules

If you had project-specific rules in `.claude/rules/`:

1. Review each rule
2. Add to `_meta/_learnings.md` as patterns
3. Or contribute to `skills/rules/SKILL.md` if universal

### 5. Migrate Memory

Old session memory is incompatible. Start fresh:

1. Review `_meta/memory/` for critical context
2. Add key learnings to AgentDB rules table
3. Delete old memory files

---

## Breaking Changes

1. **No project CLAUDE.md** - Plugin provides all config
2. **No `.claude/` directory** - Removed entirely
3. **25 agents → 6 agents** - Specialized agents consolidated
4. **File memory → SQLite** - AgentDB replaces markdown
5. **Implicit work → Contracts** - Explicit scope required
6. **Manual routing → Tier system** - Auto-detected complexity

---

## Compatibility

| Feature | v4.x Projects | Action |
|---------|--------------|--------|
| Existing code | Compatible | No change |
| `.claude/` | Incompatible | Delete |
| `_meta/memory/` | Incompatible | Migrate or delete |
| Project CLAUDE.md | Ignored | Delete |
| Commands | Changed | Learn new names |
