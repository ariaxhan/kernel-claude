---
name: orchestration
description: "Multi-agent orchestration patterns. AgentDB as structured briefing, 4 fault tolerance layers (retry, fallback, classification, checkpointing), context transfer protocols. Triggers: orchestrate, coordinate, agents, parallel, spawn, contract, tier 2, tier 3."
allowed-tools: Task, Bash, Read
---

<skill id="orchestration">

<purpose>
Orchestration is coordination, not implementation.
You define contracts. Agents execute. AgentDB is the bus.
Never assume completion without reading AgentDB entry.
</purpose>

<prerequisite>
AgentDB read-start has run. Check active contracts and pending checkpoints.
</prerequisite>

<reference>
Skill-specific: skills/orchestration/reference/orchestration-research.md
</reference>

<core_principles>
1. CONTRACTS FIRST: Observable goal, bounded scope, clear failure conditions.
2. AGENTDB IS THE BUS: Agents don't report verbally. They write to DB.
3. NEVER ASSUME: Always read checkpoint/verdict before proceeding.
4. PARALLEL DEFAULT: Independent tasks = concurrent agents.
5. FAIL FAST: Surface blockers immediately. Don't hide failures.
</core_principles>

<fault_tolerance>
4 required layers:
1. RETRY: Transient failures (timeout, rate limit) → backoff, max 3 attempts
2. FALLBACK: Model/provider failure → route to alternative
3. CLASSIFICATION: Categorize failure type before choosing recovery
4. CHECKPOINTING: Write state to AgentDB at every boundary
</fault_tolerance>

<context_transfer>
Every agent boundary is lossy compression.
- Pre-transfer: Write structured briefing to AgentDB
- Post-transfer: Read AgentDB + active.md to restore
- Never rely on conversation history across agents
</context_transfer>

<anti_patterns>
- Holding context in memory instead of AgentDB
- Assuming agent completed without reading DB
- Serial execution when parallel is possible
- Retrying without new context from failure
</anti_patterns>

</skill>
