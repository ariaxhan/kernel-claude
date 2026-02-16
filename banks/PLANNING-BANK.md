# Planning Bank

## Philosophy
Get it right first time. Mental simulation before execution. One working implementation beats three debug cycles. Read state, investigate patterns, define interfaces, then build.

## Process Skeleton
1. **Understand Goal** → WHAT/WHY/DONE-WHEN
2. **Extract Assumptions** → Tech stack, locations, naming, errors, tests
3. **Investigate** → Find existing patterns in codebase (read state.md first)
4. **Define Interfaces** → Inputs/outputs/errors/side-effects BEFORE implementation
5. **Mental Simulation** → Walk through execution, catch bugs before running
6. **Validate** → Does this match spec? Handle edge cases? Connect to adjacents?

---

## Slots (Designed to Fill)

### Pre-Implementation Checklist (max 8)
[TO EVOLVE: Add project-specific planning steps]

- [ ] **WHAT**: Precise description of what needs to exist
- [ ] **WHY**: Business/user value this provides
- [ ] **DONE-WHEN**: Specific, testable completion criteria
- [ ] **Assumptions**: Confirmed (not guessed) about stack, locations, naming, errors, tests
- [ ] **Existing patterns**: Found via grep/glob, not assumed
- [ ] **Interfaces defined**: Inputs, outputs, errors, side-effects specified
- [ ] **Mental simulation**: Walked through 3+ example cases
- [ ] **Edge cases**: Identified what could fail (null, empty, invalid, race conditions)

### Investigation Patterns (max 10)
[TO EVOLVE: Add techniques for finding existing patterns in THIS codebase]

```bash
# Find similar functionality
grep -r "function.*similar" src/
glob "**/*similar*.{js,py,go}"

# Find error handling patterns
grep -r "try {" src/
grep -r "if err != nil" .
grep -r "Result<" .

# Find test patterns
find tests/ -name "*.test.js" | head -3 | xargs cat

# Check conventions in state.md first
cat kernel/state.md
```

### Risk Planning Techniques (max 5)
[TO EVOLVE: Add discovered risk patterns]

- **Data mutation**: Backup before write, transactions where available
- **External calls**: Timeout, retry, circuit breaker
- **Compatibility**: Check invariants.md for interface contracts
- **State changes**: Characterization test or validation plan first
- **Time handling**: UTC with explicit timezone

### Interface Definition Template (always use)

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

### Stack-Specific Planning (max 10 total across all stacks)
[TO EVOLVE: Add as you encounter language/framework specifics]

**TypeScript:**
- Define interfaces/types before implementation
- Check for existing similar types to reuse

**Python:**
- Use type hints: `def func(param: Type) -> ReturnType:`
- Check for dataclasses or Pydantic models to reuse

**Go:**
- Define structs and interfaces first
- Check for existing error types

**Rust:**
- Define types and Result<T, E> signatures first
- Check for existing trait implementations

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

...

RESULT: [Expected final output]

EDGE CASE 1: [What if input is null?]
EDGE CASE 2: [What if dependency fails?]
EDGE CASE 3: [What if state is inconsistent?]
```

---

## Validation Before Implementation

- [ ] Matches spec exactly (no extra features)
- [ ] Handles 3+ edge cases
- [ ] Connects to adjacent components (check state.md for conventions)
- [ ] Types correct
- [ ] Error messages clear
- [ ] No silent failures

---

⚠️ **TEMPLATE NOTICE**
This bank is scaffolding. Fill slots as you plan implementations in this codebase.
Move stable planning patterns to `.claude/rules/patterns.md` when they repeat.
Respect caps; if full, replace least valuable or promote to rules.
