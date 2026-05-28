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
4. VERIFY BY FILE, NOT BY RECEIPT: Open the deliverable file before marking DONE. Receipt = intent; file = evidence.
5. PARALLEL DEFAULT: Independent files = concurrent agents. Shared files = serialize.
6. FAIL FAST: Surface blockers immediately. Don't hide failures.
</core_principles>

<fault_tolerance>
4 required layers:
1. RETRY: Transient failures → backoff, max 3 attempts
2. FALLBACK: Model/provider failure → route to alternative
3. CLASSIFICATION: Categorize failure type before choosing recovery
4. CHECKPOINTING: Write state to AgentDB at every boundary
</fault_tolerance>

<worktree_isolation>
Use git worktree isolation for tier 2+ when multiple surgeons run in parallel.
- Set `isolation: "worktree"` on Agent tool call
- Each surgeon gets isolated repo copy; failed work abandoned (no main pollution)
- Merge protocol: review branch diff → merge to main working tree
- Tier 1: skip worktrees (unnecessary overhead)
</worktree_isolation>

<worktree_safety>
Constraint enforcement for parallel agents. Prevents scope creep and file conflicts.

**Contract constraints (mandatory for tier 2+)**:
- Every contract MUST include `constraints.files`: exhaustive list of files agent may touch.
- Format: `{"goal":"X","files":["a.sh"],"constraints":{"files":["a.sh","b.md"]},"tier":2}`
- No two concurrent contracts may have overlapping `constraints.files`.

**Pre-spawn validation**:
1. `git status --porcelain` must be clean or stashed before spawning.
2. Each surgeon's constraint list must be disjoint from all active surgeons.

**Post-agent validation**:
1. Read surgeon's checkpoint from AgentDB.
2. Run `git diff --name-only {base}..{surgeon_branch}`.
3. Every file in diff MUST appear in `constraints.files`.
4. Out-of-scope file → REJECT output. Do not merge. Re-contract.

**Merge protocol**:
- Validate constraints before merging surgeon branch to main.
- If violated: abandon branch, log failure, re-contract with corrected scope.
</worktree_safety>

<context_transfer>
Every agent boundary is lossy compression.
1. Pre-transfer: Write structured briefing to AgentDB
2. Post-transfer: Read AgentDB + active.md to restore
3. Never rely on conversation history across agents
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

<progressive_autonomy>
  Confidence-based human escalation:

  levels:
    supervised:       confidence < 0.6 — human confirms every decision
    semi_autonomous:  0.6 <= confidence < 0.8 — human confirms tier 2+ only
    autonomous:       confidence >= 0.8 — human reviews results, not decisions

  escalation_triggers:
    - confidence below threshold for current level
    - unfamiliar tech or pattern (no matching learnings)
    - scope exceeds contract by >20%
    - security-sensitive change detected
    - breaking change to public API

  rule: start supervised. Earn autonomy through consistent quality.
  rule: any security concern instantly drops to supervised level.
</progressive_autonomy>

<budget_awareness>
  Agents see their remaining budget. Self-regulate complexity.

  allocation:
    tier_1: low cost (direct execution)
    tier_2: medium cost (orchestrator + surgeon)
    tier_3: high cost (full council)

  alerts:
    50%: normal — continue
    80%: warn — simplify approach
    95%: critical — wrap up, checkpoint, stop spawning

  preflight (orchestrator enforces before any autonomous loop):
    1. Confirm `max_budget_usd` is set on contract.
    2. If unset: AskUserQuestion — set ceiling or proceed unbounded.
    3. Track cumulative cost via agentdb emit. Hard stop at 100%.

  rule: never exceed budget silently. Alert at 80%, hard stop at 95%.
  rule: budget is per-contract, not per-session.
</budget_awareness>

<checkpoint_recovery>
  Resume from last good state, not restart from scratch. Saves 40-60% on failures.

  protocol:
    1. on_spawn: check agentdb for existing checkpoint with same contract_id
    2. if_found: resume from step + 1, skip completed work
    3. if_not_found: start fresh
    4. on_each_step: write checkpoint via agentdb write-end
    5. on_failure: checkpoint preserved — next spawn resumes

  version_safety:
    - on resume: verify files haven't changed since checkpoint
    - if changed externally: invalidate checkpoint, start fresh

  rule: always checkpoint before risky operations.
  rule: checkpoint is cheap. Not checkpointing is expensive.
</checkpoint_recovery>

<entropy_adaptive>
  Dynamic orchestration based on task entropy.

  entropy_measurement:
    low:    familiar pattern, existing tests, clear scope
    medium: some unknowns, partial coverage
    high:   unfamiliar tech, no tests, cross-cutting

  adaptation:
    low_entropy:    skip researcher+scout; surgeon directly
    medium_entropy: researcher → surgeon → validator; skip adversary
    high_entropy:   full council + coroner on failure

  override:
    - security-sensitive changes always get full pipeline regardless of entropy
    - human can force entropy level via AskUserQuestion
    - first session in new project always starts at high entropy

  rule: entropy decreases as learnings accumulate.
  rule: never skip security checks regardless of entropy level.
</entropy_adaptive>

<anti_patterns>
- Holding context in memory instead of AgentDB
- Assuming agent completed without reading DB
- Trusting subagent receipts as evidence — receipts describe intent; files describe reality
- Parallel agents touching shared files — produces N-way merge conflicts
- Serial execution when parallel is genuinely safe
- Retrying without new context from failure
</anti_patterns>

</skill>
