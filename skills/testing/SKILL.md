---
name: testing
description: "Testing methodology and strategy. Tests prove behavior, not implementation. Triggers: test, tests, coverage, assertion, mock, fixture, spec, verify."
allowed-tools: Read, Bash, Grep, Glob
---

<skill id="testing">

<purpose>
Tests prove behavior, not implementation. A test that passes with buggy code is worse than no test.
Edge cases over happy paths. Boundary conditions reveal bugs; normal inputs rarely do.
If you can't explain what the test verifies, the test is worthless.
</purpose>

<prerequisite>
AgentDB read-start has run. Check past test failures—patterns repeat.
</prerequisite>

<reference>
Skill-specific: skills/testing/reference/testing-research.md
</reference>

<core_principles>
1. TEST REQUIREMENTS, NOT CODE: AI generates tests from code. This validates bugs. Test what SHOULD happen.
2. EDGE CASES FIRST: Empty, null, boundary, concurrent, error paths. Happy path is least valuable.
3. ASSERTION STRENGTH: Weak assertions (truthy, not-null) catch nothing. Assert specific values.
4. ONE BEHAVIOR PER TEST: Test names should read like specifications. If "and" appears, split.
5. REGRESSION OVER COVERAGE: One test that catches a real bug beats 10 tests that pad metrics.
</core_principles>

<!-- Updated 2026-04-27: https://medium.com/ngconf/create-reliable-unit-tests-with-claude-code-9147d050d557, https://code.claude.com/docs/en/best-practices -->
<naming_convention>
BDD format: GIVEN/WHEN/SHOULD. Reads as specification, not code description.

```javascript
// POOR: describes implementation
test('validateEmail regex check')

// GOOD: describes behavior
test('GIVEN an email without domain WHEN validated SHOULD return false')
test('GIVEN a valid email WHEN validated SHOULD return true')
```

If a test name can't be written in GIVEN/WHEN/SHOULD form, the test is ambiguous.
Also applies to test suites: describe() should be the subject, it()/test() should be the scenario.

**"Don't modify the tests" instruction**: When asking Claude to fix failing tests, include
"Do not modify the tests — fix the implementation to pass them." Without this, Claude takes
the fastest path to green: weakening assertions or skipping edge cases rather than fixing the bug.
</naming_convention>

<test_hierarchy>
1. Unit tests: isolated functions, fast, many.
2. Integration tests: component boundaries, medium speed, focused.
3. E2E tests: critical paths only, slow, few.

Invert the pyramid at your peril. More E2E = slower feedback = less testing.
</test_hierarchy>

<anti_patterns>
<block id="coverage_theater">High coverage, weak assertions. 100% coverage with .toBeTruthy() catches nothing.</block>
<block id="implementation_coupling">Test breaks when refactoring. Test behavior, not structure.</block>
<block id="happy_path_only">Normal inputs rarely fail. Test edges, nulls, boundaries, concurrent access.</block>
<block id="ai_test_trust">AI generates tests that validate bugs. Review AI tests for what they ACTUALLY assert.</block>
<block id="flaky_tolerance">Flaky test = broken test. Fix or delete. Never ignore.</block>
<!-- Updated 2026-04-07: https://www.ontestautomation.com/writing-tests-with-claude-code-part-1-initial-results/ -->
<block id="skip_or_only">Never use .skip() or .only() — Claude will rewrite tests to pass against buggy code rather than fix the bug. Disabled tests become permanent. Fix or delete.</block>
</anti_patterns>

<verification_gate>
<!-- Updated 2026-03-28: https://code.claude.com/docs/en/best-practices -->
Always provide verification. If you can't verify it, don't ship it.
AI writes tests prolifically — but tends to test where the code IS, not where it matters most.
Review AI-generated tests for: do they test the actual risk area, or just the happy path it already handles?
</verification_gate>

