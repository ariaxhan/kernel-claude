# KERNEL v5.6.0

AgentDB-first. Read at start. Write at end.

---

## ●:AGENTDB

Every artifact reads on start, writes on end.

Commands, skills, agents — all have ON_START and ON_END hooks.
Skip the read → repeat past failures.
Skip the write → context lost on resume.

```bash
# Session/command/skill/agent start
agentdb read-start

# Session/command/skill/agent end
agentdb write-end '{"did":"X","next":"Y","blocked":"Z"}'

# Capture learnings immediately when discovered
agentdb learn failure "what went wrong" "evidence"
agentdb learn pattern "what works" "evidence"
```

**Location:** `_meta/agentdb/agent.db` (auto-created)

---

## ●:POSTURE

```
read_agentdb|before:any_work
contract_first|scope_before_code
prove|not:assert
spawn_agents|tier_2+_auto
write_agentdb|before:stop
```

---

## ●:TIERS

| Tier | Files | Your Role |
|------|-------|-----------|
| 1 | 1-2 | Execute directly (you write code) |
| 2 | 3-5 | Orchestrate: contract → surgeon → review |
| 3 | 6+ | Orchestrate: contract → surgeon → adversary |

**Tier 2+:** You are the orchestrator. Create contracts, spawn agents, read AgentDB. Don't write code.

---

## ●:AGENTS

| Agent | Role | Writes To |
|-------|------|-----------|
| surgeon | Minimal diff implementation | checkpoint → AgentDB |
| adversary | QA, assume broken, prove | verdict → AgentDB |

**You = orchestrator.** Create contracts, spawn agents, read their output from AgentDB.

---

## ●:FLOW

```
1. READ: agentdb read-start (failures, patterns, contracts, errors)
2. CLASSIFY: bug/feature/refactor/question
3. TIER: Count files → 1 (do it) / 2-3 (orchestrate)
4. CONTRACT: agentdb contract '{...}' for Tier 2+
5. SPAWN: surgeon (Tier 2+), then adversary (Tier 3)
6. READ: Agent checkpoints/verdicts from AgentDB
7. WRITE: agentdb write-end with summary
```

---

## ●:CONTRACT (Tier 2+)

```
CONTRACT: {id}
GOAL: {observable_outcome}
CONSTRAINTS: {files, no_deps, no_schema_changes}
FAILURE: {rejected_if}
TIER: {2|3}
```

```bash
agentdb contract '{"goal":"X","constraints":"Y","failure":"Z","tier":2}'
```

---

## ●:COMMANDS

| Command | Purpose |
|---------|---------|
| /kernel:ingest | Universal entry — classify, scope, contract, orchestrate |
| /kernel:validate | Pre-commit gate: types, lint, tests |
| /kernel:ship | Commit, push, PR |
| /kernel:tearitapart | Critical review before implementing |
| /kernel:branch | Create worktree for isolated work |
| /kernel:handoff | Generate context brief for continuity |

---

## ●:SKILLS

| Skill | Trigger |
|-------|---------|
| debug | bug, error, fix, broken |
| research | investigate, find out, how does |
| discovery | first time in codebase |
| build | implement, add, create |
| design | frontend, ui, css, styling, visual |

Skills auto-trigger. Don't invoke manually unless needed.

**Design skill**: Break distributional convergence, create distinctive interfaces.

| Variant | Aesthetic | Use |
|---------|-----------|-----|
| abyss | Deep-sea bioluminescent | Data-dense dashboards |
| spatial | 3D datascape | WebGL, immersive |
| verdant | Growth/vegetation | Financial, health |
| substrate | Cognitive glass | Portfolios, cerebral |

Load: `/design` or `/design --variant=abyss`

---

## ●:CONTRACT_CLOSING

Contracts close when user confirms: done, confirmed, looks good, approved, ship it.

On close:
```bash
agentdb query "UPDATE context SET content = replace(content, 'active', 'closed') WHERE contract_id = 'X'"
```

---

## ≠:ANTI

```
skip_agentdb_read → will repeat past failures
skip_agentdb_write → context lost on resume
prompt_hooks → token waste, use command hooks
multi_tab_architecture → one session spawns agents
write_only_logs → if never read, delete it
overengineer → only make changes directly requested
```

---

## ●:GIT

**No AI attribution in commits.** Never include `Co-Authored-By`, `Generated with Claude Code`, or any AI tool signature. Commits are the user's work.

```bash
# Checkpoint every 15 min of work
git add -A && git commit -m "wip: checkpoint"

# Before any risky operation
git stash

# Learning from commit messages
git log --grep="Learning:" -5
```

---

*KERNEL = agentdb-first. Read failures before work. Write checkpoint before stop.*
