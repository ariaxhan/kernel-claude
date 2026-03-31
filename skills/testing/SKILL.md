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
</anti_patterns>

<jit_testing>
From Meta (Feb 2026): tests generated on-the-fly before code lands.
No maintenance burden (tests don't persist). Mutation-based fault injection.
Consider for high-churn code where traditional test suites rot faster than they help.
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
</ai_generated_test_review>

<on_complete>
agentdb write-end '{"skill":"testing","tests_added":<N>,"coverage_delta":"<+X%>","edge_cases":["<list>"],"assertions":"<strong|weak>"}'

Record what you tested and WHY. Prevent duplicate coverage.
</on_complete>

</skill>
