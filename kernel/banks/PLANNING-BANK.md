# Planning Bank

**Philosophy: Get It Right The First Time**

Correctness > Speed. One working implementation beats three debug cycles.

---

## Pre-Implementation Checklist

### 1. Understand the Goal
```
WHAT: [Precise description of what needs to exist]
WHY: [Business/user value this provides]
DONE WHEN: [Specific, testable completion criteria]
```

### 2. Extract Assumptions
Before writing ANY code, list assumptions:
- Tech stack & versions
- File locations & naming
- Error handling approach
- Testing expectations
- Dependencies & integrations

**Stop and confirm with user if ANY assumption is unclear.**

### 3. Investigate First
```
NEVER implement first. Always:
1. Search for existing patterns (grep, glob, read)
2. Find working examples in codebase
3. Read every line of similar code
4. Copy pattern exactly, adapt minimally
```

### 4. Define Interfaces
Before implementation, specify:
```
INPUTS:
  - [Type, shape, constraints]

OUTPUTS:
  - [Return type, success/error cases]

ERRORS:
  - [What can fail, how to handle]

SIDE EFFECTS:
  - [DB writes, API calls, file changes]
```

---

## Implementation Pattern

### Phase 1: Skeleton
```
1. Write types/interfaces first
2. Write function signatures (no implementation)
3. Validate: Does this shape solve the problem?
```

### Phase 2: Happy Path
```
1. Implement core logic (assume inputs are valid)
2. Test mentally: Walk through 3 example cases
3. Validate: Does this work for the normal case?
```

### Phase 3: Edge Cases
```
1. What if input is null/empty/invalid?
2. What if dependency fails?
3. What if state is inconsistent?
4. Add handling for each
```

### Phase 4: Integration
```
1. How does this connect to caller?
2. How does this connect to dependencies?
3. Are types compatible?
4. Run actual test (if available)
```

---

## Mental Simulation

Before running code, simulate execution:

```
GIVEN: [Specific input values]
STEP 1: [What happens]
STEP 2: [What happens]
...
RESULT: [Expected output]

Does this match specification? If no, fix before running.
```

This catches 80% of bugs before execution.

---

## Red Flags (Stop and Reconsider)

❌ "I'll try this and see if it works"
✅ "This will work because..."

❌ "I'll refactor while implementing"
✅ "First make it work, then refactor"

❌ "I'll handle errors later"
✅ "Error handling designed upfront"

❌ "I assume this API returns X"
✅ "I verified this API returns X"

---

## Validation Before Commit

- [ ] Matches spec exactly (no extra features)
- [ ] Handles 3+ edge cases correctly
- [ ] Connects to adjacent components
- [ ] Types are correct
- [ ] Error messages are clear
- [ ] No silent failures

---

## Stack-Specific Patterns

### TypeScript/JavaScript
```typescript
// Define types first
interface Input { /* ... */ }
interface Output { /* ... */ }

// Then implement
function process(input: Input): Output {
  // Validate early
  if (!input.required) throw new Error("Missing required field")

  // Happy path
  const result = transform(input)

  // Return typed output
  return result
}
```

### Python
```python
# Type hints first
def process(input: InputModel) -> OutputModel:
    """What this does and why."""
    # Validate early
    if not input.required:
        raise ValueError("Missing required field")

    # Happy path
    result = transform(input)

    # Return typed output
    return result
```

### Go
```go
// Define types first
type Input struct { /* ... */ }
type Output struct { /* ... */ }

// Then implement
func Process(input Input) (Output, error) {
    // Validate early
    if input.Required == "" {
        return Output{}, errors.New("missing required field")
    }

    // Happy path
    result := transform(input)

    // Return typed output
    return result, nil
}
```

---

## When to Use This Bank

✅ Starting new feature implementation
✅ Refactoring existing code
✅ Debugging complex issue (understand before fixing)
✅ Reviewing pull request (validate these steps were followed)

❌ Quick one-line fixes (overkill)
❌ Experimental prototyping (planning slows exploration)

---

**Remember: Time spent planning is time NOT spent debugging.**
