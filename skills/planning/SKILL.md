---
name: planning
description: Strategic planning mode - mental simulation before execution
triggers:
  - plan
  - plan-architecture
  - architecture
  - design system
  - before building
  - how should I
  - plan mode
---

# Planning Skill

## Purpose

Get it right first time. Mental simulation before execution. One working implementation beats three debug cycles.

**Key Concept**: Read state, investigate patterns, define interfaces, then build.

---

## Auto-Trigger Signals

This skill activates when detecting:
- "plan", "plan mode", "planning phase"
- "architecture", "design", "before building"
- "how should I approach", "what's the best way"
- Starting new features without prior research

---

## Process

```
1. UNDERSTAND GOAL → WHAT/WHY/DONE-WHEN
2. EXTRACT ASSUMPTIONS → Tech stack, locations, naming, errors, tests
3. INVESTIGATE → Find existing patterns (read state.md first)
4. DEFINE INTERFACES → Inputs/outputs/errors/side-effects BEFORE implementation
5. MENTAL SIMULATION → Walk through execution, catch bugs before running
6. VALIDATE → Does this match spec? Handle edge cases? Connect to adjacents?
```

---

## Pre-Implementation Checklist

```
□ WHAT: Precise description of what needs to exist
□ WHY: Business/user value this provides
□ DONE-WHEN: Specific, testable completion criteria
□ ASSUMPTIONS: Confirmed (not guessed) about stack, locations, naming
□ EXISTING PATTERNS: Found via grep/glob, not assumed
□ INTERFACES: Inputs, outputs, errors, side-effects specified
□ MENTAL SIMULATION: Walked through 3+ example cases
□ EDGE CASES: Identified what could fail (null, empty, invalid, race)
```

---

## Interface Definition Template

Always define before implementing:

```
INPUTS:
  - param1: Type, constraints, example
  - param2: Type, constraints, example

OUTPUTS:
  - Success: Type, shape, example
  - Error: Type, when it happens

ERRORS:
  - NullInput: When param is null/undefined/None
  - InvalidFormat: When param doesn't match constraints
  - [Dependency]Failed: When external call fails

SIDE EFFECTS:
  - Database: Writes to [table], transaction: [yes/no]
  - API calls: To [service], timeout: [duration]
  - File system: Writes to [path], creates: [yes/no]
```

---

## Mental Simulation Template

```
GIVEN: [Specific input values]

STEP 1: [What happens]
  State: [What changes]
  Output: [What's produced]

STEP 2: [What happens]
  State: [What changes]
  Output: [What's produced]

RESULT: [Expected final output]

EDGE CASE 1: [What if input is null?]
EDGE CASE 2: [What if dependency fails?]
EDGE CASE 3: [What if state is inconsistent?]
```

---

## Investigation Patterns

```bash
# Find similar functionality
grep -r "function.*similar" src/
glob "**/*similar*.{js,py,go}"

# Check conventions in active.md first
cat _meta/context/active.md

# Find error handling patterns
grep -r "try {" src/
grep -r "if err != nil" .
```

---

## Risk Planning

| Risk | Mitigation |
|------|------------|
| Data mutation | Backup before write, transactions |
| External calls | Timeout, retry, circuit breaker |
| Compatibility | Check invariants.md for contracts |
| State changes | Characterization test first |
| Time handling | UTC with explicit timezone |

---

## Validation Before Implementation

```
□ Matches spec exactly (no extra features)
□ Handles 3+ edge cases
□ Connects to adjacent components
□ Types correct
□ Error messages clear
□ No silent failures
```

---

## Anti-Patterns

- Implementing before planning
- Guessing instead of investigating
- No interface definition
- Skipping mental simulation
- Adding features not in spec

---

## Success Metrics

Planning is working well when:
- Implementation matches plan exactly
- No surprises during execution
- Edge cases were anticipated
- Adjacent code connects cleanly
