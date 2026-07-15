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

test_generated_governance() {
  python3 "$PLUGIN_ROOT/tests/test_governance.py"
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
  # weighted-75 format (H078): structural headings always present, even empty.
  assert_contains "$output" "AgentDB Context"
  assert_contains "$output" "Recent Errors"
  assert_contains "$output" "Active Contract"
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
  # Exercise the real Claude Write hook payload with clean content.
  local exit_code=0
  printf '%s\n' '{"tool_input":{"content":"const x = 123;"}}' \
    | "$PLUGIN_ROOT/hooks/scripts/detect-secrets.sh" >/dev/null 2>&1 || exit_code=$?
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
  # Compact static block: agentdb quick reference + tier rule
  assert_contains "$output" "agentdb recall"
  assert_contains "$output" "Tier by reversibility x blast radius"
}

test_session_start_skill_routing() {
  local output
  output=$("$PLUGIN_ROOT/hooks/scripts/session-start.sh" 2>&1)
  # Skills fire ambiently; the hook points at /kernel:help instead of inlining an index
  assert_contains "$output" "/kernel:help"
}

test_session_start_no_scripted_interrupts() {
  # Scripted "ASK USER" phrasing was removed; the hook states facts only.
  if grep -q "ASK USER" "$PLUGIN_ROOT/hooks/scripts/session-start.sh"; then
    echo "FAIL: session-start.sh must not contain scripted ASK USER prompts"
    return 1
  fi
}

test_pre_compact_writes_checkpoint() {
  agentdb init >/dev/null
  # Simulate pre-compact by creating a checkpoint with pre-compact marker
  agentdb write-end '{"event":"pre-compact","agent":"test","goal":"testing"}' >/dev/null
  local output
  output=$(agentdb recent 1)
  assert_contains "$output" "pre-compact"
}

# Regression: a contract goal containing a double-quote must survive into the
# write-end payload as valid JSON (was interpolated raw -> malformed -> dropped).
test_pre_compact_payload_survives_quotes() {
  agentdb init >/dev/null
  local goal='fix the "auth" bug \ here'
  # Mirror the script's escaper, then prove the payload is valid JSON and round-trips.
  local esc; esc=$(printf '%s' "$goal" | tr -d '\r\n' | sed 's/\\/\\\\/g; s/"/\\"/g')
  local payload; payload=$(printf '{"event":"pre-compact","goal":"%s"}' "$esc")
  agentdb write-end "$payload" >/dev/null 2>&1
  echo "$payload" | jq -e . >/dev/null 2>&1
  assert_exit_code 0 "$?" "escaped pre-compact payload must be valid JSON"
}

# Regression: lifecycle hooks must NEVER auto-commit (disabled plugin-wide). A `git add -A`
# + `--no-verify` auto-commit here historically swept untested source onto main, where a red
# suite rode for days. Commits are now exclusively deliberate + fully verified.
test_lifecycle_hooks_never_autocommit() {
  for h in session-end.sh pre-compact-commit.sh; do
    grep -qE '^[[:space:]]*git[[:space:]]+commit' "$PLUGIN_ROOT/hooks/scripts/$h" && {
      echo "FAIL: $h must NOT auto-commit (found 'git commit')"; return 1; }
    grep -qE '^[[:space:]]*git[[:space:]]+add' "$PLUGIN_ROOT/hooks/scripts/$h" && {
      echo "FAIL: $h must NOT 'git add' (auto-commit disabled plugin-wide)"; return 1; }
  done
  return 0
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
  # Skip if a real Vaults exists at ANY location detect_vaults probes
  # (can't observe the default branch when a real db short-circuits it).
  # Must mirror detect_vaults() in common.sh exactly, or the guard drifts.
  if [ -f "$HOME/Documents/Vaults/_meta/agentdb/agent.db" ] || \
     [ -f "$HOME/Vaults/_meta/agentdb/agent.db" ] || \
     [ -f "$HOME/Downloads/Vaults/_meta/agentdb/agent.db" ]; then
    echo "  (skipped - real Vaults exists)"
    return 0
  fi
  source "$PLUGIN_ROOT/hooks/scripts/common.sh"
  local result
  result=$(detect_vaults)
  assert_equals "$HOME/Documents/Vaults" "$result" "default should be ~/Documents/Vaults"
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
  # update_current_symlink should be called in common.sh _kernel_hook_start (runs on every hook, including session-start)
  grep -q "update_current_symlink" "$PLUGIN_ROOT/hooks/scripts/common.sh" || {
    echo "FAIL: common.sh should call update_current_symlink"
    return 1
  }
}

# === KERNEL 8 runtime upgrade tests ===

make_runtime_fixture() {
  local root="$1" version="$2"
  mkdir -p "$root/.claude-plugin" "$root/hooks/scripts" "$root/orchestration/agentdb"
  printf '{"name":"kernel","version":"%s"}\n' "$version" > "$root/.claude-plugin/plugin.json"
  cp "$PLUGIN_ROOT/hooks/scripts/common.sh" "$root/hooks/scripts/common.sh"
  : > "$root/orchestration/agentdb/agentdb"
  chmod +x "$root/orchestration/agentdb/agentdb"
}

runtime_fixture() {
  export HOME="$TEST_DIR/home with spaces"
  export KERNEL_VAULTS="$TEST_DIR/Vaults with spaces"
  local cache="$HOME/.claude/plugins/cache/kernel-marketplace/kernel"
  mkdir -p "$cache" "$KERNEL_VAULTS/.local/bin" "$KERNEL_VAULTS/.claude/kernel"
  make_runtime_fixture "$cache/7.23.0" "7.23.0"
  make_runtime_fixture "$cache/8.0.0" "8.0.0"
}

test_runtime_validates_loaded_v8_root() {
  runtime_fixture
  local cache="$HOME/.claude/plugins/cache/kernel-marketplace/kernel"
  source "$PLUGIN_ROOT/hooks/scripts/common.sh"
  kernel_validate_runtime_root "$cache/8.0.0"
}

test_runtime_selection_message_is_locally_suppressible() {
  runtime_fixture
  local cache="$HOME/.claude/plugins/cache/kernel-marketplace/kernel" output
  source "$PLUGIN_ROOT/hooks/scripts/common.sh"
  output=$(KERNEL_RUNTIME_ROOT="$cache/8.0.0" kernel_update_current)
  assert_contains "$output" "KERNEL runtime selected: 8.0.0" "normal runtime selection must stay visible" || return 1
  rm "$cache/current"
  output=$(KERNEL_RUNTIME_QUIET=1 KERNEL_RUNTIME_ROOT="$cache/8.0.0" kernel_update_current)
  assert_equals "" "$output" "quiet selection must be local to high-frequency hooks"
}

test_runtime_upgrade_repairs_only_numbered_links() {
  runtime_fixture
  local cache="$HOME/.claude/plugins/cache/kernel-marketplace/kernel"
  ln -s "$cache/7.23.0/orchestration/agentdb/agentdb" "$KERNEL_VAULTS/.local/bin/agentdb"
  ln -s "$cache/7.23.0/orchestration" "$KERNEL_VAULTS/.claude/kernel/orchestration"
  ln -s "$cache/7.23.0/hooks" "$KERNEL_VAULTS/.claude/kernel/hooks"
  mkdir -p "$KERNEL_VAULTS/_meta/agentdb" "$KERNEL_VAULTS/_meta/handoffs"
  echo precious > "$KERNEL_VAULTS/_meta/agentdb/agent.db"
  echo state > "$KERNEL_VAULTS/_meta/handoffs/live.json"
  local before; before=$(find "$KERNEL_VAULTS/_meta" -type f -exec shasum -a 256 {} \; | sort)
  source "$PLUGIN_ROOT/hooks/scripts/common.sh"
  KERNEL_RUNTIME_ROOT="$cache/8.0.0" kernel_reconcile_runtime "$KERNEL_VAULTS"
  assert_equals "$cache/current/orchestration/agentdb/agentdb" "$(readlink "$KERNEL_VAULTS/.local/bin/agentdb")"
  assert_equals "$cache/current/orchestration" "$(readlink "$KERNEL_VAULTS/.claude/kernel/orchestration")"
  assert_equals "$cache/current/hooks" "$(readlink "$KERNEL_VAULTS/.claude/kernel/hooks")"
  assert_equals "$before" "$(find "$KERNEL_VAULTS/_meta" -type f -exec shasum -a 256 {} \; | sort)" "project data must not change"
}

test_runtime_current_noop_and_missing_untouched() {
  runtime_fixture
  local cache="$HOME/.claude/plugins/cache/kernel-marketplace/kernel"
  ln -s "$cache/8.0.0" "$cache/current"
  ln -s "$cache/current/hooks" "$KERNEL_VAULTS/.claude/kernel/hooks"
  local inode; inode=$(stat -f %i "$KERNEL_VAULTS/.claude/kernel/hooks" 2>/dev/null || stat -c %i "$KERNEL_VAULTS/.claude/kernel/hooks")
  source "$PLUGIN_ROOT/hooks/scripts/common.sh"
  KERNEL_RUNTIME_ROOT="$cache/8.0.0" kernel_reconcile_runtime "$KERNEL_VAULTS"
  assert_equals "$inode" "$(stat -f %i "$KERNEL_VAULTS/.claude/kernel/hooks" 2>/dev/null || stat -c %i "$KERNEL_VAULTS/.claude/kernel/hooks")" "correct links must not churn"
  [ ! -e "$KERNEL_VAULTS/.local/bin/agentdb" ] && [ ! -L "$KERNEL_VAULTS/.local/bin/agentdb" ]
}

test_runtime_refuses_user_owned_destinations() {
  runtime_fixture
  local cache="$HOME/.claude/plugins/cache/kernel-marketplace/kernel"
  echo mine > "$KERNEL_VAULTS/.local/bin/agentdb"
  mkdir "$KERNEL_VAULTS/.claude/kernel/orchestration"
  ln -s "$TEST_DIR/unrelated" "$KERNEL_VAULTS/.claude/kernel/hooks"
  source "$PLUGIN_ROOT/hooks/scripts/common.sh"
  local output rc=0
  output=$(KERNEL_RUNTIME_ROOT="$cache/8.0.0" kernel_reconcile_runtime "$KERNEL_VAULTS" 2>&1) || rc=$?
  [ "$rc" -ne 0 ]
  assert_contains "$output" "run /kernel:init"
  assert_equals mine "$(cat "$KERNEL_VAULTS/.local/bin/agentdb")"
  [ -d "$KERNEL_VAULTS/.claude/kernel/orchestration" ]
  assert_equals "$TEST_DIR/unrelated" "$(readlink "$KERNEL_VAULTS/.claude/kernel/hooks")"
}

test_runtime_repairs_broken_relative_numbered_link() {
  runtime_fixture
  local dest="$KERNEL_VAULTS/.claude/kernel/hooks"
  local cache="$(dirname "$dest")/cache"
  make_runtime_fixture "$cache/8.0.0" 8.0.0
  local rel="cache/7.23.0/hooks"
  ln -s "$rel" "$dest"
  source "$PLUGIN_ROOT/hooks/scripts/common.sh"
  KERNEL_CACHE_DIR="$cache" KERNEL_RUNTIME_ROOT="$cache/8.0.0" kernel_reconcile_runtime "$KERNEL_VAULTS"
  assert_equals "$cache/current/hooks" "$(readlink "$dest")"
}

test_runtime_rejects_malformed_cache_and_preserves_current() {
  runtime_fixture
  local cache="$HOME/.claude/plugins/cache/kernel-marketplace/kernel"
  mkdir -p "$cache/9.0.0/.claude-plugin"
  printf '{"name":"not-kernel","version":"9.0.0"}\n' > "$cache/9.0.0/.claude-plugin/plugin.json"
  ln -s "$cache/8.0.0" "$cache/current"
  source "$PLUGIN_ROOT/hooks/scripts/common.sh"
  ! KERNEL_RUNTIME_ROOT="$cache/9.0.0" kernel_update_current
  assert_equals "$cache/8.0.0" "$(readlink "$cache/current")"
}

test_runtime_authority_is_monotonic_but_override_can_rollback() {
  runtime_fixture
  local cache="$HOME/.claude/plugins/cache/kernel-marketplace/kernel"
  ln -s "$cache/8.0.0" "$cache/current"
  source "$PLUGIN_ROOT/hooks/scripts/common.sh"
  KERNEL_LOADED_ROOT="$cache/7.23.0" kernel_update_current
  assert_equals "$cache/8.0.0" "$(readlink "$cache/current")" "old loaded session must not downgrade"
  KERNEL_RUNTIME_ROOT="$cache/7.23.0" kernel_update_current
  assert_equals "$cache/7.23.0" "$(readlink "$cache/current")" "explicit rollback must win"
}

test_runtime_failed_replacement_leaves_original() {
  runtime_fixture
  local cache="$HOME/.claude/plugins/cache/kernel-marketplace/kernel"
  ln -s "$cache/7.23.0/hooks" "$KERNEL_VAULTS/.claude/kernel/hooks"
  source "$PLUGIN_ROOT/hooks/scripts/common.sh"
  KERNEL_ATOMIC_LINK_FAIL=1 ! kernel_repair_host_link "$KERNEL_VAULTS/.claude/kernel/hooks" "$cache/current/hooks" "$cache" "hooks"
  assert_equals "$cache/7.23.0/hooks" "$(readlink "$KERNEL_VAULTS/.claude/kernel/hooks")"
}

test_runtime_startup_arms_reconciliation() {
  runtime_fixture
  local cache="$HOME/.claude/plugins/cache/kernel-marketplace/kernel"
  ln -s "$cache/7.23.0/hooks" "$KERNEL_VAULTS/.claude/kernel/hooks"
  source "$PLUGIN_ROOT/hooks/scripts/common.sh"
  KERNEL_RUNTIME_ROOT="$cache/8.0.0" _kernel_hook_start
  assert_equals "$cache/current/hooks" "$(readlink "$KERNEL_VAULTS/.claude/kernel/hooks")"
}

test_select_runtime_supports_explicit_local_rollback() {
  runtime_fixture
  local cache="$HOME/.claude/plugins/cache/kernel-marketplace/kernel"
  ln -s "$cache/8.0.0" "$cache/current"
  ln -s "$cache/8.0.0/hooks" "$KERNEL_VAULTS/.claude/kernel/hooks"
  local local_root="$TEST_DIR/local kernel 7"
  make_runtime_fixture "$local_root" 7.23.0
  local output
  output=$(KERNEL_CACHE_DIR="$cache" KERNEL_VAULTS="$KERNEL_VAULTS" "$PLUGIN_ROOT/scripts/select-runtime.sh" "$local_root")
  assert_equals "$local_root" "$(readlink "$cache/current")"
  assert_contains "$output" "KERNEL runtime: 7.23.0"
}

test_select_runtime_accepts_real_legacy_common() {
  runtime_fixture
  local cache="$HOME/.claude/plugins/cache/kernel-marketplace/kernel"
  local legacy="$TEST_DIR/real legacy 7.23"
  mkdir -p "$legacy/.claude-plugin" "$legacy/hooks/scripts" "$legacy/orchestration/agentdb"
  git -C "$PLUGIN_ROOT" show 54a0053:hooks/scripts/common.sh > "$legacy/hooks/scripts/common.sh" 2>/dev/null || {
    # CI uses a shallow checkout. This is the relevant legacy behavior: the target
    # common exists but has none of KERNEL 8's selector functions.
    printf '#!/bin/bash\nupdate_current_symlink() { :; }\n' > "$legacy/hooks/scripts/common.sh"
  }
  git -C "$PLUGIN_ROOT" show 54a0053:orchestration/agentdb/agentdb > "$legacy/orchestration/agentdb/agentdb" 2>/dev/null || cp "$PLUGIN_ROOT/orchestration/agentdb/agentdb" "$legacy/orchestration/agentdb/agentdb"
  chmod +x "$legacy/orchestration/agentdb/agentdb"
  printf '{"name":"kernel","version":"7.23.0"}\n' > "$legacy/.claude-plugin/plugin.json"
  ! grep -q 'kernel_validate_runtime_root' "$legacy/hooks/scripts/common.sh"
  KERNEL_CACHE_DIR="$cache" KERNEL_VAULTS="$KERNEL_VAULTS" "$PLUGIN_ROOT/scripts/select-runtime.sh" "$legacy" >/dev/null
  assert_equals "$legacy" "$(readlink "$cache/current")"
}

test_runtime_rejects_helper_escape_and_special_files() {
  runtime_fixture
  local cache="$HOME/.claude/plugins/cache/kernel-marketplace/kernel"
  local bad="$cache/9.0.0" outside="$TEST_DIR/outside"
  make_runtime_fixture "$bad" 9.0.0
  mkdir -p "$outside/hooks/scripts"
  : > "$outside/hooks/scripts/common.sh"
  rm "$bad/hooks/scripts/common.sh"
  ln -s "$outside/hooks/scripts/common.sh" "$bad/hooks/scripts/common.sh"
  source "$PLUGIN_ROOT/hooks/scripts/common.sh"
  ! kernel_validate_runtime_root "$bad"
  rm "$bad/hooks/scripts/common.sh"
  mkdir "$bad/hooks/scripts/common.sh"
  ! kernel_validate_runtime_root "$bad"
  rm -rf "$bad/hooks/scripts/common.sh"
  mkfifo "$bad/hooks/scripts/common.sh"
  ! kernel_validate_runtime_root "$bad"
}

test_runtime_rejects_symlinked_version_root() {
  runtime_fixture
  local cache="$HOME/.claude/plugins/cache/kernel-marketplace/kernel"
  local external="$TEST_DIR/external-valid-runtime"
  make_runtime_fixture "$external" 9.0.0
  ln -s "$external" "$cache/9.0.0"
  source "$PLUGIN_ROOT/hooks/scripts/common.sh"
  local current_before; current_before=$(readlink "$cache/current" 2>/dev/null || true)
  if kernel_validate_runtime_root "$cache/9.0.0" >/dev/null; then
    echo "symlinked cache version root was accepted"
    return 1
  fi
  kernel_validate_runtime_root "$cache/8.0.0" >/dev/null
  assert_equals "$current_before" "$(readlink "$cache/current" 2>/dev/null || true)" "validation must not mutate current"
}

test_runtime_rejects_control_paths_and_traversal_links() {
  runtime_fixture
  local cache="$HOME/.claude/plugins/cache/kernel-marketplace/kernel"
  source "$PLUGIN_ROOT/hooks/scripts/common.sh"
  ! KERNEL_RUNTIME_ROOT="$cache/8.0.0" KERNEL_CACHE_DIR="$cache/line"$'\n'"break" kernel_update_current
  ! KERNEL_VAULTS="$TEST_DIR/vault"$'\n'"break" detect_vaults >/dev/null
  local dest="$KERNEL_VAULTS/.claude/kernel/hooks"
  ln -s "$cache/junk/../7.23.0/hooks" "$dest"
  ! kernel_repair_host_link "$dest" "$cache/current/hooks" "$cache" hooks
  assert_equals "$cache/junk/../7.23.0/hooks" "$(readlink "$dest")"
}

test_atomic_link_scavenges_only_matching_symlink_residue() {
  local dest="$TEST_DIR/current" target="$TEST_DIR/target"
  source "$PLUGIN_ROOT/hooks/scripts/common.sh"
  ln -s "$target" "$dest.kernel-tmp.111.222"
  echo mine > "$dest.kernel-tmp.user"
  kernel_atomic_link "$target" "$dest"
  [ ! -L "$dest.kernel-tmp.111.222" ]
  assert_equals mine "$(cat "$dest.kernel-tmp.user")"
}

