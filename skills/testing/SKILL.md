---
name: testing
description: "Testing methodology and strategy. Tests prove behavior, not implementation. Triggers: test, tests, coverage, assertion, mock, fixture, spec, verify."
allowed-tools: Read, Bash, Grep, Glob
---

<skill id="testing">

<on_start>
agentdb read-start — check past test failures, patterns repeat.
Load: skills/testing/reference/testing-research.md on demand.
</on_start>

## Core Laws (non-negotiable)

1. TEST REQUIREMENTS, NOT CODE. AI generates tests from code — this validates bugs. Test what SHOULD happen.
2. EDGE CASES FIRST. Empty, null, boundary, concurrent, error paths. Happy path is least valuable.
3. STRONG ASSERTIONS ONLY. `.toBeTruthy()` catches nothing. Assert specific values.
4. ONE BEHAVIOR PER TEST. If "and" appears in the test name, split the test.
5. REGRESSION OVER COVERAGE. One test that catches a real bug beats 10 that pad metrics.
6. NEVER use `.skip()` or `.only()` — Claude rewrites tests to pass buggy code rather than fix the bug.

---

## Flow

### Step 1 — Specify before writing
1. Write test case descriptions (inputs + expected outputs) BEFORE requesting implementation.
2. For AI-generated code: provide spec, then ask for tests, then ask for implementation.
   (gate: spec exists as comments or descriptions before any test code is written)
3. If a test name cannot be written in GIVEN/WHEN/SHOULD form, the test is ambiguous — clarify first.

### Step 2 — Prioritize by risk
Order of testing priority:
1. Business logic (core correctness rules)
2. Error handling (what fails gracefully vs. crashes)
3. Boundary conditions (edges of valid input ranges)
4. State transitions (auth flows, multi-step workflows)
5. Integration points (external systems, DB, APIs)
6. Regression cases (every bug fix gets a test that would have caught it)

### Step 3 — Write edge cases explicitly
For every function, enumerate:
- Empty / null / undefined inputs
- Boundary values (0, -1, MAX_INT, empty string, oversized input)
- Invalid type/shape → error, not corrupted result
- Security inputs (injection payloads, newline injection) → rejected at entry
- Concurrent access or race conditions where applicable
(gate: minimum 3 edge cases per non-trivial function)

### Step 4 — Name tests as specifications
Format: `GIVEN <state> WHEN <action> SHOULD <expected>`
```
GOOD: test('GIVEN email without domain WHEN validated SHOULD return false')
POOR: test('validateEmail regex check')
```
Pattern for file/function naming: `test_{function}_{scenario}_{expected}`

### Step 5 — Layer by pyramid
1. Unit tests — isolated functions, fast, many. (primary layer)
2. Integration tests — component boundaries, DB/API calls, medium speed.
3. E2E / browser — critical user-visible flows only, slow, few.
(gate: E2E count stays low; flaky tests fixed or deleted immediately)

### Step 5b — Test signal flexibility
Any deterministic output Claude can read counts as a gate: test suite exit code, linter report, build failure, fixture diff, browser screenshot delta. Don't limit "testing" to unit test runners — if it produces a signal, it can gate a decision. <!-- Updated 2026-06-09: https://code.claude.com/docs/en/best-practices -->

### Step 6 — Review AI-generated tests
Before accepting any AI-generated test, verify:
1. Does the assertion verify the RIGHT thing? (not just `.toBe(true)`)
2. Is the test coupled to implementation? (mocks of internals → brittle)
3. Is state shared between tests? (order-dependent failures)
4. Does it test requirements or does it mirror code that may be buggy?
(gate: at least one negative/rejection case per test file)

