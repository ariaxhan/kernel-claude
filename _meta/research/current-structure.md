# KERNEL Plugin Current Structure

**Analysis of the kernel-plugin repository before alignment.**

---

## Structure

```
kernel-plugin/
├── .claude/                    # Project-level KERNEL config
│   ├── CLAUDE.md              # Philosophy + session protocol
│   ├── rules/                 # 6 rule files
│   ├── settings.json          # Hook config
│   ├── settings.local.json    # Local overrides
│   └── skills/                # Specialized capabilities
├── .claude-plugin/            # Plugin metadata
│   ├── plugin.json
│   └── marketplace.json
├── kernel/                    # KERNEL distribution templates
│   ├── state.md              # Project reality tracker
│   ├── CLAUDE.md             # Kernel template
│   ├── banks/                # 10 methodology banks
│   ├── rules/                # 7 rules (methodology, patterns, etc)
│   ├── hooks/                # Hook templates
│   └── tools/                # Tool definitions
├── memory/                    # Session/registry storage
│   └── config_registry.jsonl # Empty registry
├── commands/                  # 11 command definitions
├── sample-project/            # Example KERNEL project
├── _meta/                     # NEW: Session tracking (added)
│   ├── INDEX.md              # Navigation hub
│   ├── _session.md           # Session context
│   ├── _learnings.md         # Learnings log
│   ├── context/
│   │   └── active.md         # Current work state
│   └── research/             # Investigation outputs
├── README.md
├── CLAUDE.md                  # Root philosophy
├── SETUP.md
├── CONFIG-TYPES.md
└── RELEASE_NOTES.md
```

---

## Key Files

| File | Purpose |
|------|---------|
| `kernel/state.md` | Single source of truth for project reality |
| `kernel/banks/` | 10 methodology templates |
| `.claude/CLAUDE.md` | Project-specific philosophy |
| `commands/` | Skill/command definitions |
| `_meta/` | Session tracking and research |

---

## What Changed

1. **Added `_meta/`** structure:
   - `_session.md` - Session context
   - `_learnings.md` - Change/problem log
   - `context/active.md` - Current work
   - `INDEX.md` - Navigation
   - `research/` - Investigation outputs

2. **Updated `.claude/CLAUDE.md`**:
   - Added Session Protocol section
   - Added Project Structure table
   - Added "When learning" instruction

---

## Alignment with CodingVault

Now matches the CodingVault pattern:
- `_meta/_session.md` mirrors vault-level session tracking
- `_meta/_learnings.md` captures project-specific learnings
- Research outputs persist in `_meta/research/`

---

*Analysis conducted 2026-01-17*
