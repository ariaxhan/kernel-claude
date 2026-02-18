# KERNEL v5.3.0

AgentDB-first. Read at start. Write at end.

---

## ●:AGENTDB (NON-NEGOTIABLE)

**Every artifact reads on start, writes on end. No exceptions.**

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

| Tier | Files | Action |
|------|-------|--------|
| 1 | 1-2 | Execute directly |
| 2 | 3-5 | Spawn surgeon agent |
| 3 | 6+ | Contract → surgeon → adversary |

**Auto-spawn:** Don't ask. Detect tier from file count, spawn appropriate agents.

---

## ●:AGENTS

| Agent | When | Focus |
|-------|------|-------|
| surgeon | Tier 2+ | Minimal diff, commit working state |
| adversary | Before ship | Assume broken, find edge cases, prove |

Orchestrator = you (main session). No separate orchestrator agent needed.

---

## ●:FLOW

```
1. READ: agentdb read-start (failures to avoid, patterns, checkpoint)
2. SCOPE: Determine tier (file count), create contract if Tier 2+
3. WORK: Execute or spawn agents
4. VERIFY: Run adversary for Tier 2+
5. WRITE: agentdb write-end, commit
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
| /build | Full pipeline: research → plan → implement → verify |
| /validate | Pre-commit gate: types, lint, tests |
| /ship | Commit, push, PR |
| /contract | Create scoped work agreement |
| /ingest | Universal entry point (classify → route) |

---

## ●:SKILLS

| Skill | Trigger |
|-------|---------|
| debug | bug, error, fix, broken |
| research | investigate, find out, how does |
| discovery | first time in codebase |
| build | implement, add, create |

Skills auto-trigger. Don't invoke manually unless needed.

---

## ≠:ANTI

```
skip_agentdb_read → will repeat past failures
skip_agentdb_write → context lost on resume
prompt_hooks → token waste, use command hooks
multi_tab_architecture → one session spawns agents
write_only_logs → if never read, delete it
```

---

## ●:GIT

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
