# Debugging Bank

**Systematic debugging: Reproduce → Isolate → Fix → Verify**

---

## The Process

### 1. Reproduce
```
Can you trigger the bug consistently?

YES → Proceed to step 2
NO → Gather more data:
  - Under what conditions does it happen?
  - What's different when it doesn't happen?
  - Can you make it happen more often?
```

### 2. Isolate
```
Narrow down WHERE the bug occurs:

BINARY SEARCH:
1. Identify the call chain
2. Check midpoint: Is bug before or after this?
3. Repeat until you find the exact line

LOGGING:
1. Add strategic console.log/print statements
2. Trace data flow through the system
3. Find where expected != actual
```

### 3. Understand Root Cause
```
Why does this happen?

COMMON CAUSES:
- Wrong assumption about input shape
- Off-by-one error
- Race condition / timing issue
- Missing null/undefined check
- Incorrect operator (= vs ==, && vs ||)
- Mutating shared state
- Wrong variable scope
```

### 4. Fix
```
Fix the ROOT CAUSE, not the symptom.

BAD: Add a try-catch to hide the error
GOOD: Fix why the error occurs

BAD: Add special case for this one input
GOOD: Handle the whole class of inputs correctly
```

### 5. Verify
```
Test the fix:
1. Original bug case → Should now work
2. Edge cases → Should still work
3. Regression → Old functionality still works
```

---

## Debugging Checklist

### Data Flow Issues
- [ ] Check input shape/type (console.log it)
- [ ] Check each transformation step
- [ ] Check output shape/type
- [ ] Verify no mutation of shared data

### Logic Issues
- [ ] Are conditions correct? (>, >=, ==, ===)
- [ ] Are all branches covered?
- [ ] Is loop termination correct?
- [ ] Are variables in correct scope?

### Async Issues
- [ ] Are promises awaited?
- [ ] Is race condition possible?
- [ ] Are callbacks called?
- [ ] Is event handler registered?

### Integration Issues
- [ ] Does API return what you expect?
- [ ] Are headers/auth correct?
- [ ] Is data format compatible?
- [ ] Are versions compatible?

---

## Stack-Specific Debugging

### JavaScript/TypeScript
```javascript
// Strategic logging
console.log('Input:', JSON.stringify(input, null, 2))
console.log('After step 1:', result1)
console.log('Final:', output)

// Debugger breakpoint
debugger;  // Execution pauses here

// Type checking
console.log(typeof value, Array.isArray(value))
```

### Python
```python
# Strategic logging
import json
print(f"Input: {json.dumps(input, indent=2)}")
print(f"After step 1: {result1}")
print(f"Final: {output}")

# Debugger breakpoint
import pdb; pdb.set_trace()

# Type checking
print(type(value), isinstance(value, list))
```

### Go
```go
// Strategic logging
import "encoding/json"
data, _ := json.MarshalIndent(input, "", "  ")
fmt.Printf("Input: %s\n", data)
fmt.Printf("After step 1: %+v\n", result1)
fmt.Printf("Final: %+v\n", output)

// Type checking
fmt.Printf("%T\n", value)
```

---

## Common Patterns

### "It works locally but not in production"
```
CHECK:
- Environment variables different?
- Dependencies/versions different?
- Data different (dev DB vs prod DB)?
- Permissions different?
- External services configured differently?
```

### "Intermittent failure"
```
LIKELY:
- Race condition
- Timing-dependent
- Depends on external state (cache, DB)
- Resource exhaustion
- Retry logic hiding root cause
```

### "It worked yesterday"
```
FIND:
- What changed? (git diff, deploy logs)
- New dependency version?
- Config change?
- Data migration?
```

---

## Red Flags (Stop Doing This)

❌ Random code changes hoping it fixes
✅ Understand WHY it's broken, then fix

❌ "It's probably X" without verifying
✅ Verify with evidence (logs, debugger)

❌ Fixing symptom instead of cause
✅ Find root cause, fix that

❌ Skipping verification step
✅ Always test the fix thoroughly

---

## When Stuck

1. **Explain it to a rubber duck** (or write it out)
2. **Read the error message carefully** (contains the answer 80% of the time)
3. **Check the docs** (you might be using the API wrong)
4. **Simplify** (make a minimal reproduction case)
5. **Take a break** (fresh eyes find bugs faster)

---

**Remember: Systematic debugging is faster than random debugging.**
