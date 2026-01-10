---
trigger: After observing repeated pattern (naming, error handling, logging, etc.)
---

# Pattern Capture Hook

When you notice a pattern repeated 2+ times:

1. Identify the pattern (naming convention, error handling approach, logging pattern, etc.)
2. Check if it's already in `kernel/state.md` conventions or `.claude/rules/patterns.md`
3. If new, offer: "I noticed [pattern]. Save to conventions? [y/n]"
4. On confirm:
   - Add to `kernel/state.md` conventions (if slot not full)
   - Or add to `.claude/rules/patterns.md` (if state.md full or pattern is detailed)
5. On reject: Do not ask again for this pattern

Never silent writes. Always offer first.