<jit_testing>
<!-- Updated 2026-04-25: https://www.infoq.com/news/2026/04/meta-jit-testing-ai-detection/ -->
From Meta: Just-in-Time (JiT) testing generates tests *during code review* instead of relying on static suites.
Result: **~4x bug detection improvement** in AI-assisted development (InfoQ, April 2026).
No maintenance burden (tests don't persist). Mutation-based fault injection.
Consider for high-churn code where traditional test suites rot faster than they help.
Also useful during refactoring: generate behavioral tests for the code being refactored *before* making changes,
run them after to confirm behavior preservation without a pre-existing test suite.
</jit_testing>

<!-- Updated 2026-03-30: Claude Code best practices, AI code review research -->
<golden_ratio_principle>
Test coverage follows diminishing returns past ~80%. Beyond that, invest in:
- Mutation testing (verify your tests actually catch real mutations)
- Property-based testing for complex logic (fast-check, hypothesis)
- Contract tests at service boundaries (Pact, schema mocks)

Coverage % is a vanity metric without mutation score.
</golden_ratio_principle>

<ai_generated_test_review>
When reviewing AI-generated tests, specifically check:
1. Does the assertion verify the RIGHT thing? (.toBe(true) catches nothing meaningful)
2. Is the test coupled to implementation? (mocking internals → brittle)
3. Is the test isolated? (shared state between tests → order-dependent failures)
4. Does it test requirements or code? (test what SHOULD happen, not what code does)

AI-generated tests frequently validate bugs because they're synthesized FROM the code.
Read them as if the implementation might be wrong — because it might be.

<!-- Updated 2026-04-10: https://code.claude.com/docs/en/best-practices, https://utofa.com/blogs/ai-code-review-2026-best-practices/ -->
**Pre-generation test descriptions**: When asking Claude to generate code, provide at minimum
the test case descriptions (inputs and expected outputs) BEFORE requesting implementation.
This forces behavioral specification first and prevents tautological tests that just validate
what the code does rather than what it should do. Example:
> "Write validateEmail. Test cases: user@example.com → true, invalid → false, user@.com → false.
> Write the tests first, then implement the function to pass them."

**40-70% of production code is now AI-generated** (industry estimate, 2026). The proportion
of tautological tests in codebases is rising proportionally. Manual review of AI-generated
tests for behavioral correctness is non-optional.
</ai_generated_test_review>

<!-- Updated 2026-04-02: https://code.claude.com/docs/en/best-practices, https://testdino.com/blog/claude-code-with-playwright/ -->
<multi_agent_test_patterns>
**Writer/Reviewer split**: Have one agent write tests, a separate agent write code to pass them.
This prevents the common failure where AI writes tests FROM the code (validating bugs, not behavior).
The test-writing agent must only see the SPECIFICATION, not the implementation.

**Parallel hypothesis testing**: When coverage gaps exist across multiple modules, spawn agents
per module boundary. Each agent tests its domain independently. Prevents agents from stepping
on each other's test state or sharing fixtures incorrectly.

**Test-before-code in agentic context**: When issuing a contract to a surgeon agent, include
acceptance criteria as executable test cases. The surgeon's done-when is tests passing, not
code written. This forces behavioral specification before implementation.

**Verification criteria = highest leverage**: Claude performs dramatically better when it can
verify its own work by running tests. Always give agents runnable verification — a test
suite they can execute — not just a written description of done.

<!-- Updated 2026-04-19: Anthropic Opus 4.7 migration guide -->
**Effort levels for test agents (Opus 4.7)**: Use `effort: high` when spawning test-generation agents.
Opus 4.7 at default effort under-generates edge cases. At `high`, it produces fuller coverage with
more boundary conditions. At `xhigh`, test generation is exhaustive — use for security-critical code.
Pair with "Report ALL issues" framing: avoid "be conservative" prompts that cause under-reporting.
Opus 4.7 has 11pp better recall on issues — don't filter it out at the prompt level.
</multi_agent_test_patterns>

<!-- Updated 2026-04-23: https://code.claude.com/docs/en/best-practices, https://www.tech-reader.blog/2026/04/the-secret-life-of-claude-code-testing.html -->
<behavior_vs_implementation>
AI tends to write tests that validate implementation details, not behavior. These break on refactoring.
Test WHAT the code does, not HOW it does it.

```javascript
// POOR: Tests implementation (breaks on refactor)
test('validateEmail uses regex pattern', () => {
  expect(validateEmail).toHaveBeenCalledWith(expect.stringMatching(/\w+@\w+/));
});

// GOOD: Tests behavior (survives refactor)
test('validateEmail rejects invalid formats', () => {
  expect(validateEmail('user@.com')).toBe(false);
  expect(validateEmail('user@example.com')).toBe(true);
  expect(validateEmail('invalid')).toBe(false);
});
```
</behavior_vs_implementation>

<!-- Updated 2026-04-23: https://code.claude.com/docs/en/best-practices (QA automation section) -->
<edge_case_discovery>
Claude's testing strength is edge case discovery, not boilerplate unit tests.
Prompt explicitly for edge cases rather than asking for generic coverage.

Effective prompt structure:
1. "What edge cases exist for [function]?"
2. Show 2–3 expected edge cases to anchor thinking.
3. "What boundary conditions or interaction effects might break this?"
4. "Generate N test cases covering these scenarios."

Example for validateEmail:
```
"Write tests covering:
- Invalid formats (missing @, missing domain, invalid chars)
- Boundary cases (empty string, very long email, null/undefined)
- Interaction effects (uppercase, spaces, international domains)
- Security cases (SQL injection payloads, newline injection)
Generate 15 cases that would catch a developer who forgot one category."
```
</edge_case_discovery>

<!-- Updated 2026-05-06: https://medium.com/@karkeralathesh/the-complete-guide-to-testing-claude-code-skills-with-the-skill-creator-1ae3821bd7b8 -->
<negative_case_testing>
Test what code should NOT do. In AI-assisted development, positive-case tests dominate and negative-case behavior is routinely untested.

Negative cases to add to every test suite:
- Rejection of out-of-scope inputs (tool/function declines gracefully, not crashes)
- Invalid type/shape returns an error, not a corrupted result
- Empty/null/undefined handled at boundary, not propagated
- Security inputs (injection payloads, oversized strings) rejected at entry, not silently processed

**The rejection quality test**: A function that correctly declines invalid input is more production-grade than one that accepts everything. Test this explicitly — it's not covered by happy-path suites.
</negative_case_testing>

<!-- Updated 2026-05-12: https://code.claude.com/docs/en/best-practices, https://testdino.com/blog/claude-code-with-playwright/ -->
<browser_verification>
Use browser automation (Playwright + MCP browser tools) to verify UI features before declaring done. Claude runs the browser, sees console errors, iterates until the feature works end-to-end. Not a substitute for unit tests — complements them by catching integration failures that unit tests can't.

Effective sequence: unit tests (fast feedback) → integration tests (component boundaries) → browser automation (real user path). Browser tests are slow — reserve for critical user-visible flows only.
</browser_verification>

<!-- Updated 2026-05-12: https://www.mindstudio.ai/blog/code-w-claude-2026-new-agent-features -->
<grader_pattern>
For complex features where "all tests pass" isn't sufficient: define a success rubric (expected behaviors, edge case handling, performance bounds) BEFORE writing tests or code. After implementation, spawn a grader agent in a fresh context — no knowledge of how the code was written — to evaluate output against the rubric.

Grader failure returns specific, addressable issues. Implementing agent takes another pass. This outer loop catches the "tautological test" failure mode (tests pass, rubric fails) by separating evaluation context from implementation context.
</grader_pattern>

<!-- Updated 2026-05-14: https://www.infoq.com/news/2026/04/claude-code-review/, https://www.coderabbit.ai/blog/claude-opus-4-7-for-ai-code-review -->
<native_code_review_stats>
Anthropic's Code Review feature (launched March 2026) integrates with GitHub and leaves inline comments automatically on PRs.
Production stats:
- Large PRs (>1000 lines): 84% get findings, avg 7.5 issues flagged
- Small PRs (<50 lines): 31% get findings, avg 0.5 issues
- Average review time: ~20 minutes. Average cost: $15–25/review (token-based)
- Focus: logical errors over style. Opus 4.7 has stronger cross-file reasoning for multi-module issues.

Best ROI: large PRs where human reviewers are most likely to miss cross-file interactions.
Use small PRs strategically to reduce both review time and cost.
</native_code_review_stats>

<on_complete>
agentdb write-end '{"skill":"testing","tests_added":<N>,"coverage_delta":"<+X%>","edge_cases":["<list>"],"assertions":"<strong|weak>"}'

Record what you tested and WHY. Prevent duplicate coverage.
</on_complete>

</skill>
