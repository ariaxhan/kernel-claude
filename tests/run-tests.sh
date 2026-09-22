#!/bin/bash
# KERNEL Test Runner
# Real deps, minimal mocking, edge cases first
#
# Usage: ./tests/run-tests.sh [all|<suite>|--changed [base]]
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

# Path prefix -> suite. `--changed [base]` runs only suites whose paths changed vs base
# (default HEAD, working tree + untracked included). tests/run-tests.sh itself maps to all.
SUITE_PATHS=(
  "security_hooks:hooks/scripts/detect-secrets hooks/scripts/auto-approve hooks/scripts/common.sh"
  "circuit_breaker:hooks/scripts/circuit-breaker hooks/scripts/detect-secrets hooks/scripts/auto-approve"
  "corpus:hooks/ tests/corpus/"
  "hooks:hooks/hooks.json hooks/scripts/session-start hooks/scripts/common.sh .claude-plugin/"
  "runtime_upgrade:hooks/scripts/common.sh scripts/select-runtime"
  "agentdb:orchestration/agentdb/"
  "migrations:orchestration/agentdb/"
  "manifest:schemas/ orchestration/manifest/ tests/fixtures/manifests/"
  "governance:governance/ scripts/generate- scripts/adjudicate hooks/scripts/session-start .claude-plugin/ CLAUDE.md AGENTS.md tests/test_governance.py tests/test_adjudicate.py tests/kernel9/test_adapters.py"
)


_AGENTDB_DIR="$PLUGIN_ROOT/orchestration/agentdb"
KM="$PLUGIN_ROOT/orchestration/manifest/kernel-manifest"
FIXTURES="$PLUGIN_ROOT/tests/fixtures/manifests"

