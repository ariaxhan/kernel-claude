# Review Bank

## Philosophy
Correctness, consistency, completeness. Check against spec, conventions (state.md), invariants (.claude/rules/invariants.md), and validation matrix. Good reviews prevent bugs from reaching production.

## Process Skeleton
1. **Read** → Understand what changed (git diff, commit message)
2. **Correctness** → Does it do what it should? Edge cases handled?
3. **Consistency** → Matches conventions in state.md?
4. **Contracts** → Respects invariants in .claude/rules/invariants.md?
5. **Validation** → Are relevant checks passing?
6. **Verdict** → Approve, request changes, or block

---

## Slots (Designed to Fill)

### Correctness Checks (max 10)
[TO EVOLVE: Add project-specific correctness criteria]

- [ ] **Solves stated problem**: Does it do what spec/issue says?
- [ ] **Edge cases**: Null, empty, boundary values handled?
- [ ] **Error handling**: All failure paths covered?
- [ ] **Types**: Correct types, no type errors?
- [ ] **Logic**: Conditions correct? No off-by-one errors?
- [ ] **Integration**: Connects correctly to adjacent code?
- [ ] **Side effects**: Intended database writes, API calls, file changes only?
- [ ] **No regressions**: Existing functionality still works?

### Convention Adherence (max 8)
[TO EVOLVE: Add discovered conventions from THIS codebase]

Check against `kernel/state.md` conventions:
- [ ] **Naming**: Follows project naming pattern (camelCase, snake_case, etc.)
- [ ] **Error handling**: Matches project error pattern (try/catch, Result, if err)
- [ ] **Logging**: Uses project logger pattern
- [ ] **Config**: Uses project config pattern
- [ ] **File structure**: Placed in correct directory per repo map
- [ ] **Formatting**: Matches project format (check state.md for formatter)

### Invariant Checks (max 6)
[TO EVOLVE: Add non-negotiable contracts from THIS codebase]

Check against `.claude/rules/invariants.md`:
- [ ] **Interface stability**: No breaking changes to public APIs?
- [ ] **Data integrity**: No violations of schema/constraints?
- [ ] **Security**: No auth bypasses, secret leaks, injection vulnerabilities?
- [ ] **Performance**: No obvious performance regressions?
- [ ] **Compatibility**: Backward compatible per versioning policy?

### Validation Matrix Check (max 5)
[TO EVOLVE: Add validation commands from THIS codebase]

Run checks from `kernel/state.md` validation section:
```bash
# Check linter (if exists per state.md)
[linter command]

# Check typecheck (if exists)
[typecheck command]

# Check tests (if exist)
[test command]

# Check formatter (if exists)
[formatter command] --check

# Check build (if exists)
[build command]
```

### Review Severity Markers

Use these in review comments:

- 🚫 **BLOCK**: Critical issue, must fix (security, breaks existing, no tests for new logic)
- ⚠️ **IMPORTANT**: Strongly suggest fix (unclear code, missing error handling, duplication)
- 💡 **SUGGEST**: Optional improvement (simplification, optimization)
- ❓ **QUESTION**: Clarification needed (why this approach? what if X?)

---

## Review Comment Templates

**Asking Questions:**
```
❓ What happens if `user` is null here?
❓ Why did we choose approach X over Y?
❓ Is this endpoint rate-limited?
```

**Suggesting Changes:**
```
💡 Consider extracting this into a helper function
💡 We could use the existing `formatDate` util here
💡 This might be clearer with early return:
   if (invalid) return error
   // happy path here
```

**Blocking Issues:**
```
🚫 This allows SQL injection - use parameterized queries
🚫 Missing auth check - users can access others' data
🚫 No tests for new logic - add tests first
🚫 Breaks invariant in .claude/rules/invariants.md: [specific rule]
```

**Approving:**
```
✅ LGTM - clean implementation, follows conventions
✅ Approved with minor suggestions (see 💡 comments)
```

---

## Stack-Specific Patterns (max 10 total)
[TO EVOLVE: Add review patterns discovered in THIS codebase]

**JavaScript/TypeScript:**
- Check for mutation (prefer immutable operations)
- Check for strict equality (=== not ==)
- Check for awaited promises in async functions

**Python:**
- Check for mutable default arguments (use None, not [])
- Check for specific exception handling (not bare except:)
- Check for type hints on new functions

**Go:**
- Check for error handling (if err != nil)
- Check for goroutine leaks (context cancellation)
- Check for proper defer usage

**Rust:**
- Check for proper Result/Option handling
- Check for unnecessary clones
- Check for proper lifetime annotations

---

## Verdict Format

```markdown
## Code Review

**Summary**: [One line about what changed]

**Correctness**: [Pass/Issues found]
- [Issue or ✓]

**Conventions**: [Pass/Issues found]
- [Issue or ✓]

**Invariants**: [Pass/Issues found]
- [Issue or ✓]

**Validation**: [Results of checks]
- Linter: [pass/fail]
- Tests: [pass/fail]
- Typecheck: [pass/fail]

**Verdict**: [APPROVED / APPROVED WITH CHANGES / NEEDS WORK / BLOCKED]
```

---

⚠️ **TEMPLATE NOTICE**
This bank is scaffolding. Fill slots as you review code in this codebase.
Move stable review patterns to `.claude/rules/patterns.md` when they repeat.
Respect caps; if full, replace least valuable or promote to rules.
