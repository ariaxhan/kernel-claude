---
name: Refactor
trigger:
  - command: /kernel:ingest
  - issue_label: refactor
  - task_type: refactor
tier: auto  # determined at classify step
---

## Steps

1. **Scout** -- Full impact analysis (mandatory, never skip)
   - agent: scout
   - output: affected files list, dependency graph, risk zones
   - mandatory: true (refactors touch structure, must map first)

2. **Baseline** -- Snapshot current test state
   - agent: validator
   - output: full test suite results saved to AgentDB
   - required: all tests must pass before refactor begins
   - on_failure: fix failing tests first (separate task)

3. **Plan** -- Define transformations and preservation criteria
   - agent: orchestrator (you)
   - output: contract with goal, files, tier, done_when
   - constraint: behavior-preserving only, no new features
   - requires: human confirmation (ingest mode) OR auto-proceed (auto mode)

4. **Implement** -- Apply behavior-preserving transformations
   - agent: surgeon
   - isolation: worktree (tier 2+)
   - output: commits on refactor branch
   - retry: max 3 with feedback
   - constraint: no new tests needed, but all existing tests must stay green

5. **Verify Baseline** -- Confirm no behavior change
   - agent: validator
   - output: test suite results diffed against baseline
   - check: test results identical to step 2 (same pass/fail, same count)
   - on_reject: return to step 4 with diff of what changed

6. **Ship** -- Commit, push, PR (profile-gated)
   - agent: orchestrator
   - local/github: push to main or refactor branch
   - github-oss: push refactor branch, create PR (required)
   - github-production: push refactor branch, create PR, request review (required)

## On Failure

- Step 1 finds excessive scope: split into smaller refactors
- Step 2 has failing tests: fix first in separate task
- Step 4 fails: retry with narrower transformations (max 3)
- Step 4 blocked: checkpoint, escalate to human
- Step 5 baseline differs: revert and retry with smaller change
- Any step exceeds timeout: checkpoint and STOP
