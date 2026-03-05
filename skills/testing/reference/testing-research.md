# Testing Reference: Research & Best Practices

Reference for test strategy, AI-generated test pitfalls, and verification methodology.
Read on demand. Not auto-loaded.

## Sources

CodeRabbit State of AI Code Generation (2025), Qodo State of AI Code Quality (2025),
Parasoft AI testing research (2025), foojay.io AI-driven testing best practices,
World Quality Report 2025-26, DORA Impact of Generative AI (2025), Microsoft QA
engineering prompting guide (2026), Medium/HackerNoon AI test quality analyses,
Meta JiT Testing (Feb 11, 2026), Qodo 2.0 (Feb 4, 2026), State of Testing 2026
(PractiTest Feb 2026), Test Pyramid 2.0 (Frontiers in AI), arXiv 2602.07900
Agent Test Generation (Feb 2026).

---

## The AI Testing Crisis

AI generates tests that look correct but verify nothing meaningful.

Qodo: only 27% of developers not using AI for tests are confident in their suite.
With AI testing, confidence jumps to 61%, but this confidence is often misplaced.

Parasoft (2025): over 50% of AI-generated code samples contain logical or security
flaws even when code "looks correct on the surface."

IBM study: developers tossed 70% of AI-generated tests because they felt "robotic"
with no flow, no intent, no design thinking.

World Quality Report 2025-26: 50% of QA leaders cite "maintenance burden and flaky
scripts" as top challenge with AI test automation.

The core problem: AI generates tests from code, not from requirements. It tests
what the code DOES, not what it SHOULD do. If the code has a bug, the test
validates the bug.

---

## Just-in-Time (JiT) Testing (Meta, Feb 2026)

A fundamentally new approach from Meta:
- Tests generated on-the-fly by LLMs before code lands in production.
- No maintenance required (tests don't persist in codebase).
- Mutation-based: introduces deliberate faults, generates tests to catch them.
- Addresses "agentic development dramatically increases pace of code change."

---

## Test Writing Paradox (arXiv Feb 2026)

Striking finding from arXiv 2602.07900:
- Claude Opus 4.5 writes tests in 83% of tasks (74.4% resolution)
- GPT-5.2 writes tests in 0.6% of tasks (71.8% resolution)
- Only 2.6 percentage point difference in success rate

Test volume does NOT correlate with task success.
"Value-revealing prints consistently outnumber assertions across all models."

---

## The 8 AI Test Anti-Patterns

### 1. Happy Path Only
AI tests the basic success case. Nulls, errors, boundaries, concurrent access
are ignored unless explicitly requested.
Fix: for every test, ask "what's the sad path?" Test failure modes first.

### 2. Weak Assertions
assertNotNull(result) proves the result exists, not that it's correct.
assertTrue(true) is literally useless. assertEquals on the wrong field.
Fix: assert specific values, specific fields, specific state changes.
"What would this assertion catch if the code were wrong?"

### 3. Mock Overuse
AI generates verbose mocks that lock onto implementation details. When you
refactor internals, tests break even though behavior is unchanged.
Studies: LLMs botch mocks 25% of the time, creating integration-test-shaped
unit tests that hit live endpoints or depend on execution order.
Fix: mock at boundaries (external services, databases), not internal functions.
Test behavior at the public interface, not implementation details.

### 4. Implementation Testing (Not Behavior Testing)
AI tests that function X calls function Y with parameter Z. This tests HOW
the code works, not WHAT it does. Any refactor breaks the test.
Fix: test inputs and outputs at the public API boundary. "Given this input,
I expect this output." Implementation is free to change.

### 5. Hallucinated API Calls
AI generates tests referencing functions, methods, or endpoints that don't
exist. The test fails on import/compile, not on logic.
Fix: run every generated test immediately. If it doesn't compile, discard it.

### 6. Outdated Patterns
AI defaults to older framework versions. Appium 2 syntax when Appium 3 is
current. Old Jest patterns. Deprecated assertion libraries.
Fix: specify framework version in test generation prompts. Review imports.

### 7. Flaky Async Tests
AI generates timing-dependent tests for async code. Sometimes pass, sometimes
fail. Thread races, unresolved promises, missing awaits.
Fix: use deterministic async patterns (await, test utilities like waitFor).
Never rely on setTimeout or sleep in tests.

### 8. Missing Edge Cases
AI's biggest blind spot. It doesn't test: empty strings, zero-length arrays,
MAX_INT, negative numbers, unicode, concurrent access, timeout scenarios,
malformed input, missing required fields.
Fix: explicit edge case list for every function. Minimum 3 edge cases per test.

### 9. Print-Over-Assert (NEW 2026)
Agents default to print statements over formal assertions. Only 35-43% are
exact-value checks. Relational/range constraints in single digits.
Fix: Require formal assertions. Suppressing tests reduced tokens 49% with
only 2.6% success drop - focus on quality over quantity.

---

## The Test Pyramid (Still Valid, Despite AI)

Unit tests: fast, isolated, test one function. Bulk of your suite.
Integration tests: test boundaries between components. Database queries,
API calls, service interactions.
E2E tests: test critical user flows. Expensive, slow, few of these.

AI tends to generate unit tests that are actually integration tests (because
they don't mock properly) and E2E tests that are actually smoke tests (because
they only check happy path). Enforce the pyramid consciously.

---

## What to Test (Priority Order)

1. Business logic: the core rules that define correct behavior.
2. Error handling: what happens when things go wrong.
3. Boundary conditions: edges of valid input ranges.
4. State transitions: from one state to another (auth, workflows).
5. Integration points: where your code meets external systems.
6. Regression cases: every bug fix gets a test that would have caught it.

What NOT to test (waste of tokens):
- Getters/setters with no logic
- Framework internals (React renders, Express routing)
- Third-party library behavior (that's their job)
- Implementation details that may change

---

## Test Naming Convention

test_{function}_{scenario}_{expected_result}

Examples:
- test_calculateTax_negativeIncome_returnsZero
- test_fetchUser_invalidId_throws404
- test_parseDate_emptyString_returnsNull

The name IS the specification. If you can't name it clearly, you don't
understand what you're testing.

---

## KERNEL Integration

- Adversary agent: uses this reference to evaluate surgeon's tests.
  "Are assertions specific? Are edge cases covered? Are mocks appropriate?"
- Validator agent: runs test suite as pre-commit gate. No exceptions.
- Surgeon agent: writes tests alongside implementation. Never after.
  Bug fixes MUST include regression test. Feature code MUST include
  at least happy path + 3 edge cases.
- Every test must be independently runnable. No order dependence.
- **2026 Context Priority**: Context gaps cited MORE OFTEN than hallucinations
  (65% vs lower). Missing context is the root cause; hallucinations are symptom.
- **Self-healing tests**: 95% maintenance reduction claimed, but caution:
  may mask genuine product bugs. Use with transparent logging.