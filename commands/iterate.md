---
description: Continuous improvement mode - analyze, improve, and iterate on existing code
---

# Iterate Command

Deep improvement of existing code.

## Phases

### Phase 1: Deep Understanding

1. Read the target code completely
2. Understand its purpose and context
3. Map dependencies and callers
4. Document current behavior
5. Write to `.claude/iterations/{target}/understanding.md`

### Phase 2: Improvement Identification

Analyze for:
- **Code reduction** - Can this be shorter?
- **Performance** - Any bottlenecks?
- **Robustness** - Edge cases handled?
- **Maintainability** - Easy to change?
- **Readability** - Easy to understand?
- **UX** - Better for users?

Write findings to `.claude/iterations/{target}/improvements.md`

### Phase 3: Research

For each improvement:
1. Is there a better library/pattern?
2. How do others solve this?
3. What are the trade-offs?

### Phase 4: Implementation

1. Prioritize by impact/effort ratio
2. Make changes incrementally
3. Test after each change
4. Commit atomically

### Phase 5: Documentation

Log changes to `.claude/iterations/{target}/history.md`:
```markdown
## {date}

### Changed
- {what changed}

### Why
- {rationale}

### Impact
- {metrics if available}
```

## Usage

```
/iterate src/components/UserProfile.tsx
/iterate lib/database/
```

## Focus Areas

When iterating, aggressively pursue:
- Fewer lines of code (same functionality)
- Faster execution
- Better error handling
- Clearer naming
- Simpler logic
