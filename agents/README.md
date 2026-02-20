# Agents

Spawned by the orchestrator (main session) for Tier 2+ work. All communication via AgentDB.

| Agent | Role | Reads | Writes |
|-------|------|-------|--------|
| surgeon | Minimal diff implementation | contract | checkpoint |
| adversary | QA — assume broken, prove | checkpoint | verdict |

## Communication Flow

```
1. Orchestrator creates CONTRACT → AgentDB
2. Surgeon reads contract, writes CHECKPOINT → AgentDB
3. Orchestrator reads checkpoint, spawns adversary (Tier 3)
4. Adversary reads checkpoint, writes VERDICT → AgentDB
5. Orchestrator reads verdict, reports to user
```

## Spawning

Use `Task` tool with `kernel:surgeon` or `kernel:adversary` subagent type.

Include in prompt:
- Contract ID and goal
- Explicit file list (scope)
- Anti-patterns (what not to do)
- Failure paths (what to do when stuck)
- AgentDB write instructions

## Anti-Patterns

```
agents_report_verbally     → They write to AgentDB
orchestrator_writes_code   → Spawn surgeon instead (Tier 2+)
skip_contract              → No agent work without contract
```
