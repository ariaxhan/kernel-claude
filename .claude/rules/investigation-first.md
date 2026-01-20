---
paths: "**/*"
---

# Investigation First Rule

**Never implement before investigating existing patterns.**

## The Law

```
NEVER implement first.
1. Find working example (search, grep, docs)
2. Read every line
3. Copy pattern exactly
4. Adapt minimally
```

## Process

### Before Writing Any Code

1. **Search codebase** for similar implementations
   ```
   Glob: Find files with similar names
   Grep: Find similar function/class names
   Read: Understand existing patterns
   ```

2. **If pattern exists** → Copy it exactly, adapt minimally

3. **If no pattern** → Search external sources:
   - Official docs
   - GitHub examples
   - Stack Overflow

4. **Document the source** in commit message

## Why This Matters

- Existing patterns are tested and reviewed
- Consistency reduces cognitive load
- Fighting the framework causes pain
- Native > custom > clever

## Anti-patterns

- Writing code without searching first
- Reimplementing what exists
- Using different patterns than codebase
- "I'll figure it out as I go"

## Verification Questions

Before implementing, answer:
1. Does this pattern exist elsewhere in the codebase?
2. Is there a library that does this?
3. What's the canonical way to do this?
4. Am I fighting the framework?

## Example

```
BAD:
User: "Add pagination to the API"
Claude: *immediately starts coding pagination*

GOOD:
User: "Add pagination to the API"
Claude: *searches for existing pagination in codebase*
"Found pagination in /api/users.ts. Using same pattern for consistency."
```
