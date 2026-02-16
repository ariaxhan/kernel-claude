---
name: review
description: Code review methodology - correctness, consistency, completeness
triggers:
  - review
  - code review
  - PR review
  - review this
  - check this code
  - LGTM?
---

# Review Skill

## Purpose

Correctness, consistency, completeness. Check against spec, conventions (state.md), invariants, and validation matrix.

**Key Concept**: Good reviews prevent bugs from reaching production.

---

## Auto-Trigger Signals

This skill activates when detecting:
- "review", "code review", "PR review"
- "check this", "look at this code"
- "is this correct", "LGTM?"
- Git diff or commit output in context

---

## Process

```
1. READ → Understand what changed (git diff, commit message)
2. CORRECTNESS → Does it do what it should? Edge cases handled?
3. CONSISTENCY → Matches conventions in state.md?
4. CONTRACTS → Respects invariants?
5. VALIDATION → Are relevant checks passing?
6. VERDICT → Approve, request changes, or block
```

---

## Correctness Checks

```
□ Solves stated problem: Does it do what spec/issue says?
□ Edge cases: Null, empty, boundary values handled?
□ Error handling: All failure paths covered?
□ Types: Correct types, no type errors?
□ Logic: Conditions correct? No off-by-one errors?
□ Integration: Connects correctly to adjacent code?
□ Side effects: Only intended database writes, API calls, file changes?
□ No regressions: Existing functionality still works?
```

---

## Convention Adherence

Check against `_meta/context/active.md` conventions:
```
□ Naming: Follows project naming pattern
□ Error handling: Matches project error pattern
□ Logging: Uses project logger pattern
□ Config: Uses project config pattern
□ File structure: Placed in correct directory
□ Formatting: Matches project format
```

---

## Invariant Checks

Check against `.claude/rules/invariants.md`:
```
□ Interface stability: No breaking changes to public APIs?
□ Data integrity: No violations of schema/constraints?
□ Security: No auth bypasses, secret leaks, injection vulnerabilities?
□ Performance: No obvious performance regressions?
□ Compatibility: Backward compatible per versioning policy?
```

---

## Severity Markers

Use in review comments:

| Marker | Meaning | Action Required |
|--------|---------|-----------------|
| BLOCK | Critical issue | Must fix |
| IMPORTANT | Strongly suggest | Should fix |
| SUGGEST | Optional improvement | Consider |
| QUESTION | Clarification needed | Explain |

---

## Review Comment Templates

**Asking Questions:**
```
QUESTION: What happens if `user` is null here?
QUESTION: Why did we choose approach X over Y?
```

**Suggesting Changes:**
```
SUGGEST: Consider extracting this into a helper function
SUGGEST: This might be clearer with early return
```

**Blocking Issues:**
```
BLOCK: This allows SQL injection - use parameterized queries
BLOCK: Missing auth check - users can access others' data
BLOCK: No tests for new logic
```

**Approving:**
```
APPROVED: Clean implementation, follows conventions
APPROVED: With minor suggestions (see SUGGEST comments)
```

---

## Verdict Format

```markdown
## Code Review

**Summary**: [One line about what changed]

**Correctness**: [Pass/Issues found]
**Conventions**: [Pass/Issues found]
**Invariants**: [Pass/Issues found]

**Validation**:
- Linter: [pass/fail]
- Tests: [pass/fail]
- Typecheck: [pass/fail]

**Verdict**: [APPROVED / APPROVED WITH CHANGES / NEEDS WORK / BLOCKED]
```

---

## Stack-Specific Patterns

**JavaScript/TypeScript:**
- Check for mutation (prefer immutable)
- Check for strict equality (=== not ==)
- Check for awaited promises

**Python:**
- Check for mutable default arguments
- Check for specific exception handling
- Check for type hints

**Go:**
- Check for error handling (if err != nil)
- Check for goroutine leaks
- Check for proper defer usage

---

## Anti-Patterns

- Approving without reading
- Nitpicking style over substance
- Missing security issues
- Not checking existing patterns
- Blocking for preferences not requirements

---

## Success Metrics

Review is working well when:
- Real issues are caught before merge
- Feedback is actionable
- Conventions are maintained
- Security issues are never missed
