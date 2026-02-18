---
name: debug
description: Systematic debugging methodology - auto-triggers on bug/error/not working signals
triggers:
  - bug
  - error
  - fix
  - broken
  - not working
  - fails
  - crashed
  - unexpected
---

# Debug Skill

## ●:ON_START (REQUIRED)

```bash
agentdb read-start
```

Check past failures - you may have seen this bug pattern before.

## Purpose

Reproduce first. Isolate via binary search. Instrument, don't guess. Fix root cause, not symptom.

**Key Concept**: Most debugging failures come from jumping to solutions before understanding the problem. Systematic debugging beats random changes.

---

## Auto-Trigger Signals

This skill activates when detecting:
- "bug", "error", "fix", "broken", "not working"
- "fails", "failing", "crashed", "unexpected"
- Stack traces or error messages in context
- "why is this...", "why does this..."

---

## Process

```
1. REPRODUCE → Can you trigger it consistently? If no, gather more data.
2. ISOLATE → Binary search the call chain, find exact location
3. INSTRUMENT → Add logging/breakpoints, observe state
4. UNDERSTAND ROOT CAUSE → Why does this happen? (Not just what fails)
5. FIX ROOT CAUSE → Not the symptom
6. VERIFY → Original bug + edge cases + regression check
```

---

## PHASE 1: Deep Reproduction

Before touching ANY code:

```
REPRODUCE WITH EXACT STEPS:
1. What are the specific inputs that trigger the bug?
2. What is the expected behavior?
3. What is the actual behavior?
4. Is it consistent or intermittent?

DOCUMENT:
- Input: [exact values]
- Expected: [what should happen]
- Actual: [what happens instead]
- Environment: [OS, versions, state]
- Frequency: Always, sometimes, specific conditions?
```

**Anti-pattern**: "It sometimes fails" - get SPECIFIC.

---

## PHASE 2: Systematic Isolation (Binary Search)

Don't grep randomly. Use binary search:

```
CALL CHAIN ANALYSIS:
If A → B → C → D → E fails:

1. Check midpoint (C):
   - Works? Bug is in D or E
   - Fails? Bug is in A, B, or C

2. Repeat until exact location found

This is O(log n), not O(n) random guessing.
```

**Instrumentation**:
- Add logging at boundaries
- Check inputs/outputs at each step
- Verify data shapes match expectations

**Logging Strategy:**
```javascript
console.log('1. Input:', JSON.stringify(input))
console.log('2. After transform:', result1)
console.log('3. Before external call:', params)
console.log('4. After external call:', response)
console.log('5. Final:', output)
```

**Dependency Removal:**
- Comment out external API calls, use mock data
- Comment out database queries, use in-memory data
- Remove complex logic, use simple placeholder
- Isolate which dependency causes failure

---

## PHASE 3: Root Cause Analysis

Once isolated, ask WHY:

```
ROOT CAUSE QUESTIONS:
- What assumption was violated?
- What invariant was broken?
- What changed recently that could cause this?
- Is this a symptom of a deeper issue?

AVOID:
- Fixing symptoms (masking the real bug)
- Guessing without evidence
- "It works now" without understanding why
```

**Common Root Causes:**
- Wrong assumption about input shape/type
- Off-by-one error (loop bounds, array indices)
- Missing null/undefined/None check
- Race condition (async timing issue)
- Mutating shared state
- Wrong operator (=, ==, ===, >, >=)
- Variable scope issue
- Incorrect error handling (swallowing errors)
- API mismatch (expected response vs actual)
- Timezone/datetime handling

---

## PHASE 4: Permanent Fix + Regression Test

```
FIX PROTOCOL:
1. Fix the ROOT CAUSE, not the symptom
2. Write a test that would have caught this
3. Verify the fix doesn't break other things
4. Document in _meta/project-notes/bugs.md

TEST REQUIREMENT:
Every bug fix MUST include a test that:
- Reproduces the original bug (would fail before fix)
- Passes after the fix
- Prevents regression
```

**Regression Validation:**
1. Original bug case - Should now work
2. Edge cases - Null, empty, boundary values still work
3. Happy path - Normal case still works
4. Integration - Adjacent code still works
5. Add test - Prevent regression

---

## Debugging Checklist

**Data Flow:**
```
□ Check input shape/type (log it)
□ Check each transformation step
□ Check output shape/type
□ Verify no mutation of shared data
```

**Logic:**
```
□ Are conditions correct? (>, >=, ==, ===)
□ Are all branches covered?
□ Is loop termination correct?
□ Are variables in correct scope?
```

**Async (if applicable):**
```
□ Are promises awaited?
□ Is race condition possible?
□ Are callbacks called?
□ Is event handler registered?
```

---

## When Stuck

1. Explain to rubber duck (or write it out)
2. Read error message carefully (contains answer 80% of time)
3. Check docs (might be using API wrong)
4. Simplify (make minimal reproduction case)
5. Take a break (fresh eyes find bugs faster)

---

## Quick Reference

| Phase | Question | Output |
|-------|----------|--------|
| Reproduce | What exactly happens? | Bug spec |
| Isolate | Where exactly is it? | Location |
| Root Cause | Why does it happen? | Understanding |
| Fix | How to prevent forever? | Code + Test |

---

## Stack-Specific Instrumentation

| Stack | Debugger | Logging |
|-------|----------|---------|
| JavaScript | `debugger`, Chrome DevTools | `console.log` |
| Python | `import pdb; pdb.set_trace()` | `print()`, logging |
| Go | delve | `fmt.Printf`, `log.Printf` |
| Rust | rust-gdb | `println!`, `dbg!` |

---

## Anti-Patterns

- Jumping to code changes without reproducing
- "Let me try this and see" approach
- Fixing symptoms instead of root cause
- Not writing regression tests
- Not documenting the fix
- Guessing without evidence

---

## Success Metrics

Debugging is working well when:
- Bug is reproduced before any fix attempted
- Root cause is understood, not just symptoms
- Regression test prevents recurrence
- Bug is documented for team knowledge

---

## ●:ON_END (REQUIRED)

```bash
agentdb write-end '{"skill":"debug","bug":"description","fix":"what fixed it","learned":"pattern to remember"}'
```

Always record debugging learnings - they prevent repeat bugs.
