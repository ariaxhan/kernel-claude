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
7. **Plan Mode**: For complex or sensitive bugs, use Plan Mode to analyze errors and form hypotheses without making any code changes until the approach is approved. Paste stack traces and error messages in Plan Mode first.
8. **Rewind to pre-bug state**: `Esc+Esc` or `/rewind` opens checkpoint history. Restore code state to before the suspected change without losing conversation context. Faster than manual git reset when the bug was introduced in the current session. Checkpoints persist across terminal closes — they survive session restarts.
9. **Visibility-first**: Don't describe the problem — show the raw evidence. Paste terminal output, actual error logs, or screenshots directly. Let Claude read the data, not your interpretation of it. A description of a bug introduces your assumptions; the raw output doesn't.
<!-- Updated 2026-04-14: https://allierays.com/posts/5-techniques-to-debug-claude-code/ -->
</when_stuck>
<!-- Updated 2026-03-28: https://code.claude.com/docs/en/best-practices, https://claudelog.com/faqs/how-to-use-claude-code-for-debugging/ -->
<!-- Updated 2026-04-10: https://code.claude.com/docs/en/best-practices -->

<escalation>
- 30+ min on single hypothesis with no evidence → abandon it.
- 3+ hypotheses rejected → step back, re-examine assumptions.
- 2 failed fix attempts → orchestrator should invoke tearitapart. May be design problem, not implementation.
- 2+ failed corrections in same session → `/clear` and rewrite the initial prompt incorporating lessons learned. A clean session with a better prompt outperforms a long session polluted with failed approaches.
- Bug only in production → add targeted monitoring, document, move on.
<!-- Updated 2026-05-12: https://bits-bytes-nn.github.io/insights/agentic-ai/2026/03/31/claude-code-architecture-analysis.html -->
- **Diminishing returns signal**: If Claude produces 3 consecutive responses under ~500 tokens without progress, the session has anchored. Don't retry — `/clear`, strip the problem to its minimal reproduction, restart fresh. A shorter prompt with better constraints beats a longer session with more correction attempts.
</escalation>

<!-- Updated 2026-03-30: Claude Code debugging techniques, Anthropic prompt engineering guide -->
<!-- Updated 2026-04-02: https://claudefa.st/blog/guide/agents/agent-teams, https://medium.com/@Coda./inside-claude-code-engineering-the-future-of-agentic-development-508050bf37a2 -->
<parallel_debug_strategy>
**Competing hypothesis agents**: For bugs with multiple plausible causes, spawn separate agents
per hypothesis. Each investigates independently with a fresh, unpolluted context window.
Agents with fresh context catch what a single long session anchors past.

```
Agent A: Hypothesis — race condition in cache layer
Agent B: Hypothesis — API contract mismatch on response shape
Agent C: Hypothesis — off-by-one in pagination cursor

Each reports: evidence_for | evidence_against | confidence (0-1)
Coroner agent synthesizes findings.
```

**Fresh context advantage**: Long debugging sessions accumulate cognitive anchoring.
A fresh agent given only the minimal reproduction case (not 200 lines of chat history)
reasons more clearly. When stuck >30 min, spawn a fresh agent with only:
- The exact input that triggers the bug
- The expected vs actual output
- The relevant code section (not the whole file)

**AgentDB as debug log**: Write each hypothesis and its test result to AgentDB before
abandoning it. Prevents the same hypothesis being re-investigated in the next session.
</parallel_debug_strategy>

<agentic_debugging>
When debugging in an agentic context, additional failure modes arise:

**Agent-introduced bugs**: Check whether the bug was introduced by an AI edit. Run
`git log --oneline -20` to identify when it appeared. `git bisect` between last known-good
and first known-bad agent commit. AI edits tend to: drop early returns, misplace null
checks, and silently change API call signatures.

**Tool-call failures vs logic failures**: Distinguish between:
- Tool call returned wrong result (environment/permissions issue)
- Tool call succeeded but logic was wrong (code issue)
These have completely different fixes. Check tool outputs before assuming logic error.

**Interrupted state**: If a previous agent session was interrupted, check for partial
writes or uncommitted changes (`git status`, `git diff`) before assuming the code is
the canonical version.

**Reproduce with minimal agent context**: If bug is hard to reproduce, reduce the
problem to its smallest form BEFORE spawning any agents. Agents given a vague reproduction
reproduce the wrong thing.
</agentic_debugging>

<!-- Updated 2026-04-23: https://code.claude.com/docs/en/best-practices (debugging anti-patterns) -->
<persistent_truth_file>
Long debugging sessions create circles: Claude tries fix, fails, context compresses, Claude forgets what was tried.
Prevent this with a persistent investigation file that survives auto-compaction.

Create `_meta/context/DEBUG.md` at session start. Update it throughout. Claude reads it before each attempt.

**Evidence**: Structured persistent investigation achieves ~95% first-time fix rate vs ~40% for ad-hoc debugging. The file prevents circular re-investigation across context compression boundaries. <!-- Updated 2026-05-06: https://allierays.com/posts/5-techniques-to-debug-claude-code/ -->

Template:
```markdown
# Debugging Session: [Issue Title]

## Problem Statement
[Concise problem + exact error message]

## What We Know
- [confirmed fact 1]
- [confirmed fact 2]

## Approaches Tried
- [ ] Approach A: [description] → Failed because [reason]
- [ ] Approach B: [description] → Failed because [reason]
- [x] Approach C: [description] → Partially works, need to [next step]

## Current Hypothesis
[Best current theory of root cause]

## Next Steps
1. [specific action]
```

Instruct Claude: "Read _meta/context/DEBUG.md before each attempt. Update it after each attempt."
Prevents re-trying failed approaches across context compression boundaries.
</persistent_truth_file>

<!-- Updated 2026-04-25: https://medium.com/@sean.j.moran/effective-claude-code-workflows-in-2026-what-changed-and-what-works-now-c93ebc6f8f50, https://allierays.com/posts/5-techniques-to-debug-claude-code/ -->
<tooling_2026>
In 2026, Claude Code's default tooling handles more of the debugging burden automatically:

- **Compaction**: Auto-manages context window limits. You no longer need to manually `/compact` during debug sessions — the system does it. But instruct compaction to preserve `_meta/context/DEBUG.md` so investigation state survives.
- **Plan Mode**: Use for complex or multi-file bugs before touching code. Scope the exploration, form hypotheses, get approval — then switch to Act mode for fixes.
- **Agent tool for parallel exploration**: Spawn competing-hypothesis agents without polluting the main context. Each agent gets only the minimal reproduction, not 200 lines of chat history.

**Root cause over fast fix**: Claude solves the immediate problem by finding the fastest path to making the error go away. The fastest fix is frequently wrong — it patches the symptom and breaks something downstream. When a fix "works" but you can't explain *why the bug occurred*, you haven't fixed it.
</tooling_2026>

<on_complete>
agentdb write-end '{"skill":"debug","bug":"<description>","root_cause":"<what_broke>","fix":"<what_fixed>","test":"<regression_test_name>","learned":"<pattern_for_future>"}'

Always record debugging learnings. They prevent repeat investigation.
</on_complete>

</skill>
