---
name: debug
description: "Systematic debugging methodology based on Zeller's scientific method. Reproduce, hypothesize, predict, test, isolate via binary search, fix root cause. Every fix gets a regression test. Triggers: bug, error, fix, broken, not working, fails, crashed, unexpected, stack trace, regression, exception."
allowed-tools: Read, Bash, Grep, Glob
---

<skill id="debug">

<purpose>
Debugging is forming and testing a THEORY that explains the bug.
Not random changes. Not guessing. Scientific method applied to code.
DEFECT (in code) → INFECTION (in state) → FAILURE (visible symptom).
The failure you see is NOT where the bug is. Binary search upstream.
</purpose>

<prerequisite>
AgentDB read-start has run. Check past failures—you may have seen this pattern.
</prerequisite>

<reference>
Skill-specific: skills/debug/reference/debug-research.md
</reference>

<scientific_method>
1. OBSERVE: What exactly failed? Document input, expected, actual.
2. HYPOTHESIZE: Why might this happen? List 3 possible causes before pursuing any.
3. PREDICT: If this hypothesis is correct, what else should I see?
4. TEST: Does the prediction hold? Seek DISCONFIRMING evidence first.
5. REFINE or REJECT: Based on evidence, narrow or abandon hypothesis.
6. REPEAT: Until the defect—not the symptom—is isolated.

Write each hypothesis and test result to AgentDB. Prevents circular investigation.
</scientific_method>

<phase id="reproduce">
Before touching code, get SPECIFIC:
- Input: exact values, sequence, timing that triggers the bug.
- Expected: what should happen.
- Actual: what happens instead (full error, stack trace).
- Environment: versions, OS, relevant state.
- Frequency: always? sometimes? specific conditions?

"It sometimes fails" is NOT a reproduction. Get deterministic.
If it can't be reproduced, add targeted logging and wait.
</phase>

<phase id="isolate">
Binary search is O(log n). Random guessing is O(n). Use binary search.

CODE: Call chain A→B→C→D→E fails. Check C. Works? Bug in D-E. Fails? Bug in A-C. Recurse.
TIME: git bisect between known-good and known-bad commit. ~10 tests for 1000 commits.
INPUT: Large failing input? Split in half. Which half fails? Recurse to minimal case.

Instrument at boundaries: log inputs/outputs at each step.
Mock external dependencies to isolate which one causes failure.
</phase>

<phase id="root_cause">
The error line is the FAILURE. The DEFECT is upstream.
Ask: what assumption was violated? What invariant broke?

<common_causes rank="by_frequency">
1. Wrong input shape or type
2. Off-by-one (loop bounds, indices, slicing)
3. Missing null/undefined check
4. Race condition or async timing
5. Mutating shared state (aliasing)
6. Wrong comparison operator (=, ==, ===, >, >=)
7. Variable scope (closure captures, shadowing)
8. Swallowed error (empty catch block)
9. API contract mismatch
10. Environment difference
</common_causes>

If you can't explain WHY it broke, you haven't found root cause.
</phase>

<phase id="fix">
1. Fix ROOT CAUSE, not symptom. (Null check at crash site = symptom fix.)
2. Write test that reproduces original bug. Must fail before fix, pass after.
3. Run regression: original case + edge cases + happy path.
4. Commit fix + test together.

Every bug fix MUST include a regression test. No exceptions.
</phase>

<cognitive_biases>
<bias id="confirmation">You look for evidence your hypothesis is right. Actively seek DISCONFIRMING evidence instead.</bias>
<bias id="anchoring">First error message anchors you. Read ALL output first. List 3 causes before pursuing any.</bias>
<bias id="availability">"Last time it was the database." This time might be different. Past patterns are hypotheses, not conclusions.</bias>
<bias id="sunk_cost">15 min with no evidence for hypothesis → abandon it. Write what you tested, move on.</bias>
<bias id="optimism">"It probably works now." Re-run the EXACT original failing case. "Seems to work" is not evidence.</bias>
</cognitive_biases>

<anti_patterns>
<block id="shotgun">Random changes until it works. Even if it works, you don't know why. Fragile.</block>
<block id="fix_and_pray">Change something, don't test original case, declare victory. Bug returns.</block>
<block id="symptom_fixing">Null check at crash instead of asking why null. Real defect is upstream.</block>
<block id="printf_flooding">Logging everywhere. Use binary search first, then targeted logging.</block>
<block id="blame_framework">It's almost never the library. Check your usage first.</block>
</anti_patterns>

<when_stuck>
1. Explain problem in writing (rubber duck—engages System 2 cognition).
2. Read error message carefully. Answer is there 80% of the time.
3. Simplify to minimal reproduction case.
4. "What changed?" Check git log, git diff, dependency updates, env changes.
5. Search exact error message in quotes.
6. Step away. Bias accumulates under sustained focus.
</when_stuck>

<escalation>
- 30+ min on single hypothesis with no evidence → abandon it.
- 3+ hypotheses rejected → step back, re-examine assumptions.
- 2 failed fix attempts → orchestrator should invoke tearitapart. May be design problem, not implementation.
- Bug only in production → add targeted monitoring, document, move on.
</escalation>

<on_complete>
agentdb write-end '{"skill":"debug","bug":"<description>","root_cause":"<what_broke>","fix":"<what_fixed>","test":"<regression_test_name>","learned":"<pattern_for_future>"}'

Always record debugging learnings. They prevent repeat investigation.
</on_complete>

</skill>
