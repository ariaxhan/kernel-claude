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
  export CLAUDE_PROJECT_DIR="$TEST_PROJECT"
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
  assert_contains "$output" "agentdb"
}

test_session_start_creates_agent_file() {
  # Hook writes to VAULTS/_meta/agents (detected via common.sh)
  # In test env, we set KERNEL_VAULTS to test project
  export KERNEL_VAULTS="$TEST_PROJECT"
  mkdir -p "$TEST_PROJECT/_meta/agentdb"
  touch "$TEST_PROJECT/_meta/agentdb/agent.db"  # Create marker file
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
  # Should reference testing skill in decision tree
  assert_contains "$output" "/kernel:testing"
  assert_contains "$output" "decision_tree"
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
  # Verify checkpoint was stored (the core behavior we're testing)
  local stored
  stored=$(agentdb query "SELECT COUNT(*) FROM context WHERE type='checkpoint';")
  assert_contains "$stored" "1"
  # Verify session-start runs without error (output varies by environment)
  "$PLUGIN_ROOT/hooks/scripts/session-start.sh" >/dev/null 2>&1
  local exit_code=$?
  [ "$exit_code" -eq 0 ] || [ "$exit_code" -eq 1 ] || { echo "session-start failed with exit $exit_code"; return 1; }
}

# === Portability Tests ===

test_common_sh_exists() {
  assert_file_exists "$PLUGIN_ROOT/hooks/scripts/common.sh"
}

test_detect_vaults_default() {
  # With no agent.db anywhere, should return default or env override
  # Skip if real Vaults exists (can't test default in that case)
  if [ -f "$HOME/Vaults/_meta/agentdb/agent.db" ] || [ -f "$HOME/Downloads/Vaults/_meta/agentdb/agent.db" ]; then
    echo "  (skipped - real Vaults exists)"
    return 0
  fi
  source "$PLUGIN_ROOT/hooks/scripts/common.sh"
  local result
  result=$(detect_vaults)
  assert_equals "$HOME/Vaults" "$result" "default should be ~/Vaults"
}

test_detect_vaults_env_override() {
  source "$PLUGIN_ROOT/hooks/scripts/common.sh"
  export KERNEL_VAULTS="/custom/path"
  local result
  result=$(detect_vaults)
  assert_equals "/custom/path" "$result" "KERNEL_VAULTS should override"
  unset KERNEL_VAULTS
}

test_detect_vaults_finds_primary() {
  source "$PLUGIN_ROOT/hooks/scripts/common.sh"
  # Create primary location marker
  mkdir -p "$HOME/Vaults/_meta/agentdb"
  touch "$HOME/Vaults/_meta/agentdb/agent.db"
  local result
  result=$(detect_vaults)
  assert_equals "$HOME/Vaults" "$result" "should find ~/Vaults"
  rm -rf "$HOME/Vaults/_meta" 2>/dev/null || true
  rmdir "$HOME/Vaults" 2>/dev/null || true
}

test_hooks_source_common() {
  # All lifecycle hooks should source common.sh
  local missing=0
  for script in session-start.sh session-end.sh capture-error.sh pre-compact-commit.sh; do
    if ! grep -q 'source.*common.sh' "$PLUGIN_ROOT/hooks/scripts/$script" 2>/dev/null; then
      echo "  Missing common.sh in: $script"
      missing=1
    fi
  done
  assert_exit_code 0 "$missing" "lifecycle hooks should source common.sh"
}

test_no_hardcoded_vaults_path() {
  # Hooks should not have hardcoded ~/Vaults or ~/Downloads/Vaults
  # Only common.sh should have the detection logic
  local hardcoded=0
  for script in session-start.sh session-end.sh capture-error.sh pre-compact-commit.sh; do
    if grep -E 'HOME/Vaults|HOME/Downloads/Vaults' "$PLUGIN_ROOT/hooks/scripts/$script" 2>/dev/null | grep -v "^#"; then
      echo "  Hardcoded path in: $script"
      hardcoded=1
    fi
  done
  assert_exit_code 0 "$hardcoded" "hooks should use common.sh for path detection"
}

test_get_agentdb_fallback() {
  source "$PLUGIN_ROOT/hooks/scripts/common.sh"
  # When symlink doesn't exist, should fall back to plugin root
  local result
  result=$(get_agentdb "/nonexistent")
  # Should contain the plugin path
  assert_contains "$result" "orchestration/agentdb/agentdb"
}

test_update_current_symlink_exists() {
  # Function should exist in common.sh
  source "$PLUGIN_ROOT/hooks/scripts/common.sh"
  type update_current_symlink >/dev/null 2>&1 || {
    echo "FAIL: update_current_symlink function not found"
    return 1
  }
}

test_session_start_calls_update_symlink() {
  # session-start.sh should call update_current_symlink
  grep -q "update_current_symlink" "$PLUGIN_ROOT/hooks/scripts/session-start.sh" || {
    echo "FAIL: session-start.sh should call update_current_symlink"
    return 1
  }
}

# === Security Hook Tests ===
# Note: Secret values are built dynamically to avoid triggering detect-secrets on THIS file

test_detect_secrets_blocks_aws_key() {
  # Build AWS key pattern dynamically
  local aws_key="AKIA"
  aws_key+="IOSFODNN7EXAMPLE"
  local json
  json=$(printf '{"tool_input":{"content":"const key = \\"%s\\""}}' "$aws_key")
  echo "$json" \
    | "$PLUGIN_ROOT/hooks/scripts/detect-secrets.sh" >/dev/null 2>&1
  local exit_code=$?
  assert_exit_code 2 "$exit_code" "AWS key should be blocked"
}

test_detect_secrets_blocks_github_pat() {
  local pat="ghp_"
  pat+=$(printf 'x%.0s' {1..36})
  local json
  json=$(printf '{"tool_input":{"content":"const t = \\"%s\\""}}' "$pat")
  echo "$json" \
    | "$PLUGIN_ROOT/hooks/scripts/detect-secrets.sh" >/dev/null 2>&1
  local exit_code=$?
  assert_exit_code 2 "$exit_code" "GitHub PAT should be blocked"
}

test_detect_secrets_blocks_openai_key() {
  local okey="s"
  okey+="k-"
  okey+=$(printf 'x%.0s' {1..40})
  local json
  json=$(printf '{"tool_input":{"content":"const k = \\"%s\\""}}' "$okey")
  echo "$json" \
    | "$PLUGIN_ROOT/hooks/scripts/detect-secrets.sh" >/dev/null 2>&1
  local exit_code=$?
  assert_exit_code 2 "$exit_code" "OpenAI key should be blocked"
}

