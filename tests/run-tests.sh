#!/bin/bash
# KERNEL Test Runner
# Real deps, minimal mocking, edge cases first
#
# Usage: ./tests/run-tests.sh [test-file]
# Example: ./tests/run-tests.sh agentdb

set -u  # Don't use -e, we handle errors manually

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(dirname "$SCRIPT_DIR")"
TEST_RESULTS=()
PASS_COUNT=0
FAIL_COUNT=0

# Colors (if terminal supports)
if [ -t 1 ]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  NC='\033[0m'
else
  RED='' GREEN='' YELLOW='' NC=''
fi

# === Test Framework ===

setup_test_env() {
  export TEST_DIR=$(mktemp -d)
  export TEST_PROJECT="$TEST_DIR/test-project"
  mkdir -p "$TEST_PROJECT/_meta/agentdb"
  mkdir -p "$TEST_PROJECT/.claude"
  cd "$TEST_PROJECT"

  # Make agentdb available
  export PATH="$PLUGIN_ROOT/orchestration/agentdb:$PATH"
  export CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT"
  export CLAUDE_PROJECT_ROOT="$TEST_PROJECT"
}

teardown_test_env() {
  cd /
  rm -rf "$TEST_DIR" 2>/dev/null || true
}

assert_equals() {
  local expected="$1"
  local actual="$2"
  local msg="${3:-assertion failed}"

  if [ "$expected" = "$actual" ]; then
    return 0
  else
    echo "  FAIL: $msg"
    echo "    expected: $expected"
    echo "    actual:   $actual"
    return 1
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local msg="${3:-should contain '$needle'}"

  if [[ "$haystack" == *"$needle"* ]]; then
    return 0
  else
    echo "  FAIL: $msg"
    echo "    looking for: $needle"
    echo "    in: $haystack"
    return 1
  fi
}

assert_file_exists() {
  local file="$1"
  local msg="${2:-file should exist: $file}"

  if [ -f "$file" ]; then
    return 0
  else
    echo "  FAIL: $msg"
    return 1
  fi
}

assert_exit_code() {
  local expected="$1"
  local actual="$2"
  local msg="${3:-exit code mismatch}"

  if [ "$expected" -eq "$actual" ]; then
    return 0
  else
    echo "  FAIL: $msg (expected $expected, got $actual)"
    return 1
  fi
}

run_test() {
  local name="$1"
  local fn="$2"

  echo -n "  $name... "

  setup_test_env

  local output
  local exit_code=0
  output=$($fn 2>&1) || exit_code=$?

  teardown_test_env

  if [ $exit_code -eq 0 ]; then
    echo -e "${GREEN}PASS${NC}"
    ((PASS_COUNT++))
  else
    echo -e "${RED}FAIL${NC}"
    echo "$output" | sed 's/^/    /'
    ((FAIL_COUNT++))
  fi
}

# === AgentDB Tests ===

test_agentdb_init() {
  agentdb init >/dev/null
  assert_file_exists "$TEST_PROJECT/_meta/agentdb/agent.db"
}

test_agentdb_init_idempotent() {
  agentdb init >/dev/null
  local output
  output=$(agentdb init)
  assert_contains "$output" "DB exists"
}

test_agentdb_learn_failure() {
  agentdb init >/dev/null
  local output
  output=$(agentdb learn failure "test failure" "evidence here")
  assert_contains "$output" "Learned"
  assert_contains "$output" "failure"
}

test_agentdb_learn_pattern() {
  agentdb init >/dev/null
  agentdb learn pattern "use YAML" "cleaner parsing" >/dev/null
  local output
  output=$(agentdb read-start)
  assert_contains "$output" "use YAML"
}

test_agentdb_learn_requires_type() {
  agentdb init >/dev/null
  local exit_code=0
  agentdb learn 2>/dev/null || exit_code=$?
  assert_exit_code 1 "$exit_code" "should fail without type"
}

test_agentdb_write_end() {
  agentdb init >/dev/null
  local output
  output=$(agentdb write-end '{"did":"test","learned":["thing"]}')
  assert_contains "$output" "Checkpoint"
}

test_agentdb_write_end_requires_json() {
  agentdb init >/dev/null
  local exit_code=0
  agentdb write-end 2>/dev/null || exit_code=$?
  assert_exit_code 1 "$exit_code" "should fail without json"
}

test_agentdb_contract() {
  agentdb init >/dev/null
  local output
  output=$(agentdb contract '{"goal":"test","files":["a.ts"],"tier":1}')
  assert_contains "$output" "Contract"
  assert_contains "$output" "CR-"
}

