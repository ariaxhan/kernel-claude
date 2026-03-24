---
name: Bugfix
trigger:
  - command: /kernel:ingest
  - issue_label: bug
  - task_type: bug
tier: auto  # determined at classify step
---

## Steps

1. **Reproduce** -- Write a failing test that captures the bug
   - agent: surgeon (tier 1) OR orchestrator (tier 2+)
   - output: failing test committed to branch
   - required: must fail before fix, pass after

2. **Research** -- Root cause analysis, not solution hunting
   - agent: researcher
   - output: _meta/research/{bug-topic}.md
   - focus: why it broke, not how to fix (fix follows from cause)
   - cache: check _meta/research/ first (TTL: 7d)
   - skip_if: root cause obvious from reproduction

3. **Plan** -- Define fix scope and regression criteria
   - agent: orchestrator (you)
   - output: contract with goal, files, tier, done_when
   - requires: human confirmation (ingest mode) OR auto-proceed (auto mode)

4. **Implement** -- Apply minimal fix
   - agent: surgeon
   - isolation: worktree (tier 2+)
   - output: commits on fix branch
   - retry: max 3 with feedback
   - constraint: fix must make failing test pass, no unrelated changes

5. **Verify** -- Confirm fix and check for regressions
   - agent: adversary (tier 3) OR validator (tier 1-2)
   - output: verdict to AgentDB
   - checks: failing test now passes, all existing tests still green
   - on_reject: return to step 4 with feedback

6. **Ship** -- Commit, push, PR
   - agent: orchestrator
   - output: pushed branch, optional PR

## On Failure

- Step 1 fails to reproduce: gather more context, ask human
- Step 2 fails: proceed with best hypothesis, note uncertainty
- Step 4 fails: retry with narrower scope (max 3)
- Step 4 blocked: checkpoint, escalate to human
- Step 5 rejects: return to step 4 with adversary feedback
- Any step exceeds timeout: checkpoint and STOP