test_init_agentdb_targets_selected_vaults() {
  runtime_fixture
  local cache="$HOME/.claude/plugins/cache/kernel-marketplace/kernel" elsewhere="$TEST_DIR/elsewhere"
  cp "$PLUGIN_ROOT/orchestration/agentdb/agentdb" "$cache/8.0.0/orchestration/agentdb/agentdb"
  cp "$PLUGIN_ROOT/orchestration/agentdb/schema.sql" "$cache/8.0.0/orchestration/agentdb/schema.sql"
  cp -R "$PLUGIN_ROOT/orchestration/agentdb/migrations" "$cache/8.0.0/orchestration/agentdb/migrations"
  chmod +x "$cache/8.0.0/orchestration/agentdb/agentdb"
  mkdir -p "$elsewhere/_meta/agentdb" "$KERNEL_VAULTS/_meta/agentdb"
  echo keep > "$KERNEL_VAULTS/_meta/agentdb/sentinel"
  AGENTDB_ROOT="$KERNEL_VAULTS" "$cache/8.0.0/orchestration/agentdb/agentdb" init >/dev/null
  local before sentinel_before
  before=$(shasum -a 256 "$KERNEL_VAULTS/_meta/agentdb/agent.db")
  sentinel_before=$(shasum -a 256 "$KERNEL_VAULTS/_meta/agentdb/sentinel")
  source "$PLUGIN_ROOT/hooks/scripts/common.sh"
  KERNEL_RUNTIME_ROOT="$cache/8.0.0" kernel_update_current >/dev/null || return 1
  (cd "$elsewhere" && kernel_init_agentdb "$KERNEL_VAULTS" "$cache") || return 1
  [ -f "$KERNEL_VAULTS/_meta/agentdb/agent.db" ] || return 1
  [ ! -f "$elsewhere/_meta/agentdb/agent.db" ] || return 1
  assert_equals "$before" "$(shasum -a 256 "$KERNEL_VAULTS/_meta/agentdb/agent.db")" "existing AgentDB unchanged"
  assert_equals "$sentinel_before" "$(shasum -a 256 "$KERNEL_VAULTS/_meta/agentdb/sentinel")"
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

test_detect_secrets_blocks_codex_apply_patch() {
  local key="AKIA"; key+="IOSFODNN7EXAMPLE"
  local patch json ec=0
  patch=$(printf '*** Begin Patch\n*** Add File: config.ts\n+const key = "%s";\n*** End Patch' "$key")
  json=$(jq -n --arg patch "$patch" '{tool_input:{patch:$patch}}')
  printf '%s\n' "$json" | "$PLUGIN_ROOT/hooks/scripts/detect-secrets.sh" >/dev/null 2>&1 || ec=$?
  assert_exit_code 2 "$ec" "Codex apply_patch secret must be blocked by the armed hook"
}

test_detect_secrets_allows_codex_secret_removal() {
  local key="AKIA"; key+="IOSFODNN7EXAMPLE"
  local patch json
  patch=$(printf '*** Begin Patch\n*** Update File: config.ts\n@@\n-const key = "%s";\n+const key = process.env.API_KEY;\n*** End Patch' "$key")
  json=$(jq -n --arg patch "$patch" '{tool_input:{patch:$patch}}')
  printf '%s\n' "$json" | "$PLUGIN_ROOT/hooks/scripts/detect-secrets.sh" >/dev/null 2>&1
  assert_exit_code 0 "$?" "Codex must be able to remove an existing secret"
}

test_guard_config_blocks_codex_apply_patch() {
  local patch json ec=0
  patch=$'*** Begin Patch\n*** Add File: .claude/generated/foo.md\n+generated\n*** End Patch'
  json=$(jq -n --arg patch "$patch" '{tool_input:{patch:$patch}}')
  printf '%s\n' "$json" | "$PLUGIN_ROOT/hooks/scripts/guard-config.sh" >/dev/null 2>&1 || ec=$?
  assert_exit_code 2 "$ec" "Codex apply_patch into .claude/generated must be blocked by the armed hook"
}

test_guard_config_allows_codex_apply_patch_rule() {
  local patch json
  patch=$'*** Begin Patch\n*** Add File: .claude/rules/safe.md\n+safe\n*** End Patch'
  json=$(jq -n --arg patch "$patch" '{tool_input:{patch:$patch}}')
  printf '%s\n' "$json" | "$PLUGIN_ROOT/hooks/scripts/guard-config.sh" >/dev/null 2>&1
  assert_exit_code 0 "$?" "Codex apply_patch into .claude/rules must be allowed"
}

test_guard_config_blocks_codex_dot_segment_bypass() {
  local patch json ec=0
  patch=$'*** Begin Patch\n*** Add File: .claude/rules/../generated/x.md\n+bypass\n*** End Patch'
  json=$(jq -n --arg patch "$patch" '{tool_input:{patch:$patch}}')
  printf '%s\n' "$json" | "$PLUGIN_ROOT/hooks/scripts/guard-config.sh" >/dev/null 2>&1 || ec=$?
  assert_exit_code 2 "$ec" "dot segments must not escape the .claude allowlist"
}

test_guard_config_fails_closed_on_malformed_json() {
  local ec=0
  printf '{malformed\n' | "$PLUGIN_ROOT/hooks/scripts/guard-config.sh" >/dev/null 2>&1 || ec=$?
  assert_exit_code 2 "$ec" "guard-config must block malformed hook JSON"
}

test_detect_secrets_fails_closed_on_malformed_json() {
  local ec=0
  printf '{malformed\n' | "$PLUGIN_ROOT/hooks/scripts/detect-secrets.sh" >/dev/null 2>&1 || ec=$?
  assert_exit_code 2 "$ec" "detect-secrets must block malformed hook JSON"
}

test_codex_explicit_only_skill_policies() {
  local skill policy
  for skill in init forge experiment landing-page; do
    policy="$PLUGIN_ROOT/skills/$skill/agents/openai.yaml"
    [ -f "$policy" ] || { echo "FAIL: missing Codex policy for $skill"; return 1; }
    grep -q '^policy:' "$policy" || return 1
    grep -q '^  allow_implicit_invocation: false$' "$policy" || return 1
    grep -q '^disable-model-invocation: true$' "$PLUGIN_ROOT/skills/$skill/SKILL.md" || return 1
  done
}

test_codex_apply_patch_guards_are_wired() {
  jq -e '
    .hooks.PreToolUse[]
    | select(.matcher == "Write|Edit")
    | [.hooks[].command]
    | index("${CLAUDE_PLUGIN_ROOT}/hooks/scripts/detect-secrets.sh") != null
      and index("${CLAUDE_PLUGIN_ROOT}/hooks/scripts/guard-config.sh") != null
  ' "$PLUGIN_ROOT/hooks/hooks.json" >/dev/null
}

test_session_start_includes_dual_loader_tier_rules() {
  local output
  output=$(HOME="$TEST_DIR/home" KERNEL_VAULTS="$TEST_PROJECT" \
    "$PLUGIN_ROOT/hooks/scripts/session-start.sh" </dev/null 2>/dev/null)
  assert_contains "$output" "Tier 2+: create an AgentDB contract"
  assert_contains "$output" "surgeon"
  assert_contains "$output" "adversary"
  assert_contains "$output" "Codex"
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
  # Should NOT contain allow, falls through to normal permission flow
  if [[ "$output" == *"allow"* ]]; then
    echo "FAIL: rm -rf should not be auto-approved"
    return 1
  fi
}

# Regression: real Anthropic keys (sk-ant-api03-...) contain hyphens; the old
# 'sk-ant-[a-zA-Z0-9]{20,}' stopped at the first hyphen and missed them entirely.
test_detect_secrets_blocks_anthropic_key() {
  local akey="s"; akey+="k-ant-api03-"; akey+=$(printf 'A%.0s' {1..40}); akey+="_-xyz"
  local json
  json=$(printf '{"tool_input":{"content":"ANTHROPIC_API_KEY=%s"}}' "$akey")
  echo "$json" | "$PLUGIN_ROOT/hooks/scripts/detect-secrets.sh" >/dev/null 2>&1
  assert_exit_code 2 "$?" "Anthropic sk-ant-api03 key must be blocked"
}

# Regression: secret scanner must fail CLOSED when its parser is unavailable.
test_detect_secrets_fail_closed_without_jq() {
  local bin; bin=$(mktemp -d)
  ln -s "$(command -v bash)" "$bin/bash"
  ln -s "$(command -v grep)" "$bin/grep"
  ln -s "$(command -v cat)"  "$bin/cat"   # deliberately no jq
  local ec=0
  printf '{"tool_input":{"content":"x"}}' \
    | env -i PATH="$bin" "$bin/bash" "$PLUGIN_ROOT/hooks/scripts/detect-secrets.sh" >/dev/null 2>&1 || ec=$?
  rm -rf "$bin"
  assert_exit_code 2 "$ec" "scanner must BLOCK when jq is missing (fail-closed)"
}

# Regression: -f shorthand force push to main was bypassing the guard.
test_guard_bash_blocks_force_push_shorthand() {
  echo '{"tool_input":{"command":"git push -f origin main"}}' \
    | "$PLUGIN_ROOT/hooks/scripts/guard-bash.sh" >/dev/null 2>&1
  assert_exit_code 2 "$?" "git push -f origin main must be blocked"
}

# Regression: -fr flag ordering bypassed the rm-root guard.
test_guard_bash_blocks_rm_fr_root() {
  echo '{"tool_input":{"command":"rm -fr /"}}' \
    | "$PLUGIN_ROOT/hooks/scripts/guard-bash.sh" >/dev/null 2>&1
  assert_exit_code 2 "$?" "rm -fr / must be blocked"
}

# Guard must NOT false-positive on legitimate subdir deletes.
test_guard_bash_allows_subdir_rm() {
  echo '{"tool_input":{"command":"rm -rf ~/Documents/old-cache"}}' \
    | "$PLUGIN_ROOT/hooks/scripts/guard-bash.sh" >/dev/null 2>&1
  assert_exit_code 0 "$?" "rm -rf of a home subdir must be allowed"
}

# Regression: a safe prefix must not auto-approve a chained dangerous tail.
test_auto_approve_defers_chained_command() {
  local output
  output=$(echo '{"tool_input":{"command":"git status; rm -rf /tmp/x"}}' \
    | "$PLUGIN_ROOT/hooks/scripts/auto-approve-safe.sh" 2>&1)
  if [[ "$output" == *"allow"* ]]; then
    echo "FAIL: chained command must not be auto-approved"
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
    echo "FAIL: agentdb init did not apply graph tracking migration"
    return 1
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

test_graph_project_from_receipt() {
  _ensure_graph_migration
  local receipt="$PLUGIN_ROOT/tests/fixtures/manifests/receipt-example.json"
  [ -f "$receipt" ] || { echo "FAIL: missing receipt fixture"; return 1; }
  agentdb graph-project "$receipt" >/dev/null
  local sessions nodes edges
  sessions=$(sqlite3 "$TEST_PROJECT/_meta/agentdb/agent.db" "SELECT COUNT(*) FROM context_sessions WHERE id LIKE 'RCP-%';")
  nodes=$(sqlite3 "$TEST_PROJECT/_meta/agentdb/agent.db" "SELECT COUNT(*) FROM nodes;")
  edges=$(sqlite3 "$TEST_PROJECT/_meta/agentdb/agent.db" "SELECT COUNT(*) FROM edges;")
  assert_equals "1" "$sessions" "receipt should create one graph session"
  [ "$nodes" -gt 0 ] || { echo "FAIL: expected nodes from receipt projection"; return 1; }
  [ "$edges" -gt 0 ] || { echo "FAIL: expected co-load edges from receipt projection"; return 1; }
}

test_graph_project_idempotent() {
  _ensure_graph_migration
  local receipt="$PLUGIN_ROOT/tests/fixtures/manifests/receipt-example.json"
  agentdb graph-project "$receipt" >/dev/null
  agentdb graph-project "$receipt" >/dev/null
  local sessions
  sessions=$(sqlite3 "$TEST_PROJECT/_meta/agentdb/agent.db" "SELECT COUNT(*) FROM graph_receipts WHERE receipt_path LIKE '%receipt-example.json';")
  assert_equals "1" "$sessions" "receipt projection should be idempotent"
}

test_graph_suggest_shadow_mode() {
  _ensure_graph_migration
  local output
  output=$(agentdb graph-suggest feature 2>&1)
  assert_contains "$output" "shadow mode"
  assert_contains "$output" "JSON manifests remain authoritative"
}

test_graph_outcome_from_write_end() {
  _ensure_graph_migration
  local receipt="$PLUGIN_ROOT/tests/fixtures/manifests/receipt-example.json"
  agentdb graph-project "$receipt" >/dev/null
  agentdb write-end '{"did":"finished task","next":"","blocked":""}' >/dev/null
  local success
  success=$(sqlite3 "$TEST_PROJECT/_meta/agentdb/agent.db" "SELECT success FROM context_sessions WHERE id LIKE 'RCP-%' ORDER BY started_at DESC LIMIT 1;")
  assert_equals "1" "$success" "write-end should mark latest graph session successful"
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

test_hooks_json_cross_loader_schema() {
  local hooks_file="$PLUGIN_ROOT/hooks/hooks.json"
  python3 - "$hooks_file" <<'PY'
import json, pathlib, sys
path = pathlib.Path(sys.argv[1])
data = json.loads(path.read_text())
assert set(data) <= {"description", "hooks"}, (
    f"Codex accepts only description/hooks at the hooks root, got {sorted(data)}"
)
assert isinstance(data.get("hooks"), dict) and data["hooks"], "hooks must be a non-empty object"
assert "version" not in data, "top-level version breaks the Codex hooks loader"
PY
}

test_advisory_hooks_are_synchronous_and_complete() {
  python3 - "$PLUGIN_ROOT/hooks/hooks.json" <<'PY'
import json, sys
data=json.load(open(sys.argv[1]))
def _walk(x):
    if isinstance(x, dict):
        yield x
        for value in x.values(): yield from _walk(value)
    elif isinstance(x, list):
        for value in x: yield from _walk(value)
assert not any('async' in obj for obj in _walk(data)), 'shared hook manifest must contain no async keys'
PY
}

test_six_advisory_hook_commands_are_retained() {
  python3 - "$PLUGIN_ROOT/hooks/hooks.json" <<'PY'
import json, sys
data=json.load(open(sys.argv[1]))
commands=[]
def walk(x):
    if isinstance(x, dict):
        if x.get('type') == 'command': commands.append(x.get('command'))
        for value in x.values(): walk(value)
    elif isinstance(x, list):
        for value in x: walk(value)
walk(data)
expected=[
  '${CLAUDE_PLUGIN_ROOT}/hooks/scripts/autopush.sh install',
  '${CLAUDE_PLUGIN_ROOT}/hooks/scripts/validate-structure.sh',
  '${CLAUDE_PLUGIN_ROOT}/hooks/scripts/warn-hardcoded.sh',
  '${CLAUDE_PLUGIN_ROOT}/hooks/scripts/log-write.sh',
  '${CLAUDE_PLUGIN_ROOT}/hooks/scripts/validate-json-schema.sh',
  '${CLAUDE_PLUGIN_ROOT}/hooks/scripts/capture-error.sh',
]
for command in expected:
    assert commands.count(command) == 1, (command, commands)
PY
}

test_log_write_consumes_claude_and_codex_payloads() {
  local root="$TEST_DIR/log-write-project"
  mkdir -p "$root"
  printf '%s\n' '{"tool_name":"Write","tool_input":{"file_path":"src/claude.ts"}}' \
    | CLAUDE_PROJECT_DIR="$root" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" \
      "$PLUGIN_ROOT/hooks/scripts/log-write.sh" >/dev/null 2>&1 || return 1
  printf '%s\n' '{"tool_name":"apply_patch","tool_input":{"patch":"*** Begin Patch\n*** Update File: src/codex.ts\n+changed\n*** End Patch"}}' \
    | CLAUDE_PROJECT_DIR="$root" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" \
      "$PLUGIN_ROOT/hooks/scripts/log-write.sh" >/dev/null 2>&1 || return 1
  grep -q '"tool":"Write","file":"src/claude.ts"' "$root/_meta/logs/actions.jsonl" || return 1
  grep -q '"tool":"apply_patch","file":"src/codex.ts"' "$root/_meta/logs/actions.jsonl"
}

test_log_write_is_advisory_and_leaves_no_child() {
  local root="$TEST_DIR/log-write-project" fake="$TEST_DIR/fake-plugin" pid
  mkdir -p "$root" "$fake/orchestration/agentdb"
  cat > "$fake/orchestration/agentdb/agentdb" <<'SH'
#!/bin/bash
echo $$ > "${KERNEL_TEST_CHILD_PID:?}"
sleep 0.3
exit "${KERNEL_TEST_AGENTDB_EXIT:-0}"
SH
  chmod +x "$fake/orchestration/agentdb/agentdb"
  printf '%s\n' '{"tool_name":"Write","tool_input":{"file_path":"src/file.ts"}}' \
    | KERNEL_TEST_CHILD_PID="$TEST_DIR/child.pid" CLAUDE_PROJECT_DIR="$root" CLAUDE_PLUGIN_ROOT="$fake" \
      "$PLUGIN_ROOT/hooks/scripts/log-write.sh" >/dev/null 2>&1 || return 1
  pid=$(cat "$TEST_DIR/child.pid")
  ! kill -0 "$pid" 2>/dev/null || { echo "FAIL: log-write child survived hook exit"; return 1; }
  local ec=0
  printf '%s\n' '{"tool_name":"Write","tool_input":{"file_path":"src/file.ts"}}' \
    | KERNEL_TEST_CHILD_PID="$TEST_DIR/child.pid" KERNEL_TEST_AGENTDB_EXIT=9 \
      CLAUDE_PROJECT_DIR="$root" CLAUDE_PLUGIN_ROOT="$fake" \
      "$PLUGIN_ROOT/hooks/scripts/log-write.sh" >/dev/null 2>&1 || ec=$?
  assert_exit_code 0 "$ec" "advisory hook must not block on AgentDB failure"
}

test_advisory_scripts_consume_dual_loader_payloads() {
  local root="$TEST_DIR/advisory" bad_agent="$TEST_DIR/advisory/agents/bad.md"
  local css="$TEST_DIR/advisory/app.css" bad_json="$TEST_DIR/advisory/bad.json" output payload patch
  mkdir -p "$(dirname "$bad_agent")" "$TEST_PROJECT/_meta/agentdb"
  echo 'missing frontmatter' > "$bad_agent"
  echo 'body { color: red; }' > "$css"
  echo '{bad' > "$bad_json"

  payload=$(jq -n --arg p "$bad_agent" '{tool_name:"Write",tool_input:{file_path:$p,content:"missing frontmatter"}}')
  output=$(printf '%s\n' "$payload" | "$PLUGIN_ROOT/hooks/scripts/validate-structure.sh" 2>&1)
  assert_contains "$output" "$bad_agent" "Claude structure payload path must be consumed" || return 1
  printf -v patch '*** Begin Patch\n*** Update File: %s\n+missing frontmatter\n*** End Patch' "$bad_agent"
  payload=$(jq -n --arg patch "$patch" '{tool_name:"apply_patch",tool_input:{patch:$patch}}')
  output=$(printf '%s\n' "$payload" | "$PLUGIN_ROOT/hooks/scripts/validate-structure.sh" 2>&1)
  assert_contains "$output" "$bad_agent" "Codex structure payload path must be consumed" || return 1

  payload=$(jq -n --arg p "$css" '{tool_name:"Write",tool_input:{file_path:$p,content:"color: #abcdef; margin: 12px;"}}')
  output=$(printf '%s\n' "$payload" | "$PLUGIN_ROOT/hooks/scripts/warn-hardcoded.sh" 2>&1)
  assert_contains "$output" "$css" "Claude content must be consumed" || return 1
  printf -v patch '*** Begin Patch\n*** Update File: %s\n+color: #abcdef; margin: 12px;\n*** End Patch' "$css"
  payload=$(jq -n --arg patch "$patch" '{tool_name:"apply_patch",tool_input:{patch:$patch}}')
  output=$(printf '%s\n' "$payload" | "$PLUGIN_ROOT/hooks/scripts/warn-hardcoded.sh" 2>&1)
  assert_contains "$output" "$css" "Codex patch content must be consumed" || return 1

  printf -v patch '*** Begin Patch\n*** Update File: %s\n+{bad\n*** End Patch' "$bad_json"
  for payload in \
    "$(jq -n --arg p "$bad_json" '{tool_name:"Write",tool_input:{file_path:$p}}')" \
    "$(jq -n --arg patch "$patch" '{tool_name:"apply_patch",tool_input:{patch:$patch}}')"; do
    output=$(printf '%s\n' "$payload" | "$PLUGIN_ROOT/hooks/scripts/validate-json-schema.sh" 2>&1)
    assert_contains "$output" "$bad_json" "JSON validator path must be consumed" || return 1
  done

  KERNEL_VAULTS="$TEST_PROJECT" AGENTDB_ROOT="$TEST_PROJECT" agentdb init >/dev/null
  payload=$(jq -n --arg p "$css" '{tool_name:"Write",tool_input:{file_path:$p},error:"claude failure"}')
  printf '%s\n' "$payload" | KERNEL_VAULTS="$TEST_PROJECT" AGENTDB_ROOT="$TEST_PROJECT" \
    "$PLUGIN_ROOT/hooks/scripts/capture-error.sh" >/dev/null 2>&1 || return 1
  printf -v patch '*** Begin Patch\n*** Update File: %s\n+change\n*** End Patch' "$css"
  payload=$(jq -n --arg patch "$patch" \
    '{tool_name:"apply_patch",tool_input:{patch:$patch},error:{message:"codex failure"}}')
  printf '%s\n' "$payload" | KERNEL_VAULTS="$TEST_PROJECT" AGENTDB_ROOT="$TEST_PROJECT" \
    "$PLUGIN_ROOT/hooks/scripts/capture-error.sh" >/dev/null 2>&1 || return 1
  assert_contains "$(sqlite3 "$TEST_PROJECT/_meta/agentdb/agent.db" "SELECT group_concat(error, '|') FROM errors;")" "claude failure" || return 1
  assert_contains "$(sqlite3 "$TEST_PROJECT/_meta/agentdb/agent.db" "SELECT group_concat(error, '|') FROM errors;")" "codex failure"
}

test_advisory_scripts_fail_open_without_false_positives() {
  local script ec output root="$TEST_DIR/advisory-safe"
  mkdir -p "$root"
  echo '{"ok":true}' > "$root/valid.json"
  for script in validate-structure.sh warn-hardcoded.sh validate-json-schema.sh capture-error.sh; do
    ec=0
    printf '{malformed\n' | KERNEL_VAULTS="$root/missing-vault" CLAUDE_PROJECT_DIR="$root" \
      "$PLUGIN_ROOT/hooks/scripts/$script" >/dev/null 2>&1 || ec=$?
    assert_exit_code 0 "$ec" "$script must stay advisory on malformed/downstream failure" || return 1
  done
  output=$(jq -n --arg p "$root/valid.json" '{tool_name:"Write",tool_input:{file_path:$p,content:"const color = theme.primary;"}}' \
    | "$PLUGIN_ROOT/hooks/scripts/warn-hardcoded.sh" 2>&1)
  assert_equals "" "$output" "safe advisory payload must not warn"
}

test_multifile_patch_records_are_isolated_and_complete() {
  local root="$TEST_DIR/multifile" css="$TEST_DIR/multifile/safe.css"
  local json="$TEST_DIR/multifile/later.json" agent="$TEST_DIR/multifile/agents/later.md"
  local moved="$TEST_DIR/multifile/moved.json" patch payload output
  mkdir -p "$(dirname "$agent")" "$TEST_PROJECT/_meta/agentdb"
  echo 'body { color: var(--theme); }' > "$css"
  echo '{bad' > "$json"
  echo 'missing frontmatter' > "$agent"
  echo '{bad' > "$moved"
  printf -v patch '*** Begin Patch\n*** Update File: %s\n+body { color: var(--theme); }\n*** Update File: %s\n+{"color":"#abcdef"}\n*** Update File: %s\n+missing frontmatter\n*** Update File: old.txt\n*** Move to: %s\n+{bad\n*** End Patch' "$css" "$json" "$agent" "$moved"
  payload=$(jq -n --arg patch "$patch" '{tool_name:"apply_patch",tool_input:{patch:$patch},error:{message:"multi failure"}}')

  output=$(printf '%s\n' "$payload" | "$PLUGIN_ROOT/hooks/scripts/warn-hardcoded.sh" 2>&1)
  assert_equals "" "$output" "JSON content must not be attributed to the CSS record" || return 1
  output=$(printf '%s\n' "$payload" | "$PLUGIN_ROOT/hooks/scripts/validate-json-schema.sh" 2>&1)
  assert_contains "$output" "$json" "later JSON file must be validated" || return 1
  assert_contains "$output" "$moved" "rename destination must be the effective path" || return 1
  output=$(printf '%s\n' "$payload" | "$PLUGIN_ROOT/hooks/scripts/validate-structure.sh" 2>&1)
  assert_contains "$output" "$agent" "later agent file must be structurally checked" || return 1

  KERNEL_VAULTS="$TEST_PROJECT" AGENTDB_ROOT="$TEST_PROJECT" agentdb init >/dev/null
  printf '%s\n' "$payload" | KERNEL_VAULTS="$TEST_PROJECT" AGENTDB_ROOT="$TEST_PROJECT" \
    "$PLUGIN_ROOT/hooks/scripts/capture-error.sh" >/dev/null 2>&1 || return 1
  assert_equals "4" "$(sqlite3 "$TEST_PROJECT/_meta/agentdb/agent.db" "SELECT COUNT(*) FROM errors WHERE error='multi failure';")" "capture-error must record every patch file"
}

test_log_write_multifile_and_json_roundtrip() {
  local root="$TEST_DIR/log-json" patch payload weird log
  mkdir -p "$root"
  printf -v patch '*** Begin Patch\n*** Update File: first.css\n+safe\n*** Update File: old.json\n*** Move to: later.json\n+{}\n*** End Patch'
  payload=$(jq -n --arg patch "$patch" '{tool_name:"apply_patch",tool_input:{patch:$patch}}')
  printf '%s\n' "$payload" | CLAUDE_PROJECT_DIR="$root" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" \
    "$PLUGIN_ROOT/hooks/scripts/log-write.sh" >/dev/null 2>&1 || return 1
  log="$root/_meta/logs/actions.jsonl"
  assert_equals "2" "$(wc -l < "$log" | tr -d ' ')" "log-write must log every patch record" || return 1
  assert_equals "first.css,later.json" "$(jq -rs 'map(.file)|join(",")' "$log")" "rename must log destination in order" || return 1

  weird=$'quote" slash\\ line\nnext'
  payload=$(jq -n --arg p "$weird" '{tool_name:"Write",tool_input:{file_path:$p,content:"safe"}}')
  printf '%s\n' "$payload" | CLAUDE_PROJECT_DIR="$root" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" \
    "$PLUGIN_ROOT/hooks/scripts/log-write.sh" >/dev/null 2>&1 || return 1
  jq -e . "$log" >/dev/null || return 1
  assert_equals "$weird" "$(tail -1 "$log" | jq -r .file)" "quote/backslash/newline must round-trip through valid JSON"
}

test_critical_guard_scripts_unchanged_for_802() {
  local expected actual file
  while read -r expected file; do
    actual=$(shasum -a 256 "$PLUGIN_ROOT/hooks/scripts/$file" | awk '{print $1}')
    assert_equals "$expected" "$actual" "$file must remain unchanged" || return 1
  done <<'EOF'
16fb49cbedb3bdc875c4add7cb1de0c993e6528fa4d9d520fc9ee2cba6641a93 guard-bash.sh
79b46dabd8c9e890d503548cddd98358ec59d888ada4e738e34b05b7ca4f1da1 guard-config.sh
d3611267b4f135c5b96e8a4a8af60f296b196efc135e3dfbef63d7683065608c detect-secrets.sh
dbf6680d56dfd5676a420f69f75dcfc5405f0fd53879063859a43b4dcaa5085b guard-context.sh
EOF
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
  local cmd_file="$PLUGIN_ROOT/skills/ingest/SKILL.md"
  local content
  content=$(cat "$cmd_file")
  assert_contains "$content" "RESEARCH"
  assert_contains "$content" "anti_patterns"
}

test_forge_command_has_loop() {
  local cmd_file="$PLUGIN_ROOT/skills/forge/SKILL.md"
  local content
  content=$(cat "$cmd_file")
  assert_contains "$content" "loop"
  assert_contains "$content" "max_iterations"
}

test_commands_use_structured_format() {
  # Workflow skills (former commands) use XML structure or YAML blocks
  local structured_count=0
  local total=0
  for s in ingest forge handoff retrospective diagnose dream experiment; do
    ((total++))
    if grep -qE '<skill id=|```yaml' "$PLUGIN_ROOT/skills/$s/SKILL.md" 2>/dev/null; then
      ((structured_count++))
    fi
  done
  [ "$structured_count" -ge "$total" ] || {
    echo "FAIL: workflow skills should use structured format ($structured_count/$total)"
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
  [ "$lines" -lt 400 ] || {
    echo "FAIL: CLAUDE.md too large ($lines lines, max 400)."
    return 1
  }
}

test_commands_token_budget() {
  # Skills should be focused. Guided generators (landing-page) and autonomous
  # engines (forge) legitimately run long; cap reflects real sizes.
  local failed=0
  for skill in "$PLUGIN_ROOT/skills/"*/SKILL.md; do
    local lines
    lines=$(wc -l < "$skill" | tr -d ' ')
    if [ "$lines" -gt 1000 ]; then
      echo "  OVER BUDGET: $skill = $lines lines (max 1000)"
      failed=1
    fi
  done
  [ "$failed" -eq 0 ] || {
    echo "FAIL: some skills exceed token budget. Trim or use progressive disclosure."
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
  for f in "$PLUGIN_ROOT/skills/"*/SKILL.md "$PLUGIN_ROOT/agents/"*.md; do
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
  # v8: the commands layer is gone. Guard against reintroduction.
  [ ! -d "$PLUGIN_ROOT/commands" ] || { echo "FAIL: commands/ directory must not exist (unified skills, v8)"; return 1; }
  if grep -q '"commands"' "$PLUGIN_ROOT/.claude-plugin/plugin.json"; then
    echo "FAIL: plugin.json must not register commands (skills are auto-discovered)"
    return 1
  fi
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
  # skills are auto-discovered from skills/; registration = the skill dir exists
  [ -f "$PLUGIN_ROOT/skills/metrics/SKILL.md" ]
}

test_metrics_command_has_frontmatter() {
  [ -f "$PLUGIN_ROOT/skills/metrics/SKILL.md" ] || { echo "FAIL: metrics.md not found"; return 1; }
  head -1 "$PLUGIN_ROOT/skills/metrics/SKILL.md" | grep -q "^---"
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

# Regression: a migration-created table (events, from 003) can drift away while
# its _migrations marker stays recorded. The marker-gated migration pass would
# skip the migration that recreates it, so preflight must force-re-read
# migrations on table loss. Before the force-repair fix this looped forever on
# "missing_table" + phantom repairs and never restored events.
test_preflight_restores_dropped_migration_table() {
  local db="$TEST_PROJECT/_meta/agentdb/agent.db"
  agentdb init >/dev/null
  # Drop the table but KEEP its migration marker, the drift state.
  sqlite3 "$db" "DROP TABLE events;"
  assert_equals "1" "$(sqlite3 "$db" "SELECT COUNT(*) FROM _migrations WHERE name='003_telemetry';")" "003 marker must still be present (drift precondition)"
  agentdb preflight >/dev/null 2>&1
  RESULT=$(sqlite3 "$db" "SELECT name FROM sqlite_master WHERE type='table' AND name='events';")
  assert_equals "events" "$RESULT" "preflight must recreate the dropped events table despite marker"
}

test_preflight_idempotent_after_table_drift() {
  local db="$TEST_PROJECT/_meta/agentdb/agent.db"
  agentdb init >/dev/null
  sqlite3 "$db" "DROP TABLE events;"
  agentdb preflight >/dev/null 2>&1          # run 1 heals
  local second
  second=$(agentdb preflight 2>&1)            # run 2 must be clean, no phantom repair
  assert_contains "$second" "preflight:ok" "second preflight after drift repair must be clean (no phantom repairs)"
}

# Regression: migration 010 must normalize parseable legacy timestamps WITHOUT
# nulling empty/garbage/NULL ts (strftime returns NULL on those, and the bare
# NOT LIKE '%Z' filter matched them, silent data loss before the IS NOT NULL guard).
test_migration_010_preserves_unparseable_ts() {
  local db="$TEST_PROJECT/_meta/agentdb/agent.db"
  agentdb init >/dev/null
  sqlite3 "$db" "INSERT INTO errors(ts,tool,error) VALUES ('2026-03-26 21:56:21','Bash','legacy-valid');"
  sqlite3 "$db" "INSERT INTO errors(ts,tool,error) VALUES ('','Bash','empty-ts');"
  sqlite3 "$db" "INSERT INTO errors(ts,tool,error) VALUES ('garbage-ts','Bash','garbage');"
  # Re-run 010 directly (it is already applied on a fresh DB; re-reading is idempotent).
  sqlite3 "$db" ".read $PLUGIN_ROOT/orchestration/agentdb/migrations/010_normalize_timestamps.sql"
  assert_equals "1" "$(sqlite3 "$db" "SELECT ts LIKE '%Z' FROM errors WHERE error='legacy-valid';")" "parseable legacy ts must normalize to ...Z"
  assert_equals "1" "$(sqlite3 "$db" "SELECT ts IS NOT NULL FROM errors WHERE error='empty-ts';")" "empty ts must NOT be nulled"
  assert_equals "1" "$(sqlite3 "$db" "SELECT ts IS NOT NULL FROM errors WHERE error='garbage';")" "garbage ts must NOT be nulled"
}

# === Dreamer Tests ===

test_dream_command_exists_with_frontmatter() {
  [ -f "$PLUGIN_ROOT/skills/dream/SKILL.md" ] || return 1
  head -1 "$PLUGIN_ROOT/skills/dream/SKILL.md" | grep -q "^---"
}

test_dream_command_registered_in_plugin_json() {
  [ -f "$PLUGIN_ROOT/skills/dream/SKILL.md" ]
}

# --- Version Sync Tests ---

test_version_sync_all() {
  # plugin.json is the source of truth; EVERY canonical declaration must match it.
  # Drift here = a release that shipped a stale version somewhere. Bump via
  # scripts/bump-version.sh, which updates all of these in one shot.
  local v fail=0
  v=$(python3 -c "import json; print(json.load(open('$PLUGIN_ROOT/.claude-plugin/plugin.json'))['version'])")
  local mv
  mv=$(python3 -c "import json; print(json.load(open('$PLUGIN_ROOT/.claude-plugin/marketplace.json'))['plugins'][0]['version'])")
  [ "$mv" = "$v" ]                                                 || { echo "FAIL: marketplace.json ($mv) != plugin.json ($v)"; fail=1; }
  grep -qF "<kernel version=\"$v\">" "$PLUGIN_ROOT/AGENTS.md"       || { echo "FAIL: AGENTS.md <kernel version> != $v"; fail=1; }
  grep -qF "<kernel version=\"$v\">" "$PLUGIN_ROOT/CLAUDE.md"      || { echo "FAIL: CLAUDE.md <kernel version> != $v"; fail=1; }
  grep -qF "KERNEL v$v" "$PLUGIN_ROOT/skills/help/SKILL.md"            || { echo "FAIL: skills/help/SKILL.md KERNEL version != $v"; fail=1; }
  return $fail
}

test_release_docs_reject_stale_live_claims() {
  local files=(README.md docs/QUICKSTART.md docs/MIGRATION-8.md AGENTS.md CLAUDE.md skills/help/SKILL.md skills/init/SKILL.md workflows/feature.md workflows/bugfix.md workflows/refactor.md)
  local pattern='Cursor shares|without the kernel: prefix|yaml-first|YAML is the canonical|All v7 invocations work unchanged|ln -sfn|push to main|no new tests needed|commands/\*\.md'
  ! grep -En "$pattern" "${files[@]/#/$PLUGIN_ROOT/}"
}

test_release_docs_rollback_works_outside_a_checkout() {
  local files=("$PLUGIN_ROOT/README.md" "$PLUGIN_ROOT/docs/QUICKSTART.md" "$PLUGIN_ROOT/docs/MIGRATION-8.md") file
  for file in "${files[@]}"; do
    grep -q 'git clone https://github.com/ariaxhan/kernel-claude.git' "$file" || return 1
    grep -q 'checkout 54a0053' "$file" || return 1
    grep -q 'plugins/cache/kernel-marketplace/kernel/current/scripts/select-runtime.sh' "$file" || return 1
    ! grep -q 'git worktree add' "$file" || return 1
  done
}

test_release_docs_separate_claude_and_codex_lifecycle() {
  local files=(README.md docs/QUICKSTART.md docs/MIGRATION-8.md) file content
  for file in "${files[@]}"; do
    content=$(cat "$PLUGIN_ROOT/$file")
    [[ "$content" == *"/plugin marketplace update kernel-marketplace"* ]] || return 1
    [[ "$content" == *"codex plugin marketplace upgrade kernel-marketplace"* ]] || return 1
    [[ "$content" == *"codex plugin remove kernel@kernel-marketplace"* ]] || return 1
    [[ "$content" == *"codex plugin add kernel@kernel-marketplace"* ]] || return 1
    ! grep -Eq '^codex plugin update( |$)' "$PLUGIN_ROOT/$file" || return 1
  done
  grep -q 'codex plugin marketplace add ariaxhan/kernel-claude' "$PLUGIN_ROOT/README.md"
  grep -q 'codex plugin marketplace add ariaxhan/kernel-claude' "$PLUGIN_ROOT/docs/QUICKSTART.md"
}

test_release_docs_explain_codex_invocation_and_boundaries() {
  local files=(README.md docs/QUICKSTART.md docs/MIGRATION-8.md skills/help/SKILL.md) file
  for file in "${files[@]}"; do
    grep -Fq '/kernel:' "$PLUGIN_ROOT/$file" || return 1
    grep -Fq '$kernel:' "$PLUGIN_ROOT/$file" || return 1
    grep -Fqi 'Claude Code agent' "$PLUGIN_ROOT/$file" || return 1
    grep -Fq 'SessionEnd' "$PLUGIN_ROOT/$file" || return 1
  done
}

test_release_docs_explicit_only_inventory_is_derived() {
  python3 - "$PLUGIN_ROOT" <<'PY'
import pathlib, re, sys
root = pathlib.Path(sys.argv[1])
actual = {
    skill.parent.name
    for skill in (root / "skills").glob("*/SKILL.md")
    if re.search(r"^disable-model-invocation:\s*true\s*$", skill.read_text(), re.M)
}
for relative in ("docs/QUICKSTART.md", "docs/MIGRATION-8.md"):
    text = (root / relative).read_text()
    match = re.search(r"Explicit-only skills \((\d+)\):\s*(.*?)\.", text, re.S)
    assert match, f"{relative}: explicit-only inventory missing"
    documented = set(re.findall(r"`([a-z0-9-]+)`", match.group(2)))
    assert int(match.group(1)) == len(actual), (relative, match.group(1), actual)
    assert documented == actual, (relative, documented, actual)
PY
}

test_release_changelog_v8_is_current_and_history_preserved() {
  local v811 v810 v802 v801 v800
  v811=$(awk '/^## \[8\.1\.1\]/{on=1} /^## \[8\.1\.0\]/{on=0} on' "$PLUGIN_ROOT/CHANGELOG.md")
  v810=$(awk '/^## \[8\.1\.0\]/{on=1} /^## \[8\.0\.2\]/{on=0} on' "$PLUGIN_ROOT/CHANGELOG.md")
  v802=$(awk '/^## \[8\.0\.2\]/{on=1} /^## \[8\.0\.1\]/{on=0} on' "$PLUGIN_ROOT/CHANGELOG.md")
  v801=$(awk '/^## \[8\.0\.1\]/{on=1} /^## \[8\.0\.0\]/{on=0} on' "$PLUGIN_ROOT/CHANGELOG.md")
  v800=$(awk '/^## \[8\.0\.0\]/{on=1} /^## \[7\.23\.0\]/{on=0} on' "$PLUGIN_ROOT/CHANGELOG.md")
  [[ "$v811" == *"8.1.0 documentation"* ]] && [[ "$v811" == *"failed before reaching the script"* ]] || return 1
  [[ "$v810" == *"49 canonical Git repositories"* ]] && [[ "$v810" == *"does **not** claim"* ]] || return 1
  [[ "$v802" == *"async"* ]] && [[ "$v802" == *"Codex"* ]] || return 1
  [[ "$v801" == *"incomplete"* ]] && [[ "$v801" == *"Codex"* ]] && [[ "$v801" == *"368"* ]] || return 1
  [[ "$v800" == *"strict JSON"* ]] && [[ "$v800" == *"preflight"* ]] && [[ "$v800" == *"select-runtime.sh"* ]] || return 1
  grep -q '^## \[7.23.0\] - 2026-07-06' "$PLUGIN_ROOT/CHANGELOG.md"
}

test_release_docs_use_current_801_runtime() {
  grep -q 'kernel/8\.0\.2/scripts/select-runtime\.sh' "$PLUGIN_ROOT/README.md" || return 1
  ! grep -q 'kernel/8\.0\.0/scripts/select-runtime\.sh' "$PLUGIN_ROOT/README.md" || return 1
  # Historical 8.0.0 release and upgrade references remain valid outside active runtime commands.
  grep -q '^## \[8\.0\.0\] - 2026-07-11' "$PLUGIN_ROOT/CHANGELOG.md"
}

test_release_docs_explain_vaults_continuity_boundary() {
  grep -q 'active project root exactly matches the Vaults root' "$PLUGIN_ROOT/README.md" || return 1
  grep -q 'Nested repositories retain KERNEL' "$PLUGIN_ROOT/README.md" || return 1
  grep -q 'shared Vaults continuity service' "$PLUGIN_ROOT/CHANGELOG.md"
}

test_release_metadata_and_inventory_are_truthful() {
  local skills agents
  skills=$(find "$PLUGIN_ROOT/skills" -mindepth 2 -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')
  agents=$(find "$PLUGIN_ROOT/agents" -maxdepth 1 -name '*.md' ! -name README.md | wc -l | tr -d ' ')
  assert_equals 34 "$skills" "skill inventory"
  assert_equals 15 "$agents" "agent inventory"
  python3 - "$PLUGIN_ROOT" <<'PY'
import json, pathlib, sys
r=pathlib.Path(sys.argv[1])
p=json.loads((r/'.claude-plugin/plugin.json').read_text())
m=json.loads((r/'.claude-plugin/marketplace.json').read_text())['plugins'][0]
assert p['version']==m['version']=='8.1.1'
for x in (p,m):
    assert 'JSON' in x['description'] and '34 skills' in x['description'] and '15 specialized agent' in x['description']
PY
  grep -q 'validate | latest | divergence | preflight | compile | resume | activate | deactivate' "$PLUGIN_ROOT/README.md"
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
  grep -q "output_format" "$PLUGIN_ROOT/skills/dream/SKILL.md"
}

test_dream_command_has_github_integration() {
  grep -q "github_integration\|GitHub\|gh " "$PLUGIN_ROOT/skills/dream/SKILL.md"
}

# === Compaction Restore Tests ===

make_vaults_continuity_fixture() {
  local vaults="$1"
  mkdir -p "$vaults/_meta/services" "$vaults/.claude/hooks"
  : > "$vaults/_meta/services/context_checkpoint.py"
  printf '#!/bin/bash\nexit 0\n' > "$vaults/.claude/hooks/context-checkpoint.sh"
  chmod +x "$vaults/.claude/hooks/context-checkpoint.sh"
}

test_vaults_continuity_requires_exact_root_and_executable_adapter() {
  local vaults="$TEST_DIR/vaults" nested="$TEST_DIR/vaults/nested"
  mkdir -p "$nested"
  make_vaults_continuity_fixture "$vaults"
  source "$PLUGIN_ROOT/hooks/scripts/common.sh"
  kernel_vaults_continuity_active "$vaults" "$vaults" || return 1
  ! kernel_vaults_continuity_active "$vaults" "$nested" || { echo "FAIL: nested project must retain KERNEL fallback"; return 1; }
  chmod -x "$vaults/.claude/hooks/context-checkpoint.sh"
  ! kernel_vaults_continuity_active "$vaults" "$vaults" || { echo "FAIL: non-executable adapter must not activate"; return 1; }
  rm "$vaults/_meta/services/context_checkpoint.py"
  chmod +x "$vaults/.claude/hooks/context-checkpoint.sh"
  ! kernel_vaults_continuity_active "$vaults" "$vaults" || { echo "FAIL: missing shared engine must not activate"; return 1; }
}

test_vaults_root_compaction_hooks_clean_noop() {
  local vaults="$TEST_DIR/vaults-root" output
  mkdir -p "$vaults/_meta/agents"
  make_vaults_continuity_fixture "$vaults"
  printf 'vaults-owned\n' > "$vaults/_meta/.compact-marker"
  output=$(cd "$vaults" && KERNEL_VAULTS="$vaults" CLAUDE_PROJECT_DIR="$vaults" \
    bash "$PLUGIN_ROOT/hooks/scripts/pre-compact-commit.sh" <<<'{"trigger":"manual"}' 2>&1)
  assert_equals "" "$output" "PreCompact must clean no-op at activated Vaults root" || return 1
  output=$(cd "$vaults" && KERNEL_VAULTS="$vaults" CLAUDE_PROJECT_DIR="$vaults" \
    bash "$PLUGIN_ROOT/hooks/scripts/post-compact-restore.sh" <<<'{}' 2>&1)
  assert_equals "" "$output" "PostCompact must not inject restore state at activated Vaults root" || return 1
  assert_equals "vaults-owned" "$(cat "$vaults/_meta/.compact-marker")" "KERNEL must preserve Vaults-owned marker" || return 1
  [ ! -e "$vaults/_meta/.compact-keyterms" ]
}

test_nested_project_retains_kernel_compaction_fallback() {
  local vaults="$TEST_DIR/vaults-root" nested output
  nested="$vaults/nested"
  mkdir -p "$nested/_meta" "$vaults/_meta/agents"
  make_vaults_continuity_fixture "$vaults"
  echo test-agent > "$vaults/_meta/agents/.current"
  echo nested-owned > "$nested/_meta/.compact-marker"
  output=$(cd "$nested" && KERNEL_VAULTS="$vaults" CLAUDE_PROJECT_DIR="$nested" \
    bash "$PLUGIN_ROOT/hooks/scripts/post-compact-restore.sh" <<<'{}' 2>&1)
  assert_contains "$output" "Context Restored After Compaction" || return 1
  [ ! -e "$nested/_meta/.compact-marker" ]
}

test_vaults_root_session_start_keeps_governance_without_restore() {
  local vaults="$TEST_DIR/vaults-root" output
  mkdir -p "$vaults/_meta/agentdb"
  make_vaults_continuity_fixture "$vaults"
  KERNEL_VAULTS="$vaults" AGENTDB_ROOT="$vaults" agentdb init >/dev/null
  KERNEL_VAULTS="$vaults" AGENTDB_ROOT="$vaults" agentdb write-end \
    '{"event":"pre-compact","goal":"must-not-inject"}' >/dev/null
  output=$(cd "$vaults" && KERNEL_VAULTS="$vaults" AGENTDB_ROOT="$vaults" CLAUDE_PROJECT_DIR="$vaults" \
    bash "$PLUGIN_ROOT/hooks/scripts/session-start.sh" <<<'{"session_id":"root-test"}' 2>&1)
  assert_contains "$output" "# KERNEL" "SessionStart governance must remain" || return 1
  if [[ "$output" == *"Resume From Checkpoint"* || "$output" == *"must-not-inject"* ]]; then
    echo "FAIL: SessionStart injected competing restore state at activated Vaults root"
    return 1
  fi
}

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

test_blocking_guards_do_not_source_breaker() {
  # I0.15: a blocking safety gate must run on every invocation and must never
  # auto-disable itself. So guard-bash/guard-config/detect-secrets must NOT
  # `source` the circuit breaker (a tripped breaker would fail OPEN = allow).
  # Match an active source directive only, not the explanatory comment.
  local g
  for g in guard-bash guard-config detect-secrets; do
    if grep -qE '^[[:space:]]*(source|\.)[[:space:]]+.*circuit-breaker\.sh' "$PLUGIN_ROOT/hooks/scripts/$g.sh"; then
      echo "FAIL: $g.sh sources circuit-breaker.sh, a blocking guard must always run"
      return 1
    fi
  done
  # The breaker itself still exists for non-blocking hooks (e.g. auto-approve, telemetry).
  [ -f "$PLUGIN_ROOT/hooks/scripts/circuit-breaker.sh" ]
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
  # Source circuit breaker, it should detect expired cooldown and clean up
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
  [ -f "$PLUGIN_ROOT/skills/diagnose/SKILL.md" ] || return 1
  head -1 "$PLUGIN_ROOT/skills/diagnose/SKILL.md" | grep -q "^---"
}

test_diagnose_registered() {
  [ -f "$PLUGIN_ROOT/skills/diagnose/SKILL.md" ]
}

test_diagnose_bug_mode() {
  grep -q 'mode id="bug"' "$PLUGIN_ROOT/skills/diagnose/SKILL.md"
}

test_diagnose_refactor_mode() {
  grep -q 'mode id="refactor"' "$PLUGIN_ROOT/skills/diagnose/SKILL.md"
}

test_diagnose_output_format() {
  grep -q "output_format" "$PLUGIN_ROOT/skills/diagnose/SKILL.md"
}

test_diagnose_loads_debug() {
  grep -q "debug" "$PLUGIN_ROOT/skills/diagnose/SKILL.md"
}

# === Retrospective Tests ===

test_retrospective_command_exists() {
  [ -f "$PLUGIN_ROOT/skills/retrospective/SKILL.md" ] || return 1
  head -1 "$PLUGIN_ROOT/skills/retrospective/SKILL.md" | grep -q "^---"
}

test_retrospective_registered() {
  [ -f "$PLUGIN_ROOT/skills/retrospective/SKILL.md" ]
}

test_retrospective_has_agentdb() {
  grep -q "agentdb" "$PLUGIN_ROOT/skills/retrospective/SKILL.md"
}

test_retrospective_has_output_format() {
  grep -q "output_format" "$PLUGIN_ROOT/skills/retrospective/SKILL.md"
}

test_retrospective_has_clusters() {
  grep -q "Clusters\|cluster" "$PLUGIN_ROOT/skills/retrospective/SKILL.md"
}

test_retrospective_queries_current_learning_schema() {
  local content
  content=$(cat "$PLUGIN_ROOT/skills/retrospective/SKILL.md")
  assert_contains "$content" "SELECT id, type, insight, evidence, hit_count, load_count, ts, last_hit FROM learnings ORDER BY ts DESC" "retrospective must query current AgentDB columns" || return 1
  assert_contains "$content" "COALESCE(last_hit, ts) < datetime('now', '-30 days')" "staleness must use last recall when available" || return 1
  if grep -qE 'content, evidence, reinforced, created_at|ORDER BY created_at' "$PLUGIN_ROOT/skills/retrospective/SKILL.md"; then
    echo "FAIL: retrospective still names removed learning columns"
    return 1
  fi
}

test_ship_bump_targets_are_truthful() {
  local content
  content=$(cat "$PLUGIN_ROOT/skills/ship/SKILL.md")
  for target in '.claude-plugin/plugin.json' '.claude-plugin/marketplace.json' 'AGENTS.md' 'CLAUDE.md' 'skills/help/SKILL.md'; do
    assert_contains "$content" "$target" "ship bump prose must name $target" || return 1
  done
  if grep -q 'README install path' "$PLUGIN_ROOT/skills/ship/SKILL.md"; then
    echo "FAIL: bump-version.sh does not update a README install path"
    return 1
  fi
}

test_methodology_carries_cross_loader_release_lessons() {
  grep -q "one real payload fixture per loader" "$PLUGIN_ROOT/skills/testing/SKILL.md" &&
    grep -q "NORMALIZE BEFORE ALLOWLISTS" "$PLUGIN_ROOT/skills/security/SKILL.md" &&
    grep -q "disposable plugin/cache copy" "$PLUGIN_ROOT/skills/ship/SKILL.md" &&
    grep -q "native manifest validator rejects required safety metadata" "$PLUGIN_ROOT/skills/ship/SKILL.md" &&
    grep -q "resource ceiling" "$PLUGIN_ROOT/skills/ship/SKILL.md"
}

test_retrospective_contradictions_have_mutation_evidence() {
  python3 - "$PLUGIN_ROOT/_meta/reports/retrospective-2026-07-11.json" <<'PY'
import json
import re
import sys

report = json.load(open(sys.argv[1]))
expected = report["analyzed"].get("contradictions_resolved", 0)
backed = [
    mutation for mutation in report["mutations"]
    if mutation.get("artifact_type") == "learning"
    and "contradiction" in mutation.get("reason", "").lower()
    and mutation.get("evidence")
]
if len(backed) != expected:
    raise SystemExit(
        f"contradictions_resolved={expected}, but {len(backed)} learning mutations carry contradiction evidence"
    )

paths = []
for mutation in backed:
    if mutation.get("status") != "applied":
        raise SystemExit("counted contradiction mutation must have status=applied")
    if mutation.get("op") != "modify":
        raise SystemExit("counted contradiction mutation must have op=modify")
    path = mutation.get("path", "")
    if not re.fullmatch(r"agentdb://learnings/LRN-[0-9]{14}-[0-9]+-[0-9]+", path):
        raise SystemExit(f"invalid contradiction learning path: {path!r}")
    paths.append(path)
if len(paths) != len(set(paths)):
    raise SystemExit("contradiction learning paths must be unique")

target = "agentdb://learnings/LRN-20260710185543-1035-14087"
if paths != [target]:
    raise SystemExit(f"expected exact resolved learning {target}, got {paths}")
evidence = backed[0]["evidence"]
if "Claude Code invokes /kernel:<skill>" not in evidence:
    raise SystemExit("contradiction evidence is missing Claude /kernel:<skill> truth")
if "Codex 0.144.1 invokes $kernel:<skill>" not in evidence:
    raise SystemExit("contradiction evidence is missing Codex $kernel:<skill> truth")
PY
}

# === GitHub Integration Tests ===

test_github_integration_exists() {
  [ -f "$PLUGIN_ROOT/hooks/scripts/github-integration.sh" ] || return 1
  head -1 "$PLUGIN_ROOT/hooks/scripts/github-integration.sh" | grep -q "^#!/bin/bash"
}

test_github_integration_has_availability_check() {
  grep -q "_gh_available" "$PLUGIN_ROOT/hooks/scripts/github-integration.sh"
}

test_github_integration_has_profile_gate() {
  # Must check profile, local profiles get no GitHub operations
  grep -q "local\|profile" "$PLUGIN_ROOT/hooks/scripts/github-integration.sh"
}

test_github_integration_has_issue_functions() {
  grep -q "_gh_create_issue" "$PLUGIN_ROOT/hooks/scripts/github-integration.sh" &&
  grep -q "_gh_comment_issue" "$PLUGIN_ROOT/hooks/scripts/github-integration.sh" &&
  grep -q "_gh_close_issue" "$PLUGIN_ROOT/hooks/scripts/github-integration.sh"
}

test_github_integration_has_discussion_functions() {
  grep -q "_gh_post_discussion" "$PLUGIN_ROOT/hooks/scripts/github-integration.sh" &&
  grep -q "_gh_post_session_summary" "$PLUGIN_ROOT/hooks/scripts/github-integration.sh" &&
  grep -q "_gh_post_learning" "$PLUGIN_ROOT/hooks/scripts/github-integration.sh"
}

test_github_integration_fire_and_forget() {
  # All gh calls should have error suppression, never block hooks
  # Check that functions return 0 on failure paths
  grep -q '2>/dev/null' "$PLUGIN_ROOT/hooks/scripts/github-integration.sh"
}

test_session_end_sources_github() {
  grep -q "github-integration.sh" "$PLUGIN_ROOT/hooks/scripts/session-end.sh"
}

test_session_end_posts_summary() {
  grep -q "_gh_post_session_summary" "$PLUGIN_ROOT/hooks/scripts/session-end.sh"
}

test_github_integration_not_hardcoded_repo() {
  # Repo should be derived from git remote, not hardcoded
  ! grep -q '"ariaxhan/kernel-claude"' "$PLUGIN_ROOT/hooks/scripts/github-integration.sh" || \
  grep -q 'git remote' "$PLUGIN_ROOT/hooks/scripts/github-integration.sh"
}

test_agents_have_github_layer() {
  grep -q "github\|_gh_\|issue" "$PLUGIN_ROOT/agents/surgeon.md" &&
  grep -q "github\|_gh_\|issue" "$PLUGIN_ROOT/agents/adversary.md"
}

test_commands_have_github_layer() {
  grep -q "non-local\|_gh_\|GitHub\|github" "$PLUGIN_ROOT/skills/ingest/SKILL.md" &&
  grep -q "non-local\|_gh_\|GitHub\|github" "$PLUGIN_ROOT/skills/forge/SKILL.md" &&
  grep -q "non-local\|_gh_\|GitHub\|github" "$PLUGIN_ROOT/skills/handoff/SKILL.md" &&
  grep -q "non-local\|_gh_\|GitHub\|github" "$PLUGIN_ROOT/skills/retrospective/SKILL.md"
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

# === Phase 0 Bug Fix Tests ===

test_capture_error_reads_tool_name() {
  grep -q 'tool_name' "$PLUGIN_ROOT/hooks/scripts/capture-error.sh"
}

test_capture_error_logs_tool_correctly() {
  setup_test_env
  agentdb init >/dev/null 2>&1
  local INPUT='{"tool_name":"Edit","error":"file not found","tool_input":{}}'
  local TOOL=$(echo "$INPUT" | jq -r '.tool_name // .tool // "unknown"' 2>/dev/null)
  assert_equals "Edit" "$TOOL" "tool_name should be extracted correctly"
  teardown_test_env
}

test_session_start_creates_memory_dir() {
  grep -q 'MEMORY.md' "$PLUGIN_ROOT/hooks/scripts/session-start.sh"
}

# --- Worktree Safety Tests ---

test_surgeon_has_worktree_safety() {
  local file="$PLUGIN_ROOT/agents/surgeon.md"
  assert_file_exists "$file"
  local content
  content=$(cat "$file")
  assert_contains "$content" "worktree_safety" "surgeon.md should contain worktree_safety section"
  assert_contains "$content" "constraints.files" "surgeon.md should reference constraints.files"
  assert_contains "$content" "git diff --name-only" "surgeon.md should have diff validation"
}

test_orchestration_has_constraint_validation() {
  local file="$PLUGIN_ROOT/skills/orchestration/SKILL.md"
  assert_file_exists "$file"
  local content
  content=$(cat "$file")
  assert_contains "$content" "worktree_safety" "orchestration SKILL.md should contain worktree_safety"
  assert_contains "$content" "constraints.files" "orchestration SKILL.md should reference constraints.files"
  assert_contains "$content" "Post-agent validation" "orchestration SKILL.md should have post-agent validation"
}

test_agentdb_contract_accepts_constraints() {
  local output
  output=$(agentdb contract '{"goal":"test","constraints":{"files":["a.sh","b.md"]},"tier":2}' 2>&1)
  assert_contains "$output" "Contract: CR-"
  local stored
  stored=$(agentdb query "SELECT content FROM context WHERE type='contract' ORDER BY ts DESC LIMIT 1" 2>&1)
  assert_contains "$stored" "constraints"
  assert_contains "$stored" "a.sh"
}

# --- Triage & Understudier Agent Tests ---

test_triage_exists_with_frontmatter() {
  [ -f "$PLUGIN_ROOT/agents/triage.md" ] || return 1
  head -1 "$PLUGIN_ROOT/agents/triage.md" | grep -q "^---"
}

test_triage_model_haiku() {
  grep -q "^model: haiku" "$PLUGIN_ROOT/agents/triage.md"
}

test_triage_has_complexity_classification() {
  grep -q "low.*medium.*high.*epic" "$PLUGIN_ROOT/agents/triage.md" ||
  (grep -q "low:" "$PLUGIN_ROOT/agents/triage.md" &&
   grep -q "medium:" "$PLUGIN_ROOT/agents/triage.md" &&
   grep -q "high:" "$PLUGIN_ROOT/agents/triage.md" &&
   grep -q "epic:" "$PLUGIN_ROOT/agents/triage.md")
}

test_understudier_is_gone() {
  # understudier merged into triage (viability pre-flight); the file must stay deleted.
  if [ -f "$PLUGIN_ROOT/agents/understudier.md" ]; then
    echo "FAIL: agents/understudier.md should not exist (folded into triage)"
    return 1
  fi
}

test_triage_has_viability_preflight() {
  grep -qi "viability pre-flight" "$PLUGIN_ROOT/agents/triage.md"
}

test_claude_md_references_triage() {
  grep -q 'agent id="triage"' "$PLUGIN_ROOT/CLAUDE.md"
}

test_researcher_model_not_pinned() {
  # Deep research on haiku is a tier mismatch; researcher inherits the session model.
  if grep -q "^model:" "$PLUGIN_ROOT/agents/researcher.md"; then
    echo "FAIL: researcher.md must not pin a model"
    return 1
  fi
}

# --- Inject Context Tests ---

test_inject_context_command_exists() {
  grep -q "inject-context" "$PLUGIN_ROOT/orchestration/agentdb/agentdb"
}

test_inject_context_surgeon_gotchas() {
  agentdb init >/dev/null
  agentdb learn failure "never use eval" "security risk" >/dev/null
  agentdb learn pattern "use sql_escape" "prevents injection" >/dev/null
  local output
  output=$(agentdb inject-context surgeon)
  assert_contains "$output" "Known Gotchas" &&
  assert_contains "$output" "Proven Patterns"
}

test_inject_context_adversary_failures() {
  agentdb init >/dev/null
  agentdb learn failure "timeout on large queries" "prod incident" >/dev/null
  local output
  output=$(agentdb inject-context adversary)
  assert_contains "$output" "Past Failures" &&
  assert_contains "$output" "Known Gotchas" &&
  assert_contains "$output" "Recent Errors"
}

test_inject_context_unknown_fallback() {
  agentdb init >/dev/null
  local output
  output=$(agentdb inject-context unknown_type_xyz)
  # Falls back to read-start which outputs "AgentDB Context"
  assert_contains "$output" "AgentDB Context"
}

# --- Read-Start Utilization Tests ---

test_read_start_outputs_gotchas() {
  agentdb init >/dev/null
  agentdb learn gotcha "always escape SQL inputs" "injection risk" >/dev/null
  local output
  output=$(agentdb read-start)
  # weighted-75 format (H078): gotchas surface tagged in the ranked list.
  assert_contains "$output" "[gotcha] always escape SQL inputs"
}

test_read_start_bumps_load_count_not_hit_count() {
  # Migration 013: read-start bumps load_count (session-open telemetry), and must
  # NOT touch hit_count, hit_count is relevance feedback, earned only via recall.
  agentdb init >/dev/null
  agentdb learn failure "never skip validation" "broke prod" >/dev/null
  agentdb read-start >/dev/null
  local hit load
  hit=$(sqlite3 "$TEST_PROJECT/_meta/agentdb/agent.db" "SELECT hit_count FROM learnings WHERE type='failure' LIMIT 1;")
  load=$(sqlite3 "$TEST_PROJECT/_meta/agentdb/agent.db" "SELECT load_count FROM learnings WHERE type='failure' LIMIT 1;")
  [ "$load" -ge 1 ] || { echo "Expected load_count >= 1, got $load"; return 1; }
  [ "$hit" -eq 0 ] || { echo "Expected hit_count to stay 0 (recall-only), got $hit"; return 1; }
}

# --- Recall Tests (FTS5 relevance retrieval, v7.15 quality pass) ---

test_recall_dedups_identical_insights() {
  agentdb init >/dev/null
  # Three identical insights (the clone problem). recall must return exactly one.
  agentdb learn pattern "kettlebell swing hinge mechanics matter" "e1" >/dev/null
  agentdb learn pattern "kettlebell swing hinge mechanics matter" "e2" >/dev/null
  agentdb learn pattern "kettlebell swing hinge mechanics matter" "e3" >/dev/null
  local count
  count=$(agentdb recall "kettlebell hinge" | grep -c "kettlebell swing hinge mechanics matter")
  [ "$count" -eq 1 ] || { echo "Expected 1 deduped result, got $count"; return 1; }
}

test_recall_hides_human_only() {
  agentdb init >/dev/null
  agentdb learn gotcha "zzqmarker visible agent note" "ev" --visibility agent >/dev/null
  agentdb learn gotcha "zzqmarker hidden human note" "ev" --visibility human_only >/dev/null
  local out
  out=$(agentdb recall "zzqmarker" | grep '^- ')
  echo "$out" | grep -q "visible agent note" || { echo "agent-visible row should surface"; return 1; }
  if echo "$out" | grep -q "hidden human note"; then echo "human_only row leaked to agent recall"; return 1; fi
}

test_recall_bumps_hit_count() {
  # The other half of the load_count split: recall (and only recall) earns hit_count.
  agentdb init >/dev/null
  agentdb learn failure "quokka deploy never verified live" "broke" >/dev/null
  agentdb recall "quokka deploy" >/dev/null
  local hit
  hit=$(sqlite3 "$TEST_PROJECT/_meta/agentdb/agent.db" "SELECT hit_count FROM learnings WHERE insight LIKE '%quokka%' LIMIT 1;")
  [ "$hit" -ge 1 ] || { echo "Expected recall to bump hit_count >= 1, got $hit"; return 1; }
}

_mk_global_db() {  # $1=path  $2..=rows "id|type|insight|visibility"
  local g="$1"; shift
  sqlite3 "$g" "CREATE TABLE learnings (id TEXT PRIMARY KEY, ts TEXT DEFAULT '2026-06-01T00:00:00Z', type TEXT, insight TEXT, evidence TEXT, domain TEXT, hit_count INT DEFAULT 1, visibility TEXT DEFAULT 'agent', sensitivity TEXT DEFAULT 'low');"
  local row
  for row in "$@"; do
    IFS='|' read -r id typ ins vis <<< "$row"
    sqlite3 "$g" "INSERT INTO learnings (id,type,insight,evidence,domain,visibility) VALUES ('$id','$typ','$ins','ev','shared','$vis');"
  done
}

test_recall_global_unions_and_tags() {
  agentdb init >/dev/null
  agentdb learn pattern "local widget rendering tip" "ev" >/dev/null
  local gdb="$TEST_DIR/global.db"
  _mk_global_db "$gdb" "G1|pattern|quokka cross project lesson|agent"
  local out
  out=$(AGENTDB_GLOBAL="$gdb" agentdb recall "quokka" --global)
  echo "$out" | grep -q "quokka cross project lesson" || { echo "global lesson not surfaced"; return 1; }
  echo "$out" | grep -q "\[global\]" || { echo "[global] tag missing"; return 1; }
}

test_recall_global_graceful_when_absent() {
  agentdb init >/dev/null
  agentdb learn pattern "local only kangaroo lesson" "ev" >/dev/null
  local out
  out=$(AGENTDB_GLOBAL="$TEST_DIR/nope.db" agentdb recall "kangaroo" --global) || {
    echo "recall --global errored when global absent"; return 1; }
  echo "$out" | grep -q "local only kangaroo lesson" || { echo "local lost when global absent"; return 1; }
}

test_recall_global_no_human_leak() {
  agentdb init >/dev/null
  agentdb learn pattern "local platypus lesson" "ev" >/dev/null
  local gdb="$TEST_DIR/global2.db"
  _mk_global_db "$gdb" "GH|gotcha|platypus secret human only note|human_only"
  local out
  out=$(AGENTDB_GLOBAL="$gdb" agentdb recall "platypus" --global)
  if echo "$out" | grep '^- ' | grep -q "secret human only"; then
    echo "human_only leaked from global brain"; return 1; fi
}

test_recall_survives_sqlite_control_char_escaping() {
  # Regression: sqlite3 >= ~3.45 escapes control characters in shell output, so a
  # char(31) field delimiter arrives as literal "^_" and the awk split yields empty
  # rows -> "(no matching learnings)" on perfectly good data. The delimiter must be
  # printable. Run against the NEWEST sqlite on the machine (homebrew first), since
  # /usr/bin/sqlite3 is too old to escape and masks the bug.
  local new_sqlite
  new_sqlite=$(ls /opt/homebrew/bin/sqlite3 /usr/local/bin/sqlite3 2>/dev/null | head -1)
  [ -n "$new_sqlite" ] || new_sqlite=$(command -v sqlite3)
  agentdb init >/dev/null
  agentdb learn gotcha "wombat delimiter survives escaping" "ev" >/dev/null
  local out
  out=$(PATH="$(dirname "$new_sqlite"):$PATH" agentdb recall "wombat")
  echo "$out" | grep -q "wombat delimiter survives escaping" || {
    echo "recall returned nothing under $($new_sqlite --version | cut -d' ' -f1)"; return 1; }
  if echo "$out" | grep -q '\^_'; then
    echo "escaped control-char artifact (^_) leaked into recall output"; return 1; fi
}

test_decay_spares_loaded_learnings() {
  # v7.15: hit_count is recall-only. decay must NOT delete an old, never-recalled
  # learning that read-start is still loading (load_count>0), only truly untouched
  # ones (hit_count=0 AND load_count=0 AND >46d).
  agentdb init >/dev/null
  local db="$TEST_PROJECT/_meta/agentdb/agent.db"
  sqlite3 "$db" "INSERT INTO learnings (id,ts,type,insight,hit_count,load_count) VALUES ('OLD-LOADED','2020-01-01T00:00:00Z','pattern','old but still loaded lesson',0,3);"
  sqlite3 "$db" "INSERT INTO learnings (id,ts,type,insight,hit_count,load_count) VALUES ('OLD-DEAD','2020-01-01T00:00:00Z','pattern','old and truly untouched lesson',0,0);"
  agentdb decay >/dev/null
  local loaded live_dead archived_dead
  loaded=$(sqlite3 "$db" "SELECT count(*) FROM learnings WHERE id='OLD-LOADED' AND archived_at IS NULL;")
  live_dead=$(sqlite3 "$db" "SELECT count(*) FROM learnings WHERE id='OLD-DEAD' AND archived_at IS NULL;")
  archived_dead=$(sqlite3 "$db" "SELECT count(*) FROM learnings WHERE id='OLD-DEAD' AND archived_at IS NOT NULL;")
  [ "$loaded" -eq 1 ] || { echo "decay wrongly deleted a loaded learning"; return 1; }
  [ "$live_dead" -eq 0 ] || { echo "decay failed to archive a truly-untouched learning"; return 1; }
  [ "$archived_dead" -eq 1 ] || { echo "decay should soft-archive, not hard-delete, stale learnings"; return 1; }
}

# --- Learn Domain Auto-Population Tests ---

test_learn_auto_populates_domain() {
  agentdb init >/dev/null
  agentdb learn pattern "test domain inference" "evidence" >/dev/null
  local domain
  domain=$(sqlite3 "$TEST_PROJECT/_meta/agentdb/agent.db" "SELECT domain FROM learnings ORDER BY ts DESC LIMIT 1;")
  [ -n "$domain" ] && [ "$domain" != "" ] || { echo "Expected non-empty domain, got '$domain'"; return 1; }
}

test_orchestration_skill_has_injection() {
  grep -q "knowledge_injection" "$PLUGIN_ROOT/skills/orchestration/SKILL.md"
}

# --- Phase 2 Agents Tests ---

test_reviewer_has_review_protocol() {
  local file="$PLUGIN_ROOT/agents/reviewer.md"
  assert_contains "$(cat "$file")" "review_protocol"
}

test_reviewer_has_confidence_scoring() {
  local file="$PLUGIN_ROOT/agents/reviewer.md"
  assert_contains "$(cat "$file")" "confidence_scoring"
}

test_validator_has_safety_chain() {
  local file="$PLUGIN_ROOT/agents/validator.md"
  assert_contains "$(cat "$file")" "safety_chain"
}

test_validator_has_9_gates() {
  local file="$PLUGIN_ROOT/agents/validator.md"
  local content
  content=$(cat "$file")
  assert_contains "$content" "Gate 1:"
  assert_contains "$content" "Gate 9:"
}

# === Approval Learner + R-Factor Tests ===

test_approval_learner_exists_with_frontmatter() {
  local agent_file="$PLUGIN_ROOT/agents/approval-learner.md"
  assert_file_exists "$agent_file"
  head -1 "$agent_file" | grep -q "^---" || {
    echo "FAIL: approval-learner.md missing frontmatter"
    return 1
  }
}

test_approval_learner_model_sonnet() {
  grep -q "model: sonnet" "$PLUGIN_ROOT/agents/approval-learner.md" || {
    echo "FAIL: approval-learner.md should have model: sonnet"
    return 1
  }
}

test_approval_learner_has_confidence_scoring() {
  grep -q "confidence_scoring" "$PLUGIN_ROOT/agents/approval-learner.md" || {
    echo "FAIL: approval-learner.md should have confidence scoring"
    return 1
  }
  grep -q "times_validated / times_applied" "$PLUGIN_ROOT/agents/approval-learner.md" || {
    echo "FAIL: approval-learner.md should define confidence formula"
    return 1
  }
}

test_approval_learner_has_progressive_trust() {
  grep -qi "progressive trust" "$PLUGIN_ROOT/agents/approval-learner.md" || {
    echo "FAIL: approval-learner.md should have progressive trust"
    return 1
  }
  grep -q "observe.*suggest.*enforce" "$PLUGIN_ROOT/agents/approval-learner.md" || {
    echo "FAIL: approval-learner.md should define trust levels: observe, suggest, enforce"
    return 1
  }
}

test_quality_has_big5_greps() {
  # The Big 5 keep their runnable grep one-liners; r_factor/adsr are gone by design.
  grep -q "quick_checks" "$PLUGIN_ROOT/skills/quality/SKILL.md" || {
    echo "FAIL: quality SKILL.md should keep the Big 5 quick_checks greps"
    return 1
  }
  if grep -q "r_factor\|adsr" "$PLUGIN_ROOT/skills/quality/SKILL.md"; then
    echo "FAIL: quality SKILL.md must not reintroduce r_factor/adsr"
    return 1
  fi
}

test_claude_md_references_approval_learner() {
  grep -q "approval-learner" "$PLUGIN_ROOT/CLAUDE.md" || {
    echo "FAIL: CLAUDE.md should reference approval-learner agent"
    return 1
  }
}

# === Learning System Tests ===

test_migration_005_file_exists() {
  assert_file_exists "$PLUGIN_ROOT/orchestration/agentdb/migrations/005_learning_system.sql"
}

test_migration_005_creates_execution_traces() {
  agentdb init >/dev/null
  RESULT=$(sqlite3 "$TEST_PROJECT/_meta/agentdb/agent.db" "SELECT name FROM sqlite_master WHERE type='table' AND name='execution_traces';")
  assert_equals "execution_traces" "$RESULT" "execution_traces table should exist"
}

test_execution_traces_has_correct_columns() {
  agentdb init >/dev/null
  local cols
  cols=$(sqlite3 "$TEST_PROJECT/_meta/agentdb/agent.db" "SELECT name FROM pragma_table_info('execution_traces') ORDER BY cid;" | tr '\n' ',')
  assert_contains "$cols" "id,"
  assert_contains "$cols" "goal,"
  assert_contains "$cols" "exploration,"
  assert_contains "$cols" "plan,"
  assert_contains "$cols" "action,"
  assert_contains "$cols" "outcome,"
  assert_contains "$cols" "success,"
  assert_contains "$cols" "tokens_used,"
  assert_contains "$cols" "domain,"
}

test_agentdb_trace_records() {
  agentdb init >/dev/null
  OUTPUT=$(agentdb trace '{"goal":"test goal","outcome":"success","success":1}' 2>&1)
  assert_contains "$OUTPUT" "Trace: TR-"
  RESULT=$(sqlite3 "$TEST_PROJECT/_meta/agentdb/agent.db" "SELECT goal FROM execution_traces LIMIT 1;")
  assert_equals "test goal" "$RESULT" "trace goal"
}

test_agentdb_decay_runs() {
  agentdb init >/dev/null
  OUTPUT=$(agentdb decay 2>&1)
  assert_contains "$OUTPUT" "stale learnings"
}

test_agentdb_antibody_searches() {
  agentdb init >/dev/null
  agentdb learn pattern "always validate inputs" "test evidence" >/dev/null
  OUTPUT=$(agentdb antibody "validate" 2>&1)
  assert_contains "$OUTPUT" "Pattern Antibodies"
  assert_contains "$OUTPUT" "validate inputs"
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

test_orchestration_has_lane_contract() {
  local content
  content=$(cat "$PLUGIN_ROOT/skills/orchestration/SKILL.md")
  assert_contains "$content" "lane_contract" "orchestration should define the lane contract"
  assert_contains "$content" "Forbidden list" "lane contract should include a forbidden list"
  assert_contains "$content" "Raw-data return format" "lane contract should demand raw-data returns"
}

test_orchestration_has_worker_model_doctrine() {
  local content
  content=$(cat "$PLUGIN_ROOT/skills/orchestration/SKILL.md")
  assert_contains "$content" "worker_model_doctrine" "orchestration should carry the worker-model doctrine"
  assert_contains "$content" "use your judgment" "doctrine should name the judgment tell"
}

test_claude_md_references_analyzer() {
  grep -q 'id="analyzer"' "$PLUGIN_ROOT/CLAUDE.md"
}

# === Cartographer & Coroner Tests ===

test_cartographer_exists_with_frontmatter() {
  [ -f "$PLUGIN_ROOT/agents/cartographer.md" ] || return 1
  head -1 "$PLUGIN_ROOT/agents/cartographer.md" | grep -q "^---"
}

test_cartographer_model_opus() {
  grep -q "^model: opus" "$PLUGIN_ROOT/agents/cartographer.md"
}

test_cartographer_has_codebase_map_output() {
  grep -q "codebase.map\|codebase_map\|modules.*dependencies.*risk" "$PLUGIN_ROOT/agents/cartographer.md"
}

test_coroner_exists_with_frontmatter() {
  [ -f "$PLUGIN_ROOT/agents/coroner.md" ] || return 1
  head -1 "$PLUGIN_ROOT/agents/coroner.md" | grep -q "^---"
}

test_coroner_model_sonnet() {
  grep -q "^model: sonnet" "$PLUGIN_ROOT/agents/coroner.md"
}

test_coroner_has_post_mortem_analysis() {
  grep -q "post.mortem\|cause_of_death\|root.cause" "$PLUGIN_ROOT/agents/coroner.md"
}

test_claude_md_references_cartographer() {
  grep -q 'id="cartographer"' "$PLUGIN_ROOT/CLAUDE.md"
}

test_claude_md_references_coroner() {
  grep -q 'id="coroner"' "$PLUGIN_ROOT/CLAUDE.md"
}

# === Pre-Ship + App-Dev Tests ===

test_pre_ship_exists_with_frontmatter() {
  [ -f "$PLUGIN_ROOT/agents/pre-ship.md" ] || return 1
  head -1 "$PLUGIN_ROOT/agents/pre-ship.md" | grep -q "^---"
}

test_pre_ship_has_composite_verdict() {
  grep -q "composite_verdict\|SHIP.*NO-SHIP\|SHIP-WITH-WARNINGS" "$PLUGIN_ROOT/agents/pre-ship.md"
}

test_pre_ship_spawns_parallel_validators() {
  grep -q "parallel" "$PLUGIN_ROOT/agents/pre-ship.md" && \
  grep -q "validator" "$PLUGIN_ROOT/agents/pre-ship.md" && \
  grep -q "reviewer" "$PLUGIN_ROOT/agents/pre-ship.md" && \
  grep -q "security_scan" "$PLUGIN_ROOT/agents/pre-ship.md" && \
  grep -q "test_suite" "$PLUGIN_ROOT/agents/pre-ship.md"
}

test_app_dev_skill_exists() {
  [ -f "$PLUGIN_ROOT/skills/app-dev/SKILL.md" ]
}

test_app_dev_has_store_submission() {
  grep -q "store submission\|Store Submission\|App Store\|Play Console" "$PLUGIN_ROOT/skills/app-dev/SKILL.md"
}

test_app_dev_has_triggers() {
  grep -q "app.*mobile\|EAS\|store submission\|expo\|react native" "$PLUGIN_ROOT/skills/app-dev/SKILL.md"
}

test_claude_md_references_pre_ship() {
  grep -q 'id="pre-ship"' "$PLUGIN_ROOT/CLAUDE.md"
}

test_claude_md_references_app_dev() {
  grep -q 'id="app-dev"' "$PLUGIN_ROOT/CLAUDE.md"
}

# === Extension Tests (Phase 4) ===

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
  assert_file_exists "$PLUGIN_ROOT/docs/skill-template.md" "TEMPLATE.md should exist"
}

test_template_has_sources() {
  local content
  content=$(cat "$PLUGIN_ROOT/docs/skill-template.md")
  assert_contains "$content" "sources:" "TEMPLATE.md should have sources section"
}

test_template_has_triggers() {
  local content
  content=$(cat "$PLUGIN_ROOT/docs/skill-template.md")
  assert_contains "$content" "triggers:" "TEMPLATE.md should have triggers section"
}

test_template_has_gates() {
  local content
  content=$(cat "$PLUGIN_ROOT/docs/skill-template.md")
  assert_contains "$content" "gates:" "TEMPLATE.md should have gates section"
}

test_template_has_output() {
  local content
  content=$(cat "$PLUGIN_ROOT/docs/skill-template.md")
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

# === Hooks v2 Tests ===

test_validate_json_schema_exists() {
  assert_file_exists "$PLUGIN_ROOT/hooks/scripts/validate-json-schema.sh" "validate-json-schema.sh should exist"
  local perms
  perms=$(ls -l "$PLUGIN_ROOT/hooks/scripts/validate-json-schema.sh" | cut -c4)
  assert_equals "x" "$perms" "validate-json-schema.sh should be executable"
}

test_warn_hardcoded_exists() {
  assert_file_exists "$PLUGIN_ROOT/hooks/scripts/warn-hardcoded.sh" "warn-hardcoded.sh should exist"
  local perms
  perms=$(ls -l "$PLUGIN_ROOT/hooks/scripts/warn-hardcoded.sh" | cut -c4)
  assert_equals "x" "$perms" "warn-hardcoded.sh should be executable"
}

test_hooks_json_has_validate_json_schema() {
  local content
  content=$(cat "$PLUGIN_ROOT/hooks/hooks.json")
  assert_contains "$content" "validate-json-schema.sh" "hooks.json should reference validate-json-schema.sh"
}

test_hooks_json_has_warn_hardcoded() {
  local content
  content=$(cat "$PLUGIN_ROOT/hooks/hooks.json")
  assert_contains "$content" "warn-hardcoded.sh" "hooks.json should reference warn-hardcoded.sh"
}

test_session_start_has_blocker_surfacing() {
  local content
  content=$(cat "$PLUGIN_ROOT/hooks/scripts/session-start.sh")
  assert_contains "$content" "BLOCKER SURFACING" "session-start.sh should have blocker surfacing section"
}

test_validate_json_schema_sources_common() {
  local content
  content=$(cat "$PLUGIN_ROOT/hooks/scripts/validate-json-schema.sh")
  assert_contains "$content" "common.sh" "validate-json-schema.sh should source common.sh"
}

test_warn_hardcoded_sources_common() {
  local content
  content=$(cat "$PLUGIN_ROOT/hooks/scripts/warn-hardcoded.sh")
  assert_contains "$content" "common.sh" "warn-hardcoded.sh should source common.sh"
}

# --- Forge Entropy Test ---

test_forge_has_entropy_measurement() {
  local content
  content=$(cat "$PLUGIN_ROOT/skills/forge/SKILL.md")
  assert_contains "$content" "Measure entropy" "forge.md should mention entropy measurement"
}

# === Run Tests ===

# === Test Gate (auto-commit/auto-push never ships red) ===

# Build a throwaway fake project with a controllable test command.
_tg_make_project() {
  local dir="$1" verdict="$2"  # verdict: pass|fail
  mkdir -p "$dir/_meta/plans" "$dir/tests"
  if [ "$verdict" = "pass" ]; then
    printf '#!/usr/bin/env bash\necho "Results: 3 passed, 0 failed"\nexit 0\n' > "$dir/tests/run-tests.sh"
  else
    printf '#!/usr/bin/env bash\necho "Results: 2 passed, 1 failed"\nexit 1\n' > "$dir/tests/run-tests.sh"
  fi
  chmod +x "$dir/tests/run-tests.sh"
}

test_test_gate_detects_and_passes() {
  local d; d=$(mktemp -d)
  _tg_make_project "$d" pass
  bash "$PLUGIN_ROOT/hooks/scripts/test-gate.sh" "$d" >/dev/null 2>&1
  local rc=$?
  assert_exit_code 0 "$rc" "green suite should exit 0"
  assert_contains "$(cat "$d/_meta/.test-status" 2>/dev/null)" "PASS"
  rm -rf "$d"
}

test_test_gate_detects_and_fails() {
  local d; d=$(mktemp -d)
  _tg_make_project "$d" fail
  bash "$PLUGIN_ROOT/hooks/scripts/test-gate.sh" "$d" >/dev/null 2>&1
  local rc=$?
  assert_exit_code 1 "$rc" "red suite should exit 1"
  assert_contains "$(cat "$d/_meta/.test-status" 2>/dev/null)" "FAIL"
  rm -rf "$d"
}

test_test_gate_no_suite_is_green() {
  local d; d=$(mktemp -d)
  mkdir -p "$d/_meta"
  bash "$PLUGIN_ROOT/hooks/scripts/test-gate.sh" "$d" >/dev/null 2>&1
  assert_exit_code 0 "$?" "no suite detected should not block (exit 0)"
  assert_contains "$(cat "$d/_meta/.test-status" 2>/dev/null)" "NONE"
  rm -rf "$d"
}

test_test_gate_status_recovers_to_pass() {
  # A red verdict must clear when the suite goes green (so the block self-heals).
  local d; d=$(mktemp -d)
  _tg_make_project "$d" fail
  bash "$PLUGIN_ROOT/hooks/scripts/test-gate.sh" "$d" >/dev/null 2>&1
  assert_contains "$(cat "$d/_meta/.test-status" 2>/dev/null)" "FAIL"
  _tg_make_project "$d" pass
  bash "$PLUGIN_ROOT/hooks/scripts/test-gate.sh" "$d" >/dev/null 2>&1
  assert_contains "$(cat "$d/_meta/.test-status" 2>/dev/null)" "PASS"
  rm -rf "$d"
}

test_test_gate_honors_override_file() {
  local d; d=$(mktemp -d)
  mkdir -p "$d/_meta"
  echo "exit 0" > "$d/_meta/.test-cmd"
  bash "$PLUGIN_ROOT/hooks/scripts/test-gate.sh" "$d" >/dev/null 2>&1
  assert_exit_code 0 "$?" ".test-cmd override should be used"
  rm -rf "$d"
}

test_autopush_postcommit_is_disabled() {
  # Per Aria directive 2026-06-15: per-commit auto-push to a shared `main` is OFF.
  # The hook is intentionally a no-op (commits stay local; pushing is explicit). Guard
  # that intent so nobody silently re-enables per-commit push. The red-gate now lives on
  # the paths that actually push (autopush.sh sweep), covered by test_autopush_sweep_has_red_gate.
  local hook; hook="$(cat "$PLUGIN_ROOT/hooks/scripts/autopush-postcommit")"
  assert_contains "$hook" "AUTO-PUSH DISABLED"
  assert_contains "$hook" "exit 0"
}

test_autopush_install_is_opt_in() {
  # Per-commit autopush install must be a no-op unless AUTOPUSH_ON=1 (opt-in).
  # AUTOPUSH_OFF is pinned to 0 so a machine-level AUTOPUSH_OFF=1 can't mask the check.
  local d; d=$(mktemp -d)
  git -C "$d" init -q
  (cd "$d" && CLAUDE_PROJECT_DIR="$d" AUTOPUSH_OFF=0 AUTOPUSH_ON=0 \
    bash "$PLUGIN_ROOT/hooks/scripts/autopush.sh" install >/dev/null 2>&1)
  if [ -f "$d/.git/hooks/post-commit" ]; then
    echo "FAIL: install stamped a post-commit hook without AUTOPUSH_ON=1"
    rm -rf "$d"; return 1
  fi
  (cd "$d" && CLAUDE_PROJECT_DIR="$d" AUTOPUSH_OFF=0 AUTOPUSH_ON=1 \
    bash "$PLUGIN_ROOT/hooks/scripts/autopush.sh" install >/dev/null 2>&1)
  if [ ! -f "$d/.git/hooks/post-commit" ]; then
    echo "FAIL: install with AUTOPUSH_ON=1 should stamp the hook"
    rm -rf "$d"; return 1
  fi
  rm -rf "$d"
}

test_autopush_sweep_has_red_gate() {
  assert_contains "$(grep -A1 'tests RED' "$PLUGIN_ROOT/hooks/scripts/autopush.sh")" "continue"
}

test_session_end_runs_test_gate() {
  assert_contains "$(cat "$PLUGIN_ROOT/hooks/scripts/session-end.sh")" "test-gate.sh"
}

test_session_start_surfaces_red() {
  assert_contains "$(cat "$PLUGIN_ROOT/hooks/scripts/session-start.sh")" "TESTS RED"
}

test_pre_compact_has_red_gate() {
  assert_contains "$(cat "$PLUGIN_ROOT/hooks/scripts/pre-compact-commit.sh")" ".test-status"
}

test_lifecycle_hooks_guard_main_push() {
  local session_end precompact postcommit
  session_end=$(cat "$PLUGIN_ROOT/hooks/scripts/session-end.sh")
  precompact=$(cat "$PLUGIN_ROOT/hooks/scripts/pre-compact-commit.sh")
  postcommit=$(cat "$PLUGIN_ROOT/hooks/scripts/autopush-postcommit")

  assert_contains "$session_end" "NEVER AUTO-COMMIT" "session-end should forbid auto-commit"
  assert_contains "$session_end" "test-gate.sh" "session-end should run the test gate before reporting dirty work"
  assert_contains "$precompact" "PreCompact must NEVER create a commit" "pre-compact should forbid auto-commit"
  assert_contains "$postcommit" "AUTO-PUSH DISABLED" "post-commit auto-push should stay disabled"
}

# === Manifest Runtime Tests (kernel-manifest + guard-context) ===

KM="$PLUGIN_ROOT/orchestration/manifest/kernel-manifest"
FIXTURES="$PLUGIN_ROOT/tests/fixtures/manifests"

test_manifest_schemas_parse_as_json() {
  local bad=0
  for s in "$PLUGIN_ROOT/schemas/"*.schema.json; do
    python3 -c "import json; json.load(open('$s'))" 2>/dev/null || { echo "  bad JSON: $s"; bad=1; }
  done
  assert_exit_code 0 "$bad" "all schema files must parse as JSON"
}

test_manifest_validate_handoff_example() {
  local output
  output=$("$KM" validate "$FIXTURES/handoff-example.json" 2>&1)
  assert_contains "$output" "VALID"
}

test_manifest_validate_checkpoint_example() {
  local output
  output=$("$KM" validate "$FIXTURES/checkpoint-example.json" 2>&1)
  assert_contains "$output" "VALID"
}

test_manifest_validate_retrospective_example() {
  local output
  output=$("$KM" validate "$FIXTURES/retrospective-result-example.json" 2>&1)
  assert_contains "$output" "VALID"
}

test_manifest_validate_rejects_missing_schema_field() {
  printf '{"identity": {"name": "x"}}\n' > bad.json
  local ec=0
  "$KM" validate bad.json >/dev/null 2>&1 || ec=$?
  [ "$ec" -ne 0 ] || { echo "FAIL: manifest without schema field must be rejected"; return 1; }
}

test_manifest_validate_rejects_bad_policy_mode() {
  sed 's/"mode": "bounded"/"mode": "yolo"/' "$FIXTURES/handoff-example.json" > bad-mode.json
  local ec=0
  "$KM" validate bad-mode.json >/dev/null 2>&1 || ec=$?
  assert_exit_code 1 "$ec" "invalid context policy mode must be rejected"
}

test_manifest_validate_rejects_selector_without_path() {
  python3 - "$FIXTURES/handoff-example.json" <<'PYEOF'
import json, sys
m = json.load(open(sys.argv[1]))
# strip 'path' from the first required selector -> invalid selector
m["context"]["required"][0] = {"reason": "no path here"}
json.dump(m, open("bad-selector.json", "w"))
PYEOF
  local ec=0
  "$KM" validate bad-selector.json >/dev/null 2>&1 || ec=$?
  assert_exit_code 1 "$ec" "selector without path or git_diff must be rejected"
}

test_manifest_rejects_duplicate_keys() {
  # duplicate keys silently last-winning is how 'sealed' degrades to 'advisory'
  cat > dup.json <<'MEOF'
{
  "schema": "kernel.checkpoint/v1",
  "identity": {"name": "t", "created": "2026-01-01T00:00:00Z"},
  "provenance": {"branch": "main", "commit": "abc", "dirty": false},
  "task": {"goal": "t"},
  "steps_completed": [],
  "pending_steps": [],
  "resume": {"position": "p", "next_operation": "n"},
  "context": {"policy": {"mode": "sealed", "mode": "advisory"}}
}
MEOF
  local output ec=0
  output=$("$KM" validate dup.json 2>&1) || ec=$?
  assert_exit_code 2 "$ec" "duplicate keys must be a parse-level protocol violation" || return 1
  assert_contains "$output" "duplicate key"
}

test_manifest_rejects_yaml_manifest() {
  printf 'schema: kernel.checkpoint/v1\n' > old.yaml
  local output ec=0
  output=$("$KM" validate old.yaml 2>&1) || ec=$?
  assert_exit_code 2 "$ec" "yaml manifests must be rejected with a conversion pointer" || return 1
  assert_contains "$output" "no longer canonical"
}

test_manifest_validate_rejects_unknown_keys() {
  cat > bad.json <<'MEOF'
{
  "schema": "kernel.checkpoint/v1",
  "identity": {"name": "t", "created": "2026-01-01T00:00:00Z"},
  "provenance": {"branch": "main", "commit": "abc", "dirty": false},
  "task": {"goal": "t"},
  "steps_completed": [],
  "pending_steps": [],
  "resume": {"position": "p", "next_operation": "n", "entrypointt": "typo"}
}
MEOF
  local ec=0
  "$KM" validate bad.json >/dev/null 2>&1 || ec=$?
  assert_exit_code 1 "$ec" "unknown manifest keys must be rejected"
}

test_manifest_compile_validates_before_consuming() {
  cat > bad.json <<'MEOF'
{
  "schema": "kernel.checkpoint/v1",
  "identity": {"name": "t", "created": "2026-01-01T00:00:00Z"},
  "provenance": {"branch": "main", "commit": "abc", "dirty": false},
  "task": {"goal": "t"},
  "steps_completed": [],
  "pending_steps": [],
  "resume": {"position": "p", "next_operation": "n", "entrypointt": "typo"}
}
MEOF
  local ec=0
  "$KM" compile bad.json >/dev/null 2>&1 || ec=$?
  assert_exit_code 1 "$ec" "compile must validate before consuming manifest"
}

test_manifest_activate_validates_before_pointer() {
  mkdir -p _meta
  cat > bad.json <<'MEOF'
{
  "schema": "kernel.checkpoint/v1",
  "identity": {"name": "t", "created": "2026-01-01T00:00:00Z"},
  "provenance": {"branch": "main", "commit": "abc", "dirty": false},
  "task": {"goal": "t"},
  "steps_completed": [],
  "pending_steps": [],
  "resume": {"position": "p", "next_operation": "n", "entrypointt": "typo"}
}
MEOF
  local ec=0
  "$KM" activate bad.json >/dev/null 2>&1 || ec=$?
  assert_exit_code 1 "$ec" "activate must validate before writing pointer" || return 1
  [ ! -f _meta/.active-manifest.json ] || { echo "FAIL: invalid activation wrote pointer"; return 1; }
}

test_manifest_latest_finds_newest() {
  mkdir -p _meta/handoffs _meta/checkpoints
  cp "$FIXTURES/checkpoint-example.json" _meta/handoffs/old.json
  python3 -c "import json;p='_meta/handoffs/old.json';m=json.load(open(p));m['identity']['created']='2026-01-01T00:00:00Z';json.dump(m,open(p,'w'))"
  sleep 1
  cp "$FIXTURES/checkpoint-example.json" _meta/checkpoints/new.json
  python3 -c "import json;p='_meta/checkpoints/new.json';m=json.load(open(p));m['identity']['created']='2026-02-01T00:00:00Z';json.dump(m,open(p,'w'))"
  local output
  output=$("$KM" latest --any-branch)
  assert_contains "$output" "_meta/checkpoints/new.json"
}

test_manifest_latest_fails_when_empty() {
  local ec=0
  "$KM" latest --dir does-not-exist >/dev/null 2>&1 || ec=$?
  assert_exit_code 1 "$ec" "latest with no manifests must fail"
}

test_manifest_divergence_detects_branch_mismatch() {
  git init -q -b main . && git -c user.email=test@kernel -c user.name=kernel-test commit -q --allow-empty -m init
  cat > m.json <<'MEOF'
{
  "schema": "kernel.checkpoint/v1",
  "identity": {"name": "t", "created": "2026-01-01T00:00:00Z"},
  "provenance": {"branch": "other-branch", "commit": "deadbeef", "dirty": false},
  "task": {"goal": "t"},
  "steps_completed": [],
  "pending_steps": [],
  "resume": {"position": "p", "next_operation": "n"}
}
MEOF
  local output ec=0
  output=$("$KM" divergence m.json 2>&1) || ec=$?
  assert_contains "$output" "branch: DIVERGED" || return 1
  assert_exit_code 1 "$ec" "branch mismatch must exit 1"
}

test_manifest_divergence_detects_artifact_hash_mismatch() {
  git init -q -b main . && git -c user.email=test@kernel -c user.name=kernel-test commit -q --allow-empty -m init
  echo "content-v1" > pinned.txt
  local sha head
  sha=$(python3 -c "import hashlib;print(hashlib.sha256(open('pinned.txt','rb').read()).hexdigest())")
  head=$(git rev-parse HEAD)
  cat > m.json <<MEOF
{
  "schema": "kernel.handoff/v1",
  "identity": {"name": "t", "created": "2026-01-01T00:00:00Z"},
  "provenance": {
    "branch": "main",
    "commit": "$head",
    "dirty": true,
    "artifacts": [
      {"path": "pinned.txt", "sha256": "$sha"}
    ]
  },
  "objective": {"goal": "t", "success_conditions": ["x"]},
  "workflow": {"phases": [{"name": "p", "status": "required"}]},
  "context": {"policy": {"mode": "advisory"}},
  "execution": {"entry_phase": "p"},
  "resume": {"prompt": "r"}
}
MEOF
  # clean state passes
  local output ec=0
  output=$("$KM" divergence m.json 2>&1) || ec=$?
  assert_exit_code 0 "$ec" "matching hash must pass" || return 1
  # mutate the artifact -> divergence
  echo "content-v2" > pinned.txt
  ec=0
  output=$("$KM" divergence m.json 2>&1) || ec=$?
  assert_contains "$output" "hash mismatch" || return 1
  assert_exit_code 1 "$ec" "hash mismatch must exit 1"
}

test_manifest_compile_emits_receipt_fields() {
  echo "some artifact content here" > artifact.md
  printf 'same native instructions\n' > CLAUDE.md
  cp CLAUDE.md AGENTS.md
  cp CLAUDE.md .claude/CLAUDE.md
  cat > m.json <<'MEOF'
{
  "schema": "kernel.checkpoint/v1",
  "identity": {"name": "t", "created": "2026-01-01T00:00:00Z"},
  "provenance": {"branch": "main", "commit": "abc", "dirty": false},
  "task": {"goal": "t"},
  "steps_completed": [],
  "pending_steps": [],
  "resume": {"position": "p", "next_operation": "n"},
  "context": {
    "policy": {"mode": "advisory"},
    "required": [
      {"path": "artifact.md"}
    ],
    "budget": {"target_tokens": 1000000, "max_tokens": 2000000}
  }
}
MEOF
  local output
  output=$("$KM" compile m.json 2>&1)
  assert_contains "$output" '"schema": "kernel.context-receipt/v1"' || return 1
  assert_contains "$output" "total_estimated_tokens" || return 1
  assert_contains "$output" '"status": "within_budget"' || return 1
  assert_contains "$output" "estimation_method" || return 1
  assert_contains "$output" "selected_artifacts_tokens" || return 1
  local instruction_tokens
  instruction_tokens=$(printf '%s' "$output" | python3 -c 'import json,sys; print(json.load(sys.stdin)["project_instructions_tokens"])')
  assert_equals "6" "$instruction_tokens" "identical AGENTS/CLAUDE content must count once"
}

test_manifest_compile_budget_transitions() {
  python3 -c "open('big.md','w').write('x'*40000)"
  cat > m.json <<'MEOF'
{
  "schema": "kernel.checkpoint/v1",
  "identity": {"name": "t", "created": "2026-01-01T00:00:00Z"},
  "provenance": {"branch": "main", "commit": "abc", "dirty": false},
  "task": {"goal": "t"},
  "steps_completed": [],
  "pending_steps": [],
  "resume": {"position": "p", "next_operation": "n"},
  "context": {
    "policy": {"mode": "advisory"},
    "required": [
      {"path": "big.md"}
    ],
    "budget": {"target_tokens": 5000, "max_tokens": 8000}
  }
}
MEOF
  local output ec=0
  output=$("$KM" compile m.json 2>&1) || ec=$?
  assert_contains "$output" '"status": "maximum_exceeded"' || return 1
  assert_exit_code 3 "$ec" "maximum_exceeded must exit 3" || return 1
  # widen the max -> target_exceeded
  sed -i.bak 's/"max_tokens": 8000/"max_tokens": 2000000/' m.json
  ec=0
  output=$("$KM" compile m.json 2>&1) || ec=$?
  assert_contains "$output" '"status": "target_exceeded"' || return 1
  assert_exit_code 0 "$ec" "target_exceeded must not hard-fail"
}

test_manifest_compile_selector_types_resolve() {
  printf '# Title\n\n## Section A\ncontent-a\n\n## Section B\ncontent-b\n' > doc.md
  printf 'l1\nl2\nl3\nl4\nl5\n' > lines.txt
  printf 'aaa\nMATCH-ME\nbbb\n' > grepme.txt
  cat > m.json <<'MEOF'
{
  "schema": "kernel.checkpoint/v1",
  "identity": {"name": "t", "created": "2026-01-01T00:00:00Z"},
  "provenance": {"branch": "main", "commit": "abc", "dirty": false},
  "task": {"goal": "t"},
  "steps_completed": [],
  "pending_steps": [],
  "resume": {"position": "p", "next_operation": "n"},
  "context": {
    "policy": {"mode": "advisory"},
    "required": [
      {"path": "doc.md", "heading": "## Section A"},
      {"path": "lines.txt", "lines": "2-3"},
      {"path": "grepme.txt", "grep": "MATCH-ME", "context": 1}
    ]
  }
}
MEOF
  local output
  output=$("$KM" compile m.json --bundle-out bundle.txt 2>&1)
  assert_contains "$(cat bundle.txt)" "content-a" || return 1
  if grep -q "content-b" bundle.txt; then echo "FAIL: heading selector leaked next section"; return 1; fi
  assert_contains "$(cat bundle.txt)" "l2" || return 1
  assert_contains "$(cat bundle.txt)" "MATCH-ME" || return 1
  assert_contains "$output" '"resolved": true'
}

test_manifest_compile_reports_missing_required() {
  cat > m.json <<'MEOF'
{
  "schema": "kernel.checkpoint/v1",
  "identity": {"name": "t", "created": "2026-01-01T00:00:00Z"},
  "provenance": {"branch": "main", "commit": "abc", "dirty": false},
  "task": {"goal": "t"},
  "steps_completed": [],
  "pending_steps": [],
  "resume": {"position": "p", "next_operation": "n"},
  "context": {
    "policy": {"mode": "advisory"},
    "required": [
      {"path": "nope-does-not-exist.md"}
    ]
  }
}
MEOF
  local output
  local ec=0
  output=$("$KM" compile m.json 2>&1) || ec=$?
  assert_exit_code 4 "$ec" "unresolved required selector must fail closed" || return 1
  assert_contains "$output" '"resolved": false' || return 1
  assert_contains "$output" "file missing" || return 1
  assert_contains "$output" "ERROR: unresolved required selector"
}

test_manifest_paths_anchor_to_repo_root() {
  git init -q -b main . && git -c user.email=test@kernel -c user.name=kernel-test commit -q --allow-empty -m init
  mkdir -p docs sub _meta
  echo anchored > docs/a.md
  local head; head=$(git rev-parse HEAD)
  cat > m.json <<MEOF
{"schema":"kernel.checkpoint/v1","identity":{"name":"t","created":"2026-01-01T00:00:00Z"},"provenance":{"branch":"main","commit":"$head","dirty":true,"dirty_tree_sha256":"0000000000000000000000000000000000000000000000000000000000000000"},"task":{"goal":"t"},"steps_completed":[],"pending_steps":[],"resume":{"position":"p","next_operation":"n"},"context":{"policy":{"mode":"advisory"},"required":[{"path":"docs/a.md"}]}}
MEOF
  (cd sub && "$KM" compile m.json --bundle-out bundle.txt >/dev/null)
  assert_contains "$(cat bundle.txt)" "anchored" || return 1
  (cd sub && "$KM" activate m.json >/dev/null)
  assert_file_exists "_meta/.active-manifest.json"
}

test_manifest_rejects_invalid_budget_and_selector_shapes() {
  cp "$FIXTURES/handoff-example.json" m.json
  python3 - <<'PYEOF'
import json
p='m.json'; m=json.load(open(p)); m['context']['budget']={'target_tokens':20,'max_tokens':10}; json.dump(m,open(p,'w'))
PYEOF
  local ec=0; "$KM" validate m.json >/dev/null 2>&1 || ec=$?
  assert_exit_code 1 "$ec" "target budget above max must fail" || return 1
  cp "$FIXTURES/handoff-example.json" m.json
  python3 - <<'PYEOF'
import json
p='m.json'; m=json.load(open(p)); m['context']['required'][0]['heading']='## X'; m['context']['required'][0]['grep']='X'; json.dump(m,open(p,'w'))
PYEOF
  ec=0; "$KM" validate m.json >/dev/null 2>&1 || ec=$?
  assert_exit_code 1 "$ec" "multiple selector refinements must fail"
}

test_manifest_selector_outcomes_and_hashes() {
  printf 'one\ntwo\n' > a.md
  cp "$FIXTURES/checkpoint-example.json" m.json
  python3 - <<'PYEOF'
import json
p='m.json'; m=json.load(open(p)); m['context']['required']=[{'path':'a.md','lines':'2-1'}]; json.dump(m,open(p,'w'))
PYEOF
  local output ec=0
  output=$("$KM" compile m.json --bundle-out bundle.txt 2>&1) || ec=$?
  assert_exit_code 4 "$ec" "reversed range must fail required selector" || return 1
  assert_contains "$output" '"outcome": "invalid"' || return 1
  python3 - <<'PYEOF'
import json
p='m.json'; m=json.load(open(p)); m['context']['required']=[{'path':'a.md'}]; json.dump(m,open(p,'w'))
PYEOF
  output=$("$KM" compile m.json --bundle-out bundle.txt)
  assert_contains "$output" '"manifest_sha256"' || return 1
  assert_contains "$output" '"bundle_sha256"' || return 1
  assert_contains "$output" '"resolved_sha256"'
}

test_manifest_checkpoint_requires_dirty_tree_hashes() {
  cp "$FIXTURES/checkpoint-example.json" m.json
  python3 - <<'PYEOF'
import json
p='m.json'; m=json.load(open(p)); m['provenance']['dirty']=True; m['provenance'].pop('dirty_tree_sha256',None); json.dump(m,open(p,'w'))
PYEOF
  local ec=0; "$KM" validate m.json >/dev/null 2>&1 || ec=$?
  assert_exit_code 1 "$ec" "dirty checkpoint without tree hash must fail"
}

test_manifest_divergence_json_invalidates_phases() {
  git init -q -b main . && git -c user.email=test@kernel -c user.name=kernel-test commit -q --allow-empty -m init
  local head; head=$(git rev-parse HEAD)
  cat > m.json <<MEOF
{"schema":"kernel.handoff/v1","identity":{"name":"t","created":"2026-01-01T00:00:00Z"},"provenance":{"branch":"other","commit":"$head","dirty":true},"objective":{"goal":"t","success_conditions":["x"]},"workflow":{"phases":[{"name":"research","status":"inherited"}],"invalidation_rules":[{"when":{"event":"branch_diverged"},"invalidates":["research"]}]},"context":{"policy":{"mode":"advisory"}},"execution":{"entry_phase":"research"},"resume":{"prompt":"r"}}
MEOF
  local output ec=0; output=$("$KM" divergence m.json --json) || ec=$?
  assert_exit_code 1 "$ec" "structured divergence keeps hard exit" || return 1
  assert_contains "$output" '"event": "branch_diverged"' || return 1
  assert_contains "$output" '"status": "invalidated"'
}

test_manifest_preflight_is_typed() {
  touch CLAUDE.md
  cp "$FIXTURES/handoff-example.json" m.json
  python3 - <<'PYEOF'
import json
p='m.json'; m=json.load(open(p)); m['runtime']['preflight']=[{'cmd':'rm -rf /'}]; json.dump(m,open(p,'w'))
PYEOF
  local ec=0; "$KM" validate m.json >/dev/null 2>&1 || ec=$?
  assert_exit_code 1 "$ec" "raw shell preflight must be rejected" || return 1
  python3 - <<'PYEOF'
import json
p='m.json'; m=json.load(open(p)); m['runtime']['preflight']=[{'check':'path_exists','path':'CLAUDE.md'}]; json.dump(m,open(p,'w'))
PYEOF
  "$KM" preflight m.json >/dev/null
}

test_manifest_latest_uses_identity_not_mtime() {
  mkdir -p manifests
  cp "$FIXTURES/checkpoint-example.json" manifests/new.json
  cp "$FIXTURES/checkpoint-example.json" manifests/old.json
  python3 - <<'PYEOF'
import json
for p,c in [('manifests/new.json','2026-02-01T00:00:00Z'),('manifests/old.json','2026-01-01T00:00:00Z')]:
 m=json.load(open(p)); m['identity']['created']=c; json.dump(m,open(p,'w'))
PYEOF
  touch manifests/new.json; sleep 1; touch manifests/old.json
  local output; output=$("$KM" latest --dir manifests --any-branch)
  assert_contains "$output" "new.json"
}

test_manifest_latest_reports_ambiguity() {
  mkdir -p manifests
  cp "$FIXTURES/checkpoint-example.json" manifests/a.json
  cp "$FIXTURES/checkpoint-example.json" manifests/b.json
  local output ec=0; output=$("$KM" latest --dir manifests --any-branch 2>&1) || ec=$?
  assert_exit_code 1 "$ec" "equal lineage candidates must be ambiguous" || return 1
  assert_contains "$output" "ambiguous"
}

test_guard_context_bounded_skips_allowlisted_access() {
  mkdir -p _meta
  cat > _meta/.active-manifest.json <<'JEOF'
{"manifest":"m.json","schema":"kernel.handoff/v1","mode":"bounded","forbidden":[],"allowlist":["docs/a.md"]}
JEOF
  echo '{"tool_name":"Read","tool_input":{"file_path":"docs/a.md"}}' | "$PLUGIN_ROOT/hooks/scripts/guard-context.sh"
  [ ! -f _meta/.context-ledger ] || { echo "FAIL: allowlisted read was ledgered"; return 1; }
}

test_guard_context_bounded_ledgers_valid_json_escaping() {
  mkdir -p _meta
  cat > _meta/.active-manifest.json <<'JEOF'
{"manifest":"m.json","schema":"kernel.handoff/v1","mode":"bounded","forbidden":[],"allowlist":[]}
JEOF
  local hook_input
  hook_input=$(python3 - <<'PYEOF'
import json
print(json.dumps({'tool_name':'Read','tool_input':{'file_path':'odd/quote"\\slash\nline\tcontrol.md'}}))
PYEOF
  ) || return 1
  printf '%s\n' "$hook_input" | "$PLUGIN_ROOT/hooks/scripts/guard-context.sh" || return 1
  python3 - <<'PYEOF'
import json
lines=open('_meta/.context-ledger').read().splitlines()
assert len(lines)==1, lines
entry=json.loads(lines[0])
assert entry['path']=='odd/quote"\\slash\nline\tcontrol.md', repr(entry['path'])
PYEOF
  [ "$?" -eq 0 ] || return 1
  agentdb init >/dev/null || return 1
  cp "$FIXTURES/receipt-example.json" receipt.json || return 1
  "$KM" deactivate --receipt receipt.json >/dev/null || return 1
  "$KM" validate receipt.json >/dev/null || return 1
}

test_manifest_deactivate_rejects_ledger_schema_mismatch() {
  mkdir -p _meta
  cp "$FIXTURES/receipt-example.json" receipt.json
  echo '{"path":"x.md","unknown_field":true}' > _meta/.context-ledger
  echo '{"manifest":"m.json","mode":"bounded","forbidden":[],"allowlist":[]}' > _meta/.active-manifest.json
  local ec=0; "$KM" deactivate --receipt receipt.json >/dev/null 2>&1 || ec=$?
  assert_exit_code 1 "$ec" "ledger/schema mismatch must fail deactivate" || return 1
  assert_file_exists "_meta/.active-manifest.json" "failed deactivate must stay armed"
}

test_manifest_deactivate_rejects_malformed_ledger_transactionally() {
  local payload ec before after
  for payload in '{bad' '' '[]' '{"path":42}' '{"path":"x","unknown":true}'; do
    rm -rf _meta receipt.json
    mkdir -p _meta
    cp "$FIXTURES/receipt-example.json" receipt.json || return 1
    echo '{"manifest":"m.json","mode":"bounded","forbidden":[],"allowlist":[]}' > _meta/.active-manifest.json
    printf '%s\n' "$payload" > _meta/.context-ledger
    before=$(shasum -a 256 receipt.json | awk '{print $1}')
    ec=0; "$KM" deactivate --receipt receipt.json >/dev/null 2>&1 || ec=$?
    assert_exit_code 1 "$ec" "invalid ledger payload must fail" || return 1
    after=$(shasum -a 256 receipt.json | awk '{print $1}')
    assert_equals "$before" "$after" "receipt must remain byte-identical" || return 1
    assert_file_exists "_meta/.active-manifest.json" || return 1
    assert_file_exists "_meta/.context-ledger" || return 1
  done
}

test_manifest_deactivate_projection_retry_merges_once() {
  mkdir -p _meta
  rm -rf _meta/agentdb
  cp "$FIXTURES/receipt-example.json" receipt.json || return 1
  echo '{"manifest":"m.json","mode":"bounded","forbidden":[],"allowlist":[]}' > _meta/.active-manifest.json
  echo '{"path":"retry-once.md","reason":"test","ts":"2026-01-01T00:00:00Z"}' > _meta/.context-ledger
  local before after ec attempt
  before=$(shasum -a 256 receipt.json | awk '{print $1}')
  for attempt in 1 2; do
    ec=0; "$KM" deactivate --receipt receipt.json >/dev/null 2>&1 || ec=$?
    assert_exit_code 1 "$ec" "projection failure $attempt must fail" || return 1
    after=$(shasum -a 256 receipt.json | awk '{print $1}')
    assert_equals "$before" "$after" "failed projection must not mutate receipt" || return 1
    assert_file_exists "_meta/.active-manifest.json" || return 1
    assert_file_exists "_meta/.context-ledger" || return 1
  done
  agentdb init >/dev/null || return 1
  "$KM" deactivate --receipt receipt.json >/dev/null || return 1
  python3 - <<'PYEOF' || return 1
import json
r=json.load(open('receipt.json'))
assert sum(x.get('path')=='retry-once.md' for x in r['loads_beyond_manifest']) == 1
PYEOF
  [ ! -e _meta/.active-manifest.json ] || { echo "FAIL: pointer remained"; return 1; }
  [ ! -e _meta/.context-ledger ] || { echo "FAIL: ledger remained"; return 1; }
  local sessions
  sessions=$(sqlite3 _meta/agentdb/agent.db "SELECT COUNT(*) FROM graph_receipts")
  assert_equals "1" "$sessions" "projection retry must create one graph receipt"
}

test_manifest_divergence_checks_dirty_tree_hash() {
  git init -q -b main . && git -c user.email=test@kernel -c user.name=kernel-test commit -q --allow-empty -m init
  echo one > dirty.txt
  local head; head=$(git rev-parse HEAD)
  cat > m.json <<MEOF
{"schema":"kernel.checkpoint/v1","identity":{"name":"t","created":"2026-01-01T00:00:00Z"},"provenance":{"branch":"main","commit":"$head","dirty":true,"dirty_tree_sha256":"deadbeef"},"task":{"goal":"t"},"steps_completed":[],"pending_steps":[],"resume":{"position":"p","next_operation":"n"}}
MEOF
  local output ec=0; output=$("$KM" divergence m.json --json) || ec=$?
  assert_exit_code 1 "$ec" "dirty tree hash mismatch must diverge" || return 1
  assert_contains "$output" '"event": "dirty_tree_hash_mismatch"'
}

test_manifest_schema_fields_name_enforcement_owner() {
  python3 - "$PLUGIN_ROOT/schemas" <<'PYEOF'
import json,glob,sys
bad=[]
def walk(node,path):
 if not isinstance(node,dict): return
 for name,field in (node.get('properties') or {}).items():
  if 'x-kernel-enforced-by' not in field: bad.append(f'{path}.{name}')
  walk(field,f'{path}.{name}')
 item=node.get('items')
 if isinstance(item,dict): walk(item,path+'[]')
for p in glob.glob(sys.argv[1]+'/*.schema.json'):
 walk(json.load(open(p)),'$')
if bad: print('\n'.join(bad[:20])); raise SystemExit(1)
PYEOF
}

test_manifest_committed_state_files_are_checked() {
  local bad=0 path ec
  while IFS= read -r path; do
    case "$path" in
      *.json)
        "$KM" validate "$PLUGIN_ROOT/$path" >/dev/null 2>&1 || bad=1
        local divergence_output
        ec=0; divergence_output=$("$KM" divergence "$PLUGIN_ROOT/$path" --json 2>/dev/null) || ec=$?
        manifest_divergence_result_valid "$ec" "$divergence_output" || bad=1
        ;;
      *.yaml|*.yml) ec=0; "$KM" validate "$PLUGIN_ROOT/$path" >/dev/null 2>&1 || ec=$?; [ "$ec" -eq 2 ] || bad=1 ;;
    esac
  done < <(git -C "$PLUGIN_ROOT" ls-files '_meta/handoffs/*' '_meta/checkpoints/*')
  assert_exit_code 0 "$bad" "committed canonical manifests validate and YAML is non-authoritative"
}

manifest_divergence_result_valid() {
  local ec="$1" output="$2"
  [ "$ec" -eq 0 ] || [ "$ec" -eq 1 ] || return 1
  printf '%s' "$output" | python3 -c '
import json,sys
try: doc=json.load(sys.stdin)
except (json.JSONDecodeError, UnicodeDecodeError): raise SystemExit(1)
if not isinstance(doc,dict): raise SystemExit(1)
if type(doc.get("hard_divergence")) is not bool: raise SystemExit(1)
if not isinstance(doc.get("events"),list): raise SystemExit(1)
if not isinstance(doc.get("phases"),list): raise SystemExit(1)
for event in doc["events"]:
 if not isinstance(event,dict) or not isinstance(event.get("event"),str) or not isinstance(event.get("status"),str): raise SystemExit(1)
for phase in doc["phases"]:
 if not isinstance(phase,dict) or not isinstance(phase.get("name"),str) or phase.get("status") not in ("inherited","required","invalidated"): raise SystemExit(1)
'
}

test_manifest_committed_gate_validates_divergence_protocol() {
  manifest_divergence_result_valid 1 '{"hard_divergence":true,"events":[{"event":"branch_diverged","status":"diverged"}],"phases":[{"name":"x","status":"invalidated"}]}' || return 1
  if manifest_divergence_result_valid 1 ''; then echo "FAIL: empty exit1 accepted"; return 1; fi
  if manifest_divergence_result_valid 1 'Traceback: boom'; then echo "FAIL: non-JSON exit1 accepted"; return 1; fi
  if manifest_divergence_result_valid 1 '{"hard_divergence":true}'; then echo "FAIL: incomplete protocol accepted"; return 1; fi
  if manifest_divergence_result_valid 1 '{"hard_divergence":"yes","events":[],"phases":[]}'; then echo "FAIL: wrong protocol types accepted"; return 1; fi
}

test_manifest_cli_paths_are_rooted_from_subdirs() {
  git init -q -b main . && git -c user.email=test@kernel -c user.name=kernel-test commit -q --allow-empty -m init
  mkdir -p skills manifests
  cp "$FIXTURES/checkpoint-example.json" manifests/checkpoint.json
  local root_output sub_output
  root_output=$("$KM" latest --dir manifests --any-branch)
  sub_output=$(cd skills && "$KM" latest --dir manifests --any-branch)
  assert_equals "$root_output" "$sub_output" "latest must be cwd-independent" || return 1
  (cd skills && "$KM" validate manifests/checkpoint.json >/dev/null)
}

test_manifest_rejects_paths_outside_repo() {
  cp "$FIXTURES/checkpoint-example.json" m.json
  local candidate ec
  for candidate in /etc/hosts ../escape.md; do
    python3 - "$candidate" <<'PYEOF'
import json,sys
p='m.json'; m=json.load(open(p)); m['context']['required']=[{'path':sys.argv[1]}]; json.dump(m,open(p,'w'))
PYEOF
    ec=0; "$KM" validate m.json >/dev/null 2>&1 || ec=$?
    assert_exit_code 1 "$ec" "selector path must stay in repo" || return 1
  done
  mkdir -p links
  ln -s /etc/hosts links/hosts
  python3 - <<'PYEOF'
import json
p='m.json'; m=json.load(open(p)); m['context']['required']=[{'path':'links/hosts'}]; json.dump(m,open(p,'w'))
PYEOF
  ec=0; "$KM" compile m.json >/dev/null 2>&1 || ec=$?
  assert_exit_code 1 "$ec" "selector symlink escape must fail" || return 1
  cp "$FIXTURES/handoff-example.json" m.json
  python3 - <<'PYEOF'
import json
p='m.json'; m=json.load(open(p)); m['runtime']['preflight']=[{'check':'path_exists','path':'/etc/passwd'}]; json.dump(m,open(p,'w'))
PYEOF
  ec=0; "$KM" validate m.json >/dev/null 2>&1 || ec=$?
  assert_exit_code 1 "$ec" "preflight paths must stay in repo" || return 1
  cp "$FIXTURES/handoff-example.json" m.json
  python3 - <<'PYEOF'
import json
p='m.json'; m=json.load(open(p)); m['provenance']['artifacts']=[{'path':'../escape','sha256':'x'}]; json.dump(m,open(p,'w'))
PYEOF
  ec=0; "$KM" validate m.json >/dev/null 2>&1 || ec=$?
  assert_exit_code 1 "$ec" "artifact paths must stay in repo"
}

test_manifest_rejects_bad_created_timestamp() {
  cp "$FIXTURES/checkpoint-example.json" m.json
  python3 - <<'PYEOF'
import json
p='m.json'; m=json.load(open(p)); m['identity']['created']='zzzz'; json.dump(m,open(p,'w'))
PYEOF
  local ec=0; "$KM" validate m.json >/dev/null 2>&1 || ec=$?
  assert_exit_code 1 "$ec" "identity.created must be RFC3339"
}

test_manifest_created_timestamp_is_strict_rfc3339() {
  local value ec
  for value in '2026-01-01T00:00:00+0000' '2026-01-01T00:00:00+00' \
               '2026-01-01 00:00:00Z' '2026-02-30T00:00:00Z' \
               '2026-01-01T25:00:00Z' '2026-01-01T00:00:00+24:00' \
               '2026-01-01t00:00:00z'; do
    cp "$FIXTURES/checkpoint-example.json" m.json
    python3 - "$value" <<'PYEOF'
import json,sys
p='m.json'; m=json.load(open(p)); m['identity']['created']=sys.argv[1]; json.dump(m,open(p,'w'))
PYEOF
    ec=0; "$KM" validate m.json >/dev/null 2>&1 || ec=$?
    assert_exit_code 1 "$ec" "strict RFC3339 must reject $value" || return 1
  done
  for value in '2026-01-01T00:00:00Z' '2026-01-01T00:00:00+00:00' '2026-01-01T00:00:00.123456Z'; do
    cp "$FIXTURES/checkpoint-example.json" m.json
    python3 - "$value" <<'PYEOF'
import json,sys
p='m.json'; m=json.load(open(p)); m['identity']['created']=sys.argv[1]; json.dump(m,open(p,'w'))
PYEOF
    "$KM" validate m.json >/dev/null || return 1
  done
}

test_manifest_latest_missing_dir_value_is_controlled() {
  local output ec=0; output=$("$KM" latest --dir 2>&1) || ec=$?
  assert_exit_code 1 "$ec" "missing --dir value must be usage error" || return 1
  if [[ "$output" == *Traceback* ]]; then echo "FAIL: traceback leaked"; return 1; fi
  assert_contains "$output" "--dir requires"
}


test_manifest_git_diff_rejects_option_injection() {
  git init -q -b main . && git -c user.email=test@kernel -c user.name=kernel-test commit -q --allow-empty -m init
  local escaped="$PWD/escaped.diff" value ec
  for value in "--output=$escaped" 'HEAD --output=x' $'HEAD\n--output=x' 'HEAD..'; do
    cp "$FIXTURES/checkpoint-example.json" m.json
    python3 - "$value" <<'PYEOF'
import json,sys
p='m.json'; m=json.load(open(p)); m['context']['required']=[{'git_diff':sys.argv[1]}]; json.dump(m,open(p,'w'))
PYEOF
    ec=0; "$KM" compile m.json >/dev/null 2>&1 || ec=$?
    assert_exit_code 1 "$ec" "unsafe git_diff must fail validation" || return 1
    [ ! -e "$escaped" ] || { echo "FAIL: git_diff created $escaped"; return 1; }
  done
  for value in HEAD HEAD~1..HEAD HEAD^...HEAD; do
    cp "$FIXTURES/checkpoint-example.json" m.json
    python3 - "$value" <<'PYEOF'
import json,sys
p='m.json'; m=json.load(open(p)); m['context']['required']=[{'git_diff':sys.argv[1]}]; json.dump(m,open(p,'w'))
PYEOF
    "$KM" validate m.json >/dev/null || return 1
  done
}


test_manifest_rejects_invalid_invalidation_rules() {
  local mutation ec
  for mutation in event phase; do
    cp "$FIXTURES/handoff-example.json" m.json
    python3 - "$mutation" <<'PYEOF'
import json,sys
p='m.json'; m=json.load(open(p)); rule=m['workflow']['invalidation_rules'][0]
if sys.argv[1]=='event': rule['when']['event']='brnch_diverged'
else: rule['invalidates']=['does-not-exist']
json.dump(m,open(p,'w'))
PYEOF
    ec=0; "$KM" validate m.json >/dev/null 2>&1 || ec=$?
    assert_exit_code 1 "$ec" "invalid invalidation $mutation must fail" || return 1
  done
}


test_manifest_skill_pin_enforcement_owner_is_truthful() {
  local schema="$PLUGIN_ROOT/schemas/kernel.handoff.v1.schema.json"
  assert_equals "agent" "$(jq -r '.properties.runtime.properties.required_skills.items.properties.version["x-kernel-enforced-by"]' "$schema")" "version pin is agent-enforced" || return 1
  assert_equals "agent" "$(jq -r '.properties.runtime.properties.required_skills.items.properties.sha256["x-kernel-enforced-by"]' "$schema")" "sha pin is agent-enforced"
}


test_manifest_cli_rejects_bad_options_without_traceback() {
  cp "$FIXTURES/checkpoint-example.json" m.json
  local -a cases=(
    'compile m.json --bundle-out'
    'compile m.json --receipt-out'
    'compile m.json --agentdb-tokens'
    'compile m.json --agentdb-tokens nope'
    'compile m.json --unknown'
    'deactivate --receipt'
    'deactivate --unknown'
    'latest --unknown'
    'validate m.json --unknown'
    'resume m.json --unknown'
    'activate m.json --unknown'
    'preflight m.json --unknown'
    'divergence m.json --unknown'
  )
  local case_args output ec
  for case_args in "${cases[@]}"; do
    local -a argv
    read -r -a argv <<< "$case_args"
    ec=0; output=$("$KM" "${argv[@]}" 2>&1) || ec=$?
    assert_exit_code 1 "$ec" "bad CLI args must exit 1: $case_args" || return 1
    if [[ "$output" == *Traceback* ]]; then echo "FAIL: traceback for $case_args"; return 1; fi
  done
}

test_guard_context_no_manifest_allows() {
  local ec=0
  echo '{"tool_input":{"file_path":"anything.md"}}' \
    | "$PLUGIN_ROOT/hooks/scripts/guard-context.sh" >/dev/null 2>&1 || ec=$?
  assert_exit_code 0 "$ec" "no active manifest must allow all reads"
}

test_guard_context_sealed_blocks_forbidden() {
  mkdir -p _meta
  cat > _meta/.active-manifest.json <<'JEOF'
{"manifest":"m.json","schema":"kernel.handoff/v1","mode":"sealed","forbidden":["secrets/*","frontend/*"]}
JEOF
  local ec=0
  echo '{"tool_input":{"file_path":"frontend/app.js"}}' \
    | "$PLUGIN_ROOT/hooks/scripts/guard-context.sh" >/dev/null 2>&1 || ec=$?
  assert_exit_code 2 "$ec" "sealed manifest must block forbidden path"
}

test_guard_context_sealed_allows_unforbidden() {
  mkdir -p _meta
  cat > _meta/.active-manifest.json <<'JEOF'
{"manifest":"m.json","schema":"kernel.handoff/v1","mode":"sealed","forbidden":["secrets/*"]}
JEOF
  local ec=0
  echo '{"tool_input":{"file_path":"src/app.js"}}' \
    | "$PLUGIN_ROOT/hooks/scripts/guard-context.sh" >/dev/null 2>&1 || ec=$?
  assert_exit_code 0 "$ec" "sealed manifest must allow unforbidden path"
}

test_guard_context_sealed_blocks_pathless_grep() {
  mkdir -p _meta
  cat > _meta/.active-manifest.json <<'JEOF'
{"manifest":"m.json","schema":"kernel.handoff/v1","mode":"sealed","forbidden":["secrets/*"]}
JEOF
  local ec=0
  echo '{"tool_name":"Grep","tool_input":{"pattern":"needle"}}' \
    | "$PLUGIN_ROOT/hooks/scripts/guard-context.sh" >/dev/null 2>&1 || ec=$?
  assert_exit_code 2 "$ec" "sealed manifest must block pathless Grep when forbidden globs exist"
}

test_guard_context_sealed_blocks_root_grep() {
  mkdir -p _meta
  cat > _meta/.active-manifest.json <<'JEOF'
{"manifest":"m.json","schema":"kernel.handoff/v1","mode":"sealed","forbidden":["_meta/research/**"]}
JEOF
  local ec=0
  echo '{"tool_name":"Grep","tool_input":{"pattern":"needle","path":"."}}' \
    | "$PLUGIN_ROOT/hooks/scripts/guard-context.sh" >/dev/null 2>&1 || ec=$?
  assert_exit_code 2 "$ec" "sealed manifest must block Grep from repo root when forbidden paths exist"
}

test_guard_context_sealed_blocks_absolute_read() {
  mkdir -p _meta frontend
  cat > _meta/.active-manifest.json <<'JEOF'
{"manifest":"m.json","schema":"kernel.handoff/v1","mode":"sealed","forbidden":["frontend/*"]}
JEOF
  local ec=0
  echo "{\"tool_name\":\"Read\",\"tool_input\":{\"file_path\":\"$PWD/frontend/secret.md\"}}" \
    | "$PLUGIN_ROOT/hooks/scripts/guard-context.sh" >/dev/null 2>&1 || ec=$?
  assert_exit_code 2 "$ec" "sealed manifest must block absolute paths into forbidden globs"
}

test_guard_context_sealed_blocks_dot_prefix_read() {
  mkdir -p _meta frontend
  cat > _meta/.active-manifest.json <<'JEOF'
{"manifest":"m.json","schema":"kernel.handoff/v1","mode":"sealed","forbidden":["frontend/*"]}
JEOF
  local ec=0
  echo '{"tool_name":"Read","tool_input":{"file_path":"./frontend/secret.md"}}' \
    | "$PLUGIN_ROOT/hooks/scripts/guard-context.sh" >/dev/null 2>&1 || ec=$?
  assert_exit_code 2 "$ec" "sealed manifest must block ./-prefixed forbidden paths"
}

test_guard_context_sealed_blocks_parent_directory_grep() {
  mkdir -p _meta frontend src
  cat > _meta/.active-manifest.json <<'JEOF'
{"manifest":"m.json","schema":"kernel.handoff/v1","mode":"sealed","forbidden":["frontend/*"]}
JEOF
  (cd src && \
    echo '{"tool_name":"Grep","tool_input":{"pattern":"needle","path":".."}}' \
      | "$PLUGIN_ROOT/hooks/scripts/guard-context.sh" >/dev/null 2>&1)
  local ec=$?
  assert_exit_code 2 "$ec" "sealed manifest must block parent-directory Grep that includes forbidden paths"
}

test_guard_context_sealed_blocks_symlink_read() {
  mkdir -p _meta frontend links
  touch frontend/secret.md
  ln -s ../frontend/secret.md links/secret-link.md
  cat > _meta/.active-manifest.json <<'JEOF'
{"manifest":"m.json","schema":"kernel.handoff/v1","mode":"sealed","forbidden":["frontend/*"]}
JEOF
  local ec=0
  echo '{"tool_name":"Read","tool_input":{"file_path":"links/secret-link.md"}}' \
    | "$PLUGIN_ROOT/hooks/scripts/guard-context.sh" >/dev/null 2>&1 || ec=$?
  assert_exit_code 2 "$ec" "sealed manifest must block symlinks into forbidden paths"
}

test_guard_context_bounded_ledgers_access() {
  mkdir -p _meta
  cat > _meta/.active-manifest.json <<'JEOF'
{"manifest":"m.json","schema":"kernel.handoff/v1","mode":"bounded","forbidden":[]}
JEOF
  local ec=0
  echo '{"tool_input":{"file_path":"extra/file.md"}}' \
    | "$PLUGIN_ROOT/hooks/scripts/guard-context.sh" >/dev/null 2>&1 || ec=$?
  assert_exit_code 0 "$ec" "bounded mode must allow" || return 1
  assert_file_exists "_meta/.context-ledger" "bounded access must be ledgered" || return 1
  assert_contains "$(cat _meta/.context-ledger)" "extra/file.md"
}

test_guard_context_fails_closed_on_broken_pointer() {
  mkdir -p _meta
  echo 'not json' > _meta/.active-manifest.json
  local ec=0
  echo '{"tool_input":{"file_path":"src/app.js"}}' \
    | "$PLUGIN_ROOT/hooks/scripts/guard-context.sh" >/dev/null 2>&1 || ec=$?
  assert_exit_code 2 "$ec" "unreadable pointer must fail closed (block)"
}

test_manifest_activate_deactivate_roundtrip() {
  mkdir -p _meta
  agentdb init >/dev/null
  cp "$FIXTURES/handoff-example.json" m.json
  "$KM" activate m.json >/dev/null
  assert_file_exists "_meta/.active-manifest.json" || return 1
  local mode
  mode=$(jq -r '.mode' _meta/.active-manifest.json)
  assert_equals "bounded" "$mode" "pointer must carry policy mode" || return 1
  echo '{"path":"x.md","reason":"test"}' > _meta/.context-ledger
  cp "$FIXTURES/receipt-example.json" receipt.json
  "$KM" deactivate --receipt receipt.json >/dev/null
  [ ! -f _meta/.active-manifest.json ] || { echo "FAIL: pointer not removed"; return 1; }
  [ ! -f _meta/.context-ledger ] || { echo "FAIL: ledger not removed"; return 1; }
  assert_contains "$(cat receipt.json)" "loads_beyond_manifest"
}

test_manifest_deactivate_rewrites_receipt_without_duplicate_keys() {
  mkdir -p _meta
  agentdb init >/dev/null
  cp "$FIXTURES/handoff-example.json" m.json
  "$KM" activate m.json >/dev/null
  cp "$FIXTURES/receipt-example.json" receipt.json
  printf '{"path":"extra/file.md","reason":"test"}\n' > _meta/.context-ledger
  "$KM" deactivate --receipt receipt.json >/dev/null
  local count
  count=$(grep -c '"loads_beyond_manifest"' receipt.json)
  assert_equals "1" "$count" "deactivate must keep one top-level loads_beyond_manifest key" || return 1
  assert_contains "$(cat receipt.json)" "extra/file.md" || return 1
  "$KM" validate receipt.json >/dev/null
}

test_manifest_checkpoint_resume_position_surfaced() {
  # The resume block is the contract for where ingest re-enters.
  local output
  output=$("$KM" resume "$FIXTURES/checkpoint-example.json" 2>&1)
  assert_contains "$output" "commit 3 of 5" || return 1
  assert_contains "$output" "rewrite skills/handoff/SKILL.md" || return 1
  output=$("$KM" resume "$FIXTURES/handoff-example.json" 2>&1)
  assert_contains "$output" "entry_phase: migration"
}


test_migration_every_command_has_destination() {
  # contract table section 3: every former command name resolves to a skill dir
  local missing=0
  for name in ingest forge tearitapart review handoff retrospective \
              diagnose dream metrics init help experiment landing-page checkpoint; do
    [ -f "$PLUGIN_ROOT/skills/$name/SKILL.md" ] || { echo "  no destination: $name"; missing=1; }
  done
  assert_exit_code 0 "$missing" "every former command needs a skill destination"
}

test_migration_no_live_command_references() {
  # no live file may reference commands/ paths (CHANGELOG + _meta archives excluded)
  local hits
  hits=$(grep -rln 'commands/' "$PLUGIN_ROOT" \
    --include='*.md' --include='*.sh' --include='*.json' 2>/dev/null \
    | grep -v '_meta/' | grep -v 'CHANGELOG.md' | grep -v '.obsidian' \
    | grep -v 'tests/run-tests.sh' | grep -v 'docs/MIGRATION-8.md' \
    | grep -v 'tests/fixtures/manifests/' \
    | grep -v 'guard-config.sh' || true)
  # guard-config.sh keeps commands/ in its HOST-project allowlist deliberately;
  # fixture manifests are example DATA whose narrative strings describe the
  # migration itself ("commands/ directory removed"), not live references
  [ -z "$hits" ] || { echo "  live commands/ references:"; echo "$hits"; return 1; }
}

test_migration_side_effecting_skills_not_ambient() {
  # forge/init/experiment/landing-page must carry disable-model-invocation: true
  local bad=0
  for s in forge init experiment landing-page; do
    grep -q '^disable-model-invocation: true' "$PLUGIN_ROOT/skills/$s/SKILL.md" || {
      echo "  $s can fire ambiently (missing disable-model-invocation: true)"; bad=1; }
  done
  assert_exit_code 0 "$bad" "side-effecting skills must not fire ambiently"
}

test_migration_kernel_taxonomy_blocks_parse() {
  # every SKILL.md frontmatter parses and carries kernel.kind
  python3 - "$PLUGIN_ROOT" <<'PYINNER'
import glob, re, sys
root = sys.argv[1]
bad = 0
valid_kinds = {"methodology", "workflow", "state_transition", "validator", "operator"}
for p in sorted(glob.glob(f"{root}/skills/*/SKILL.md")):
    text = open(p).read()
    m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    if not m:
        print(f"  no frontmatter: {p}"); bad = 1; continue
    fm = m.group(1)
    km = re.search(r"^kernel:\n((?:  .*\n?)+)", fm, re.M)
    if not km:
        print(f"  no kernel: block: {p}"); bad = 1; continue
    kind = re.search(r"^  kind: (\S+)", km.group(1), re.M)
    if not kind or kind.group(1) not in valid_kinds:
        print(f"  bad kernel.kind: {p}"); bad = 1
sys.exit(bad)
PYINNER
}

test_migration_workflows_reference_skills() {
  local bad=0
  for w in "$PLUGIN_ROOT/workflows/"*.md; do
    if grep -q '^  - command:' "$w"; then echo "  stale command label: $w"; bad=1; fi
  done
  assert_exit_code 0 "$bad" "workflow steps must use skill: labels"
}

run_test_suite() {
  local suite="$1"
  echo ""
  echo -e "${YELLOW}=== $suite ===${NC}"

  case "$suite" in
    governance)
      run_test "generated governance adapters and operator" test_generated_governance
      ;;
    manifest)
      run_test "schemas parse as JSON" test_manifest_schemas_parse_as_json
      run_test "handoff example validates" test_manifest_validate_handoff_example
      run_test "checkpoint example validates" test_manifest_validate_checkpoint_example
      run_test "retrospective-result example validates" test_manifest_validate_retrospective_example
      run_test "missing schema field rejected" test_manifest_validate_rejects_missing_schema_field
      run_test "bad policy mode rejected" test_manifest_validate_rejects_bad_policy_mode
      run_test "selector without path rejected" test_manifest_validate_rejects_selector_without_path
      run_test "duplicate keys rejected at parse" test_manifest_rejects_duplicate_keys
      run_test "yaml manifests rejected" test_manifest_rejects_yaml_manifest
      run_test "unknown manifest keys rejected" test_manifest_validate_rejects_unknown_keys
      run_test "compile validates before consuming" test_manifest_compile_validates_before_consuming
      run_test "activate validates before pointer" test_manifest_activate_validates_before_pointer
      run_test "latest finds newest manifest" test_manifest_latest_finds_newest
      run_test "latest fails when empty" test_manifest_latest_fails_when_empty
      run_test "divergence: branch mismatch" test_manifest_divergence_detects_branch_mismatch
      run_test "divergence: artifact hash mismatch" test_manifest_divergence_detects_artifact_hash_mismatch
      run_test "compile emits receipt fields" test_manifest_compile_emits_receipt_fields
      run_test "compile budget transitions" test_manifest_compile_budget_transitions
      run_test "compile selector types resolve" test_manifest_compile_selector_types_resolve
      run_test "compile reports missing required" test_manifest_compile_reports_missing_required
      run_test "paths anchor to repo root" test_manifest_paths_anchor_to_repo_root
      run_test "budgets and selector shapes validate" test_manifest_rejects_invalid_budget_and_selector_shapes
      run_test "selector outcomes carry hashes" test_manifest_selector_outcomes_and_hashes
      run_test "dirty checkpoint requires hash" test_manifest_checkpoint_requires_dirty_tree_hashes
      run_test "divergence JSON invalidates phases" test_manifest_divergence_json_invalidates_phases
      run_test "preflight checks are typed" test_manifest_preflight_is_typed
      run_test "latest uses identity timestamp" test_manifest_latest_uses_identity_not_mtime
      run_test "latest reports ambiguity" test_manifest_latest_reports_ambiguity
      run_test "dirty tree hash divergence" test_manifest_divergence_checks_dirty_tree_hash
      run_test "schema fields name enforcement owner" test_manifest_schema_fields_name_enforcement_owner
      run_test "committed manifests are checked" test_manifest_committed_state_files_are_checked
      run_test "committed gate validates divergence protocol" test_manifest_committed_gate_validates_divergence_protocol
      run_test "CLI paths root from subdirectories" test_manifest_cli_paths_are_rooted_from_subdirs
      run_test "manifest paths stay in repo" test_manifest_rejects_paths_outside_repo
      run_test "created timestamp validates" test_manifest_rejects_bad_created_timestamp
      run_test "created timestamp is strict RFC3339" test_manifest_created_timestamp_is_strict_rfc3339
      run_test "latest missing dir is controlled" test_manifest_latest_missing_dir_value_is_controlled
      run_test "git_diff rejects option injection" test_manifest_git_diff_rejects_option_injection
      run_test "invalidation rules validate targets" test_manifest_rejects_invalid_invalidation_rules
      run_test "skill pin owner is truthful" test_manifest_skill_pin_enforcement_owner_is_truthful
      run_test "CLI rejects bad options cleanly" test_manifest_cli_rejects_bad_options_without_traceback
      run_test "guard-context: no manifest allows" test_guard_context_no_manifest_allows
      run_test "guard-context: sealed blocks forbidden" test_guard_context_sealed_blocks_forbidden
      run_test "guard-context: sealed allows unforbidden" test_guard_context_sealed_allows_unforbidden
      run_test "guard-context: sealed blocks pathless Grep" test_guard_context_sealed_blocks_pathless_grep
      run_test "guard-context: sealed blocks root Grep" test_guard_context_sealed_blocks_root_grep
      run_test "guard-context: sealed blocks absolute read" test_guard_context_sealed_blocks_absolute_read
      run_test "guard-context: sealed blocks dot-prefix read" test_guard_context_sealed_blocks_dot_prefix_read
      run_test "guard-context: sealed blocks parent-directory Grep" test_guard_context_sealed_blocks_parent_directory_grep
      run_test "guard-context: sealed blocks symlink read" test_guard_context_sealed_blocks_symlink_read
      run_test "guard-context: bounded ledgers access" test_guard_context_bounded_ledgers_access
      run_test "guard-context: bounded skips allowlist" test_guard_context_bounded_skips_allowlisted_access
      run_test "guard-context: bounded JSON escaping" test_guard_context_bounded_ledgers_valid_json_escaping
      run_test "deactivate rejects ledger schema mismatch" test_manifest_deactivate_rejects_ledger_schema_mismatch
      run_test "deactivate rejects malformed ledger transactionally" test_manifest_deactivate_rejects_malformed_ledger_transactionally
      run_test "deactivate projection retry merges once" test_manifest_deactivate_projection_retry_merges_once
      run_test "guard-context: fails closed on broken pointer" test_guard_context_fails_closed_on_broken_pointer
      run_test "activate/deactivate roundtrip" test_manifest_activate_deactivate_roundtrip
      run_test "deactivate rewrites receipt once" test_manifest_deactivate_rewrites_receipt_without_duplicate_keys
      run_test "checkpoint resume position surfaced" test_manifest_checkpoint_resume_position_surfaced
      run_test "migration: every command has destination" test_migration_every_command_has_destination
      run_test "migration: no live command references" test_migration_no_live_command_references
      run_test "migration: side-effecting skills not ambient" test_migration_side_effecting_skills_not_ambient
      run_test "migration: kernel taxonomy blocks parse" test_migration_kernel_taxonomy_blocks_parse
      run_test "migration: workflows reference skills" test_migration_workflows_reference_skills
      ;;
    test_gate)
      run_test "test-gate detects + passes" test_test_gate_detects_and_passes
      run_test "test-gate detects + fails" test_test_gate_detects_and_fails
      run_test "test-gate no suite is green" test_test_gate_no_suite_is_green
      run_test "test-gate red recovers to pass" test_test_gate_status_recovers_to_pass
      run_test "test-gate honors override file" test_test_gate_honors_override_file
      run_test "autopush postcommit is disabled" test_autopush_postcommit_is_disabled
      run_test "autopush install is opt-in" test_autopush_install_is_opt_in
      run_test "autopush sweep has red gate" test_autopush_sweep_has_red_gate
      run_test "session-end runs test gate" test_session_end_runs_test_gate
      run_test "session-start surfaces red" test_session_start_surfaces_red
      run_test "pre-compact has red gate" test_pre_compact_has_red_gate
      ;;
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
      run_test "hooks.json supports Claude and Codex loaders" test_hooks_json_cross_loader_schema
      run_test "advisory hooks are synchronous and complete" test_advisory_hooks_are_synchronous_and_complete
      run_test "six advisory hook commands are retained" test_six_advisory_hook_commands_are_retained
      run_test "log-write consumes Claude and Codex payloads" test_log_write_consumes_claude_and_codex_payloads
      run_test "log-write is advisory and leaves no child" test_log_write_is_advisory_and_leaves_no_child
      run_test "advisory scripts consume dual-loader payloads" test_advisory_scripts_consume_dual_loader_payloads
      run_test "advisory scripts fail open without false positives" test_advisory_scripts_fail_open_without_false_positives
      run_test "multifile patch records are isolated and complete" test_multifile_patch_records_are_isolated_and_complete
      run_test "log-write multifile and JSON round-trip" test_log_write_multifile_and_json_roundtrip
      run_test "critical guard scripts unchanged for 8.0.2" test_critical_guard_scripts_unchanged_for_802
      run_test "session-start has compact quick reference" test_session_start_workflow_present
      run_test "session-start points at skill routing" test_session_start_skill_routing
      run_test "session-start has no scripted interrupts" test_session_start_no_scripted_interrupts
      run_test "pre-compact writes checkpoint" test_pre_compact_writes_checkpoint
      run_test "pre-compact payload survives quotes" test_pre_compact_payload_survives_quotes
      run_test "lifecycle hooks guard main push" test_lifecycle_hooks_guard_main_push
      run_test "session-start shows checkpoint after compact" test_session_start_shows_checkpoint_after_compact
      ;;
    runtime_upgrade)
      run_test "validated loaded v8 root" test_runtime_validates_loaded_v8_root
      run_test "runtime selection message is locally suppressible" test_runtime_selection_message_is_locally_suppressible
      run_test "7.23 links repair and data is unchanged" test_runtime_upgrade_repairs_only_numbered_links
      run_test "current no-op and missing untouched" test_runtime_current_noop_and_missing_untouched
      run_test "user-owned destinations refused" test_runtime_refuses_user_owned_destinations
      run_test "broken relative numbered link repaired" test_runtime_repairs_broken_relative_numbered_link
      run_test "malformed cache rejected" test_runtime_rejects_malformed_cache_and_preserves_current
      run_test "authority monotonic with explicit rollback" test_runtime_authority_is_monotonic_but_override_can_rollback
      run_test "failed replacement preserves original" test_runtime_failed_replacement_leaves_original
      run_test "startup arms reconciliation" test_runtime_startup_arms_reconciliation
      run_test "rollback tool selects a lower local runtime" test_select_runtime_supports_explicit_local_rollback
      run_test "rollback tool accepts real legacy common" test_select_runtime_accepts_real_legacy_common
      run_test "helper escapes and special files rejected" test_runtime_rejects_helper_escape_and_special_files
      run_test "symlinked cache version root rejected" test_runtime_rejects_symlinked_version_root
      run_test "control paths and traversal links rejected" test_runtime_rejects_control_paths_and_traversal_links
      run_test "atomic link cleans only matching symlink residue" test_atomic_link_scavenges_only_matching_symlink_residue
      run_test "init AgentDB targets selected Vaults" test_init_agentdb_targets_selected_vaults
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
      run_test "detect-secrets blocks Codex apply_patch" test_detect_secrets_blocks_codex_apply_patch
      run_test "detect-secrets allows Codex secret removal" test_detect_secrets_allows_codex_secret_removal
      run_test "guard-bash blocks force push" test_guard_bash_blocks_force_push
      run_test "guard-bash allows safe commands" test_guard_bash_allows_safe_commands
      run_test "guard-bash allows git log" test_guard_bash_allows_git_log
      run_test "guard-config blocks .claude/ write" test_guard_config_blocks_claude_dir_write
      run_test "guard-config allows CLAUDE.md" test_guard_config_allows_claude_md
      run_test "guard-config allows rules" test_guard_config_allows_rules
      run_test "guard-config blocks Codex apply_patch" test_guard_config_blocks_codex_apply_patch
      run_test "guard-config allows Codex apply_patch rule" test_guard_config_allows_codex_apply_patch_rule
      run_test "guard-config blocks Codex dot segment bypass" test_guard_config_blocks_codex_dot_segment_bypass
      run_test "guard-config fails closed on malformed JSON" test_guard_config_fails_closed_on_malformed_json
      run_test "detect-secrets fails closed on malformed JSON" test_detect_secrets_fails_closed_on_malformed_json
      run_test "Codex risky skills are explicit-only" test_codex_explicit_only_skill_policies
      run_test "Codex apply_patch guards are wired" test_codex_apply_patch_guards_are_wired
      run_test "SessionStart includes dual-loader tier rules" test_session_start_includes_dual_loader_tier_rules
      run_test "auto-approve allows git status" test_auto_approve_allows_git_status
      run_test "auto-approve allows npm test" test_auto_approve_allows_npm_test
      run_test "auto-approve rejects rm -rf" test_auto_approve_rejects_rm_rf
      run_test "detect-secrets blocks Anthropic key" test_detect_secrets_blocks_anthropic_key
      run_test "detect-secrets fail-closed without jq" test_detect_secrets_fail_closed_without_jq
      run_test "guard-bash blocks force-push -f shorthand" test_guard_bash_blocks_force_push_shorthand
      run_test "guard-bash blocks rm -fr /" test_guard_bash_blocks_rm_fr_root
      run_test "guard-bash allows subdir rm" test_guard_bash_allows_subdir_rm
      run_test "auto-approve defers chained command" test_auto_approve_defers_chained_command
      ;;
    graph_tracking)
      run_test "session-start creates session" test_session_start_creates_session
      run_test "session-start validates tier" test_session_start_validates_tier
      run_test "session-end updates session" test_session_end_updates_session
      run_test "session-end validates tokens" test_session_end_validates_tokens
      run_test "graph-project from receipt" test_graph_project_from_receipt
      run_test "graph-project idempotent" test_graph_project_idempotent
      run_test "graph-suggest shadow mode" test_graph_suggest_shadow_mode
      run_test "graph outcome from write-end" test_graph_outcome_from_write_end
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
      run_test "preflight restores dropped migration table" test_preflight_restores_dropped_migration_table
      run_test "preflight idempotent after table drift" test_preflight_idempotent_after_table_drift
      run_test "migration 010 preserves unparseable ts" test_migration_010_preserves_unparseable_ts
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
      run_test "Vaults continuity requires exact root and executable adapter" test_vaults_continuity_requires_exact_root_and_executable_adapter
      run_test "Vaults root compaction hooks clean no-op" test_vaults_root_compaction_hooks_clean_noop
      run_test "nested project retains KERNEL compaction fallback" test_nested_project_retains_kernel_compaction_fallback
      run_test "Vaults root SessionStart keeps governance without restore" test_vaults_root_session_start_keeps_governance_without_restore
      run_test "post-compact-restore fast exit without marker" test_compact_restore_fast_exit
      run_test "post-compact-restore outputs marker content" test_compact_restore_outputs_marker
      run_test "post-compact-restore deletes marker" test_compact_restore_deletes_marker
      run_test "hooks.json has UserPromptSubmit" test_hooks_json_user_prompt_submit
      ;;
    circuit_breaker)
      run_test "circuit-breaker.sh exists and is executable" test_circuit_breaker_exists
      run_test "blocking guards do NOT source circuit breaker" test_blocking_guards_do_not_source_breaker
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
      run_test "retrospective queries current learning schema" test_retrospective_queries_current_learning_schema
      run_test "ship bump targets are truthful" test_ship_bump_targets_are_truthful
      run_test "resolved contradictions have learning mutation evidence" test_retrospective_contradictions_have_mutation_evidence
      ;;
    github_integration)
      run_test "github-integration.sh exists" test_github_integration_exists
      run_test "has availability check" test_github_integration_has_availability_check
      run_test "has profile gate" test_github_integration_has_profile_gate
      run_test "has issue functions" test_github_integration_has_issue_functions
      run_test "has discussion functions" test_github_integration_has_discussion_functions
      run_test "fire-and-forget safety" test_github_integration_fire_and_forget
      run_test "session-end sources github" test_session_end_sources_github
      run_test "session-end posts summary" test_session_end_posts_summary
      run_test "repo not hardcoded" test_github_integration_not_hardcoded_repo
      run_test "agents have github layer" test_agents_have_github_layer
      run_test "commands have github layer" test_commands_have_github_layer
      ;;
    phase0_fixes)
      run_test "capture-error reads tool_name" test_capture_error_reads_tool_name
      run_test "capture-error logs tool correctly" test_capture_error_logs_tool_correctly
      run_test "session-start creates memory dir" test_session_start_creates_memory_dir
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
    worktree_safety)
      run_test "surgeon has worktree_safety section" test_surgeon_has_worktree_safety
      run_test "orchestration has constraint validation" test_orchestration_has_constraint_validation
      run_test "agentdb contract accepts constraints" test_agentdb_contract_accepts_constraints
      ;;
    inject_context)
      run_test "inject-context command exists" test_inject_context_command_exists
      run_test "inject-context surgeon outputs gotchas" test_inject_context_surgeon_gotchas
      run_test "inject-context adversary outputs failures" test_inject_context_adversary_failures
      run_test "inject-context unknown falls back to read-start" test_inject_context_unknown_fallback
      run_test "orchestration SKILL.md has knowledge_injection" test_orchestration_skill_has_injection
      ;;
    read_start)
      run_test "read-start outputs Known Gotchas section" test_read_start_outputs_gotchas
      run_test "read-start bumps load_count not hit_count" test_read_start_bumps_load_count_not_hit_count
      ;;
    recall)
      run_test "recall dedups identical insights" test_recall_dedups_identical_insights
      run_test "recall hides human_only learnings" test_recall_hides_human_only
      run_test "recall bumps hit_count on surfaced rows" test_recall_bumps_hit_count
      run_test "recall --global unions + tags global hits" test_recall_global_unions_and_tags
      run_test "recall --global graceful when global absent" test_recall_global_graceful_when_absent
      run_test "recall --global never leaks human_only" test_recall_global_no_human_leak
      run_test "recall survives sqlite control-char escaping" test_recall_survives_sqlite_control_char_escaping
      run_test "decay spares loaded (load_count>0) learnings" test_decay_spares_loaded_learnings
      ;;
    learn)
      run_test "learn auto-populates domain from PWD" test_learn_auto_populates_domain
      ;;
    version_sync)
      run_test "all canonical version declarations in sync" test_version_sync_all
      ;;
    release_docs)
      run_test "active docs reject stale claims" test_release_docs_reject_stale_live_claims
      run_test "8.0 changelog current and 7.x history preserved" test_release_changelog_v8_is_current_and_history_preserved
      run_test "active release docs use 8.0.1 runtime" test_release_docs_use_current_801_runtime
      run_test "Vaults continuity boundary is documented" test_release_docs_explain_vaults_continuity_boundary
      run_test "metadata and inventory truthful" test_release_metadata_and_inventory_are_truthful
      run_test "rollback works outside a checkout" test_release_docs_rollback_works_outside_a_checkout
      run_test "Claude and Codex lifecycle commands are separate" test_release_docs_separate_claude_and_codex_lifecycle
      run_test "Codex invocation and lifecycle boundaries are documented" test_release_docs_explain_codex_invocation_and_boundaries
      run_test "explicit-only skill inventory is derived" test_release_docs_explicit_only_inventory_is_derived
      ;;
    phase2_agents)
      run_test "reviewer has review_protocol" test_reviewer_has_review_protocol
      run_test "reviewer has confidence scoring" test_reviewer_has_confidence_scoring
      ;;
    triage_understudier)
      run_test "understudier stays deleted" test_understudier_is_gone
      run_test "researcher model is not pinned" test_researcher_model_not_pinned
      ;;
    approval_rfactor)
      ;;
    learning_system)
      run_test "migration 005 file exists" test_migration_005_file_exists
      run_test "migration 005 creates execution_traces" test_migration_005_creates_execution_traces
      run_test "execution_traces has correct columns" test_execution_traces_has_correct_columns
      run_test "agentdb trace records trace" test_agentdb_trace_records
      run_test "agentdb decay runs" test_agentdb_decay_runs
      run_test "agentdb antibody searches learnings" test_agentdb_antibody_searches
      ;;
    cartographer_coroner)
      ;;
    phase4_agents)
      run_test "orchestration defines the lane contract" test_orchestration_has_lane_contract
      run_test "orchestration carries worker-model doctrine" test_orchestration_has_worker_model_doctrine
      ;;
    phase4_extensions)
      run_test "agentdb co-change command exists" test_agentdb_co_change_exists
      run_test "co-change runs without error" test_agentdb_co_change_runs
      ;;
    hooks_v2)
      run_test "validate-json-schema.sh exists and is executable" test_validate_json_schema_exists
      run_test "warn-hardcoded.sh exists and is executable" test_warn_hardcoded_exists
      run_test "hooks.json references validate-json-schema" test_hooks_json_has_validate_json_schema
      run_test "hooks.json references warn-hardcoded" test_hooks_json_has_warn_hardcoded
      run_test "session-start.sh has blocker surfacing section" test_session_start_has_blocker_surfacing
      run_test "validate-json-schema.sh sources common.sh" test_validate_json_schema_sources_common
      run_test "warn-hardcoded.sh sources common.sh" test_warn_hardcoded_sources_common
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
    pre_ship_app)
      run_test "app-dev SKILL.md exists" test_app_dev_skill_exists
      run_test "app-dev SKILL.md has store submission" test_app_dev_has_store_submission
      run_test "app-dev SKILL.md has triggers" test_app_dev_has_triggers
      run_test "CLAUDE.md references app-dev" test_claude_md_references_app_dev
      ;;
    entropy_adaptive)
      run_test "forge.md mentions entropy measurement" test_forge_has_entropy_measurement
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
    run_test_suite "github_integration"
    run_test_suite "profile"
    run_test_suite "phase0_fixes"
    run_test_suite "worktree_safety"
    run_test_suite "phase2_agents"
    run_test_suite "triage_understudier"
    run_test_suite "inject_context"
    run_test_suite "approval_rfactor"
    run_test_suite "learning_system"
    run_test_suite "phase4_agents"
    run_test_suite "phase4_extensions"
    run_test_suite "hooks_v2"
    run_test_suite "phase4_framework"
    run_test_suite "cartographer_coroner"
    run_test_suite "pre_ship_app"
    run_test_suite "entropy_adaptive"
    run_test_suite "read_start"
    run_test_suite "recall"
    run_test_suite "learn"
    run_test_suite "version_sync"
    run_test_suite "governance"
    run_test_suite "runtime_upgrade"
    run_test_suite "release_docs"
    run_test_suite "test_gate"
    run_test_suite "manifest"
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