test_agentdb_verdict_pass() {
  agentdb init >/dev/null
  local output
  output=$(agentdb verdict pass "all tests green")
  assert_contains "$output" "Verdict: pass"
}

test_agentdb_verdict_fail() {
  agentdb init >/dev/null
  local output
  output=$(agentdb verdict fail "3 tests red")
  assert_contains "$output" "Verdict: fail"
}

test_agentdb_read_start_empty() {
  agentdb init >/dev/null
  local output
  output=$(agentdb read-start)
  assert_contains "$output" "AgentDB Context"
  assert_contains "$output" "Recent Failures"
  assert_contains "$output" "Active Patterns"
}

test_agentdb_read_start_with_data() {
  agentdb init >/dev/null
  agentdb learn failure "SQL injection in input" "found by scanner" >/dev/null
  agentdb learn pattern "validate all inputs" "security best practice" >/dev/null
  local output
  output=$(agentdb read-start)
  assert_contains "$output" "SQL injection"
  assert_contains "$output" "validate all inputs"
}

test_agentdb_status() {
  agentdb init >/dev/null
  agentdb learn pattern "test" >/dev/null
  agentdb write-end '{"did":"test"}' >/dev/null
  local output
  output=$(agentdb status)
  assert_contains "$output" "learnings:"
  assert_contains "$output" "checkpoints:"
}

test_agentdb_prune() {
  agentdb init >/dev/null
  # Create 15 checkpoints
  for i in {1..15}; do
    agentdb write-end "{\"n\":$i}" >/dev/null
  done
  # Prune to 5
  local output
  output=$(agentdb prune 5)
  assert_contains "$output" "Pruned 10"
  assert_contains "$output" "Kept 5"
}

test_agentdb_query() {
  agentdb init >/dev/null
  agentdb learn pattern "test query" >/dev/null
  local output
  output=$(agentdb query "SELECT COUNT(*) FROM learnings;")
  assert_contains "$output" "1"
}

test_agentdb_recent() {
  agentdb init >/dev/null
  agentdb write-end '{"test":"recent1"}' >/dev/null
  agentdb write-end '{"test":"recent2"}' >/dev/null
  local output
  output=$(agentdb recent 2)
  assert_contains "$output" "recent1"
  assert_contains "$output" "recent2"
}

test_agentdb_error() {
  agentdb init >/dev/null
  agentdb error "Edit" "file not found" "src/app.ts" >/dev/null
  local output
  output=$(agentdb read-start)
  assert_contains "$output" "Edit"
  assert_contains "$output" "file not found"
}

# === Edge Case Tests ===

test_agentdb_special_chars_in_insight() {
  agentdb init >/dev/null
  # Test SQL injection attempt
  agentdb learn pattern "test'; DROP TABLE learnings;--" "evidence" >/dev/null
  local count
  count=$(agentdb query "SELECT COUNT(*) FROM learnings;" | tail -1 | tr -d ' ')
  assert_equals "1" "$count" "table should still exist"
}

test_agentdb_empty_db_read_start() {
  # Don't init, just run read-start (should auto-init)
  local output
  output=$(agentdb read-start)
  assert_contains "$output" "AgentDB Context"
}

test_agentdb_unicode() {
  agentdb init >/dev/null
  agentdb learn pattern "使用中文测试" "证据" >/dev/null
  local output
  output=$(agentdb read-start)
  assert_contains "$output" "使用中文测试"
}

test_agentdb_long_content() {
  agentdb init >/dev/null
  local long_content
  long_content=$(printf 'x%.0s' {1..1000})
  agentdb learn pattern "$long_content" >/dev/null
  local output
  output=$(agentdb read-start)
  assert_contains "$output" "xxxx"
}

# === Hook Tests ===

test_session_start_outputs_kernel() {
  local output
  output=$("$PLUGIN_ROOT/hooks/scripts/session-start.sh" 2>&1)
  assert_contains "$output" "# KERNEL"
  assert_contains "$output" "AgentDB"
}

test_session_start_creates_agent_file() {
  "$PLUGIN_ROOT/hooks/scripts/session-start.sh" >/dev/null 2>&1
  local agent_files
  agent_files=$(ls "$TEST_PROJECT/_meta/agents/"*.json 2>/dev/null | wc -l)
  [ "$agent_files" -gt 0 ] || { echo "FAIL: no agent file created"; return 1; }
}

