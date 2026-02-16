# KERNEL v5.1.0

status: complete | structure: clean | agentdb: native

---

## Ψ:STRUCTURE

```
kernel-claude/
├── .claude-plugin/plugin.json
├── CLAUDE.md                    (~200 tokens, VN-native)
├── agents/                      (6 orchestration agents)
│   ├── orchestrator.md
│   ├── architect.md
│   ├── surgeon.md
│   ├── adversary.md
│   ├── searcher.md
│   └── researcher.md
├── commands/                    (16 commands)
├── skills/                      (11 skills)
│   ├── planning/
│   ├── debug/
│   ├── research/
│   ├── review/
│   ├── discovery/
│   ├── iteration/
│   ├── tearitapart/
│   ├── docs/
│   ├── build/
│   ├── rules/                   (consolidated invariants)
│   └── coding-prompt-bank/
├── hooks/hooks.json
├── orchestration/agentdb/
└── _meta/
```

---

## Δ:CHANGES

| Before | After |
|--------|-------|
| 25 agents | 6 agents (orchestration core) |
| rules/ directory | skills/rules/ |
| banks/ directory | 10 skills |
| ~800 token CLAUDE.md | ~200 token VN-native |
| Prose-heavy | VN notation |

---

## ●:DELETED

- 19 bloat agents (test-runner, lint-fixer, etc.)
- rules/ directory (→ skills/rules/)
- banks/ directory (→ 10 skills)
- kernel/ templates directory
- .claude/ project config

---

*2026-02-15*
