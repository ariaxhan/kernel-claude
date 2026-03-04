---
name: debug
description: >
  Systematic debugging methodology. Reproduce first, isolate via binary search,
  fix root cause not symptom. Use when encountering bugs, errors, crashes,
  unexpected behavior, or stack traces.
  Triggers: bug, error, fix, broken, not working, fails, crashed, unexpected, stack trace.
allowed-tools: Read, Bash, Grep, Glob
---

<skill id="debug">

<purpose>
Reproduce first. Isolate via binary search. Instrument, don't guess.
Fix root cause, not symptom. Every fix gets a regression test.
</purpose>

<prerequisite>
  KERNEL active. AgentDB read-start has run. Check past failures first; you may have seen this pattern before.
</prerequisite>

<!-- PHASE 1: REPRODUCE -->

<phase id="reproduce" label="Can you trigger it consistently?">
  Before touching ANY code, document:
  - Input: exact values that trigger the bug.
  - Expected: what should happen.
  - Actual: what happens instead.
  - Environment: OS, versions, relevant state.
  - Frequency: always, sometimes, specific conditions?

  <rule>"It sometimes fails" is not a reproduction. Get SPECIFIC.</rule>
</phase>

<!-- PHASE 2: ISOLATE (Binary Search) -->

<phase id="isolate" label="Where exactly is it?">
  If call chain is A → B → C → D → E:
  1. Check midpoint (C). Works? Bug is in D-E. Fails? Bug is in A-C.
  2. Repeat. O(log n), not O(n) random guessing.

  Instrumentation: add logging at boundaries. Check inputs/outputs at each step.

  Dependency removal: mock external calls, use in-memory data, replace complex logic with placeholder. Isolate which dependency causes failure.
</phase>

<!-- PHASE 3: ROOT CAUSE -->

<phase id="root_cause" label="Why does it happen?">
  Questions:
  - What assumption was violated?
  - What invariant was broken?
  - What changed recently?
  - Is this a symptom of something deeper?

  Common root causes: wrong input shape/type, off-by-one, missing null check, race condition, mutating shared state, wrong operator, scope issue, swallowed error, API mismatch, timezone handling.

  <rule>If you can't explain WHY it broke, you haven't found root cause.</rule>
</phase>

<!-- PHASE 4: FIX + REGRESSION TEST -->

<phase id="fix" label="Permanent fix">
  1. Fix ROOT CAUSE, not symptom.
  2. Write test that reproduces original bug (would fail before fix, passes after).
  3. Run regression: original case + edge cases + happy path + adjacent code.
  4. Commit fix + test together.

  <rule>Every bug fix MUST include a regression test. No exceptions.</rule>
</phase>

<!-- DEBUGGING CHECKLISTS -->

<checklist id="data_flow">
  Check input shape/type (log it). Check each transformation. Check output. Verify no shared-state mutation.
</checklist>

<checklist id="logic">
  Conditions correct (>, >=, ==, ===)? All branches covered? Loop termination? Variable scope?
</checklist>

<checklist id="async">
  Promises awaited? Race condition possible? Callbacks called? Event handlers registered?
</checklist>

<!-- WHEN STUCK -->

<when_stuck>
  1. Explain the problem in writing (rubber duck).
  2. Read the error message carefully (answer is there 80% of the time).
  3. Check docs (might be using API wrong).
  4. Simplify: make minimal reproduction case.
  5. Search: "{exact error message}" in quotes.
</when_stuck>

<on_complete>
  agentdb write-end with skill="debug", bug description, fix, learned pattern.
  <rule>Always record debugging learnings. They prevent repeat bugs.</rule>
</on_complete>
</skill>