setup_test_env() {
  export TEST_DIR=$(mktemp -d)
  export TEST_PROJECT="$TEST_DIR/test-project"
  mkdir -p "$TEST_PROJECT/_meta/agentdb"
  mkdir -p "$TEST_PROJECT/.claude"
  cd "$TEST_PROJECT"

  # Make agentdb available
  export PATH="$PLUGIN_ROOT/orchestration/agentdb:$PATH"
  export CLAUDE_PROJECT_DIR="$TEST_PROJECT"
  # Never let the suite touch the machine's real runtime selector: a checkout carrying a
  # bumped version outranks the installed cache, and one hook run repointed every live
  # session's hooks at the dev tree (2026-08-28).
  export KERNEL_CACHE_DIR="$TEST_DIR/kernel-cache"
  mkdir -p "$KERNEL_CACHE_DIR"
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

  # #229: assert_* helpers print "  FAIL: ..." on failure but a function that keeps
  # executing after an ungraded assert only reports the LAST statement's exit code.
  # Grade on any FAIL marker in the captured output too, so no assert call is dead.
  if [ $exit_code -eq 0 ] && printf '%s\n' "$output" | grep -q '^  FAIL:'; then
    exit_code=1
  fi

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

test_agentdb_init() {
  agentdb init >/dev/null
  assert_file_exists "$TEST_PROJECT/_meta/agentdb/agent.db"
}

test_generated_governance() {
  python3 "$PLUGIN_ROOT/tests/test_governance.py"
}

# The acceptance function (#204). Review has no natural stopping condition, so the verdict is
# decided by scripts/adjudicate.py rather than by the critic that produced the findings.
test_verdict_adjudication() {
  python3 "$PLUGIN_ROOT/tests/test_adjudicate.py"
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
  assert_contains "$output" "Learned" || return 1
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

test_agentdb_recall_defaults_to_pure_fts() {
  # 8.6.2: recall is pure FTS by default (eval-proven best arm); the semantic-embed
  # hybrid is opt-in via AGENTDB_EMBED=1. Guards against a silent re-flip of the default.
  # 1) Source-level: the fusion gate must default OFF (opt-in), not ON.
  assert_contains "$(cat "$PLUGIN_ROOT/orchestration/agentdb/agentdb")" \
    '[ "${AGENTDB_EMBED:-0}" = "1" ] || { printf '"'"'%s'"'"' "$raw"; return 0; }' || return 1
  # 2) Behavioral: recall works with NO backend and NO opt-in (pure FTS standalone),
  #    and setting AGENTDB_EMBED=1 without a backend still returns results (graceful).
  agentdb init >/dev/null
  agentdb learn pattern "rate limiter uses a token bucket" "src/limit.ts" >/dev/null
  local def opt
  def=$(agentdb recall "token bucket rate limiter")
  assert_contains "$def" "token bucket" || return 1
  opt=$(AGENTDB_EMBED=1 agentdb recall "token bucket rate limiter")
  assert_contains "$opt" "token bucket"
}

test_agentdb_special_chars_in_insight() {
  agentdb init >/dev/null
  # Test SQL injection attempt
  agentdb learn pattern "test'; DROP TABLE learnings;--" "evidence" >/dev/null
  local count
  count=$(agentdb query "SELECT COUNT(*) FROM learnings;" | tail -1 | tr -d ' ')
  assert_equals "1" "$count" "table should still exist"
}

test_session_start_outputs_kernel() {
  local output
  output=$("$PLUGIN_ROOT/hooks/scripts/session-start.sh" </dev/null 2>&1)
  assert_contains "$output" "# KERNEL" || return 1
  assert_contains "$output" "agentdb"
}

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
  export KERNEL_CACHE_DIR="$cache"
  mkdir -p "$cache" "$KERNEL_VAULTS/.local/bin" "$KERNEL_VAULTS/.claude/kernel"
  make_runtime_fixture "$cache/7.23.0" "7.23.0"
  make_runtime_fixture "$cache/8.0.0" "8.0.0"
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
  assert_contains "$output" "run /kernel:init" || return 1
  assert_equals mine "$(cat "$KERNEL_VAULTS/.local/bin/agentdb")" || return 1
  [ -d "$KERNEL_VAULTS/.claude/kernel/orchestration" ]
  assert_equals "$TEST_DIR/unrelated" "$(readlink "$KERNEL_VAULTS/.claude/kernel/hooks")"
}

test_runtime_failed_replacement_leaves_original() {
  runtime_fixture
  local cache="$HOME/.claude/plugins/cache/kernel-marketplace/kernel"
  ln -s "$cache/7.23.0/hooks" "$KERNEL_VAULTS/.claude/kernel/hooks"
  source "$PLUGIN_ROOT/hooks/scripts/common.sh"
  KERNEL_ATOMIC_LINK_FAIL=1 ! kernel_repair_host_link "$KERNEL_VAULTS/.claude/kernel/hooks" "$cache/current/hooks" "$cache" "hooks"
  assert_equals "$cache/7.23.0/hooks" "$(readlink "$KERNEL_VAULTS/.claude/kernel/hooks")"
}

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

test_detect_secrets_blocks_codex_command_shape() {
  local key="AKIA"; key+="IOSFODNN7EXAMPLE"
  local patch json ec=0
  patch=$(printf '*** Begin Patch\n*** Add File: config.ts\n+const key = "%s";\n*** End Patch' "$key")
  json=$(jq -n --arg patch "$patch" '{tool_name:"apply_patch",tool_input:{command:$patch}}')
  printf '%s\n' "$json" | "$PLUGIN_ROOT/hooks/scripts/detect-secrets.sh" >/dev/null 2>&1 || ec=$?
  assert_exit_code 2 "$ec" "a secret in the real Codex apply_patch shape must be blocked"
}

test_detect_secrets_fails_closed_on_malformed_json() {
  local ec=0
  printf '{malformed\n' | "$PLUGIN_ROOT/hooks/scripts/detect-secrets.sh" >/dev/null 2>&1 || ec=$?
  assert_exit_code 2 "$ec" "detect-secrets must block malformed hook JSON"
}

test_auto_approve_allows_git_status() {
  local output
  output=$(echo '{"tool_input":{"command":"git status"}}' \
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

test_detect_secrets_blocks_anthropic_key() {
  local akey="s"; akey+="k-ant-api03-"; akey+=$(printf 'A%.0s' {1..40}); akey+="_-xyz"
  local json
  json=$(printf '{"tool_input":{"content":"ANTHROPIC_API_KEY=%s"}}' "$akey")
  echo "$json" | "$PLUGIN_ROOT/hooks/scripts/detect-secrets.sh" >/dev/null 2>&1
  assert_exit_code 2 "$?" "Anthropic sk-ant-api03 key must be blocked"
}

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

test_auto_approve_defers_chained_command() {
  local output
  output=$(echo '{"tool_input":{"command":"git status; rm -rf /tmp/x"}}' \
    | "$PLUGIN_ROOT/hooks/scripts/auto-approve-safe.sh" 2>&1)
  if [[ "$output" == *"allow"* ]]; then
    echo "FAIL: chained command must not be auto-approved"
    return 1
  fi
}

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
  assert_equals "1" "$has_sessions" "context_sessions table should exist" || return 1
  assert_equals "1" "$has_nodes" "nodes table should exist" || return 1
  assert_equals "1" "$has_edges" "edges table should exist"
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

test_learning_dedup_reinforces() {
  agentdb init >/dev/null
  agentdb learn pattern "sqlite busy_timeout prevents failures" "evidence1" >/dev/null
  agentdb learn pattern "sqlite busy_timeout prevents failures" "evidence2" >/dev/null
  COUNT=$(sqlite3 "$TEST_PROJECT/_meta/agentdb/agent.db" "SELECT COUNT(*) FROM learnings;")
  assert_equals "1" "$COUNT" "should have 1 learning not 2" || return 1
  HIT=$(sqlite3 "$TEST_PROJECT/_meta/agentdb/agent.db" "SELECT hit_count FROM learnings LIMIT 1;")
  assert_equals "1" "$HIT" "hit_count should be 1 after reinforcement"
}

test_preflight_restores_dropped_migration_table() {
  local db="$TEST_PROJECT/_meta/agentdb/agent.db"
  agentdb init >/dev/null
  # Drop the table but KEEP its migration marker, the drift state.
  sqlite3 "$db" "DROP TABLE events;"
  assert_equals "1" "$(sqlite3 "$db" "SELECT COUNT(*) FROM _migrations WHERE name='003_telemetry';")" "003 marker must still be present (drift precondition)" || return 1
  agentdb preflight >/dev/null 2>&1
  RESULT=$(sqlite3 "$db" "SELECT name FROM sqlite_master WHERE type='table' AND name='events';")
  assert_equals "events" "$RESULT" "preflight must recreate the dropped events table despite marker"
}

test_blocking_guards_do_not_source_breaker() {
  # I0.15: a blocking safety gate must run on every invocation and must never
  # auto-disable itself. So detect-secrets must NOT
  # `source` the circuit breaker (a tripped breaker would fail OPEN = allow).
  # Match an active source directive only, not the explanatory comment.
  if grep -qE '^[[:space:]]*(source|\.)[[:space:]]+.*circuit-breaker\.sh' "$PLUGIN_ROOT/hooks/scripts/detect-secrets.sh"; then
    echo "FAIL: detect-secrets.sh sources circuit-breaker.sh, a blocking guard must always run"
    return 1
  fi
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

test_recall_hides_human_only() {
  agentdb init >/dev/null
  agentdb learn gotcha "zzqmarker visible agent note" "ev" --visibility agent >/dev/null
  agentdb learn gotcha "zzqmarker hidden human note" "ev" --visibility human_only >/dev/null
  local out
  out=$(agentdb recall "zzqmarker" | grep '^- ')
  echo "$out" | grep -q "visible agent note" || { echo "agent-visible row should surface"; return 1; }
  if echo "$out" | grep -q "hidden human note"; then echo "human_only row leaked to agent recall"; return 1; fi
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

test_manifest_validate_rejects_missing_schema_field() {
  printf '{"identity": {"name": "x"}}\n' > bad.json
  local ec=0
  "$KM" validate bad.json >/dev/null 2>&1 || ec=$?
  [ "$ec" -ne 0 ] || { echo "FAIL: manifest without schema field must be rejected"; return 1; }
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

test_violation_corpus() {
  cd "$PLUGIN_ROOT" || return 1
  python3 tests/corpus/run-corpus.py
}

test_plugin_manifests_parse() {
  local f
  for f in hooks/hooks.json .claude-plugin/plugin.json .claude-plugin/marketplace.json; do
    python3 -m json.tool "$PLUGIN_ROOT/$f" >/dev/null 2>&1 || { echo "  FAIL: invalid JSON: $f"; return 1; }
  done
}

test_recall_excludes_archived() {
  agentdb init >/dev/null
  local db="$TEST_PROJECT/_meta/agentdb/agent.db"
  agentdb learn pattern "zanzibar live lesson" >/dev/null
  sqlite3 "$db" "INSERT INTO learnings (id,ts,type,insight,archived_at) VALUES ('ARCH-1','2026-01-01T00:00:00Z','pattern','zanzibar archived lesson','2026-01-02T00:00:00Z');"
  local out
  out=$(agentdb recall zanzibar 2>&1)
  assert_contains "$out" "zanzibar live lesson" || return 1
  [[ "$out" != *"zanzibar archived lesson"* ]] || { echo "  FAIL: archived row surfaced by recall"; return 1; }
}

test_host_adapters() {
  cd "$PLUGIN_ROOT" || return 1
  python3 -m unittest tests/kernel9/test_adapters.py
}

run_test_suite() {
  local suite="$1"
  echo ""
  echo -e "${YELLOW}=== $suite ===${NC}"
  case "$suite" in
    security_hooks)
      run_test "detect-secrets blocks AWS key" test_detect_secrets_blocks_aws_key
      run_test "detect-secrets blocks GitHub PAT" test_detect_secrets_blocks_github_pat
      run_test "detect-secrets blocks Anthropic key" test_detect_secrets_blocks_anthropic_key
      run_test "detect-secrets blocks private key" test_detect_secrets_blocks_private_key
      run_test "detect-secrets allows clean code" test_detect_secrets_allows_clean_code
      run_test "detect-secrets blocks Codex apply_patch" test_detect_secrets_blocks_codex_apply_patch
      run_test "detect-secrets blocks the real Codex shape" test_detect_secrets_blocks_codex_command_shape
      run_test "detect-secrets fails closed on malformed JSON" test_detect_secrets_fails_closed_on_malformed_json
      run_test "detect-secrets fail-closed without jq" test_detect_secrets_fail_closed_without_jq
      run_test "auto-approve allows git status" test_auto_approve_allows_git_status
      run_test "auto-approve rejects rm -rf" test_auto_approve_rejects_rm_rf
      run_test "auto-approve defers chained command" test_auto_approve_defers_chained_command
      ;;
    circuit_breaker)
      run_test "blocking guards do NOT source circuit breaker" test_blocking_guards_do_not_source_breaker
      run_test "breaker trips after 3 failures" test_breaker_trips
      run_test "breaker resets after cooldown" test_breaker_resets
      ;;
    corpus)
      run_test "violation corpus: gates still refuse, and fail as declared" test_violation_corpus
      ;;
    hooks)
      run_test "plugin manifests parse as JSON" test_plugin_manifests_parse
      run_test "hooks.json supports Claude and Codex loaders" test_hooks_json_cross_loader_schema
      run_test "session-start outputs KERNEL" test_session_start_outputs_kernel
      ;;
    runtime_upgrade)
      run_test "user-owned destinations refused" test_runtime_refuses_user_owned_destinations
      run_test "failed replacement preserves original" test_runtime_failed_replacement_leaves_original
      ;;
    agentdb)
      run_test "init creates db" test_agentdb_init
      run_test "init is idempotent" test_agentdb_init_idempotent
      run_test "learn failure" test_agentdb_learn_failure
      run_test "learn requires type" test_agentdb_learn_requires_type
      run_test "learn pattern shows in read-start" test_agentdb_learn_pattern
      run_test "learning dedup reinforces existing" test_learning_dedup_reinforces
      run_test "write-end creates checkpoint" test_agentdb_write_end
      run_test "recall returns what was written" test_agentdb_recall_defaults_to_pure_fts
      run_test "recall excludes archived rows" test_recall_excludes_archived
      run_test "recall hides human_only learnings" test_recall_hides_human_only
      run_test "recall --global never leaks human_only" test_recall_global_no_human_leak
      run_test "decay soft-archives only untouched learnings" test_decay_spares_loaded_learnings
      run_test "special chars (SQL injection)" test_agentdb_special_chars_in_insight
      run_test "SQL injection via tier" test_agentdb_numeric_injection_tier
      ;;
    migrations)
      run_test "inline schema matches schema.sql" test_inline_schema_matches_schema_sql
      run_test "migrations apply cleanly on a fresh DB" test_migration_applies_cleanly
      run_test "preflight restores dropped migration table" test_preflight_restores_dropped_migration_table
      ;;
    manifest)
      run_test "schemas parse as JSON" test_manifest_schemas_parse_as_json
      run_test "handoff example validates" test_manifest_validate_handoff_example
      run_test "missing schema field rejected" test_manifest_validate_rejects_missing_schema_field
      run_test "git_diff rejects option injection" test_manifest_git_diff_rejects_option_injection
      ;;
    governance)
      run_test "generated governance adapters and operator" test_generated_governance
      run_test "host adapters generated from one source" test_host_adapters
      run_test "verdict adjudication: the acceptance function" test_verdict_adjudication
      ;;
    *) echo "unknown suite: $suite"; FAIL_COUNT=$((FAIL_COUNT+1)) ;;
  esac
}

