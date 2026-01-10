# KERNEL

**CORRECTNESS > SPEED**
One working implementation beats three debug cycles.

**DETECT, THEN ACT**
Never assume tooling. Find it first.

**PROTECT STATE**
Backup before mutation. Explicit time. Confirm before delete.

**CAPTURE ON CONFIRMATION**
Patterns save only when approved. Never silent writes.

---

## Project Structure

This project uses KERNEL - evolvable development intelligence.

- **Banks** (`kernel/banks/`) contain methodology templates with slots to fill
- **State** (`kernel/state.md`) tracks discovered reality - read on mode activation
- **Modes** (`kernel/modes/`) activate thinking styles (discover, plan, debug, review)
- **Rules** (`.claude/rules/`) capture project-specific patterns as they evolve

---

## How to Use

**Start with discovery:**
```
/discover
```

Populates `kernel/state.md` with tooling, conventions, repo map.

**Then work in modes:**
- `/plan` - Activate planning mode (loads PLANNING-BANK + state)
- `/debug` - Activate debugging mode (loads DEBUGGING-BANK + state)
- `/review` - Activate review mode (loads REVIEW-BANK + state)

**When uncertain:**
Read `kernel/state.md` first - it's the shared world model.

---

⚠️ **TEMPLATE NOTICE**
KERNEL is scaffolding, not gospel. Banks have slots designed to fill as you learn this codebase.
Rules start empty and grow from confirmed observations. State tracks reality, not hopes.
