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
    count: 7
    tests:
      - session-start output, agent file creation
      - detect-secrets clean file
      - hooks.json structure
      - workflow presence, testing philosophy

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

  verify:
    count: 7
    tests:
      - frontmatter in commands, skills, agents
      - hooks.json valid
      - ingest has research, auto has loop
      - structured format (XML/YAML)
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
