# Memory-First Protocol

**Check project memory BEFORE acting.** Answers often already exist.

---

## Before Any Task

### Architectural Changes
```
BEFORE proposing architecture:
→ Check kernel/project-notes/decisions.md
→ Ask: "Was this already decided? Why?"
→ If conflict: surface it, don't override silently
```

### Encountering Errors
```
BEFORE debugging from scratch:
→ Search kernel/project-notes/bugs.md
→ Ask: "Have we fixed this before?"
→ If found: apply solution, verify, move on
→ If new: fix it, then ADD to bugs.md
```

### Infrastructure Lookups
```
BEFORE discovering infra:
→ Check kernel/project-notes/key_facts.md
→ Ask: "Is this already documented?"
→ If found: use it
→ If missing: discover once, ADD to key_facts.md
```

### Context on Past Work
```
BEFORE asking "what were we doing?":
→ Check kernel/project-notes/issues.md
→ Check _meta/context/active.md
→ Check _meta/_session.md
```

---

## The Loop to Break

Without memory protocol:
```
Session 1: Discover → Fix → (knowledge lost)
Session 2: Discover → Fix → (knowledge lost)
Session 3: Discover → Fix → (knowledge lost)
...
```

With memory protocol:
```
Session 1: Discover → Fix → RECORD
Session 2: Check memory → Apply → Done (5x faster)
Session 3: Check memory → Apply → Done
Session N: Pattern encoded → Never happens
```

---

## Integration

This protocol runs BEFORE:
- `investigation-first.md` (memory is fastest investigation)
- `assumptions.md` (memory validates assumptions)
- Any debugging or implementation task

Memory check takes 10 seconds. Re-discovery takes 10+ minutes.

---

*The best debugging session is the one you skip because the answer was already recorded.*
