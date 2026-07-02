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
Systematic methodology beats ad-hoc guessing. The process is the multiplier.
</purpose>

<prerequisite>
AgentDB read-start has run. Check past failures; you may have seen this pattern.
Debuggability setup (run once per project, not per session): ensure the test suite runs headlessly (`npm test` / `pytest -x` / `cargo test`), add structured logging at service/module boundaries, and document known failure modes in `_meta/context/DEBUG.md`. These three give Claude the foundation to trace and verify without blind file exploration. Without them, debugging sessions spend the first third just establishing a reproduction path.
</prerequisite>

<reference>
Skill-specific: skills/debug/reference/debug-research.md
</reference>

<steps>

1. **REPRODUCE**: get specific before touching code.
   - Document: exact input, expected output, actual output (full stack trace), environment, frequency.
   - "Sometimes fails" is not a reproduction. Get deterministic.
   - (gate: can reproduce consistently, OR have added targeted logging to wait for next occurrence)

2. **HYPOTHESIZE**: list 3 causes before pursuing any.
   - Read ALL error output first (anchoring bias mitigation).
   - Write each hypothesis to AgentDB. Prevents circular re-investigation.
   - (gate: 3 candidate hypotheses written; none pursued yet)

3. **ISOLATE**: binary search, O(log n) not O(n).
   - **Code**: call chain A→B→C→D→E fails → check midpoint C → recurse into failing half.
   - **Time**: `git bisect` between known-good and known-bad commit. ~10 tests for 1000 commits.
   - **Input**: large failing input → split in half → recurse to minimal reproduction case.
   - Instrument at boundaries: log inputs/outputs at each layer boundary.
   - Mock external dependencies to isolate which one causes failure.
   - (gate: failure localized to a specific function/commit/input subset)

4. **ROOT CAUSE**: the error line is the FAILURE. The DEFECT is upstream.
   - Ask: what assumption was violated? What invariant broke?
   - If you can't explain WHY it broke, you haven't found root cause.
   - Top causes by frequency: wrong input shape/type · off-by-one · missing null check · race condition · shared-state mutation · wrong comparison operator · variable scope · swallowed error · API contract mismatch · environment difference.
   - (gate: can state root cause in one sentence explaining the violated invariant)

