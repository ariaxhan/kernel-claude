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

<steps>

1. **REPRODUCE** — get specific before touching code.
   - Document: exact input, expected output, actual output (full stack trace), environment, frequency.
   - "Sometimes fails" is not a reproduction. Get deterministic.
   - (gate: can reproduce consistently, OR have added targeted logging to wait for next occurrence)

2. **HYPOTHESIZE** — list 3 causes before pursuing any.
   - Read ALL error output first (anchoring bias mitigation).
   - Write each hypothesis to AgentDB. Prevents circular re-investigation.
   - (gate: 3 candidate hypotheses written; none pursued yet)

3. **ISOLATE** — binary search, O(log n) not O(n).
   - **Code**: call chain A→B→C→D→E fails → check midpoint C → recurse into failing half.
   - **Time**: `git bisect` between known-good and known-bad commit. ~10 tests for 1000 commits.
   - **Input**: large failing input → split in half → recurse to minimal reproduction case.
   - Instrument at boundaries: log inputs/outputs at each layer boundary.
   - Mock external dependencies to isolate which one causes failure.
   - (gate: failure localized to a specific function/commit/input subset)

4. **ROOT CAUSE** — the error line is the FAILURE. The DEFECT is upstream.
   - Ask: what assumption was violated? What invariant broke?
   - If you can't explain WHY it broke, you haven't found root cause.
   - Top causes by frequency: wrong input shape/type · off-by-one · missing null check · race condition · shared-state mutation · wrong comparison operator · variable scope · swallowed error · API contract mismatch · environment difference.
   - (gate: can state root cause in one sentence explaining the violated invariant)

5. **FIX** — root cause, not symptom.
   - Fix the DEFECT, not the FAILURE site. (Null check at crash site = symptom fix.)
   - Write regression test that fails before fix, passes after.
   - Run: original failing case + edge cases + full regression suite.
   - Commit fix + test together.
   - (gate: regression test green; original failing case passes)

</steps>

<cognitive_biases>
<bias id="confirmation">Seek DISCONFIRMING evidence first. Ask: "What would I see if my hypothesis were WRONG?"</bias>
<bias id="anchoring">Read ALL output before investigating. List 3 causes before pursuing any.</bias>
<bias id="availability">Past patterns are hypotheses, not conclusions. Check AgentDB but test them.</bias>
<bias id="sunk_cost">15 min with no evidence for hypothesis → abandon it. Write what you tested, move on.</bias>
<bias id="optimism">Re-run the EXACT original failing case. "Seems to work" is not evidence.</bias>
</cognitive_biases>

<anti_patterns>
<block id="shotgun">Random changes until it works. Even if it works, you don't know why. Fragile.</block>
<block id="fix_and_pray">Change something, don't test original case, declare victory. Bug returns.</block>
<block id="symptom_fixing">Null check at crash instead of asking why null. Real defect is upstream.</block>
<block id="printf_flooding">Logging everywhere. Use binary search first, then targeted logging.</block>
<block id="blame_framework">It's almost never the library. Check your usage first.</block>
</anti_patterns>

<when_stuck>
1. Explain problem in writing (rubber duck — engages System 2 cognition).
2. Read error message carefully. Answer is there 80% of the time.
3. Simplify to minimal reproduction case.
4. "What changed?" Check git log, git diff, dependency updates, env changes.
5. Search exact error message in quotes.
6. Step away. Bias accumulates under sustained focus.
7. **Plan Mode**: Paste stack traces in Plan Mode first. Analyze, form hypotheses, get approval — then switch to Act mode for fixes.
8. **Rewind**: `Esc+Esc` or `/rewind` restores code to a pre-bug checkpoint without losing conversation context. Checkpoints survive terminal closes.
9. **Visibility-first**: Paste raw terminal output / error logs / screenshots directly. Raw data beats your interpretation.
10. **Evidence-first, not assertion**: Show the actual evidence (test output, exact command + result, screenshot) rather than stating "it works." Reviewing evidence is faster than re-running verification, and catches cases where "seems to work" masks a different failure path. <!-- Updated 2026-06-05: https://code.claude.com/docs/en/best-practices -->
11. **Extended thinking**: for complex bugs with no clear hypothesis after all above, request deep analysis using extended thinking. Deliberate multi-step reasoning before output catches subtle root causes that fast responses miss. <!-- Updated 2026-06-06: https://gitnation.com/contents/advanced-claude-code-techniques-for-2026 -->
</when_stuck>

<escalation>
- 30+ min on single hypothesis with no evidence → abandon it.
- 3+ hypotheses rejected → step back, re-examine assumptions.
- 2 failed fix attempts → orchestrator invokes tearitapart. May be design problem, not implementation.
- 2+ failed corrections in same session → `/clear`, rewrite initial prompt with lessons learned. Clean session beats polluted long session.
- 3 consecutive responses under ~500 tokens with no progress → anchor-drift. `/clear`, strip to minimal reproduction, restart.
- Bug only in production → add targeted monitoring, document, move on.
</escalation>

<parallel_debug_strategy>
Competing hypothesis agents: for bugs with 3+ plausible causes, spawn one agent per hypothesis with fresh context.
Each reports: evidence_for | evidence_against | confidence (0-1). Coroner agent synthesizes.
Fresh context catches what a long session anchors past.
When stuck >30 min, spawn fresh agent with ONLY: exact input, expected vs actual, relevant code section.
See: skills/debug/reference/debug-research.md — Parallel Debug Strategy.
</parallel_debug_strategy>

<agentic_debugging>
- Check whether bug was introduced by an AI edit: `git log --oneline -20`, then `git bisect`.
- AI edits tend to: drop early returns, misplace null checks, silently change API call signatures.
- Distinguish tool-call failure (environment/permissions) from logic failure (code) — different fixes.
- Check `git status` / `git diff` for interrupted-state partial writes before assuming canonical version.
- Reduce to minimal reproduction BEFORE spawning agents. Agents given vague reproductions reproduce the wrong thing.
</agentic_debugging>

<persistent_truth_file>
Create `_meta/context/DEBUG.md` at session start. Update throughout. Claude reads it before each attempt.
Prevents circular re-investigation across context compression boundaries.

Template fields: Problem Statement · What We Know · Approaches Tried (with failure reason) · Current Hypothesis · Next Steps.
Full template: skills/debug/reference/debug-research.md — Persistent Investigation File.
</persistent_truth_file>

<on_complete>
agentdb write-end '{"skill":"debug","bug":"<description>","root_cause":"<what_broke>","fix":"<what_fixed>","test":"<regression_test_name>","learned":"<pattern_for_future>"}'

Always record debugging learnings. They prevent repeat investigation.
</on_complete>

</skill>
