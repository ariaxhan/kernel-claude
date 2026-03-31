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

<worktree_isolation>
Use git worktree isolation for tier 2+ when multiple surgeons run in parallel.

**When**: Tier 2+ with 2+ concurrent surgeons touching different files.
**How**: Claude Code natively supports `isolation: "worktree"` on the Agent tool.
  - Each surgeon gets an isolated repo copy
  - If changes are made, worktree path and branch are returned
  - If no changes, worktree auto-cleans

**Pattern**:
```
Agent tool call:
  subagent_type: kernel:surgeon
  isolation: "worktree"
  prompt: "Contract CR-xxx: implement..."
```

**Merge protocol**: After surgeon completes, orchestrator reviews branch diff, then merges to main working tree.
**Failure mode**: Surgeon fails → worktree abandoned (no main pollution). Read AgentDB checkpoint for details.
**Tier 1**: Don't use worktrees. Unnecessary overhead for 1-2 file changes.
</worktree_isolation>

<context_transfer>
Every agent boundary is lossy compression.
- Pre-transfer: Write structured briefing to AgentDB
- Post-transfer: Read AgentDB + active.md to restore
- Never rely on conversation history across agents
</context_transfer>

<knowledge_injection>
  Before spawning any agent, inject relevant context:

  orchestrator_protocol:
    1. Build context slice: `agentdb inject-context <agent_type>`
    2. Include slice in agent prompt (not as a separate tool call)
    3. Agent receives pre-loaded context — doesn't need to search

  agent_slicing:
    surgeon: gotchas + patterns + active contract
    adversary: past failures + gotchas + recent errors
    reviewer: same as adversary (test for known failure modes)
    researcher: all learnings by domain + recent verdicts
    triage: complexity signals + recent contracts
    understudier: same as triage

  rule: inject BEFORE spawn. Never let agents discover context at runtime.
  rule: orchestrator owns injection. Agents don't call inject-context themselves.
</knowledge_injection>

<anti_patterns>
- Holding context in memory instead of AgentDB
- Assuming agent completed without reading DB
- Serial execution when parallel is possible
- Retrying without new context from failure
</anti_patterns>

</skill>
