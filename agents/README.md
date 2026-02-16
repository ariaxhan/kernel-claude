# Orchestration Agents

Tier 3 specialized agents for multi-agent coordination. Invoked via `/orchestrate` command.

| Agent | Role | Frame |
|-------|------|-------|
| orchestrator | Coordinate contracts, route work | coordinate |
| architect | Discovery, scoping, risk analysis | discover |
| surgeon | Minimal diff implementation | execute |
| adversary | QA, break it, verify claims | verify |
| searcher | Deep codebase exploration | search |
| researcher | External research, docs, patterns | research |

These agents communicate via AgentDB (SQLite). See `kernel/orchestration/agentdb/` for setup.