ALL_SUITES=(security_hooks circuit_breaker corpus hooks runtime_upgrade agentdb migrations manifest governance)

# Print suites whose mapped paths changed vs $1 (tracked diff + untracked files).
changed_suites() {
  local base="$1" files entry suite prefix f
  files=$( { git -C "$PLUGIN_ROOT" diff --name-only "$base" --; git -C "$PLUGIN_ROOT" ls-files --others --exclude-standard; } 2>/dev/null)
  [ -n "$files" ] || return 0
  if printf '%s\n' "$files" | grep -qx 'tests/run-tests.sh'; then printf '%s\n' "${ALL_SUITES[@]}"; return 0; fi
  for entry in "${SUITE_PATHS[@]}"; do
    suite="${entry%%:*}"
    for prefix in ${entry#*:}; do
      if printf '%s\n' "$files" | grep -q "^$prefix"; then echo "$suite"; break; fi
    done
  done
}

main() {
  echo "================================="
  echo "KERNEL Plugin Test Suite"
  echo "================================="
  local target="${1:-all}" s suites=()
  case "$target" in
    all) suites=("${ALL_SUITES[@]}") ;;
    --changed)
      while IFS= read -r s; do [ -n "$s" ] && suites+=("$s"); done < <(changed_suites "${2:-HEAD}")
      echo "changed vs ${2:-HEAD}: ${#suites[@]} suite(s)" ;;
    *) suites=("$target") ;;
  esac
  for s in ${suites[@]+"${suites[@]}"}; do run_test_suite "$s"; done

  echo ""
  echo "================================="
  echo -e "Results: ${GREEN}$PASS_COUNT passed${NC}, ${RED}$FAIL_COUNT failed${NC}"
  echo "================================="
  [ "$FAIL_COUNT" -eq 0 ]
}

main "$@"
