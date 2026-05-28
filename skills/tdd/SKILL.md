---
name: tdd
description: "Test-Driven Development workflow. Tests BEFORE code. Red-green-refactor cycle. Triggers: tdd, test-first, test-driven, red-green, coverage."
allowed-tools: Read, Bash, Write, Edit, Grep, Glob
---

<skill id="tdd">

<prerequisite>
1. agentdb read-start — check for existing test patterns in codebase.
2. Identify test framework in use (Jest, Vitest, pytest).
3. Check _meta/research/ for prior TDD work.
</prerequisite>

<reference>
skills/tdd/reference/tdd-research.md — mocking patterns, framework examples, coverage config, organization strategies
</reference>

<workflow>
1. Write user journey: "As a [role], I want [action], so that [benefit]"
2. Generate test cases from journey (happy path, edge cases, errors)
3. Write tests first.
   (gate: `npm test` / `pytest` exits non-zero — tests must FAIL red before proceeding)
4. Implement MINIMAL code to pass — no anticipatory features.
   (gate: `npm test` / `pytest` exits zero — all tests GREEN)
5. Refactor while keeping tests green.
   (gate: tests still pass after every change; file ends same length or shorter)
6. Verify coverage >= 80% branches/functions/lines/statements.
   (gate: coverage report shows >= 80% on all axes)
</workflow>

<core_principles>
1. TESTS DEFINE BEHAVIOR: Write tests from requirements, not implementation. Test what SHOULD happen.
2. MINIMAL CODE: Write only enough code to make the test pass. No anticipatory features.
3. REFACTOR WHILE GREEN: Clean up only when tests pass. Never refactor red.
4. 80% COVERAGE MINIMUM: Unit + integration + E2E. All edge cases covered.
5. ONE ASSERT PER TEST: Test names are specifications. Split if "and" appears.
</core_principles>

<anti_patterns>
<block id="code_before_test">Writing code then tests validates bugs. Test first or not at all.</block>
<block id="testing_implementation">Test behavior, not structure. Refactoring should not break tests.</block>
<block id="multiple_asserts">One behavior per test. If you need "and", split the test.</block>
<block id="brittle_selectors">Use semantic selectors ([data-testid], role), not CSS classes.</block>
<block id="test_dependency">Each test must be independent. No shared state between tests.</block>
</anti_patterns>

<on_complete>
agentdb write-end '{"skill":"tdd","tests_written":<N>,"coverage":"<X%>","cycle":"red->green->refactor","failures_caught":["<list>"]}'

Record test count, coverage achieved, and what edge cases the tests catch.
</on_complete>

</skill>
