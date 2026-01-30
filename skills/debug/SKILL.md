---
name: debug
description: Systematic debugging methodology - auto-triggers on bug/error/not working signals
---

# Debug Skill

## Purpose

This skill provides a systematic methodology for diagnosing and fixing bugs. It auto-triggers when context suggests debugging is needed.

**Key Concept**: Most debugging failures come from jumping to solutions before understanding the problem. This skill enforces a disciplined approach.

---

## Auto-Trigger Signals

This skill activates when detecting:
- "bug", "error", "fix", "broken", "not working"
- "fails", "failing", "crashed", "unexpected"
- Stack traces or error messages in context
- "why is this...", "why does this..."

---

## The Four-Phase Protocol

### PHASE 1: Deep Reproduction

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
```

**Anti-pattern**: "It sometimes fails" - get SPECIFIC.

---

### PHASE 2: Systematic Isolation (Binary Search)

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

---

### PHASE 3: Root Cause Analysis

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

---

### PHASE 4: Permanent Fix + Regression Test

```
FIX PROTOCOL:
1. Fix the ROOT CAUSE, not the symptom
2. Write a test that would have caught this
3. Verify the fix doesn't break other things
4. Document in kernel/project-notes/bugs.md

TEST REQUIREMENT:
Every bug fix MUST include a test that:
- Reproduces the original bug (would fail before fix)
- Passes after the fix
- Prevents regression
```

---

## Quick Reference

| Phase | Question | Output |
|-------|----------|--------|
| Reproduce | What exactly happens? | Bug spec |
| Isolate | Where exactly is it? | Location |
| Root Cause | Why does it happen? | Understanding |
| Fix | How to prevent forever? | Code + Test |

---

## Integration

- **Memory First**: Check `kernel/project-notes/bugs.md` before debugging
- **Bank Reference**: Load `kernel/banks/DEBUGGING-BANK.md` for complex bugs
- **Log When Done**: Add solved bug to bugs.md for future reference

---

## Anti-Patterns

- Jumping to code changes without reproducing
- "Let me try this and see" approach
- Fixing symptoms instead of root cause
- Not writing regression tests
- Not documenting the fix

---

## Success Metrics

Debugging is working well when:
- Bug is reproduced before any fix attempted
- Root cause is understood, not just symptoms
- Regression test prevents recurrence
- Bug is documented for team knowledge
