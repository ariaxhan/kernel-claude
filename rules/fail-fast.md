---
paths: "**/*"
---

# Fail Fast Rule

**Exit early. Clear messages. No silent failures.**

## Philosophy

```
If uncertain: STOP → ASK → WAIT
Assumptions cause debugging.
Silent failures cause pain.
```

## Implementation

### Code Behavior

- Validate inputs at entry points
- Return/throw early on invalid state
- Use specific error messages
- Never swallow errors silently

### Agent Behavior

- Stop when blocked, don't work around
- Ask when uncertain, don't guess
- Report failures immediately
- Document what went wrong

## Anti-patterns

```
BAD: try { ... } catch (e) { /* ignore */ }
BAD: if (x) { ... } // silently skip invalid
BAD: result ?? {} // hide missing data
BAD: "I'll just try this and see"
```

## Good Patterns

```
GOOD: if (!x) throw new Error("x required: ${reason}")
GOOD: "I'm uncertain about X. Options are A, B, C. Which?"
GOOD: "This failed because Y. To fix: Z"
```

## Error Message Requirements

Every error should include:
1. What went wrong
2. Why it went wrong (if known)
3. How to fix it (if known)
4. Context (file, line, function)

## Example

```typescript
// BAD
function getUser(id) {
  const user = db.find(id);
  return user || {}; // Silent failure
}

// GOOD
function getUser(id) {
  if (!id) throw new Error("getUser: id is required");
  const user = db.find(id);
  if (!user) throw new Error(`getUser: no user found with id ${id}`);
  return user;
}
```
