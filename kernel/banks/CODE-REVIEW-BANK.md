# Code Review Bank

**Review standards: Quality, Tests, Security, Clarity**

---

## Review Checklist

### 1. Correctness
- [ ] Does it solve the stated problem?
- [ ] Are edge cases handled?
- [ ] Is error handling complete?
- [ ] Are there off-by-one errors?
- [ ] Are types correct?

### 2. Testing
- [ ] Are there tests for new functionality?
- [ ] Do tests cover happy path AND edge cases?
- [ ] Do existing tests still pass?
- [ ] Is test coverage adequate?

### 3. Security
- [ ] No SQL injection vulnerabilities?
- [ ] No XSS vulnerabilities?
- [ ] User input validated/sanitized?
- [ ] Secrets not committed?
- [ ] Auth/permissions checked?

### 4. Code Quality
- [ ] Follows project conventions?
- [ ] No duplicated code?
- [ ] Functions are single-purpose?
- [ ] Names are clear and descriptive?
- [ ] No unnecessary complexity?

### 5. Performance
- [ ] No N+1 queries?
- [ ] No unnecessary loops?
- [ ] Large datasets handled efficiently?
- [ ] No memory leaks?

### 6. Integration
- [ ] Backward compatible (if required)?
- [ ] API contracts maintained?
- [ ] Database migrations included?
- [ ] Documentation updated?

---

## Red Flags

### Critical (Block Merge)
🚫 **Security vulnerability** - Fix immediately
🚫 **Breaks existing functionality** - Add tests, fix regression
🚫 **Secrets in code** - Remove, use env vars
🚫 **No tests for new logic** - Add tests first

### Important (Strongly Suggest Fix)
⚠️ **Unclear naming** - Future devs will struggle
⚠️ **Missing error handling** - Will fail in production
⚠️ **Code duplication** - Harder to maintain
⚠️ **Complex logic without comments** - Document WHY

### Nice-to-Have (Optional)
💡 **Could be simplified** - But works as-is
💡 **Performance could improve** - But not a bottleneck
💡 **Style inconsistency** - Minor cleanup

---

## Review Comments Template

### Asking Questions
```
❓ What happens if `user` is null here?
❓ Is this endpoint rate-limited?
❓ Why did we choose approach X over Y?
```

### Suggesting Changes
```
💡 Consider extracting this into a helper function
💡 We could use the existing `formatDate` util here
💡 This might be clearer with early return
```

### Blocking Issues
```
🚫 This allows SQL injection - use parameterized queries
🚫 Missing auth check - users can access others' data
🚫 This breaks the payment flow (test_checkout failing)
```

### Approving
```
✅ LGTM - clean implementation, good tests
✅ Approved with minor suggestions (see comments)
```

---

## Common Issues by Language

### JavaScript/TypeScript
```javascript
// BAD: Mutation
function addItem(array, item) {
  array.push(item)  // Mutates input!
  return array
}

// GOOD: Immutable
function addItem(array, item) {
  return [...array, item]
}

// BAD: Type coercion bug
if (value == 0)  // true for 0, "0", false, "", null, undefined

// GOOD: Strict equality
if (value === 0)  // true only for 0

// BAD: Missing await
async function getData() {
  const result = fetch('/api')  // Returns Promise, not data!
  return result
}

// GOOD: Await promise
async function getData() {
  const result = await fetch('/api')
  return result
}
```

### Python
```python
# BAD: Mutable default argument
def append_to(item, list=[]):
    list.append(item)  # Shared across calls!
    return list

# GOOD: Use None default
def append_to(item, list=None):
    if list is None:
        list = []
    list.append(item)
    return list

# BAD: Broad except
try:
    process()
except:  # Catches EVERYTHING, even Ctrl+C
    pass

# GOOD: Specific exception
try:
    process()
except ValueError as e:
    handle_error(e)
```

### Go
```go
// BAD: Ignoring errors
result, _ := doSomething()

// GOOD: Handle errors
result, err := doSomething()
if err != nil {
    return err
}

// BAD: Goroutine leak
go func() {
    // Long-running without context
    for {
        work()
    }
}()

// GOOD: Cancelable goroutine
ctx, cancel := context.WithCancel(context.Background())
defer cancel()
go func() {
    for {
        select {
        case <-ctx.Done():
            return
        default:
            work()
        }
    }
}()
```

---

## Security Checklist

### Input Validation
- [ ] Length limits enforced?
- [ ] Type validation?
- [ ] Whitelist, not blacklist?
- [ ] Sanitized before use?

### Authentication & Authorization
- [ ] User authenticated?
- [ ] User authorized for this action?
- [ ] Session validated?
- [ ] Tokens expire?

### Data Handling
- [ ] Sensitive data encrypted?
- [ ] Secrets not in logs?
- [ ] PII handled correctly?
- [ ] SQL queries parameterized?

### External Calls
- [ ] API keys from env, not code?
- [ ] HTTPS for external calls?
- [ ] Timeout configured?
- [ ] Rate limiting?

---

## When to Use This Bank

✅ Reviewing pull requests
✅ Self-reviewing before commit
✅ Pair programming checklist
✅ Onboarding new contributors

---

**Remember: Good reviews make the whole codebase better.**
