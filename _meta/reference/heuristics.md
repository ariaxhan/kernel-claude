# Decision Heuristics

**Type:** reference | **Load:** on-demand

When to invoke commands, spawn agents, or change execution mode. The routing layer.

---

## Tier Detection

Before ANY implementation: count affected files.

- **1-2 files:** Tier 1. Execute directly.
- **3-5 files:** Tier 2. Invoke /kernel:ingest → contract → surgeon.
- **6+ files:** Tier 3. Invoke /kernel:ingest → contract → surgeon → adversary.
- **Ambiguous:** Assume higher tier. Ask user if still unclear.

---

## Review Trigger

**When:**
- Tier 2+ feature or refactor, before implementation
- Circuit breaker: 3 consecutive failures on same feature
- User says: review, critique, tear apart, find holes, break this

**Action:** Invoke /kernel:tearitapart

**Rule:** If verdict is RETHINK, do NOT proceed. Revise plan first.

---

## Handoff Trigger

**When:**
- Session ending or user says: handoff, pause, continue later, save state
- Context window approaching compaction threshold
- Switching to different agent/system/session

**Action:** Invoke /kernel:handoff

**Rule:** Always capture git state, active contracts, open threads.

---

## Parallel Detection

**When:**
- 2+ independent files to create or modify (no shared dependencies)
- 2+ independent systems to test or verify
- Task contains list of independent subtasks

**Action:** Spawn parallel agents. One contract per file group.

**Constraints:**
- Verify no file overlap between parallel contracts
- Shared files = sequential, not parallel

**Rule:** Default answer is YES to parallelization. Err on the side of parallel.

---

## Error Recovery Trigger

**When:**
- Agent checkpoint reports failure or blocked status
- Adversary verdict is fail
- Same contract fails 2+ times

**Action:** Classify failure type (transient, scope, test, blocked, divergent) and follow error recovery protocol in /kernel:ingest.

**Circuit breaker:** 3 consecutive failures on same feature → stop, invoke /kernel:tearitapart.

---

## Agent Spawn Decision

**When to spawn each agent:**

- **surgeon:** Contract exists, tier 2+, implementation needed
- **adversary:** Surgeon checkpoint complete, tier 3, or user requests verification
- **researcher:** Unfamiliar tech, package selection, new integration. See research_trigger
- **scout:** First codebase interaction, no active.md, stale discovery. See discovery_trigger
- **validator:** Pre-commit, before ship. See validation_trigger

**Rules:**
- Never spawn agent without a contract in AgentDB
- Never spawn adversary without surgeon checkpoint to verify

---

## Research Trigger

**When:**
- Unfamiliar technology or library encountered
- Package selection decision needed
- New external integration
- No existing _meta/research/ doc covers the topic

**Action:** Spawn researcher agent. Wait for output before proceeding to implementation.

**Rules:**
- Never implement with unfamiliar tech without research agent output
- Researcher writes to _meta/research/{topic}-research.md

---

## Discovery Trigger

**When:**
- First session with a codebase
- No _meta/context/active.md exists or is stale (>7 days)
- User says: explore, discover, what's in this repo, map the code

**Action:** Spawn scout agent. Wait for output before any implementation.

**Rules:**
- Never implement in unfamiliar codebase without scout output
- Scout writes to _meta/context/active.md

---

## Validation Trigger

**When:**
- Before any commit (automatic)
- Before /kernel:ship (automatic)
- User says: validate, check, pre-commit

**Action:** Spawn validator agent.

**Rules:**
- Nothing ships without validator pass
- Validator writes verdict to AgentDB

---

## Skill Selection

Methodology only, not actors.

- **bug, error, fix, broken, regression, exception, crash:** Load debug skill (methodology for surgeon)
- **implement, add, create, build, integrate:** Load build skill (methodology for surgeon)
- **frontend, ui, css, styling, visual, design:** Load design skill (aesthetics)

**Note:** research/discovery are now AGENTS, not skills.