### Step 7 — Multi-agent test patterns (tier 2+)
- **Writer/Reviewer split**: one agent writes tests (spec only, no implementation), separate agent writes code to pass them.
- **Parallel per module**: when coverage gaps span multiple modules, spawn one agent per module boundary.
- **Surgeon done-when**: acceptance criteria = runnable tests passing, not "code written."
- **Effort level**: use `effort: high` for test-generation agents; default under-generates edge cases.
- **BQ testing (agent output)**: AI agent output is non-deterministic — validate action patterns and behavioral invariants, not exact text. Test WHAT the agent did, not how it phrased it.
- **Subagent scope reviewer**: after implementation, spawn a reviewer agent to verify: every requirement is implemented, listed edge cases have tests, nothing outside task scope changed. <!-- Updated 2026-06-05: https://code.claude.com/docs/en/best-practices -->
- **Context-aware verification rigor**: solo dev → verify logic + edge cases; team → systematic peer review; production → mandatory gating tests. Match rigor to deployment stakes. <!-- Updated 2026-06-05: https://levelup.gitconnected.com/claude-code-best-practices-12-patterns-agentic-engineers-use-65264e3eb919 -->
- **Stop hook gates**: configure `Stop` hooks in `hooks/scripts/` to run tests/lint checks mechanically after each turn — moves quality gates from agent honor-system to enforcement (I0.15). <!-- Updated 2026-06-07: https://popularaitools.ai/blog/claude-code-workflow-patterns-agentic-guide-2026 -->
- **Five agentic workflow patterns** (match to test scope): sequential (one agent, ordered steps) · operator (supervisor routes to specialists) · split-and-merge (parallel execution + synthesis) · agent teams (specialist groups per module) · headless (no-UI CI-style automated). <!-- Updated 2026-06-08: https://www.mindstudio.ai/blog/claude-code-agentic-workflow-patterns -->

### Step 8 — Grader pattern (complex features)
1. Define success rubric (expected behaviors, edge handling, perf bounds) BEFORE tests or code.
2. After implementation, spawn a grader agent in fresh context (no knowledge of implementation).
3. Grader evaluates output against rubric. Failure → specific issues → surgeon takes another pass.
(gate: grader verdict is PASS before declaring done on complex features)

### Step 9 — JiT testing for high-churn code
Generate tests during code review, not into the static suite, when:
- Code changes faster than test suites can track
- Refactoring: generate behavioral tests BEFORE changes, run AFTER to confirm preservation
Meta 2026: JiT generates ~4x more bug-catching tests than static suite additions for AI-generated code.
(reference: testing-research.md § Just-in-Time Testing)

---

## Anti-Patterns (block on sight)

| Pattern | Block |
|---|---|
| `coverage_theater` | High coverage, weak assertions. 100% + `.toBeTruthy()` = nothing caught. |
| `implementation_coupling` | Tests break on refactor. Test behavior, not structure. |
| `happy_path_only` | Normal inputs rarely fail. Test edges, nulls, boundaries, concurrent access. |
| `ai_test_trust` | AI synthesizes tests FROM code → validates bugs. Review what assertions ACTUALLY check. |
| `flaky_tolerance` | Flaky test = broken test. Fix or delete. Never ignore. |
| `skip_or_only` | `.skip()` / `.only()` become permanent. Fix or delete. |
| `print_over_assert` | Print statements are not assertions. Require formal `expect`/`assert` calls. |
| `snapshot_relaxation` | Never update snapshots to make failing tests pass. Snapshots are the source of truth — if they fail, the code changed unexpectedly. Fix the code, not the snapshot. <!-- Updated 2026-06-10: https://smartscope.blog/en/generative-ai/claude/claude-code-best-practices-advanced-2026/ --> |

---

## Verification Gate

Always provide runnable verification. If you can't verify it, don't ship it.
AI writes tests prolifically — review for: does it test the actual risk area, or just the happy path it already handles?

When reviewing AI-generated code in 2026 (40–70% of production is AI-generated), check for **intent drift**: AI correctly implements what it inferred from the prompt, not what was actually needed. Verify against the original spec, not just the code structure.

---

<on_complete>
agentdb write-end '{"skill":"testing","tests_added":<N>,"coverage_delta":"<+X%>","edge_cases":["<list>"],"assertions":"<strong|weak>"}'

Record what you tested and WHY. Prevent duplicate coverage.
</on_complete>

</skill>
