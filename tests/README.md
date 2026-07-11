# KERNEL Test Suite

```yaml
runner: ./tests/run-tests.sh
deps: sqlite3, bash
framework: pure bash (no bats required)
principle: real deps, minimal mocks, edge cases first
```

## Run Tests

```bash
# All suites
./tests/run-tests.sh

# Specific suite
./tests/run-tests.sh agentdb
./tests/run-tests.sh security
./tests/run-tests.sh hooks
```

## Test Suites

# 282 tests total across the suites below.
```yaml
suites:
  agentdb:
    count: 17
    tests:
      - init, idempotent, learn, write-end, contract, verdict
      - read-start, status, prune, query, recent, error

  edge:
    count: 4
    tests:
      - SQL injection prevention
      - unicode content
      - long content
      - empty db auto-init

  hooks:
    count: 12
    tests:
      - session-start/session-end lifecycle, tier validation
      - detect-secrets clean file, hooks.json structure
      - schema parity (inline vs schema.sql), migration applies
      - agentdb emit records/validates events

  security:
    count: 6
    tests:
      - no hardcoded secrets
      - scripts have set -e
      - no eval usage
      - JSON with quotes, newlines, shell expansion

  observe:
    count: 4
    tests:
      - status healthy, export, timestamps
      - DB size reasonable

  metrics:
    count: 5
    tests:
      - metrics runs, custom days, shows learnings
      - metrics skill registered, has frontmatter

  verify:
    count: 7
    tests:
      # v8: commands layer is gone. "commands have frontmatter" now asserts
      # the commands dir does NOT exist and plugin.json registers no commands.
      - no commands dir; skills + agents have frontmatter
      - hooks.json valid
      - ingest has research step, forge has loop control
      - structured format (XML/YAML), token budgets

  manifest:
    count: 27
    tests:
      # v8 YAML manifest runtime + guard-context hook + migration guards
      - schemas parse; handoff/checkpoint/retrospective examples validate
      - validate rejects bad schema/policy/selector
      - latest, divergence, compile (receipt fields, budget, selectors)
      - guard-context: sealed blocks/allows, bounded ledgers, fails closed
      - migration: every command has a destination, no live command refs,
        side-effecting skills not ambient, taxonomy blocks parse

  test_gate:
    count: 11
    tests:
      - test-gate detects/passes/fails, red recovers, honors override
      - autopush postcommit disabled, install opt-in, sweep red gate
      - session-end runs gate, session-start surfaces red, pre-compact gate
```

## Adding Tests

```bash
# Test function naming
test_{component}_{scenario}() {
  # setup
  agentdb init >/dev/null

  # action
  local output
  output=$(agentdb learn pattern "test" 2>&1)

  # assert
  assert_contains "$output" "Learned"
}

# Register in run_test_suite
run_test "description" test_function_name
```

## Assertions

```yaml
available:
  assert_equals: expected actual "message"
  assert_contains: haystack needle "message"
  assert_file_exists: path "message"
  assert_exit_code: expected actual "message"
```

## Principles

```yaml
no_mocking:
  - use real sqlite3
  - use real file system (temp dirs)
  - use real hook scripts

edge_cases_first:
  - SQL injection
  - unicode, special chars
  - empty/null inputs
  - resource limits

isolation:
  - each test gets fresh temp dir
  - cleanup after every test
  - no shared state
```