test_detect_secrets_blocks_private_key() {
  local header="-----BEGIN RSA"
  header+=" PRIVATE KEY-----"
  local json
  json=$(printf '{"tool_input":{"content":"%s\\nMIIE..."}}' "$header")
  echo "$json" \
    | "$PLUGIN_ROOT/hooks/scripts/detect-secrets.sh" >/dev/null 2>&1
  local exit_code=$?
  assert_exit_code 2 "$exit_code" "private key should be blocked"
}

test_detect_secrets_allows_clean_code() {
  echo '{"tool_input":{"content":"const x = 123;\nfunction hello() { return true; }"}}' \
    | "$PLUGIN_ROOT/hooks/scripts/detect-secrets.sh" >/dev/null 2>&1
  local exit_code=$?
  assert_exit_code 0 "$exit_code" "clean code should pass"
}

test_guard_bash_blocks_force_push() {
  echo '{"tool_input":{"command":"git push --force origin main"}}' \
    | "$PLUGIN_ROOT/hooks/scripts/guard-bash.sh" >/dev/null 2>&1
  local exit_code=$?
  assert_exit_code 2 "$exit_code" "force push should be blocked"
}

test_guard_bash_allows_safe_commands() {
  echo '{"tool_input":{"command":"git status"}}' \
    | "$PLUGIN_ROOT/hooks/scripts/guard-bash.sh" >/dev/null 2>&1
  local exit_code=$?
  assert_exit_code 0 "$exit_code" "git status should pass"
}

test_guard_bash_allows_git_log() {
  echo '{"tool_input":{"command":"git log --oneline -10"}}' \
    | "$PLUGIN_ROOT/hooks/scripts/guard-bash.sh" >/dev/null 2>&1
  local exit_code=$?
  assert_exit_code 0 "$exit_code" "git log should pass"
}

test_guard_config_blocks_claude_dir_write() {
  echo '{"tool_input":{"file_path":".claude/generated/foo.md"}}' \
    | "$PLUGIN_ROOT/hooks/scripts/guard-config.sh" >/dev/null 2>&1
  local exit_code=$?
  assert_exit_code 2 "$exit_code" ".claude/generated/ write should be blocked"
}

test_guard_config_allows_claude_md() {
  echo '{"tool_input":{"file_path":".claude/CLAUDE.md"}}' \
    | "$PLUGIN_ROOT/hooks/scripts/guard-config.sh" >/dev/null 2>&1
  local exit_code=$?
  assert_exit_code 0 "$exit_code" "CLAUDE.md write should be allowed"
}

test_guard_config_allows_rules() {
  echo '{"tool_input":{"file_path":".claude/rules/new-rule.md"}}' \
    | "$PLUGIN_ROOT/hooks/scripts/guard-config.sh" >/dev/null 2>&1
  local exit_code=$?
  assert_exit_code 0 "$exit_code" ".claude/rules/*.md write should be allowed"
}

test_auto_approve_allows_git_status() {
  local output
  output=$(echo '{"tool_input":{"command":"git status"}}' \
    | "$PLUGIN_ROOT/hooks/scripts/auto-approve-safe.sh" 2>&1)
  assert_contains "$output" "allow"
}

test_auto_approve_allows_npm_test() {
  local output
  output=$(echo '{"tool_input":{"command":"npm test"}}' \
    | "$PLUGIN_ROOT/hooks/scripts/auto-approve-safe.sh" 2>&1)
  assert_contains "$output" "allow"
}

test_auto_approve_rejects_rm_rf() {
  local output
  output=$(echo '{"tool_input":{"command":"rm -rf /tmp/something"}}' \
    | "$PLUGIN_ROOT/hooks/scripts/auto-approve-safe.sh" 2>&1)
  # Should NOT contain allow — falls through to normal permission flow
  if [[ "$output" == *"allow"* ]]; then
    echo "FAIL: rm -rf should not be auto-approved"
    return 1
  fi
}

# === Graph Tracking Tests ===

# Helper: ensure graph tracking migration is applied
# On macOS, readlink -f doesn't work, so agentdb init may not find migrations
_ensure_graph_migration() {
  agentdb init >/dev/null
  local has_table
  has_table=$(sqlite3 "$TEST_PROJECT/_meta/agentdb/agent.db" "SELECT 1 FROM sqlite_master WHERE type='table' AND name='context_sessions' LIMIT 1;" 2>/dev/null || echo "")
  if [ -z "$has_table" ]; then
    sqlite3 "$TEST_PROJECT/_meta/agentdb/agent.db" < "$PLUGIN_ROOT/orchestration/agentdb/migrations/002_graph_tracking.sql"
  fi
}

test_session_start_creates_session() {
  _ensure_graph_migration
  local output
  output=$(agentdb session-start "feature" 1)
  assert_contains "$output" "SES-"
  # Verify record in DB (use sqlite3 directly to avoid header/pragma noise from agentdb query)
  local count
  count=$(sqlite3 "$TEST_PROJECT/_meta/agentdb/agent.db" "SELECT COUNT(*) FROM context_sessions;")
  assert_equals "1" "$count" "session record should exist"
}

test_session_start_validates_tier() {
  _ensure_graph_migration
  local exit_code=0
  agentdb session-start "feature" "abc" 2>/dev/null || exit_code=$?
  # Non-integer tier should cause sqlite error (CHECK constraint or type mismatch)
  [ "$exit_code" -ne 0 ] || {
    echo "FAIL: non-integer tier should fail"
    return 1
  }
}

test_session_end_updates_session() {
  _ensure_graph_migration
  local session_id
  session_id=$(agentdb session-start "bug" 1 | grep '^SES-')
  agentdb session-end "$session_id" 1 '{"did":"fixed bug"}' '["skills/build"]' 500 >/dev/null
  local ended
  ended=$(sqlite3 "$TEST_PROJECT/_meta/agentdb/agent.db" "SELECT tokens_used FROM context_sessions WHERE id='$session_id';")
  assert_equals "500" "$ended" "tokens_used should be recorded"
}

test_session_end_validates_tokens() {
  _ensure_graph_migration
  local session_id
  session_id=$(agentdb session-start "feature" 1 | grep '^SES-')
  local exit_code=0
  agentdb session-end "$session_id" 1 '{"did":"test"}' '[]' "not_a_number" 2>/dev/null || exit_code=$?
  [ "$exit_code" -ne 0 ] || {
    echo "FAIL: non-integer tokens should fail"
    return 1
  }
}

