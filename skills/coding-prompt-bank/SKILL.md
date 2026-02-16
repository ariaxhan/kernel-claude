---
name: coding-prompt-bank
description: Base rules and behaviors for AI coding agents. Trigger on starting a coding project, "use my coding rules", "coding agent setup", "initialize project", "new codebase", or when providing instructions to any coding agent (Claude Code, Cursor, etc). Provides tier-based complexity rules and project templates.
triggers:
  - coding rules
  - coding agent setup
  - initialize project
  - new codebase
  - use my coding rules
  - project setup
---

# Coding Prompt Bank

Project-agnostic base rules for AI coding agents. Copy relevant sections based on tier.

---

## Core Philosophy

```
PARSE, DON'T READ
Treat requests as objects to decompose.
Extract: goal, constraints, inputs, outputs, dependencies.
Never process as prose blob.

CORRECTNESS > SPEED
Working first attempt beats fast iteration + debug.
Mental simulation catches 80% of bugs before execution.

EVERY LINE IS LIABILITY
Config > code. Native > custom. Existing > new.
Delete what doesn't earn its place.

CONTEXT IS SCARCE
Lean context prevents rot.
Reference, don't restate.
Compress aggressively.
```

---

## Recursive Decomposition Pattern

```
1. INSPECT: Examine input programmatically, not wholesale
2. FILTER: Extract only relevant portions
3. TRANSFORM: Process via focused sub-operations
4. DELEGATE: Spawn sub-tasks with minimal context
5. AGGREGATE: Combine results, discard intermediates

Apply at every scale: task → subtask → function → line.
```

---

## Execution Laws

### Investigate First
```
NEVER implement first.
1. Find working example (search, grep, docs)
2. Read every line
3. Copy pattern exactly
4. Adapt minimally
```

### Single Source of Truth
```
One location for each concern:
- Auth: one extraction point
- Validation: one schema
- Config: one file
- Types: one definition
```

### Fail Fast
```
Exit early. Clear messages. No silent failures.
If uncertain: STOP → ASK → WAIT.
Assumptions cause debugging.
```

### Atomicity
```
No partial states.
- Writes: transaction or nothing
- Async: use locks
- Batch: Promise.all, not loop-await
```

### Response Handling
```
Different sources = different shapes.
- Read type definition first
- Never assume .data exists
- Verify shape before access
```

---

## Git Workflow: Worktree-Based Development

```
NEVER WORK ON MAIN
All work happens on isolated worktrees.
Create worktree first, then code.
Git history IS the changelog. Ship via PR.
```

### Starting Work
```bash
# 1. Check current state
git branch --show-current
git worktree list

# 2. If on main, create worktree for work
PROJECT=$(basename $(pwd))
git worktree add -b <type>/<description> ../${PROJECT}-<type>-<description>
```

### Branch Types
```
feat/     New feature
fix/      Bug fix
docs/     Documentation
refactor/ Code restructure
test/     Test changes
chore/    Maintenance
```

---

## Tier Selection

```
T1 (Hackathon): Learning, throwaway, demo, <4 hours
T2 (Real): Side project, MVP, anything that persists (DEFAULT)
T3 (Critical): Production, multi-team, regulated, zero-downtime
```

### T1: Minimal Process
- Ship > perfect
- Comments optional
- Tests optional
- "Does it work?" is the only gate

### T2: Default Standard (use for most work)
- Pre-flight: What am I building? Why this approach? How will I know it works?
- One task = one thing
- Verify integration immediately
- Log decisions: `DECISION: X because Y`
- Basic error handling

### T3: Full Rigor
- Phase gates required
- All T2 rules +
- Test coverage 100%
- Rollback plan
- Documentation
- Code review checklist
- Audit trail: who/what/when/why
- Contract tests at boundaries
- Conflict resolution: STOP → report → wait

---

## Validation Protocol

**Pre-Write:**
```
□ State what, why, dependencies
□ Interfaces defined (inputs/outputs/errors)
□ Done-when criteria explicit
□ Working pattern found
□ Pause if anything unclear
```

**Pre-Commit:**
```
□ Matches spec exactly? Nothing more?
□ Connects to adjacent components?
□ 3 edge cases confirmed?
□ Linter clean?
□ Types correct?
```

**Kill Criteria:**
```
STOP if:
- More custom code than expected
- Core assumption proven false
- Native solution found mid-build
- Fighting the framework
```

---

## Error Prevention

```
GRACEFUL DEGRADATION
Optional fails → core continues.
Feature flags > hard dependencies.

IDEMPOTENT OPERATIONS
Same command twice = same state.
Safe to retry. Safe to resume.

ROLLBACK AWARE
Know how to undo before doing.
Document recovery path.
```

---

## Project Template

```
PROJECT: [name]
TIER: [1-3] (default: 2)
STACK: [languages, frameworks, infra]

CONSTRAINTS:
- [hard limit 1]
- [hard limit 2]

AVOID:
- [anti-pattern 1]
- [anti-pattern 2]

OVERRIDES:
- [any base rule modifications]

TASK: [current request]
```

---

## Quick Reference

```
BEFORE WRITING:
□ What am I building?
□ Why this approach?
□ What depends on this?
□ What does this depend on?
□ How will I know it works?

DURING:
□ One task, one thing
□ Clear done-when
□ No speculation
□ Verify integration immediately

AFTER:
□ Matches spec exactly?
□ Idempotent?
□ Fail-fast?
□ Decision logged?
```

---

## Testing Requirements

**T2 Minimum:**
```
□ Unit: all components
□ Integration: critical paths
□ Edge: nulls, empty, bounds
□ Error: failures handled
□ Speed: < 30s total
```

**T3 Additions:**
```
□ Contract: API boundaries
□ Coverage: 100%
□ Speed: < 5s (mock externals)
```

---

## Anti-Patterns

```
UNIVERSAL AVOID:
- Raw magic values (use constants/config)
- Deprecated syntax
- Console.log in commits
- Duplicating existing components
- Assuming function signatures
- Silent failures
- Speculation beyond requirements
- Fighting framework conventions
- Speculative code ("in case we need it")
- Partial implementations
- Reimplementing existing solutions
- Skipping investigation phase
- Multiple sources of truth
```

---

## Token Economy

```
STRUCTURE
Summary top, details below.
Phase done → 1-2 line summary.
Reference by ID, don't restate.

COMPRESSION
Strip redundancy ruthlessly.
Minimal context for sub-tasks.
Delete completed intermediate artifacts.
```
