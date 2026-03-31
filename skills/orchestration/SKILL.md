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

<progressive_autonomy>
  Confidence-based human escalation. Higher confidence = less human involvement.

  levels:
    supervised:    confidence < 0.6 — human confirms every decision
    semi_autonomous: 0.6 <= confidence < 0.8 — human confirms tier 2+ only
    autonomous:    confidence >= 0.8 — human reviews results, not decisions

  escalation_triggers:
    - confidence below threshold for current level
    - unfamiliar tech or pattern (no matching learnings)
    - scope exceeds contract by >20%
    - security-sensitive change detected
    - breaking change to public API

  measurement:
    agent_confidence: from reviewer 11-phase scoring
    historical_accuracy: from approval-learner pattern matching
    domain_familiarity: from agentdb learning count in this domain

  rule: start supervised. Earn autonomy through consistent quality.
  rule: any security concern instantly drops to supervised level.
</progressive_autonomy>

<budget_awareness>
  Agents see their remaining budget. Self-regulate complexity.

  allocation:
    tier_1: low cost (direct execution)
    tier_2: medium cost (orchestrator + surgeon)
    tier_3: high cost (full council)

  tracking:
    - agentdb emit tracks token usage per agent per session
    - orchestrator monitors cumulative cost across spawned agents
    - budget injected into agent context: "Remaining budget: ~{N} tokens"

  alerts:
    50%: normal — continue
    80%: warn — simplify approach
    95%: critical — wrap up, checkpoint, stop spawning

  self_regulation:
    - agent sees remaining budget in injected context
    - high budget: explore multiple approaches
    - low budget: pick simplest viable approach
    - exhausted: checkpoint and report to human

  rule: never exceed budget silently. Alert at 80%, hard stop at 95%.
  rule: budget is per-contract, not per-session.
</budget_awareness>

<checkpoint_recovery>
  Resume from last good state, not restart from scratch. Saves 40-60% on failures.

  checkpoint_schema:
    agent_id: which agent was working
    step: last completed step number
    state: JSON blob of current progress
    files_modified: list of files changed so far
    tests_passing: count of passing tests at this point
    timestamp: when checkpoint was written

  protocol:
    on_spawn: check agentdb for existing checkpoint with same contract_id
    if_found: resume from step + 1, skip completed work
    if_not_found: start fresh
    on_each_step: write checkpoint via agentdb write-end
    on_failure: checkpoint is preserved — next spawn resumes

  version_safety:
    - each checkpoint stores list of files_modified
    - on resume: verify files haven't changed since checkpoint
    - if changed externally: invalidate checkpoint, start fresh
    - prevents "double update" from stale state

  integration:
    - surgeon writes checkpoint after each file modification
    - forge checks for checkpoint before each heat cycle
    - orchestrator reads checkpoint to determine resume point

  rule: always checkpoint before risky operations.
  rule: checkpoint is cheap. Not checkpointing is expensive.
</checkpoint_recovery>

<anti_patterns>
- Holding context in memory instead of AgentDB
- Assuming agent completed without reading DB
- Serial execution when parallel is possible
- Retrying without new context from failure
</anti_patterns>

</skill>