test_detect_secrets_clean() {
  # Create a clean file
  echo "const x = 123;" > "$TEST_PROJECT/test.ts"
  local exit_code=0
  "$PLUGIN_ROOT/hooks/scripts/detect-secrets.sh" "$TEST_PROJECT/test.ts" >/dev/null 2>&1 || exit_code=$?
  # Should pass (0) for clean file
  assert_exit_code 0 "$exit_code" "clean file should pass"
}

# === Security Tests ===

test_no_hardcoded_secrets_in_plugin() {
  local secrets_found=0

  # Check for common secret patterns
  if grep -rE "(password|secret|api_key|token)\s*=\s*['\"][^'\"]+['\"]" "$PLUGIN_ROOT" \
      --include="*.sh" --include="*.md" 2>/dev/null | grep -v "test" | grep -v "example" | grep -v "#"; then
    secrets_found=1
  fi

  assert_exit_code 0 "$secrets_found" "no hardcoded secrets should exist"
}

test_scripts_have_set_e() {
  local missing=0
  # Only check scripts that should fail-fast
  # Hook scripts (guard-*, detect-*, auto-approve-*) intentionally control exit codes
  local require_set_e=(
    "session-start.sh"
    "session-end.sh"
    "pre-compact-commit.sh"
  )
  for script_name in "${require_set_e[@]}"; do
    local script="$PLUGIN_ROOT/hooks/scripts/$script_name"
    if [ -f "$script" ] && ! grep -q "set -e" "$script" 2>/dev/null; then
      echo "  Missing 'set -e' in: $script"
      missing=1
    fi
  done
  assert_exit_code 0 "$missing" "lifecycle scripts should have set -e"
}

test_no_eval_usage() {
  local eval_found=0
  if grep -rE "^\s*eval\s+" "$PLUGIN_ROOT/hooks/scripts/" 2>/dev/null; then
    eval_found=1
  fi
  assert_exit_code 0 "$eval_found" "no eval usage (security risk)"
}

# === Observability Tests ===

test_agentdb_status_healthy() {
  agentdb init >/dev/null
  local output
  output=$(agentdb status)
  assert_contains "$output" "DB:"
  assert_contains "$output" "Size:"
  assert_contains "$output" "Counts:"
}

test_agentdb_export_creates_file() {
  agentdb init >/dev/null
  agentdb learn pattern "test export" >/dev/null
  local output
  output=$(agentdb export)
  assert_contains "$output" "Exported to:"
  # Verify file exists
  local export_file
  export_file=$(echo "$output" | grep -o '_meta/agentdb/learnings-export.*\.md')
  assert_file_exists "$TEST_PROJECT/$export_file"
}

test_checkpoint_includes_timestamp() {
  agentdb init >/dev/null
  agentdb write-end '{"test":"timestamp"}' >/dev/null
  local output
  output=$(agentdb recent 1)
  # Should contain a timestamp like 2026-03-12
  [[ "$output" =~ [0-9]{4}-[0-9]{2}-[0-9]{2} ]] || {
    echo "FAIL: checkpoint should include timestamp"
    return 1
  }
}

# === Additional Security Tests ===

test_agentdb_json_with_quotes() {
  agentdb init >/dev/null
  # Test JSON with embedded quotes
  agentdb write-end '{"message":"test \"quoted\" value"}' >/dev/null
  local output
  output=$(agentdb recent 1)
  assert_contains "$output" "quoted"
}

test_agentdb_newlines_in_content() {
  agentdb init >/dev/null
  # Test multiline content
  agentdb learn pattern "line1
line2
line3" "evidence" >/dev/null
  local count
  count=$(agentdb query "SELECT COUNT(*) FROM learnings;" | tail -1 | tr -d ' ')
  assert_equals "1" "$count" "multiline content should be stored"
}

test_no_shell_expansion_in_content() {
  agentdb init >/dev/null
  # Test that shell expansion doesn't happen
  agentdb learn pattern '$(whoami)' 'evidence' >/dev/null
  local output
  output=$(agentdb read-start)
  assert_contains "$output" '$(whoami)'
}

# === Resource Tests ===

test_db_size_reasonable() {
  agentdb init >/dev/null
  # Add some data
  for i in {1..10}; do
    agentdb learn pattern "pattern $i" "evidence" >/dev/null
    agentdb write-end "{\"iteration\":$i}" >/dev/null
  done
  local size_kb
  size_kb=$(du -k "$TEST_PROJECT/_meta/agentdb/agent.db" | cut -f1)
  # Should be under 1MB for this amount of data
  [ "$size_kb" -lt 1024 ] || {
    echo "FAIL: DB size unreasonable: ${size_kb}KB"
    return 1
  }
}