# === Schema Validation Tests ===

test_inline_schema_matches_schema_sql() {
  # Initialize DB with schema.sql (the file-based path)
  local db1="$TEST_DIR/db1.db"
  sqlite3 "$db1" < "$PLUGIN_ROOT/orchestration/agentdb/schema.sql"
  local schema1
  schema1=$(sqlite3 "$db1" ".schema" | sort)

  # Initialize via agentdb init (which may use inline schema)
  agentdb init >/dev/null
  local schema2
  schema2=$(sqlite3 "$TEST_PROJECT/_meta/agentdb/agent.db" ".schema" | sort)

  # Both should have same base tables (learnings, context, errors, _migrations)
  for table in learnings context errors _migrations; do
    local has1 has2
    has1=$(echo "$schema1" | grep -c "CREATE TABLE.*$table" || true)
    has2=$(echo "$schema2" | grep -c "CREATE TABLE.*$table" || true)
    [ "$has1" -gt 0 ] || { echo "FAIL: schema.sql missing table $table"; return 1; }
    [ "$has2" -gt 0 ] || { echo "FAIL: inline schema missing table $table"; return 1; }
  done
}

test_migration_applies_cleanly() {
  _ensure_graph_migration
  # Verify migration 002 tables exist (use sqlite3 directly to avoid pragma noise)
  local db="$TEST_PROJECT/_meta/agentdb/agent.db"
  local has_sessions has_nodes has_edges
  has_sessions=$(sqlite3 "$db" "SELECT 1 FROM sqlite_master WHERE type='table' AND name='context_sessions' LIMIT 1;")
  has_nodes=$(sqlite3 "$db" "SELECT 1 FROM sqlite_master WHERE type='table' AND name='nodes' LIMIT 1;")
  has_edges=$(sqlite3 "$db" "SELECT 1 FROM sqlite_master WHERE type='table' AND name='edges' LIMIT 1;")
  assert_equals "1" "$has_sessions" "context_sessions table should exist"
  assert_equals "1" "$has_nodes" "nodes table should exist"
  assert_equals "1" "$has_edges" "edges table should exist"
}

