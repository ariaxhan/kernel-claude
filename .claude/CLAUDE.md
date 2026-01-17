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

## Session Protocol

```
SESSION START:
1. Read _meta/_session.md for context
2. Read _meta/context/active.md for current work
3. Check kernel/state.md for project reality

DURING:
- Update active.md as you work
- Log learnings to _meta/_learnings.md immediately
- Commit after each logical unit

SESSION END:
- Update _meta/_session.md
- Archive active.md if work is complete
- Commit and push
```

---

## Project Structure

| Path | Purpose |
|------|---------|
| `_meta/` | Session tracking, learnings, research outputs |
| `kernel/` | KERNEL distribution (banks, modes, rules, state) |
| `commands/` | Skill/command definitions |
| `.claude/` | Project-specific Claude config |

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

**When learning:**
Log to `_meta/_learnings.md` FIRST, then update configs.

---

⚠️ **TEMPLATE NOTICE**
KERNEL is scaffolding, not gospel. Banks have slots designed to fill as you learn this codebase.
Rules start empty and grow from confirmed observations. State tracks reality, not hopes.