# === Hook Integration Tests ===

test_hooks_json_has_session_start() {
  local hooks_file="$PLUGIN_ROOT/hooks/hooks.json"
  if [ -f "$hooks_file" ]; then
    grep -q "SessionStart" "$hooks_file" || {
      echo "FAIL: hooks.json should define SessionStart hook"
      return 1
    }
  fi
}

test_hooks_json_has_session_end() {
  local hooks_file="$PLUGIN_ROOT/hooks/hooks.json"
  if [ -f "$hooks_file" ]; then
    grep -q "SessionEnd" "$hooks_file" || {
      echo "FAIL: hooks.json should define SessionEnd hook"
      return 1
    }
  fi
}

test_session_start_workflow_present() {
  local output
  output=$("$PLUGIN_ROOT/hooks/scripts/session-start.sh" 2>&1)
  # Should contain the workflow steps we defined
  assert_contains "$output" "READ"
  assert_contains "$output" "RESEARCH"
  assert_contains "$output" "EXECUTE"
}

test_session_start_testing_philosophy() {
  local output
  output=$("$PLUGIN_ROOT/hooks/scripts/session-start.sh" 2>&1)
  # Should contain testing philosophy
  assert_contains "$output" "tests"
  assert_contains "$output" "mock"
}

test_pre_compact_writes_checkpoint() {
  agentdb init >/dev/null
  # Simulate pre-compact by creating a checkpoint with pre-compact marker
  agentdb write-end '{"event":"pre-compact","agent":"test","goal":"testing"}' >/dev/null
  local output
  output=$(agentdb recent 1)
  assert_contains "$output" "pre-compact"
}

test_session_start_shows_checkpoint_after_compact() {
  agentdb init >/dev/null
  # Create a pre-compact checkpoint
  agentdb write-end '{"event":"pre-compact","agent":"test","goal":"continue testing","branch":"main"}' >/dev/null
  local output
  output=$("$PLUGIN_ROOT/hooks/scripts/session-start.sh" 2>&1)
  # Should show the checkpoint for resumption
  assert_contains "$output" "Checkpoint" || assert_contains "$output" "checkpoint"
}

# === Command Structure Tests ===

test_ingest_command_has_research_step() {
  local cmd_file="$PLUGIN_ROOT/commands/ingest.md"
  local content
  content=$(cat "$cmd_file")
  assert_contains "$content" "RESEARCH"
  assert_contains "$content" "anti_patterns"
}

test_auto_command_has_loop() {
  local cmd_file="$PLUGIN_ROOT/commands/auto.md"
  local content
  content=$(cat "$cmd_file")
  assert_contains "$content" "loop"
  assert_contains "$content" "max_iterations"
}

test_commands_use_structured_format() {
  # Commands should use XML structure (like skills) with semantic tags
  # or YAML code blocks - both are valid formats
  local structured_count=0
  local total_commands=0
  for cmd in "$PLUGIN_ROOT/commands/"*.md; do
    ((total_commands++))
    # Check for XML structure (<command id="X">) or YAML blocks
    if grep -qE '<command id=|```yaml' "$cmd" 2>/dev/null; then
      ((structured_count++))
    fi
  done
  # Core commands must use structured format - at least 2
  [ "$structured_count" -ge 2 ] || {
    echo "FAIL: core commands should use structured format ($structured_count/$total_commands)"
    return 1
  }
}

# === Verification Tests ===

test_commands_have_frontmatter() {
  local missing=0
  for cmd in "$PLUGIN_ROOT/commands/"*.md; do
    if ! grep -q "^---" "$cmd" 2>/dev/null; then
      echo "  Missing frontmatter in: $cmd"
      missing=1
    fi
  done
  assert_exit_code 0 "$missing" "all commands should have frontmatter"
}

test_skills_have_frontmatter() {
  local missing=0
  for skill in "$PLUGIN_ROOT/skills/"*/SKILL.md; do
    if ! grep -q "^---" "$skill" 2>/dev/null; then
      echo "  Missing frontmatter in: $skill"
      missing=1
    fi
  done
  assert_exit_code 0 "$missing" "all skills should have frontmatter"
}

test_agents_have_frontmatter() {
  local missing=0
  for agent in "$PLUGIN_ROOT/agents/"*.md; do
    if ! grep -q "^---" "$agent" 2>/dev/null; then
      echo "  Missing frontmatter in: $agent"
      missing=1
    fi
  done
  assert_exit_code 0 "$missing" "all agents should have frontmatter"
}

