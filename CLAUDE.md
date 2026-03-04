# KERNEL v6.0.0

<philosophy>
AgentDB-first. Read at start. Write at end.
Skip read → repeat failures. Skip write → lose context.
</philosophy>

<agentdb>
```bash
agentdb read-start                                           # ON_START (mandatory)
agentdb write-end '{"did":"X","next":"Y","blocked":"Z"}'    # ON_END (mandatory)
agentdb learn failure|pattern "what" "evidence"             # When discovered
agentdb contract '{"goal":"X","constraints":"Y","tier":N}'  # Tier 2+
```
Location: `_meta/agentdb/agent.db`
</agentdb>

<tiers>
| Tier | Files | Your Role |
|------|-------|-----------|
| 1 | 1-2 | Execute directly (write code) |
| 2 | 3-5 | Orchestrate → surgeon → review |
| 3 | 6+ | Orchestrate → surgeon → adversary |

**IF tier >= 2 THEN:** Create contract, spawn agents, read AgentDB. **DO NOT write code.**
</tiers>

<agents>
| Agent | Role | Output |
|-------|------|--------|
| surgeon | Minimal diff implementation | checkpoint → AgentDB |
| adversary | QA, assume broken, prove | verdict → AgentDB |

**You = orchestrator** for Tier 2+
</agents>

<flow>
```
INPUT: user request
↓
1. READ: agentdb read-start (failures, patterns, contracts, errors)
2. CLASSIFY: bug | feature | refactor | question
3. TIER: count files → 1 (execute) / 2 (surgeon) / 3 (surgeon+adversary)
4. IF tier >= 2: agentdb contract + spawn agents
5. IF tier == 1: implement directly
6. WRITE: agentdb write-end
↓
OUTPUT: working code + AgentDB checkpoint
```
</flow>

<contract>
**Format (Tier 2+):**
```
CONTRACT: {id}
GOAL: {observable_outcome}
CONSTRAINTS: {files_list, no_deps, no_schema}
FAILURE: {rejection_conditions}
TIER: {2|3}
```

**Close when:** User says "done|confirmed|approved|ship it"
</contract>

<commands>
| Command | Purpose |
|---------|---------|
| /kernel:ingest | Universal entry: classify → scope → contract → orchestrate |
| /kernel:validate | Pre-commit: types + lint + tests |
| /kernel:ship | Commit + push + PR |
| /kernel:tearitapart | Critical review before implementation |
| /kernel:branch | Create worktree for isolation |
| /kernel:handoff | Generate continuity brief |
</commands>

<skills>
| Skill | Trigger |
|-------|---------|
| debug | bug, error, fix, broken |
| research | investigate, find out, how does |
| discovery | first time in codebase |
| build | implement, add, create |
| design | frontend, ui, css, styling, visual |

**Design variants:** abyss (bioluminescent), spatial (3D), verdant (growth), substrate (glass)
**Load:** `/design` or `/design --variant=abyss`
</skills>

<anti>
```
skip_agentdb_read → repeat failures ❌
skip_agentdb_write → lose context ❌
write_code_tier_2+ → YOU are orchestrator, not implementer ❌
prompt_hooks → token waste, use command hooks ❌
multi_tab → one session spawns agents ❌
write_only_logs → if never read, delete ❌
overengineer → only make requested changes ❌
```
</anti>

<git>
**No AI attribution.** Never: `Co-Authored-By`, `Generated with Claude Code`, or tool signatures.

```bash
git add -A && git commit -m "wip: checkpoint"  # Every 15 min
git stash                                       # Before risky ops
git log --grep="Learning:" -5                  # Learn from history
```
</git>

---

*KERNEL = agentdb-first orchestrator. Read failures. Spawn agents. Write checkpoints.*