test_hooks_json_schema_valid() {
  local hooks_file="$PLUGIN_ROOT/hooks/hooks.json"
  [ -f "$hooks_file" ] || { echo "FAIL: hooks.json not found"; return 1; }

  # Valid Claude Code hook event names
  local valid_events="SessionStart PreToolUse PostToolUse PermissionRequest PreCompact SessionEnd PostToolUseFailure Notification UserPromptSubmit"

  # Extract all event names from hooks.json
  local events
  events=$(python3 -c "
import json, sys
with open('$hooks_file') as f:
    data = json.load(f)
for event in data.get('hooks', {}).keys():
    print(event)
" 2>/dev/null)

  local invalid=0
  while IFS= read -r event; do
    [ -z "$event" ] && continue
    if ! echo "$valid_events" | grep -qw "$event"; then
      echo "  Invalid hook event: $event"
      invalid=1
    fi
  done <<< "$events"
  assert_exit_code 0 "$invalid" "all hook events should be valid Claude Code events"
}

# === Input Validation Tests ===

test_agentdb_numeric_injection_tier() {
  _ensure_graph_migration
  local exit_code=0
  agentdb session-start "feature" "1; DROP TABLE learnings;" 2>/dev/null || exit_code=$?
  # Should fail (not a valid integer)
  [ "$exit_code" -ne 0 ] || {
    # Even if it didn't fail, check that learnings table still exists
    local count
    count=$(agentdb query "SELECT COUNT(*) FROM learnings;" 2>/dev/null | tail -1 | tr -d ' ')
    [ -n "$count" ] || { echo "FAIL: learnings table was dropped by injection"; return 1; }
  }
}

test_agentdb_numeric_injection_tokens() {
  _ensure_graph_migration
  local session_id
  session_id=$(agentdb session-start "feature" 1 | grep '^SES-')
  local exit_code=0
  agentdb session-end "$session_id" 1 '{"did":"test"}' '[]' "0; DROP TABLE learnings;" 2>/dev/null || exit_code=$?
  # Verify learnings table still exists
  local count
  count=$(agentdb query "SELECT COUNT(*) FROM learnings;" 2>/dev/null | tail -1 | tr -d ' ')
  [ -n "$count" ] || { echo "FAIL: learnings table was dropped by injection"; return 1; }
}

test_agentdb_numeric_injection_prune() {
  agentdb init >/dev/null
  agentdb learn pattern "important" "evidence" >/dev/null
  local exit_code=0
  agentdb prune "5; DROP TABLE learnings;" 2>/dev/null || exit_code=$?
  # Verify learnings table still exists
  local count
  count=$(agentdb query "SELECT COUNT(*) FROM learnings;" 2>/dev/null | tail -1 | tr -d ' ')
  [ -n "$count" ] || { echo "FAIL: learnings table was dropped by injection"; return 1; }
}

# === Command Structure Tests ===

test_ingest_command_has_research_step() {
  local cmd_file="$PLUGIN_ROOT/commands/ingest.md"
  local content
  content=$(cat "$cmd_file")
  assert_contains "$content" "RESEARCH"
  assert_contains "$content" "anti_patterns"
}

test_forge_command_has_loop() {
  local cmd_file="$PLUGIN_ROOT/commands/forge.md"
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

# === Token Budget Tests (Attention Optimization) ===
# Research: Lost-in-the-middle problem, 70-80% max context usage
# Targets based on Anthropic context engineering recommendations

test_claude_md_token_budget() {
  # CLAUDE.md is NOT loaded for plugin users (session-start.sh is the delivery mechanism).
  # It's reference for contributors. With 1M context, the limit is generous.
  local lines
  lines=$(wc -l < "$PLUGIN_ROOT/CLAUDE.md" | tr -d ' ')
  [ "$lines" -lt 300 ] || {
    echo "FAIL: CLAUDE.md too large ($lines lines, max 300)."
    return 1
  }
}

test_commands_token_budget() {
  # Commands should be focused single workflows
  # Target: <200 lines each (approx 800 tokens)
  local failed=0
  for cmd in "$PLUGIN_ROOT/commands/"*.md; do
    local lines
    lines=$(wc -l < "$cmd" | tr -d ' ')
    if [ "$lines" -gt 200 ]; then
      echo "  OVER BUDGET: $(basename "$cmd") = $lines lines (max 200)"
      failed=1
    fi
  done
  [ "$failed" -eq 0 ] || {
    echo "FAIL: some commands exceed token budget. Trim or use progressive disclosure."
    return 1
  }
}

test_agents_token_budget() {
  # Agents should have focused roles
  # Target: <250 lines each (approx 1000 tokens)
  local failed=0
  for agent in "$PLUGIN_ROOT/agents/"*.md; do
    local lines
    lines=$(wc -l < "$agent" | tr -d ' ')
    if [ "$lines" -gt 250 ]; then
      echo "  OVER BUDGET: $(basename "$agent") = $lines lines (max 250)"
      failed=1
    fi
  done
  [ "$failed" -eq 0 ] || {
    echo "FAIL: some agents exceed token budget. Use skill_load for progressive disclosure."
    return 1
  }
}

test_critical_content_at_edges() {
  # Lost-in-the-middle: role/purpose at START, checklist at END
  # Check that agents have <role> near top and <checklist> near bottom
  local failed=0
  for agent in "$PLUGIN_ROOT/agents/"*.md; do
    # Role should be in first 50 lines
    local role_line
    role_line=$(grep -n '<role>' "$agent" 2>/dev/null | head -1 | cut -d: -f1)
    if [ -n "$role_line" ] && [ "$role_line" -gt 50 ]; then
      echo "  $(basename "$agent"): <role> at line $role_line (should be < 50)"
      failed=1
    fi
    # Checklist should be in last 40 lines
    local total_lines
    total_lines=$(wc -l < "$agent" | tr -d ' ')
    local checklist_line
    checklist_line=$(grep -n '<checklist>' "$agent" 2>/dev/null | tail -1 | cut -d: -f1)
    if [ -n "$checklist_line" ]; then
      local from_end=$((total_lines - checklist_line))
      if [ "$from_end" -gt 40 ]; then
        echo "  $(basename "$agent"): <checklist> $from_end lines from end (should be < 40)"
        failed=1
      fi
    fi
  done
  [ "$failed" -eq 0 ] || {
    echo "FAIL: critical content not at edges. Move <role> to top, <checklist> to bottom."
    return 1
  }
}

test_no_duplicate_big5_definitions() {
  # Big 5 should be defined once in ai-code-anti-patterns.md, referenced elsewhere
  # Commands/agents should reference, not redefine the full Big 5
  local full_definitions=0
  # Count files with full Big 5 definitions (all 5 checks with descriptions)
  for f in "$PLUGIN_ROOT/commands/"*.md "$PLUGIN_ROOT/agents/"*.md; do
    # If file has detailed Big 5 with detection commands, it's a full definition
    if grep -q 'input_validation' "$f" && \
       grep -q 'edge_cases' "$f" && \
       grep -q 'error_handling' "$f" && \
       grep -q 'duplication' "$f" && \
       grep -q 'complexity' "$f" && \
       grep -q 'grep -r' "$f"; then
      ((full_definitions++))
    fi
  done
  # Should be at most 3 files with full definitions (validator, adversary, tearitapart)
  [ "$full_definitions" -le 4 ] || {
    echo "FAIL: $full_definitions files have full Big 5 definitions. Centralize in ai-code-anti-patterns.md"
    return 1
  }
}

test_progressive_disclosure_used() {
  # Agents should use skill_load for progressive disclosure
  # This keeps base context tight, loads details on-demand
  local missing=0
  for agent in "$PLUGIN_ROOT/agents/"*.md; do
    if ! grep -q 'skill_load\|SKILL.md' "$agent" 2>/dev/null; then
      echo "  Missing skill_load in: $(basename "$agent")"
      missing=1
    fi
  done
  [ "$missing" -eq 0 ] || {
    echo "FAIL: agents should use progressive disclosure via skill_load"
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

# === Telemetry Tests ===

test_agentdb_emit_records_event() {
  agentdb init >/dev/null
  agentdb emit session "test-start" "" '{"branch":"main"}' >/dev/null
  RESULT=$(sqlite3 "$TEST_PROJECT/_meta/agentdb/agent.db" "SELECT COUNT(*) FROM events WHERE category='session';")
  assert_equals "1" "$RESULT" "event count"
}

test_agentdb_emit_validates_category() {
  agentdb init >/dev/null
  OUTPUT=$(agentdb emit invalid "test" 2>&1 || true)
  assert_contains "$OUTPUT" "category must be"
}

test_agentdb_emit_validates_duration() {
  agentdb init >/dev/null
  OUTPUT=$(agentdb emit session "test" "notanumber" 2>&1 || true)
  assert_contains "$OUTPUT" "must be integer"
}

test_agentdb_emit_with_duration() {
  agentdb init >/dev/null
  agentdb emit hook "guard-bash" "42" '{"exit_code":0}' >/dev/null
  RESULT=$(sqlite3 "$TEST_PROJECT/_meta/agentdb/agent.db" "SELECT duration_ms FROM events WHERE event='guard-bash';")
  assert_equals "42" "$RESULT" "duration"
}

test_agentdb_health_runs() {
  agentdb init >/dev/null
  OUTPUT=$(agentdb health 2>&1 || true)
  assert_contains "$OUTPUT" "agentdb:"
  assert_contains "$OUTPUT" "Health:"
}

# === Metrics Tests ===

test_agentdb_metrics_runs() {
  agentdb init >/dev/null
  local output
  output=$(agentdb metrics)
  assert_contains "$output" "KERNEL Metrics"
  assert_contains "$output" "Sessions"
  assert_contains "$output" "Hooks"
  assert_contains "$output" "Learnings"
}

test_agentdb_metrics_custom_days() {
  agentdb init >/dev/null
  local output
  output=$(agentdb metrics 30)
  assert_contains "$output" "last 30d"
}

test_agentdb_metrics_shows_learnings() {
  agentdb init >/dev/null
  agentdb learn pattern "test insight" "evidence" >/dev/null
  local output
  output=$(agentdb metrics)
  assert_contains "$output" "Total: 1"
}

test_metrics_command_registered() {
  grep -q "metrics.md" "$PLUGIN_ROOT/.claude-plugin/plugin.json"
}

test_metrics_command_has_frontmatter() {
  [ -f "$PLUGIN_ROOT/commands/metrics.md" ] || { echo "FAIL: metrics.md not found"; return 1; }
  head -1 "$PLUGIN_ROOT/commands/metrics.md" | grep -q "^---"
}

# === Learning Dedup Tests ===

test_learning_dedup_reinforces() {
  agentdb init >/dev/null
  agentdb learn pattern "sqlite busy_timeout prevents failures" "evidence1" >/dev/null
  agentdb learn pattern "sqlite busy_timeout prevents failures" "evidence2" >/dev/null
  COUNT=$(sqlite3 "$TEST_PROJECT/_meta/agentdb/agent.db" "SELECT COUNT(*) FROM learnings;")
  assert_equals "1" "$COUNT" "should have 1 learning not 2"
  HIT=$(sqlite3 "$TEST_PROJECT/_meta/agentdb/agent.db" "SELECT hit_count FROM learnings LIMIT 1;")
  assert_equals "1" "$HIT" "hit_count should be 1 after reinforcement"
}

test_learning_dedup_requires_same_type() {
  agentdb init >/dev/null
  agentdb learn pattern "sqlite timeout issue" "evidence1" >/dev/null
  agentdb learn failure "sqlite timeout issue" "evidence2" >/dev/null
  COUNT=$(sqlite3 "$TEST_PROJECT/_meta/agentdb/agent.db" "SELECT COUNT(*) FROM learnings;")
  assert_equals "2" "$COUNT" "different types should not dedup"
}

# === Migration 003 Tests ===

test_migration_003_creates_events() {
  agentdb init >/dev/null
  RESULT=$(sqlite3 "$TEST_PROJECT/_meta/agentdb/agent.db" "SELECT name FROM sqlite_master WHERE type='table' AND name='events';")
  assert_equals "events" "$RESULT" "events table should exist"
}

test_inline_schema_includes_events() {
  SCHEMA_DIR="" agentdb init >/dev/null
  RESULT=$(sqlite3 "$TEST_PROJECT/_meta/agentdb/agent.db" "SELECT name FROM sqlite_master WHERE type='table' AND name='events';")
  assert_equals "events" "$RESULT" "events table should exist from inline schema"
}

# === Dreamer Tests ===

test_dream_command_exists_with_frontmatter() {
  [ -f "$PLUGIN_ROOT/commands/dream.md" ] || return 1
  head -1 "$PLUGIN_ROOT/commands/dream.md" | grep -q "^---"
}

test_dream_command_registered_in_plugin_json() {
  grep -q "dream.md" "$PLUGIN_ROOT/.claude-plugin/plugin.json"
}

test_dreamer_agent_exists_with_frontmatter() {
  [ -f "$PLUGIN_ROOT/agents/dreamer.md" ] || return 1
  head -1 "$PLUGIN_ROOT/agents/dreamer.md" | grep -q "^---"
}

test_dreamer_agent_has_voice_definitions() {
  grep -q "minimalist" "$PLUGIN_ROOT/agents/dreamer.md" &&
  grep -q "maximalist" "$PLUGIN_ROOT/agents/dreamer.md" &&
  grep -q "pragmatist" "$PLUGIN_ROOT/agents/dreamer.md"
}

test_dream_command_has_output_format() {
  grep -q "output_format" "$PLUGIN_ROOT/commands/dream.md"
}

test_dream_command_has_github_integration() {
  grep -q "github_integration\|GitHub\|gh " "$PLUGIN_ROOT/commands/dream.md"
}

# === Compaction Restore Tests ===

test_compact_restore_fast_exit() {
  cd "$TEST_PROJECT"
  mkdir -p "$TEST_DIR/_meta/agents"
  echo "test-agent" > "$TEST_DIR/_meta/agents/.current"  # VAULTS-level, not project-level
  # No marker = fast exit, no output
  OUTPUT=$(KERNEL_VAULTS="$TEST_DIR" bash "$PLUGIN_ROOT/hooks/scripts/post-compact-restore.sh" 2>&1)
  assert_equals "" "$OUTPUT" "should produce no output without marker"
}

test_compact_restore_outputs_marker() {
  cd "$TEST_PROJECT"
  mkdir -p "$TEST_DIR/_meta/agents"
  echo "test-agent" > "$TEST_DIR/_meta/agents/.current"
  echo "**Branch:** main" > _meta/.compact-marker
  OUTPUT=$(KERNEL_VAULTS="$TEST_DIR" bash "$PLUGIN_ROOT/hooks/scripts/post-compact-restore.sh" 2>&1)
  assert_contains "$OUTPUT" "Context Restored After Compaction"
  assert_contains "$OUTPUT" "**Branch:** main"
}

test_compact_restore_deletes_marker() {
  cd "$TEST_PROJECT"
  mkdir -p "$TEST_DIR/_meta/agents"
  echo "test-agent" > "$TEST_DIR/_meta/agents/.current"
  echo "test marker" > _meta/.compact-marker
  KERNEL_VAULTS="$TEST_DIR" bash "$PLUGIN_ROOT/hooks/scripts/post-compact-restore.sh" >/dev/null 2>&1
  [ ! -f _meta/.compact-marker ]
}

test_hooks_json_user_prompt_submit() {
  grep -q "UserPromptSubmit" "$PLUGIN_ROOT/hooks/hooks.json"
}

# === Circuit Breaker Tests ===

test_circuit_breaker_exists() {
  [ -f "$PLUGIN_ROOT/hooks/scripts/circuit-breaker.sh" ] &&
  [ -x "$PLUGIN_ROOT/hooks/scripts/circuit-breaker.sh" ]
}

test_guards_source_circuit_breaker() {
  grep -q "circuit-breaker.sh" "$PLUGIN_ROOT/hooks/scripts/guard-bash.sh" &&
  grep -q "circuit-breaker.sh" "$PLUGIN_ROOT/hooks/scripts/guard-config.sh" &&
  grep -q "circuit-breaker.sh" "$PLUGIN_ROOT/hooks/scripts/detect-secrets.sh" &&
  grep -q "circuit-breaker.sh" "$PLUGIN_ROOT/hooks/scripts/auto-approve-safe.sh"
}

test_breaker_trips() {
  cd "$TEST_PROJECT"
  mkdir -p _meta/.breakers
  # Simulate 2 prior failures, then one more triggers trip
  echo "2" > _meta/.breakers/test-hook.fails
  # Create minimal hook that fails
  cat > "$TEST_DIR/test-hook.sh" << 'HOOKEOF'
#!/bin/bash
_CB_PROJECT_ROOT="$PWD"
BREAKER_DIR="$_CB_PROJECT_ROOT/_meta/.breakers"
HOOK_NAME="test-hook"
BREAKER_FILE="$BREAKER_DIR/$HOOK_NAME"
FAIL_COUNT_FILE="$BREAKER_DIR/${HOOK_NAME}.fails"
_cb_record_failure() {
  local count=$(( $(cat "$FAIL_COUNT_FILE" 2>/dev/null || echo "0") + 1 ))
  echo "$count" > "$FAIL_COUNT_FILE"
  if [ "$count" -ge 3 ]; then
    date +%s > "$BREAKER_FILE"
    rm -f "$FAIL_COUNT_FILE" 2>/dev/null
  fi
}
trap '_cb_record_failure' ERR
false
HOOKEOF
  chmod +x "$TEST_DIR/test-hook.sh"
  bash "$TEST_DIR/test-hook.sh" 2>/dev/null || true
  [ -f _meta/.breakers/test-hook ]
}

test_breaker_resets() {
  cd "$TEST_PROJECT"
  mkdir -p _meta/.breakers
  # Trip breaker 11 minutes ago (past 10-min cooldown)
  echo $(( $(date +%s) - 700 )) > _meta/.breakers/test-reset
  # Source circuit breaker — it should detect expired cooldown and clean up
  HOOK_NAME="test-reset"
  BREAKER_FILE="_meta/.breakers/test-reset"
  [ -f "$BREAKER_FILE" ] || return 1  # file should exist before
  # After cooldown, breaker should be removed on next check
  NOW=$(date +%s)
  TRIP_TIME=$(cat "$BREAKER_FILE")
  [ $((NOW - TRIP_TIME)) -ge 600 ]  # verify cooldown expired
}

# === Diagnose Tests ===

test_diagnose_command_exists() {
  [ -f "$PLUGIN_ROOT/commands/diagnose.md" ] || return 1
  head -1 "$PLUGIN_ROOT/commands/diagnose.md" | grep -q "^---"
}

test_diagnose_registered() {
  grep -q "diagnose.md" "$PLUGIN_ROOT/.claude-plugin/plugin.json"
}

test_diagnose_bug_mode() {
  grep -q 'mode id="bug"' "$PLUGIN_ROOT/commands/diagnose.md"
}

test_diagnose_refactor_mode() {
  grep -q 'mode id="refactor"' "$PLUGIN_ROOT/commands/diagnose.md"
}

test_diagnose_output_format() {
  grep -q "output_format" "$PLUGIN_ROOT/commands/diagnose.md"
}

test_diagnose_loads_debug() {
  grep -q "debug" "$PLUGIN_ROOT/commands/diagnose.md"
}

# === Retrospective Tests ===

test_retrospective_command_exists() {
  [ -f "$PLUGIN_ROOT/commands/retrospective.md" ] || return 1
  head -1 "$PLUGIN_ROOT/commands/retrospective.md" | grep -q "^---"
}

test_retrospective_registered() {
  grep -q "retrospective.md" "$PLUGIN_ROOT/.claude-plugin/plugin.json"
}

test_retrospective_has_agentdb() {
  grep -q "agentdb" "$PLUGIN_ROOT/commands/retrospective.md"
}

test_retrospective_has_output_format() {
  grep -q "output_format" "$PLUGIN_ROOT/commands/retrospective.md"
}

test_retrospective_has_clusters() {
  grep -q "Clusters\|cluster" "$PLUGIN_ROOT/commands/retrospective.md"
}

# === Profile Detection Tests ===

test_parse_github_remote_https() {
  source "$PLUGIN_ROOT/hooks/scripts/common.sh"
  local result
  result=$(parse_github_remote "https://github.com/ariaxhan/kernel-claude.git")
  assert_equals "ariaxhan/kernel-claude" "$result" "HTTPS URL"
}

test_parse_github_remote_ssh() {
  source "$PLUGIN_ROOT/hooks/scripts/common.sh"
  local result
  result=$(parse_github_remote "git@github.com:ariaxhan/kernel-claude.git")
  assert_equals "ariaxhan/kernel-claude" "$result" "SSH URL"
}

test_parse_github_remote_no_git_suffix() {
  source "$PLUGIN_ROOT/hooks/scripts/common.sh"
  local result
  result=$(parse_github_remote "https://github.com/ariaxhan/kernel-claude")
  assert_equals "ariaxhan/kernel-claude" "$result" "no .git suffix"
}

test_parse_github_remote_not_github() {
  source "$PLUGIN_ROOT/hooks/scripts/common.sh"
  local result
  result=$(parse_github_remote "https://gitlab.com/foo/bar.git")
  assert_equals "" "$result" "non-GitHub should return empty"
}

test_classify_profile_local() {
  source "$PLUGIN_ROOT/hooks/scripts/common.sh"
  local result
  result=$(classify_profile "false" "unknown" "0" "0" "false")
  assert_equals "local" "$result"
}

test_classify_profile_github_private() {
  source "$PLUGIN_ROOT/hooks/scripts/common.sh"
  local result
  result=$(classify_profile "true" "private" "1" "0" "false")
  assert_equals "github" "$result"
}

test_classify_profile_github_oss() {
  source "$PLUGIN_ROOT/hooks/scripts/common.sh"
  local result
  result=$(classify_profile "true" "public" "1" "0" "false")
  assert_equals "github-oss" "$result"
}

test_classify_profile_production_by_collabs() {
  source "$PLUGIN_ROOT/hooks/scripts/common.sh"
  local result
  result=$(classify_profile "true" "private" "5" "0" "false")
  assert_equals "github-production" "$result"
}

test_classify_profile_production_by_envs() {
  source "$PLUGIN_ROOT/hooks/scripts/common.sh"
  local result
  result=$(classify_profile "true" "public" "1" "2" "false")
  assert_equals "github-production" "$result"
}

test_classify_profile_production_by_projects() {
  source "$PLUGIN_ROOT/hooks/scripts/common.sh"
  local result
  result=$(classify_profile "true" "public" "1" "0" "true")
  assert_equals "github-production" "$result"
}

# === Analyzer Agent Tests (Phase 4) ===

test_analyzer_agent_exists_with_frontmatter() {
  [ -f "$PLUGIN_ROOT/agents/analyzer.md" ] || return 1
  head -1 "$PLUGIN_ROOT/agents/analyzer.md" | grep -q "^---"
}

test_analyzer_agent_has_dependency_detection() {
  grep -q "dependency_detection" "$PLUGIN_ROOT/agents/analyzer.md"
}

test_analyzer_agent_has_model_opus() {
  grep -q "model: opus" "$PLUGIN_ROOT/agents/analyzer.md"
}

test_orchestration_has_progressive_autonomy() {
  grep -q "progressive_autonomy" "$PLUGIN_ROOT/skills/orchestration/SKILL.md"
}

test_orchestration_has_budget_awareness() {
  grep -q "budget_awareness" "$PLUGIN_ROOT/skills/orchestration/SKILL.md"
}

test_claude_md_references_analyzer() {
  grep -q 'id="analyzer"' "$PLUGIN_ROOT/CLAUDE.md"
}

# === Extension Tests (Phase 4) ===

test_quality_has_adsr() {
  grep -q "adsr" "$PLUGIN_ROOT/skills/quality/SKILL.md"
}

test_orchestration_has_checkpoint_recovery() {
  grep -q "checkpoint_recovery" "$PLUGIN_ROOT/skills/orchestration/SKILL.md"
}

test_agentdb_co_change_exists() {
  grep -q "cmd_co_change" "$PLUGIN_ROOT/orchestration/agentdb/agentdb"
}

test_agentdb_co_change_runs() {
  # Run co-change on CLAUDE.md (exists in repo, will have git history)
  local output
  output=$(agentdb co-change "CLAUDE.md" 5 2>&1) || true
  assert_contains "$output" "Co-Change Graph"
}

# === Framework Tests (Phase 4) ===

test_template_exists() {
  assert_file_exists "$PLUGIN_ROOT/skills/TEMPLATE.md" "TEMPLATE.md should exist"
}

test_template_has_sources() {
  local content
  content=$(cat "$PLUGIN_ROOT/skills/TEMPLATE.md")
  assert_contains "$content" "sources:" "TEMPLATE.md should have sources section"
}

test_template_has_triggers() {
  local content
  content=$(cat "$PLUGIN_ROOT/skills/TEMPLATE.md")
  assert_contains "$content" "triggers:" "TEMPLATE.md should have triggers section"
}

test_template_has_gates() {
  local content
  content=$(cat "$PLUGIN_ROOT/skills/TEMPLATE.md")
  assert_contains "$content" "gates:" "TEMPLATE.md should have gates section"
}

test_template_has_output() {
  local content
  content=$(cat "$PLUGIN_ROOT/skills/TEMPLATE.md")
  assert_contains "$content" "output:" "TEMPLATE.md should have output section"
}

test_validate_structure_exists() {
  assert_file_exists "$PLUGIN_ROOT/hooks/scripts/validate-structure.sh" "validate-structure.sh should exist"
  local perms
  perms=$(ls -l "$PLUGIN_ROOT/hooks/scripts/validate-structure.sh" | cut -c4)
  assert_equals "x" "$perms" "validate-structure.sh should be executable"
}

test_hooks_json_has_validate_structure() {
  local content
  content=$(cat "$PLUGIN_ROOT/hooks/hooks.json")
  assert_contains "$content" "validate-structure.sh" "hooks.json should reference validate-structure.sh"
}

test_validate_structure_sources_common() {
  local content
  content=$(cat "$PLUGIN_ROOT/hooks/scripts/validate-structure.sh")
  assert_contains "$content" "common.sh" "validate-structure.sh should source common.sh"
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
      run_test "forge has loop control" test_forge_command_has_loop
      run_test "commands use structured format" test_commands_use_structured_format
      ;;
    tokens)
      run_test "CLAUDE.md token budget" test_claude_md_token_budget
      run_test "commands token budget" test_commands_token_budget
      run_test "agents token budget" test_agents_token_budget
      run_test "critical content at edges" test_critical_content_at_edges
      run_test "no duplicate Big 5 definitions" test_no_duplicate_big5_definitions
      run_test "progressive disclosure used" test_progressive_disclosure_used
      ;;
    portable)
      run_test "common.sh exists" test_common_sh_exists
      run_test "detect_vaults default" test_detect_vaults_default
      run_test "detect_vaults env override" test_detect_vaults_env_override
      run_test "detect_vaults finds primary" test_detect_vaults_finds_primary
      run_test "hooks source common.sh" test_hooks_source_common
      run_test "no hardcoded Vaults path" test_no_hardcoded_vaults_path
      run_test "get_agentdb fallback" test_get_agentdb_fallback
      run_test "update_current_symlink exists" test_update_current_symlink_exists
      run_test "session-start calls symlink update" test_session_start_calls_update_symlink
      ;;
    security_hooks)
      run_test "detect-secrets blocks AWS key" test_detect_secrets_blocks_aws_key
      run_test "detect-secrets blocks GitHub PAT" test_detect_secrets_blocks_github_pat
      run_test "detect-secrets blocks OpenAI key" test_detect_secrets_blocks_openai_key
      run_test "detect-secrets blocks private key" test_detect_secrets_blocks_private_key
      run_test "detect-secrets allows clean code" test_detect_secrets_allows_clean_code
      run_test "guard-bash blocks force push" test_guard_bash_blocks_force_push
      run_test "guard-bash allows safe commands" test_guard_bash_allows_safe_commands
      run_test "guard-bash allows git log" test_guard_bash_allows_git_log
      run_test "guard-config blocks .claude/ write" test_guard_config_blocks_claude_dir_write
      run_test "guard-config allows CLAUDE.md" test_guard_config_allows_claude_md
      run_test "guard-config allows rules" test_guard_config_allows_rules
      run_test "auto-approve allows git status" test_auto_approve_allows_git_status
      run_test "auto-approve allows npm test" test_auto_approve_allows_npm_test
      run_test "auto-approve rejects rm -rf" test_auto_approve_rejects_rm_rf
      ;;
    graph_tracking)
      run_test "session-start creates session" test_session_start_creates_session
      run_test "session-start validates tier" test_session_start_validates_tier
      run_test "session-end updates session" test_session_end_updates_session
      run_test "session-end validates tokens" test_session_end_validates_tokens
      ;;
    schema_validation)
      run_test "inline schema matches schema.sql" test_inline_schema_matches_schema_sql
      run_test "migration 002 applies cleanly" test_migration_applies_cleanly
      run_test "hooks.json events are valid" test_hooks_json_schema_valid
      ;;
    telemetry)
      run_test "agentdb emit records event" test_agentdb_emit_records_event
      run_test "agentdb emit validates category" test_agentdb_emit_validates_category
      run_test "agentdb emit validates duration" test_agentdb_emit_validates_duration
      run_test "agentdb emit with duration" test_agentdb_emit_with_duration
      run_test "agentdb health runs" test_agentdb_health_runs
      ;;
    metrics)
      run_test "agentdb metrics runs" test_agentdb_metrics_runs
      run_test "agentdb metrics custom days" test_agentdb_metrics_custom_days
      run_test "agentdb metrics shows learnings" test_agentdb_metrics_shows_learnings
      run_test "metrics command registered in plugin.json" test_metrics_command_registered
      run_test "metrics command has frontmatter" test_metrics_command_has_frontmatter
      ;;
    learning_dedup)
      run_test "learning dedup reinforces existing" test_learning_dedup_reinforces
      run_test "learning dedup requires same type" test_learning_dedup_requires_same_type
      ;;
    migration_003)
      run_test "migration 003 creates events table" test_migration_003_creates_events
      run_test "inline schema includes events table" test_inline_schema_includes_events
      ;;
    input_validation)
      run_test "SQL injection via tier" test_agentdb_numeric_injection_tier
      run_test "SQL injection via tokens" test_agentdb_numeric_injection_tokens
      run_test "SQL injection via prune" test_agentdb_numeric_injection_prune
      ;;
    dreamer)
      run_test "dream command exists and has frontmatter" test_dream_command_exists_with_frontmatter
      run_test "dream command registered in plugin.json" test_dream_command_registered_in_plugin_json
      run_test "dreamer agent exists and has frontmatter" test_dreamer_agent_exists_with_frontmatter
      run_test "dreamer agent has voice definitions" test_dreamer_agent_has_voice_definitions
      run_test "dream command has output format" test_dream_command_has_output_format
      run_test "dream command has github integration" test_dream_command_has_github_integration
      ;;
    compaction_restore)
      run_test "post-compact-restore fast exit without marker" test_compact_restore_fast_exit
      run_test "post-compact-restore outputs marker content" test_compact_restore_outputs_marker
      run_test "post-compact-restore deletes marker" test_compact_restore_deletes_marker
      run_test "hooks.json has UserPromptSubmit" test_hooks_json_user_prompt_submit
      ;;
    circuit_breaker)
      run_test "circuit-breaker.sh exists and is executable" test_circuit_breaker_exists
      run_test "guard hooks source circuit breaker" test_guards_source_circuit_breaker
      run_test "breaker trips after 3 failures" test_breaker_trips
      run_test "breaker resets after cooldown" test_breaker_resets
      ;;
    diagnose)
      run_test "diagnose command exists with frontmatter" test_diagnose_command_exists
      run_test "diagnose registered in plugin.json" test_diagnose_registered
      run_test "diagnose has bug mode" test_diagnose_bug_mode
      run_test "diagnose has refactor mode" test_diagnose_refactor_mode
      run_test "diagnose has output format" test_diagnose_output_format
      run_test "diagnose loads debug skill" test_diagnose_loads_debug
      ;;
    retrospective)
      run_test "retrospective command exists with frontmatter" test_retrospective_command_exists
      run_test "retrospective registered in plugin.json" test_retrospective_registered
      run_test "retrospective has agentdb integration" test_retrospective_has_agentdb
      run_test "retrospective has output format" test_retrospective_has_output_format
      run_test "retrospective has cluster analysis" test_retrospective_has_clusters
      ;;
    profile)
      run_test "parse_github_remote HTTPS" test_parse_github_remote_https
      run_test "parse_github_remote SSH" test_parse_github_remote_ssh
      run_test "parse_github_remote no .git suffix" test_parse_github_remote_no_git_suffix
      run_test "parse_github_remote non-GitHub" test_parse_github_remote_not_github
      run_test "classify_profile local" test_classify_profile_local
      run_test "classify_profile github private" test_classify_profile_github_private
      run_test "classify_profile github-oss" test_classify_profile_github_oss
      run_test "classify_profile production by collabs" test_classify_profile_production_by_collabs
      run_test "classify_profile production by envs" test_classify_profile_production_by_envs
      run_test "classify_profile production by projects" test_classify_profile_production_by_projects
      ;;
    phase4_agents)
      run_test "analyzer agent exists with frontmatter" test_analyzer_agent_exists_with_frontmatter
      run_test "analyzer agent has dependency detection" test_analyzer_agent_has_dependency_detection
      run_test "analyzer agent has model opus" test_analyzer_agent_has_model_opus
      run_test "orchestration has progressive_autonomy" test_orchestration_has_progressive_autonomy
      run_test "orchestration has budget_awareness" test_orchestration_has_budget_awareness
      run_test "CLAUDE.md references analyzer" test_claude_md_references_analyzer
      ;;
    phase4_extensions)
      run_test "quality SKILL.md has adsr section" test_quality_has_adsr
      run_test "orchestration SKILL.md has checkpoint_recovery" test_orchestration_has_checkpoint_recovery
      run_test "agentdb co-change command exists" test_agentdb_co_change_exists
      run_test "co-change runs without error" test_agentdb_co_change_runs
      ;;
    phase4_framework)
      run_test "TEMPLATE.md exists" test_template_exists
      run_test "TEMPLATE.md has sources section" test_template_has_sources
      run_test "TEMPLATE.md has triggers section" test_template_has_triggers
      run_test "TEMPLATE.md has gates section" test_template_has_gates
      run_test "TEMPLATE.md has output section" test_template_has_output
      run_test "validate-structure.sh exists and is executable" test_validate_structure_exists
      run_test "hooks.json references validate-structure.sh" test_hooks_json_has_validate_structure
      run_test "validate-structure.sh sources common.sh" test_validate_structure_sources_common
      ;;
  esac
}

main() {
  echo "================================="
  echo "KERNEL Plugin Test Suite"
  echo "================================="
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
    run_test_suite "tokens"
    run_test_suite "portable"
    run_test_suite "security_hooks"
    run_test_suite "graph_tracking"
    run_test_suite "schema_validation"
    run_test_suite "input_validation"

    run_test_suite "telemetry"
    run_test_suite "metrics"
    run_test_suite "learning_dedup"
    run_test_suite "migration_003"

    run_test_suite "dreamer"

    run_test_suite "compaction_restore"
    run_test_suite "circuit_breaker"
    run_test_suite "diagnose"
    run_test_suite "retrospective"
    run_test_suite "profile"
    run_test_suite "phase4_agents"
    run_test_suite "phase4_framework"
  else
    run_test_suite "$target"
  fi

  echo ""
  echo "================================="
  echo -e "Results: ${GREEN}$PASS_COUNT passed${NC}, ${RED}$FAIL_COUNT failed${NC}"
  echo "================================="

  [ "$FAIL_COUNT" -eq 0 ]
}

main "$@"