5. **FIX**: root cause, not symptom.
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
<block id="infinite_exploration">Asking Claude to "investigate" without scope. Claude reads hundreds of files, filling context before doing anything useful. Scope investigations narrowly ("look at src/auth only") or use a subagent (the summary returns, the file reads don't).</block>
</anti_patterns>

<when_stuck>
1. Explain problem in writing (rubber duck: engages System 2 cognition).
2. Read error message carefully. Answer is there 80% of the time.
3. Simplify to minimal reproduction case.
4. "What changed?" Check git log, git diff, dependency updates, env changes.
5. Search exact error message in quotes.
6. Step away. Bias accumulates under sustained focus.
7. **Plan Mode**: Paste stack traces in Plan Mode first. Analyze, form hypotheses, get approval, then switch to Act mode for fixes.
8. **Rewind**: `Esc+Esc` or `/rewind` restores code to a pre-bug checkpoint without losing conversation context. Checkpoints survive terminal closes.
9. **Visibility-first**: Paste raw terminal output / error logs / screenshots directly. Raw data beats your interpretation.
10. **Evidence-first, not assertion**: Show the actual evidence (test output, exact command + result, screenshot) rather than stating "it works." Reviewing evidence is faster than re-running verification, and catches cases where "seems to work" masks a different failure path. <!-- Updated 2026-06-05: https://code.claude.com/docs/en/best-practices -->
11. **`--debug` flag**: run `claude --debug` to expose raw tool inputs/outputs and internal state transitions, going deeper than `--verbose` which shows only high-level steps. Use when `--verbose` doesn't pinpoint which tool call produced the unexpected state. The basic quartet for hard bugs: `--debug`, `--verbose`, `/cost`, `/compact`. <!-- Updated 2026-06-28: https://institute.sfeir.com/en/claude-code/claude-code-advanced-best-practices/debugging/ (verified 2026-07-01) -->
12. **Extended thinking**: for complex bugs with no clear hypothesis after all above, request deep analysis using extended thinking. Deliberate multi-step reasoning before output catches subtle root causes that fast responses miss. <!-- Updated 2026-06-06: https://gitnation.com/contents/advanced-claude-code-techniques-for-2026 -->
13. **--verbose mode**: run `claude --verbose` for hard-to-reproduce bugs: shows tool calls, thinking steps, and execution paths in real time. Catches silent failures and misparsed outputs.
14. **Native debugger**: when an IDE or runtime debugger is available (VS Code, Xcode LLDB, Chrome DevTools), prefer it over print-statement flooding. Set a breakpoint at the suspected boundary, inspect locals at the failure point, evaluate expressions mid-run without re-running from scratch. The call stack tells you the execution path that led to the state. <!-- Updated 2026-06-13: https://claudecode-lab.com/en/blog/claude-code-debugging-techniques/ -->
15. **Pipe raw data**: `cat error.log | claude` or `npm run build 2>&1 | claude`; pipe terminal output directly instead of copy-pasting. Claude receives full fidelity output without truncation or formatting artifacts. <!-- Updated 2026-06-14: https://code.claude.com/docs/en/best-practices -->
16. **Test-driven debugging**: when failing behavior is covered by a test suite, run the tests first: failing test names and assertions mark the exact defect entry point. Trace backwards from the failing assertion rather than reading code cold; the test already has the failure isolated to a function boundary. `npm test -- --watch <file>` or `pytest -x` stops on first failure. Lets the test suite do the reproduction work. <!-- Updated 2026-06-17: https://www.sitepoint.com/debugging-ai-claude-code-vs-traditional-methods/ -->
17. **Domain context injection for business logic bugs**: before asking Claude to debug a business-rule violation, state the rule in plain English ("the discount should apply before tax, not after"). Claude cannot infer invisible business invariants from code alone; naming the violated rule converts an opaque logic mystery into a targeted search. Works especially well for pricing/calculation bugs, multi-step workflows, and permission logic where the correct behavior isn't encoded anywhere in the code. <!-- Updated 2026-06-20: https://claude-world.com/articles/debugging-techniques/ -->
18. **Traditional debugger vs Claude Code**: use a traditional debugger (IDE breakpoints, Chrome DevTools, LLDB) when you need to inspect runtime state at a specific execution point: step through, watch locals, evaluate expressions. Use Claude Code when you need to trace a bug across multiple files or apply a coordinated fix to many call sites. Combining both is faster than forcing either tool outside its strength. <!-- Updated 2026-06-26: https://www.sitepoint.com/debugging-ai-claude-code-vs-traditional-methods/ -->
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
Trial segmentation: when debugging multi-agent or long-running systems, break the execution trace into segments and analyze each independently. Shorter segments → cleaner causal attribution. Full traces cause spurious correlations that obscure root cause. One segment = one causal claim. <!-- Updated 2026-06-12: https://arxiv.org/pdf/2512.06749 -->
See: skills/debug/reference/debug-research.md (Parallel Debug Strategy).
</parallel_debug_strategy>

<agentic_debugging>
- Check whether bug was introduced by an AI edit: `git log --oneline -20`, then `git bisect`.
- AI edits tend to: drop early returns, misplace null checks, silently change API call signatures.
- Distinguish tool-call failure (environment/permissions) from logic failure (code): different fixes.
- Check `git status` / `git diff` for interrupted-state partial writes before assuming canonical version.
- Reduce to minimal reproduction BEFORE spawning agents. Agents given vague reproductions reproduce the wrong thing.
- Verify AI's understanding before accepting a fix: ask "What does this function currently do?" before applying a suggested change. Catches hallucinated APIs, misread variable names, and wrong architecture assumptions; catching these before the edit is faster than reverting after.
- **Rate-limit and timeout as dominant agentic failure modes**: in agentic systems, 429 (rate-limit) and ETIMEOUT account for a majority of production errors in team environments (per >50K sessions analyzed in 2025). Classify failure type first: transient (retry with exponential backoff) vs. permanent (abort, escalate), before investigating code logic. Automate retry handling for these two classes rather than debugging each instance manually. <!-- Updated 2026-06-29: https://institute.sfeir.com/en/claude-code/claude-code-advanced-best-practices/debugging/ (verified 2026-07-01) -->
- **Team debugging branch convention**: when multiple developers use Claude Code simultaneously on the same repo, create a dedicated branch per debugging session (e.g., `fix/issue-123-auth-timeout`) and scope Claude Code to relevant files only. Prevents file-write conflicts between concurrent sessions, makes the debugging trail reviewable, and produces a clean PR if the fix ships.
- **Trailing whitespace as a silent auth failure cause**: an estimated 23% of authentication errors trace back to a trailing space or newline in a copy-pasted API key/token, where the key looks correct on inspection but fails comparison. Before deep-diving auth logic, `.trim()` the credential or diff its raw byte length against the expected key length. <!-- Updated 2026-07-01: https://www.sitepoint.com/debugging-ai-claude-code-vs-traditional-methods/ -->
</agentic_debugging>

<persistent_truth_file>
Create `_meta/context/DEBUG.md` at session start. Update throughout. Claude reads it before each attempt.
Prevents circular re-investigation across context compression boundaries.

Template fields: Problem Statement · What We Know · Approaches Tried (with failure reason) · Current Hypothesis · Next Steps.
Full template: skills/debug/reference/debug-research.md (Persistent Investigation File).
</persistent_truth_file>

<on_complete>
agentdb write-end '{"skill":"debug","bug":"<description>","root_cause":"<what_broke>","fix":"<what_fixed>","test":"<regression_test_name>","learned":"<pattern_for_future>"}'

Always record debugging learnings. They prevent repeat investigation.
</on_complete>

</skill>
