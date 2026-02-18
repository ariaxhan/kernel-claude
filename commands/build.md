---
description: Unified planning and execution pipeline - from idea to working code
---

# Build Mode

## ●:ON_START

```bash
agentdb read-start
```

Entering BUILD mode.

1. Read `skills/BUILD-BANK.md` for methodology
2. Read `_meta/context/active.md` for current context
3. Detect input: raw idea? existing plan? partial implementation?
4. Follow pipeline: research, plan, review, execute, validate
5. Create `_meta/plans/{feature-name}.md` with plan
6. Update `_meta/context/active.md` when complete

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

## ●:ON_END

```bash
agentdb write-end '{"command":"build","did":"implemented feature","result":"success|fail","plan":"_meta/plans/<feature-name>.md"}'
```
