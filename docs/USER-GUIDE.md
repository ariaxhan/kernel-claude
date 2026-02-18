# KERNEL User Guide

**Version:** 5.2.0
**Plugin for:** Claude Code CLI

---

## Installation

```bash
/install-plugin https://github.com/ariaxhan/kernel-claude
```

After installation, KERNEL loads automatically for all projects.

---

## First Session

When you start a session in a new project:

1. **AgentDB initializes** - SQLite database at `_meta/agentdb/agent.db`
2. **Run `agentdb read-start`** - Reads failures to avoid, active contract, last checkpoint
3. **KERNEL detects stack** - Language, framework, test tools
4. **Ready to work** - No templates to copy, plugin provides everything

```bash
agentdb read-start
```

Output shows: recent failures, active patterns, last checkpoint.

---

## The 2 Orchestration Agents

KERNEL uses two specialized agents for implementation and verification.

| Agent | Role | Model |
|-------|------|-------|
| **surgeon** | Minimal diff implementation, commit every working state | opus |
| **adversary** | Assume broken, find edge cases, prove/disprove | opus |

### How They Work Together

```
orchestrator (you) creates CONTRACT
       |
surgeon implements minimal diff
       |
adversary verifies CHECKPOINT
       |
orchestrator reads VERDICT -> ship/iterate
```

---

## Commands

### Setup Commands

| Command | Purpose |
|---------|---------|
| `/kernel-status` | Show KERNEL config health and staleness report |
| `/kernel-prune` | Review and remove stale config entries |

### Development Commands

| Command | Purpose |
|---------|---------|
| `/build` | Full pipeline: idea -> research -> plan -> tearitapart -> execute -> validate |
| `/validate` | Pre-commit gate: types, lint, tests in parallel |
| `/ingest` | Universal entry point: classify -> route |

### Git Commands

| Command | Purpose |
|---------|---------|
| `/ship` | Commit, push, create PR (optionally release) |
| `/branch` | Create worktree for isolated development |

### Review Commands

| Command | Purpose |
|---------|---------|
| `/tearitapart` | Critical review mode: world-class developer tears your plan apart |
| `/handoff` | Generate structured context brief for session continuation |
| `/contract` | Create explicit work agreement with scope, constraints, failure conditions |

---

## Skills

Skills are loaded on-demand when relevant triggers occur.

| Skill | Triggers |
|-------|----------|
| **debug** | Bug reports, error investigation, "not working" signals |
| **research** | "investigate", "find out", research signals |
| **discovery** | Exploring unfamiliar codebase |
| **build** | Feature implementation from idea to code |

---

## AgentDB

SQLite database for agent memory and communication. Located at `_meta/agentdb/agent.db`.

### Key Tables

**context** - Work state: contracts, checkpoints, handoffs, verdicts
```sql
SELECT id, type, agent, content FROM context
WHERE contract_id = '{id}' ORDER BY ts DESC;
```

Contracts are stored in the `context` table with `type='contract'`:
```sql
SELECT id, content FROM context
WHERE type = 'contract' ORDER BY ts DESC;
```

**learnings** - Cross-session memory (survives forever)
```sql
SELECT type, insight, domain FROM learnings
WHERE type IN ('failure', 'pattern')
ORDER BY ts DESC LIMIT 10;
```

**errors** - Automatic failure capture
```sql
SELECT tool, error, file FROM errors
ORDER BY ts DESC LIMIT 10;
```

### Basic Queries

Check recent context entries:
```bash
sqlite3 _meta/agentdb/agent.db "SELECT type, agent, ts FROM context ORDER BY ts DESC LIMIT 10;"
```

Check active contracts:
```bash
sqlite3 _meta/agentdb/agent.db "SELECT id, content FROM context WHERE type='contract' ORDER BY ts DESC;"
```

Check learnings:
```bash
sqlite3 _meta/agentdb/agent.db "SELECT type, insight FROM learnings ORDER BY ts DESC LIMIT 10;"
```

---

## Common Workflows

### Bug Fix (Tier 1-2)

**Tier 1: 1-2 files** - Orchestrator executes directly
```
1. Describe bug
2. KERNEL diagnoses (grep, read)
3. Minimal fix applied
4. Commit immediately
```

**Tier 2: 3-5 files** - Orchestrator delegates to surgeon
```
1. Describe bug
2. Contract created
3. Surgeon implements fix
4. Adversary verifies (optional)
5. Ship
```

### Feature (Tier 2-3)

**Tier 3: 6+ files** - Full orchestration
```
1. /build "Add user authentication"
2. Research phase - 3+ solution approaches
3. Plan phase - scope work
4. /tearitapart - critical review of plan
5. Execute phase - surgeon implements
6. QA phase - adversary verifies
7. /ship - commit, push, PR
```

### Refactor (Tier 3)

```
1. /build on authentication module
2. Analyze coupling, dependencies
3. Plan created with risk assessment
4. /tearitapart on plan
5. Incremental implementation with commits
6. Adversary ensures no regressions
7. /ship
```

---

## Tier System

| Tier | Scope | Flow |
|------|-------|------|
| 1 | 1-2 files | orchestrator executes directly |
| 2 | 3-5 files | orchestrator -> surgeon |
| 3 | 6+ files | orchestrator -> surgeon -> adversary |

KERNEL auto-detects tier based on scope. You can override:
```
"This is a Tier 1 fix - just update the config"
```

---

## Model Routing

| Tier | Model | Used For |
|------|-------|----------|
| 1 | ollama | Drafts, brainstorm, variations |
| 2 | gemini | Web search, bulk read, research |
| 3 | sonnet | Secondary impl, synthesis |
| 4 | opus | Core impl, planning, orchestrate |
| 5 | haiku | Test exec, lint, typecheck |

---

## Key Principles

- **Contract first** - No work without explicit scope agreement
- **Minimal diff** - Smallest change that works
- **Commit every working state** - Never lose progress
- **Prove, don't assert** - Evidence over claims
- **Memory first** - Check `_meta/` before rediscovering
- **AgentDB first** - Read at session start, write at session end

---

## Quick Reference

```bash
# Start every session
agentdb read-start

# Develop feature
/build "feature description"

# Fix bug
# (just describe - KERNEL auto-detects tier)

# Pre-commit check
/validate

# Ship when ready
/ship

# Critical review
/tearitapart

# Continue after break
/handoff

# End every session
agentdb write-end '{"did":"X","next":"Y"}'
```
