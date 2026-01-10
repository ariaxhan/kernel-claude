---
name: testing-strategy
description: Testing strategy - what to test, when to test, how to test
---

# Testing Strategy Skill

When writing tests, refer to **TESTING-BANK.md** for comprehensive guidance.

## Quick Reference

**Test pyramid:** Many unit tests → Some integration → Few E2E

**Always test:** Core logic, edge cases, error paths
**Sometimes test:** Complex integrations
**Rarely test:** Simple getters, framework boilerplate

**Key principle:** Test behavior, not implementation.

See TESTING-BANK.md in kernel/banks/ for full strategy, stack-specific examples, and coverage guidelines.
