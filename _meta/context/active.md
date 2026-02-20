# KERNEL v5.5.0

status: complete | orchestrator-pattern | agentdb-bus

---

## Ψ:STRUCTURE

```
kernel-claude/
├── .claude-plugin/
│   ├── plugin.json
│   └── marketplace.json
├── CLAUDE.md                    (~200 tokens)
├── agents/                      (2 agents)
│   ├── surgeon.md              (implementation)
│   └── adversary.md            (verification)
├── commands/                    (6 commands)
│   ├── ingest.md               (universal entry + orchestrator)
│   ├── validate.md
│   ├── ship.md
│   ├── tearitapart.md
│   ├── branch.md
│   └── handoff.md
├── skills/                      (4 skills)
│   ├── build/
│   ├── debug/
│   ├── discovery/
│   └── research/
├── hooks/
│   ├── hooks.json
│   └── scripts/
│       ├── session-start.sh    (philosophy + active contracts)
│       └── capture-error.sh
├── orchestration/agentdb/
│   ├── agentdb                  (CLI)
│   ├── schema.sql              (3 tables)
│   └── init.sh
└── _meta/
```

---

## ●:CORE_PATTERN

**AgentDB is the communication bus. You are the orchestrator.**

```
Tier 1 (1-2 files): Execute directly
Tier 2+ (3+ files): Contract → Spawn agents → Read AgentDB
```

### Agent Communication Flow
```
1. Orchestrator → CONTRACT → AgentDB
2. Surgeon reads contract → CHECKPOINT → AgentDB
3. Orchestrator reads checkpoint → spawns adversary (Tier 3)
4. Adversary reads checkpoint → VERDICT → AgentDB
5. Orchestrator reads verdict → reports to user
```

---

## ●:SCHEMA (3 tables)

| Table | Purpose | Types |
|-------|---------|-------|
| learnings | Cross-session memory | failure, pattern, gotcha, preference |
| context | Agent communication | contract, checkpoint, handoff, verdict |
| errors | Auto-captured failures | (auto from hook) |

---

## ●:COMMANDS

| Command | Purpose |
|---------|---------|
| /kernel:ingest | Universal entry — classify, scope, orchestrate |
| /kernel:validate | Pre-commit: types, lint, tests |
| /kernel:ship | Commit, push, PR |
| /kernel:tearitapart | Critical review |
| /kernel:branch | Worktree creation |
| /kernel:handoff | Context handoff |

---

## ●:AGENTS

| Agent | Role | Reads | Writes |
|-------|------|-------|--------|
| surgeon | Implement | contract | checkpoint |
| adversary | Verify | checkpoint | verdict |

---

## Δ:v5.5.0

- `/kernel:ingest` is now the universal entry point + orchestrator
- Consolidated /kernel:build and /kernel:contract into ingest
- Agents have hyper-specific instructions (anti-patterns, failure paths, AgentDB writes)
- Startup script shows active contracts and pending reviews
- 3-table schema clearly documented (learnings, context, errors)
- Main session = orchestrator for Tier 2+ (doesn't write code, spawns agents)

---

*Updated: 2026-02-20*
