# Debugging Bank

## Philosophy
Reproduce first. Isolate via binary search. Instrument, don't guess. Fix root cause, not symptom. Confirm fix with regression validation. Systematic debugging beats random changes.

## Process Skeleton
1. **Reproduce** → Can you trigger it consistently? If no, gather more data first.
2. **Isolate** → Binary search the call chain, find exact location
3. **Instrument** → Add logging/breakpoints, observe state
4. **Understand Root Cause** → Why does this happen? (Not just what fails)
5. **Fix Root Cause** → Not the symptom
6. **Verify** → Original bug + edge cases + regression check

---

## Slots (Designed to Fill)

### Reproduction Patterns (max 8)
[TO EVOLVE: Add techniques discovered while debugging THIS codebase]

- **Exact steps**: Write down precise sequence to trigger bug
- **Minimal repro**: Remove unrelated code until minimal case that fails
- **Input data**: What specific input causes failure?
- **Environment**: Local vs prod, versions, config differences?
- **Frequency**: Always, sometimes, specific conditions?
- **Logs**: What does output show? Error messages? Stack traces?

### Isolation Techniques (max 8)
[TO EVOLVE: Add debugging strategies that work in THIS codebase]

**Binary Search:**
```
Call chain: A → B → C → D → E (fails)
Check C: Works? Bug is in D or E. Fails? Bug is in A, B, or C.
Repeat until exact location found.
```

**Logging Strategy:**
```javascript
// Add strategic checkpoints
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

### Instrumentation Patterns (max 6)
[TO EVOLVE: Add debugging tools discovered in THIS codebase]

**Stack-specific:**
- JavaScript: `console.log`, `debugger`, Chrome DevTools
- Python: `print()`, `import pdb; pdb.set_trace()`, logging module
- Go: `fmt.Printf`, `log.Printf`, delve debugger
- Rust: `println!`, `dbg!`, rust-gdb

**State Inspection:**
```
At failure point, check:
- Variable values: Are they what you expect?
- Types: console.log(typeof x), print(type(x))
- Null/undefined: Explicit checks
- Array/object contents: JSON.stringify, pprint
```

### Common Root Causes (max 10)
[TO EVOLVE: Add patterns discovered while fixing bugs in THIS codebase]

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

### Regression Validation (max 5)
[TO EVOLVE: Add validation patterns for THIS codebase]

After fix:
1. **Original bug case** → Should now work
2. **Edge cases** → Null, empty, boundary values still work
3. **Happy path** → Normal case still works
4. **Integration** → Adjacent code still works
5. **Add test** → Prevent regression (if tests exist per state.md)

---

## Debugging Checklist

### Data Flow
- [ ] Check input shape/type (log it)
- [ ] Check each transformation step
- [ ] Check output shape/type
- [ ] Verify no mutation of shared data

### Logic
- [ ] Are conditions correct? (>, >=, ==, ===)
- [ ] Are all branches covered?
- [ ] Is loop termination correct?
- [ ] Are variables in correct scope?

### Async (if applicable)
- [ ] Are promises awaited?
- [ ] Is race condition possible?
- [ ] Are callbacks called?
- [ ] Is event handler registered?

---

## When Stuck

1. **Explain to rubber duck** (or write it out)
2. **Read error message carefully** (contains answer 80% of time)
3. **Check docs** (might be using API wrong)
4. **Simplify** (make minimal reproduction case)
5. **Take a break** (fresh eyes find bugs faster)

---

⚠️ **TEMPLATE NOTICE**
This bank is scaffolding. Fill slots as you debug issues in this codebase.
Move stable debugging patterns to `.claude/rules/patterns.md` when they repeat.
Respect caps; if full, replace least valuable or promote to rules.
