# Active Work

**Status: Complete — v5.2.0**

Full plugin restructure complete. Flat, cohesive, no templates.

## Final Structure

```
kernel-claude/
├── .claude-plugin/plugin.json    (v5.2.0)
├── CLAUDE.md                     (plugin philosophy)
├── README.md
├── agents/                       (25 agents)
│   ├── [19 standard]
│   └── orchestration/            (6 orchestration)
├── commands/                     (16 commands)
├── skills/                       (3 skills)
├── rules/                        (14 rules)
├── banks/                        (10 methodology banks)
├── hooks/
│   └── hooks.json                (SessionStart + PostToolUse)
├── orchestration/
│   └── agentdb/                  (SQLite setup)
├── _meta/
│   ├── context/active.md
│   ├── _learnings.md
│   └── benchmark/
└── archive/
    └── deprecated/
```

## Changes (v5.1.0 → v5.2.0)

| Before | After |
|--------|-------|
| `.claude/rules/` | `rules/` (root level) |
| `kernel/banks/` | `banks/` (root level) |
| `kernel/orchestration/` | `orchestration/` (root level) |
| `kernel/` (templates) | Deleted - no templates |
| `.claude/` (project config) | Deleted - plugin IS config |
| `hooks/` empty | `hooks/hooks.json` active |
| `/repo-init` copies templates | `/repo-init` analyze-only |

## Philosophy

The plugin IS the configuration. No templates to copy. No init step required.

Activate plugin → start working → it builds context as you go.

---

*Updated 2026-02-15*