test_hooks_json_valid() {
  local hooks_file="$PLUGIN_ROOT/hooks/hooks.json"
  if [ -f "$hooks_file" ]; then
    python3 -m json.tool "$hooks_file" >/dev/null 2>&1 || {
      echo "  Invalid JSON in hooks.json"
      return 1
    }
  fi
}

# === Run Tests ===

run_test_suite() {
  local suite="$1"
  echo ""
  echo -e "${YELLOW}=== $suite ===${NC}"

  case "$suite" in
    agentdb)
      run_test "init creates db" test_agentdb_init
      run_test "init is idempotent" test_agentdb_init_idempotent
      run_test "learn failure" test_agentdb_learn_failure
      run_test "learn pattern shows in read-start" test_agentdb_learn_pattern
      run_test "learn requires type" test_agentdb_learn_requires_type
      run_test "write-end creates checkpoint" test_agentdb_write_end
      run_test "write-end requires json" test_agentdb_write_end_requires_json
      run_test "contract creates record" test_agentdb_contract
      run_test "verdict pass" test_agentdb_verdict_pass
      run_test "verdict fail" test_agentdb_verdict_fail
      run_test "read-start empty db" test_agentdb_read_start_empty
      run_test "read-start with data" test_agentdb_read_start_with_data
      run_test "status shows counts" test_agentdb_status
      run_test "prune keeps N" test_agentdb_prune
      run_test "query works" test_agentdb_query
      run_test "recent shows checkpoints" test_agentdb_recent
      run_test "error records tool errors" test_agentdb_error
      ;;
    edge)
      run_test "special chars (SQL injection)" test_agentdb_special_chars_in_insight
      run_test "empty db auto-init" test_agentdb_empty_db_read_start
      run_test "unicode content" test_agentdb_unicode
      run_test "long content" test_agentdb_long_content
      ;;
    hooks)
      run_test "session-start outputs KERNEL" test_session_start_outputs_kernel
      run_test "session-start creates agent file" test_session_start_creates_agent_file
      run_test "detect-secrets clean file" test_detect_secrets_clean
      run_test "hooks.json has SessionStart" test_hooks_json_has_session_start
      run_test "hooks.json has SessionEnd" test_hooks_json_has_session_end
      run_test "session-start has workflow" test_session_start_workflow_present
      run_test "session-start has testing philosophy" test_session_start_testing_philosophy
      run_test "pre-compact writes checkpoint" test_pre_compact_writes_checkpoint
      run_test "session-start shows checkpoint after compact" test_session_start_shows_checkpoint_after_compact
      ;;
    security)
      run_test "no hardcoded secrets" test_no_hardcoded_secrets_in_plugin
      run_test "scripts have set -e" test_scripts_have_set_e
      run_test "no eval usage" test_no_eval_usage
      run_test "JSON with quotes safe" test_agentdb_json_with_quotes
      run_test "newlines in content safe" test_agentdb_newlines_in_content
      run_test "no shell expansion" test_no_shell_expansion_in_content
      ;;
    observe)
      run_test "status is healthy" test_agentdb_status_healthy
      run_test "export creates file" test_agentdb_export_creates_file
      run_test "checkpoint has timestamp" test_checkpoint_includes_timestamp
      run_test "DB size reasonable" test_db_size_reasonable
      ;;
    verify)
      run_test "commands have frontmatter" test_commands_have_frontmatter
      run_test "skills have frontmatter" test_skills_have_frontmatter
      run_test "agents have frontmatter" test_agents_have_frontmatter
      run_test "hooks.json valid" test_hooks_json_valid
      run_test "ingest has research step" test_ingest_command_has_research_step
      run_test "auto has loop control" test_auto_command_has_loop
      run_test "commands use structured format" test_commands_use_structured_format
      ;;
  esac
}

main() {
  echo "========================================"
  echo "KERNEL Plugin Test Suite"
  echo "========================================"
  echo "Plugin: $PLUGIN_ROOT"
  echo "sqlite3: $(which sqlite3)"

  local target="${1:-all}"

  if [ "$target" = "all" ]; then
    run_test_suite "agentdb"
    run_test_suite "edge"
    run_test_suite "hooks"
    run_test_suite "security"
    run_test_suite "observe"
    run_test_suite "verify"
  else
    run_test_suite "$target"
  fi

  echo ""
  echo "========================================"
  echo -e "Results: ${GREEN}$PASS_COUNT passed${NC}, ${RED}$FAIL_COUNT failed${NC}"
  echo "========================================"

  [ "$FAIL_COUNT" -eq 0 ]
}

main "$@"
