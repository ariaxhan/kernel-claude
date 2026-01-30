---
name: coding-prompt-bank
description: Base rules and behaviors for AI coding agents. Trigger on starting a coding project, "use my coding rules", "coding agent setup", "initialize project", "new codebase", or when providing instructions to any coding agent (Claude Code, Cursor, etc). Provides tier-based complexity rules and project templates.
---

# Coding Prompt Bank

Project-agnostic base rules for AI coding agents. Copy relevant sections based on tier.

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
```

### Atomicity
```
No partial states. Transaction succeeds or rolls back.
Test in isolation before integration.
```

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
- Test coverage
- Rollback plan
- Documentation
- Code review checklist

## Validation Protocol

Before implementation:
```
□ Working example found?
□ Dependencies identified?
□ Integration points clear?
□ Done-when defined?
□ Edge cases listed?
```

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

## Quick Reference

```
BEFORE WRITING:
□ What am I building?
□ Why this approach?
□ What depends on this?
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

## Anti-Patterns

- Speculative code ("in case we need it")
- Partial implementations
- Silent failures
- Reimplementing existing solutions
- Skipping investigation phase
- Multiple sources of truth
