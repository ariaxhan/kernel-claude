---
description: Systematic debugging workflow - reproduce, isolate, fix, verify
allowed-tools: Read, Bash, Grep, Glob, AskUserQuestion
---

# Debug Command

Apply DEBUGGING-BANK systematic process to the issue.

## Step 1: Read Debugging Bank

Read DEBUGGING-BANK.md from kernel/banks/ (or project root if copied).

## Step 2: Understand the Problem

Ask user (if not already clear):
- What is the expected behavior?
- What is the actual behavior?
- When does it happen? (always, sometimes, specific conditions?)
- Any error messages?

## Step 3: Reproduce

Can we trigger the bug consistently?

If YES:
- Document exact steps to reproduce
- Proceed to isolation

If NO:
- Ask: Under what conditions does it happen?
- Ask: What's different when it doesn't happen?
- Gather more data before proceeding

## Step 4: Isolate

Use binary search to narrow down:

1. Identify the call chain (grep for function calls)
2. Add strategic logging points
3. Check midpoint: Is bug before or after this?
4. Repeat until exact line found

Read relevant files to understand data flow.

## Step 5: Understand Root Cause

Why does this happen?

Check common causes:
- Wrong assumption about input shape
- Off-by-one error
- Race condition / timing
- Missing null check
- Wrong operator (=, ==, ===)
- Mutating shared state
- Variable scope issue

## Step 6: Propose Fix

Fix ROOT CAUSE, not symptom.

Present:
```
## Debugging Analysis

### Problem
[What's wrong]

### Root Cause
[Why it happens]

### Proposed Fix
[Specific code change]

### Why This Works
[Explanation]

### Test Plan
- [ ] Original bug case → Should work
- [ ] Edge cases → Should still work
- [ ] Regression → Old functionality intact
```

## Step 7: Implement & Verify

After user confirms:
1. Apply fix
2. Test original bug case
3. Test edge cases
4. Run existing tests (ensure no regression)

## Notes

- Reference DEBUGGING-BANK.md for full process
- Systematic > random changes
- Always verify the fix
- Document root cause for future reference
