---
name: Feature Implementation
trigger:
  - command: /kernel:ingest
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
   - requires: human confirmation (ingest mode) OR auto-proceed (auto mode)

4. **Implement** -- Execute the contract
   - agent: surgeon
   - isolation: worktree (tier 2+)
   - output: commits on feature branch
   - retry: max 3 with feedback

5. **Verify** -- QA and validation
   - agent: adversary (tier 3) OR validator (tier 1-2)
   - output: verdict to AgentDB
   - on_reject: return to step 4 with feedback

6. **Ship** -- Commit, push, and follow profile git workflow
   - agent: orchestrator
   - actions:
     - Push commits to feature branch
     - If profile is github-oss or github-production: create PR via `gh pr create`
     - If profile is github: push branch (no PR needed)
     - If profile is local: merge to main directly
     - If gh CLI unavailable: push branch, output manual PR URL
   - output: pushed branch + PR link (if applicable)
   - rule: NEVER merge to main directly for github-oss or github-production

## On Failure

- Step 2 fails: proceed with caution, note gap in research
- Step 4 fails: retry with narrower scope (max 3)
- Step 4 blocked: checkpoint, escalate to human
- Step 5 rejects: return to step 4 with adversary feedback
- Any step exceeds timeout: checkpoint and STOP
