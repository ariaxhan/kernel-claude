---
name: Feature Implementation
trigger:
  - skill: /kernel:ingest
  - issue_label: feature
  - task_type: feature
tier: auto  # determined at classify step
---

## Steps

1. **Scout** -- Map affected areas
   - agent: scout
   - output: affected files list, risk zones, existing patterns
   - skip_if: familiar AND tier == 1

2. **Research** -- Find anti-patterns and proven solutions
   - agent: researcher
   - output: _meta/research/{topic}.md
   - cache: check _meta/research/ first (TTL: 7d patterns, 30d docs)
   - skip_if: familiar AND tier == 1 AND cache_hit

3. **Plan** -- Define scope and acceptance criteria
   - agent: orchestrator (you)
   - output: contract with goal, files, tier, done_when
   - requires: human confirmation (ingest mode) OR auto-proceed (forge mode)

4. **Implement** -- Execute the contract
   - agent: surgeon
   - isolation: worktree (tier 2+)
   - output: commits on feature branch
   - retry: max 3 with feedback

5. **Verify** -- QA and validation
   - agent: adversary
   - output: verdict to AgentDB
   - on_reject: return to step 4 with feedback

6. **Prepare to ship** -- validate committed branch; external writes need user authority
   - agent: orchestrator
   - local: leave verified commits ready for the user
   - github: push the feature branch only when the task authorizes a push
   - github-oss: push feature branch, create PR (required)
   - github-production: push feature branch, create PR, request review (required)

## On Failure

- Step 2 fails: checkpoint and resolve the research gap before implementation
- Step 4 fails: retry with narrower scope (max 3)
- Step 4 blocked: checkpoint, escalate to human
- Step 5 rejects: return to step 4 with adversary feedback
- Any step exceeds timeout: checkpoint and STOP
