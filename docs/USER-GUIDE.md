# KERNEL User Guide

**Version:** 5.1.0
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

1. **Run `/repo-init`** - Analyzes your codebase, creates `_meta/` directory
2. **AgentDB initializes** - SQLite database at `_meta/agentdb/agent.db`
3. **KERNEL detects stack** - Language, framework, test tools
4. **Ready to work** - No templates to copy, plugin provides everything

```
/repo-init
```

Output shows: stack detected, entry points found, patterns identified.

---

## The 6 Orchestration Agents

KERNEL uses specialized agents in separate tabs, communicating via AgentDB.

### Core 4 (Multi-Tab Model)

| Agent | Tab | Role | Model |
|-------|-----|------|-------|
| **orchestrator** | main | Route work, create contracts, reconcile conflicts, decide ship | opus |
| **architect** | plan | Discovery, scoping, risk identification (Tier 3) | opus |
| **surgeon** | exec | Minimal diff implementation, commit every working state | opus |
| **adversary** | qa | Assume broken, find edge cases, prove/disprove | opus |

### Support 2

| Agent | Tab | Role | Model |
|-------|-----|------|-------|
| **searcher** | search | Deep code search, trace calls, map dependencies | sonnet |
| **researcher** | research | External research - docs, APIs, best practices | sonnet |

### How They Work Together

```
orchestrator creates CONTRACT
       ↓
architect discovers scope (Tier 3)
       ↓
orchestrator approves PACKET
       ↓
surgeon implements minimal diff
       ↓
adversary verifies CHECKPOINT
       ↓
orchestrator reads VERDICT → ship/iterate
```

---

## Commands by Workflow

### Setup Commands

| Command | Purpose |
|---------|---------|
| `/repo-init` | Analyze codebase, create `_meta/`, bootstrap context |
| `/kernel-user-init` | Initialize user-level KERNEL at `~/.claude/` |
| `/kernel-status` | Show KERNEL config health and staleness report |
| `/kernel-prune` | Review and remove stale config entries |

### Development Commands

| Command | Purpose |
|---------|---------|
| `/build` | Full pipeline: idea -> research -> plan -> tearitapart -> execute -> validate |
| `/iterate` | Continuous improvement mode: analyze, improve, iterate on existing code |
| `/validate` | Pre-commit gate: types, lint, tests in parallel |
| `/design` | Design mode: load philosophy, audit UI, build with intention |
| `/docs` | Documentation mode: audit, generate, maintain docs |

### Git Commands

| Command | Purpose |
|---------|---------|
| `/ship` | Commit, push, create PR (optionally release) |
| `/branch` | Create worktree for isolated development |
| `/parallelize` | Set up git worktrees for parallel development |

### Review Commands

| Command | Purpose |
|---------|---------|
| `/tearitapart` | Critical review mode: world-class developer tears your plan apart |
| `/handoff` | Generate structured context brief for session continuation |
| `/contract` | Create explicit work agreement with scope, constraints, failure conditions |
| `/orchestrate` | Invoke full orchestration with multi-agent coordination |

---

## Skills

Skills are loaded on-demand via the Skill tool when relevant triggers occur.

| Skill | Triggers |
|-------|----------|
| **planning** | Complex multi-step tasks, architecture decisions |
| **debug** | Bug reports, error investigation, "not working" signals |
| **research** | "investigate", "find out", research signals |
| **review** | PR reviews, code review requests |
| **discovery** | Exploring unfamiliar codebase |
| **iteration** | Continuous improvement, refactoring |
| **tearitapart** | Critical pre-implementation review |
| **docs** | Documentation generation requests |
| **build** | Feature implementation from idea to code |
| **rules** | Base coding rules, tier system |
| **coding-prompt-bank** | Coding agent setup, project initialization |

---

## AgentDB

SQLite database for agent communication. Located at `_meta/agentdb/agent.db`.

### Key Tables

**context_log** - Communication bus between agents
```sql
SELECT tab, type, vn, detail FROM context_log
WHERE contract = '{id}' ORDER BY ts DESC;
```

**contracts** - Active work agreements
```sql
SELECT id, goal, tier, status FROM contracts
WHERE status = 'active';
```

**rules** - Project-specific learnings
```sql
SELECT domain, rule FROM rules
WHERE confidence = 'proven';
```

**learnings** - Session insights
```sql
SELECT category, summary FROM learnings
ORDER BY created_at DESC LIMIT 10;
```

### Basic Queries

Check recent activity:
```bash
sqlite3 _meta/agentdb/agent.db "SELECT tab, type, vn FROM context_log ORDER BY ts DESC LIMIT 10;"
```

Check active contracts:
```bash
sqlite3 _meta/agentdb/agent.db "SELECT id, goal, tier, status FROM contracts WHERE status = 'active';"
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
3. Plan phase - architect scopes work
4. /tearitapart - critical review of plan
5. Execute phase - surgeon implements
6. QA phase - adversary verifies
7. /ship - commit, push, PR
```

### Refactor (Tier 3)

```
1. /iterate on authentication module
2. Architect analyzes coupling, dependencies
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
| 3 | 6+ files | orchestrator -> architect -> surgeon -> adversary |

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
- **LSP first** - goToDefinition, findReferences, hover

---

## Quick Reference

```bash
# Start new project
/repo-init

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
```
