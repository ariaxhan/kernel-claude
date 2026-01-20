---
description: Unified planning and execution pipeline - from idea to working code
---

# Build Mode

Entering BUILD mode.

1. Read `kernel/banks/BUILD-BANK.md` for methodology
2. Read `kernel/state.md` for current context
3. Detect input: raw idea? existing plan? partial implementation?
4. Follow pipeline: research, plan, review, execute, validate
5. Create `.claude/plans/{feature-name}.md` with plan
6. Update `kernel/state.md` when complete

**Pipeline:** Idea -> Research -> Multiple Solutions -> Choose Simplest -> Plan -> Tear Apart -> Execute -> Validate -> Done

**Integration:**
- Calls `/research` for solution discovery
- Calls `/tearitapart` for critical review before implementation
- Uses `/execute` for advanced execution (optional)

**Core principle:** Minimal code through maximum research. Your first solution is never right - explore multiple approaches.

**Flags:**
- Default: Full flow with confirmations
- `--quick`: Skip confirmations
- `--plan-only`: Stop after planning
- `--resume`: Continue in-progress work
