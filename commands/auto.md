---
name: kernel:auto
description: "Autonomous execution loop. Tests first, iterate until green. No hand-holding. Triggers: auto, ralph, loop, autonomous, ship it."
user-invocable: true
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Task, WebSearch, WebFetch
---

# AUTONOMOUS EXECUTION

```yaml
mode: loop until verified complete
trigger: ralph, auto, "just do it", "ship it"
flow: RESEARCH → TESTS → IMPLEMENT → VERIFY → (loop if red) → SHIP

when_to_use:
  - user trusts iteration
  - clear success criteria
  - familiar domain

when_not_to_use:
  - user wants visibility into each step
  - unfamiliar domain
  - high-risk/irreversible changes
```

---

## PHASE 0: SETUP

```yaml
mandatory:
  do: agentdb read-start
  extract:
    - prior_failures: don't repeat
    - testing_patterns: follow existing
    - active_contract: resume or close

classify:
  goal: what success looks like
  type: bug|feature|refactor
  tier: 1|2|3
  exit_criteria: must be testable
```

---

## PHASE 1: RESEARCH

```yaml
search_order:  # anti-patterns FIRST
  1: "{tech} not working", "{tech} gotchas"
  2: "{tech} best practices 2025 2026"
  3: official docs → github issues → stack overflow

output: _meta/research/{topic}.md

extract:
  - anti_patterns: 3-5 with fixes
  - proven_solution: package + stats
  - testing_approach: for this domain

parallel: spawn researcher agent if complex
```

---

## PHASE 2: TESTS FIRST

```yaml
rule: tests BEFORE implementation, no exceptions

steps:
  2a_identify:
    format: |
      TESTS NEEDED:
      - [ ] {behavior} → {expected}
      - [ ] {edge_case} → {expected}
      - [ ] {error_case} → {expected}

  2b_write_failing:
    do: write tests that fail
    verify: npm test must FAIL (red)
    if_passes: tests are wrong, testing nothing

  2c_philosophy:
    mock_only:
      - external HTTP APIs (nock/msw)
      - third-party services (Stripe, Auth0)
      - time-sensitive operations
    never_mock:
      - internal functions
      - database (use test container or in-memory)
      - file system (use tmp dirs)
      - your own services

principles:
  tests_first: code-then-tests validates bugs
  mock_boundaries_only: NOT internal functions
  real_deps_preferred: test containers > mocks
  edge_cases_first: null, empty, boundary, concurrent, timeout
  strong_assertions: specific values, not truthy/exists
  graceful_fallbacks: test primary, fallback, AND degraded mode
```

---

## PHASE 3: IMPLEMENT (loop)

```yaml
loop:
  3a: write minimal code to pass tests
  3b: run tests (npm test --coverage)
  3c: evaluate:
    all_pass: → phase 4
    failing: → fix implementation (NOT tests)
    flaky: → fix test (async/race issue)
    coverage_low: → add edge case tests
  3d: repeat until green + coverage >= 80%

max_iterations: 5
on_max_exceeded: STOP, report blockers to user
```

---

## PHASE 4: VERIFY

```yaml
checks:
  build: npm run build
  lint: npm run lint
  test: npm test --coverage
  security: npm audit --audit-level=high
  diff: git diff --stat

on_any_fail: back to phase 3
```

---

## PHASE 5: SHIP

```yaml
steps:
  commit: git add -A && git commit -m "{type}({scope}): {desc}"
  push: git push -u origin HEAD
  report:
    goal: what was done
    tests: N added, X% coverage
    files: list
    iterations: N
    branch: name
  learn:
    do: agentdb learn pattern "what worked"
    then: agentdb write-end '{"command":"auto","iterations":N,"tests":N,"coverage":"X%","shipped":true}'
```

---

## PARALLEL EXECUTION (tier 2+)

```yaml
spawn_order:
  1: researcher → _meta/research/{topic}.md
  2: test_writer → failing tests (parallel with 1)
  3: wait for 1,2
  4: surgeon → implement to pass tests
  5: adversary → find edge cases, add tests
  6: validator → full verification

rule: orchestrator reads AgentDB, does NOT write code
```

---

## LOOP CONTROL

```yaml
continue_if:
  - tests failing but progress made
  - coverage increasing
  - new edge cases discovered

stop_if:
  - 5 iterations without progress
  - blocked on external dependency
  - scope creep detected
  - security concern found

escalate_if:
  - architectural decision needed
  - trade-off requires human judgment
  - risk exceeds autonomous threshold
```

---

## GRACEFUL FALLBACKS

```yaml
pattern: |
  try primary
  catch → try fallback
  catch → return cached/default

test_all_three:
  - primary success
  - fallback success
  - degraded mode

example: |
  async function fetch() {
    try { return await primary.fetch() }
    catch {
      try { return await fallback.fetch() }
      catch { return cache.get() ?? DEFAULT }
    }
  }
```

---

## ANTI-PATTERNS

```yaml
dont:
  code_then_tests: validates bugs
  mock_everything: mock boundaries only
  test_implementation: test behavior
  happy_path_only: edge cases first
  weak_assertions: specific values
  loop_forever: max 5, then report
  skip_research: prevents 80% of bugs

do:
  tests_first: always
  mock_boundaries: external APIs, DBs
  test_behavior: at public interface
  edge_cases: null, empty, boundary, error
  strong_assertions: specific values
  max_iterations: 5 then stop
  research_first: anti-patterns before solutions
```

---

## QUICK START

```yaml
example:
  user: "ralph add user authentication"

  agent:
    1: agentdb read-start
    2: research auth anti-patterns, proven packages
    3: write failing tests (login, logout, session, invalid creds, expired token)
    4: implement minimal auth to pass tests
    5: loop until green + 80% coverage
    6: validate (build, lint, test, security)
    7: ship (commit, push)
    8: agentdb write-end

  user_interaction: 0 (unless blocked)
```
