---
name: tdd
description: "Test-Driven Development workflow. Tests BEFORE code. Red-green-refactor cycle. Triggers: tdd, test-first, test-driven, red-green, coverage."
allowed-tools: Read, Bash, Write, Edit, Grep, Glob
---

<skill id="tdd">

<purpose>
Tests first, code second. No exceptions. The test defines the contract; the code fulfills it.
Red (failing test) -> Green (minimal code to pass) -> Refactor (clean up while green).
If you write code before tests, you're testing your bugs, not your requirements.
</purpose>

<prerequisite>
AgentDB read-start has run. Check for existing test patterns in codebase.
Identify test framework in use (Jest, Vitest, pytest, etc.).
</prerequisite>

<reference>
Skill-specific: skills/tdd/reference/tdd-research.md
</reference>

<core_principles>
1. TESTS DEFINE BEHAVIOR: Write tests from requirements, not implementation. Test what SHOULD happen.
2. MINIMAL CODE: Write only enough code to make the test pass. No anticipatory features.
3. REFACTOR WHILE GREEN: Clean up only when tests pass. Never refactor red.
4. 80% COVERAGE MINIMUM: Unit + integration + E2E. All edge cases covered.
5. ONE ASSERT PER TEST: Test names are specifications. Split if "and" appears.
</core_principles>

<workflow>
1. Write user journey: "As a [role], I want [action], so that [benefit]"
2. Generate test cases from journey (happy path, edge cases, errors)
3. Run tests - they MUST fail (red)
4. Implement minimal code to pass
5. Run tests - they MUST pass (green)
6. Refactor while keeping tests green
7. Verify coverage >= 80%
</workflow>

<mocking_patterns>
<!-- Supabase -->
```typescript
jest.mock('@/lib/supabase', () => ({
  supabase: {
    from: jest.fn(() => ({
      select: jest.fn(() => ({
        eq: jest.fn(() => Promise.resolve({
          data: [{ id: 1, name: 'Test' }],
          error: null
        }))
      }))
    }))
  }
}))
```

<!-- Redis -->
```typescript
jest.mock('@/lib/redis', () => ({
  searchByVector: jest.fn(() => Promise.resolve([
    { slug: 'test', similarity_score: 0.95 }
  ])),
  checkHealth: jest.fn(() => Promise.resolve({ connected: true }))
}))
```

<!-- OpenAI -->
```typescript
jest.mock('@/lib/openai', () => ({
  generateEmbedding: jest.fn(() => Promise.resolve(
    new Array(1536).fill(0.1)
  ))
}))
```
</mocking_patterns>

<test_organization>
```
src/
  components/
    Button/
      Button.tsx
      Button.test.tsx      # Unit tests colocated
  app/
    api/
      users/
        route.ts
        route.test.ts      # Integration tests colocated
e2e/
  auth.spec.ts             # E2E tests separate
  checkout.spec.ts
```
</test_organization>

<anti_patterns>
<block id="code_before_test">Writing code then tests validates bugs. Test first or not at all.</block>
<block id="testing_implementation">Test behavior, not structure. Refactoring should not break tests.</block>
<block id="multiple_asserts">One behavior per test. If you need "and", split the test.</block>
<block id="brittle_selectors">Use semantic selectors ([data-testid], role), not CSS classes.</block>
<block id="test_dependency">Each test must be independent. No shared state between tests.</block>
</anti_patterns>

<coverage_config>
```json
{
  "jest": {
    "coverageThreshold": {
      "global": {
        "branches": 80,
        "functions": 80,
        "lines": 80,
        "statements": 80
      }
    }
  }
}
```
</coverage_config>

<on_complete>
agentdb write-end '{"skill":"tdd","tests_written":<N>,"coverage":"<X%>","cycle":"red->green->refactor","failures_caught":["<list>"]}'

Record test count, coverage achieved, and what edge cases the tests catch.
</on_complete>

</skill>
