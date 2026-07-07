---
name: orchestration
description: "Multi-agent orchestration. Lane contracts, worker-model doctrine, fault tolerance, worktree isolation. Triggers: orchestrate, coordinate, agents, parallel, spawn, contract, tier 2, tier 3."
allowed-tools: Task, Bash, Read
---

<skill id="orchestration">

<purpose>
Orchestration is coordination, not implementation. You define contracts, agents
execute, AgentDB is the bus. Never assume completion without reading the file.
Reference on demand: skills/orchestration/reference/orchestration-research.md.
</purpose>

<lane_contract>
Every spawned lane gets ALL of these fields; a missing field is where the lane fails:
1. **Deliverable**: the observable artifact, named exactly (file path, PR, report).
2. **Read-first list**: the files/docs the lane must read before acting.
3. **Files table**: exhaustive list of files it may touch (`constraints.files`).
   No two concurrent lanes may overlap. Contract JSON:
   `{"goal":"X","constraints":{"files":["a.sh","b.md"]},"tier":2}`
4. **Known traps, restated**: gotchas relevant to this lane, inlined, not linked.
5. **Verification loop with exact commands**: the literal commands the lane runs to
   prove its own work (test invocation, grep, curl), plus expected output.
6. **Forbidden list**: what the lane must NOT do (push, touch _meta/, add deps, ...).
7. **Raw-data return format**: counts, file lists, command output. Never narrative
   alone; a lane that returns only prose has returned nothing checkable.
</lane_contract>

<worker_model_doctrine>
Cheap models (haiku/codex-tier) are safe ONLY for total-spec execution and mechanical
evidence-only verification: zero delegated decisions, a pre-verified guide, every step
spelled out. If you are tempted to write "use your judgment" in a cheap-model prompt,
it is a strong-model task. The coordinator re-runs gates itself; lane reports are
claims, not facts, and are wrong roughly 1 in 5. Adjudicate on evidence you reproduce.
</worker_model_doctrine>

<fault_tolerance>
1. RETRY transient failures with backoff, max 3. 2. FALLBACK to an alternative
model/provider on provider failure. 3. CLASSIFY the failure type before choosing
recovery. 4. CHECKPOINT state to AgentDB at every boundary so a respawn resumes
instead of restarting.
</fault_tolerance>

<worktree_safety>
Parallel lanes (tier 2+) run in isolated git worktrees (`isolation: "worktree"`),
never the main worktree; failed work is discarded by deleting the worktree. Pre-spawn:
working tree clean or stashed; each lane's `constraints.files` disjoint from all
active lanes. Post-agent validation: read the lane's checkpoint, then
`git diff --name-only {base}..{lane_branch}`; every changed file MUST appear in
`constraints.files`, and an out-of-scope file means reject, do not merge, re-contract.
Tier 1 skips worktrees (unnecessary overhead).
</worktree_safety>

<knowledge_injection>
Inject context BEFORE spawn, never let lanes discover it at runtime: build the slice
with `agentdb inject-context <agent_type>` and inline it in the prompt (surgeon gets
gotchas + patterns + contract; adversary/reviewer get past failures + recent errors;
researcher gets domain learnings). The orchestrator owns injection. Every agent
boundary is lossy compression: structured briefing in, structured checkpoint out;
never rely on conversation history across agents.
</knowledge_injection>

<anti_patterns>
Holding context in memory instead of AgentDB · assuming a lane finished without
reading the deliverable file (receipts describe intent; files describe reality) ·
parallel lanes touching shared files (N-way merge conflicts) · serial execution when
parallel is genuinely safe · retrying without new information from the failure ·
autonomous loops without a budget cap (`max_budget_usd` on the contract).
</anti_patterns>

</skill>
