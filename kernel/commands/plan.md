---
description: Before implementing features - Plan to get it right first time
---

# Plan Implementation

**When to use**: Before implementing new features, complex changes, or refactoring.
**What it does**: Systematic planning to understand requirements, verify assumptions, and design implementation.

## Process

1. Read `kernel/banks/PLANNING-BANK.md` for methodology
2. Read `kernel/state.md` for current context
3. Apply planning: understand goal, extract assumptions, investigate patterns, define interfaces, mental simulation
4. Update `kernel/state.md` with any new discoveries

## What This Prevents

- Wasted implementation cycles
- Missing edge cases
- Incorrect assumptions
- Integration issues
- Breaking existing code

Planning mode prioritizes correctness over speed. One working implementation beats three debug cycles.
