#!/usr/bin/env bash
# Test gate (kernel plugin). Runs the project's test suite and records a verdict so the
# auto-commit / auto-push path can never silently ship red.
#
# Why this exists: session-end.sh + pre-compact-commit.sh commit with --no-verify (a
# documented carve-out to avoid an infinite hook chain). That carve-out meant the
# "chore(session-end)" auto-commits NEVER ran tests — so a red suite sailed onto main for
# days until CI caught it. This gate closes that hole: it runs the suite outside the
# commit-verify chain, writes a per-repo status file, and lets autopush refuse to push red.
#
# Usage:  test-gate.sh [project_root]
# Output: writes "$project_root/_meta/.test-status"  (format: STATUS|EPOCH|COMMAND|SUMMARY)
# Exit:   0 = green OR no suite detected (nothing to gate)
#         1 = red (suite ran and failed)
#
# Portable: detects the nearest configured test command, no hardcoded paths. Set
# KERNEL_TEST_OFF=1 to disable. Honors a per-project override file _meta/.test-cmd.
set -u

PROJECT_ROOT="${1:-${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}}"
[ -d "$PROJECT_ROOT" ] || exit 0
[ "${KERNEL_TEST_OFF:-0}" = "1" ] && exit 0

STATUS_FILE="$PROJECT_ROOT/_meta/.test-status"
TIMEOUT_S="${KERNEL_TEST_TIMEOUT:-180}"
NOW="$(date +%s)"

# --- Detect the test command (project's nearest configured command; invent nothing) ---
detect_cmd() {
  # 1. Explicit per-project override wins.
  if [ -f "$PROJECT_ROOT/_meta/.test-cmd" ]; then
    local c; c="$(head -1 "$PROJECT_ROOT/_meta/.test-cmd" 2>/dev/null)"
    [ -n "$c" ] && { echo "$c"; return; }
  fi
  # 2. package.json with a real (non-placeholder) test script.
  if [ -f "$PROJECT_ROOT/package.json" ] && command -v node >/dev/null 2>&1; then
    local t; t="$(node -e 'try{const s=require(process.argv[1]).scripts||{};process.stdout.write(s.test||"")}catch(e){}' "$PROJECT_ROOT/package.json" 2>/dev/null)"
    case "$t" in ""|*"no test specified"*) : ;; *) echo "npm test"; return ;; esac
  fi
  # 3. Repo-local shell test harness.
  [ -f "$PROJECT_ROOT/tests/run-tests.sh" ] && { echo "bash tests/run-tests.sh"; return; }
  # 4. Makefile / justfile test target.
  if [ -f "$PROJECT_ROOT/Makefile" ] && grep -qE '^test:' "$PROJECT_ROOT/Makefile" 2>/dev/null; then
    echo "make test"; return
  fi
  if [ -f "$PROJECT_ROOT/justfile" ] && grep -qE '^test\b' "$PROJECT_ROOT/justfile" 2>/dev/null; then
    echo "just test"; return
  fi
  # 5. Python: pytest with a tests dir or pyproject.
  if command -v pytest >/dev/null 2>&1 && { [ -d "$PROJECT_ROOT/tests" ] || [ -f "$PROJECT_ROOT/pyproject.toml" ]; }; then
    echo "pytest -q"; return
  fi
  echo ""  # nothing detected
}

CMD="$(detect_cmd)"
if [ -z "$CMD" ]; then
  # No suite to gate — record NONE so downstream knows it wasn't skipped silently.
  mkdir -p "$PROJECT_ROOT/_meta" 2>/dev/null
  printf 'NONE|%s|-|no test suite detected\n' "$NOW" > "$STATUS_FILE" 2>/dev/null || true
  exit 0
fi

# --- Run with a timeout (portable: prefer timeout/gtimeout, else background+wait) ---
LOG="$(mktemp 2>/dev/null || echo /tmp/kernel-test-gate.$$)"
run_with_timeout() {
  if command -v timeout >/dev/null 2>&1; then
    ( cd "$PROJECT_ROOT" && timeout "$TIMEOUT_S" bash -c "$CMD" ) >"$LOG" 2>&1
  elif command -v gtimeout >/dev/null 2>&1; then
    ( cd "$PROJECT_ROOT" && gtimeout "$TIMEOUT_S" bash -c "$CMD" ) >"$LOG" 2>&1
  else
    ( cd "$PROJECT_ROOT" && bash -c "$CMD" ) >"$LOG" 2>&1 &
    local pid=$!; local waited=0
    while kill -0 "$pid" 2>/dev/null; do
      sleep 1; waited=$((waited+1))
      [ "$waited" -ge "$TIMEOUT_S" ] && { kill -9 "$pid" 2>/dev/null; return 124; }
    done
    wait "$pid"
  fi
}

run_with_timeout
RC=$?

mkdir -p "$PROJECT_ROOT/_meta" 2>/dev/null
# One-line summary: last non-empty line of output (covers "Results: N passed, M failed").
SUMMARY="$(grep -E 'pass|fail|error|Results' -i "$LOG" 2>/dev/null | tail -1 | tr '|\n' '  ' | cut -c1-200)"
[ -n "$SUMMARY" ] || SUMMARY="$(tail -1 "$LOG" 2>/dev/null | tr '|\n' '  ' | cut -c1-200)"

if [ "$RC" -eq 124 ]; then
  printf 'FAIL|%s|%s|TIMEOUT after %ss\n' "$NOW" "$CMD" "$TIMEOUT_S" > "$STATUS_FILE" 2>/dev/null || true
  rm -f "$LOG" 2>/dev/null
  exit 1
elif [ "$RC" -ne 0 ]; then
  printf 'FAIL|%s|%s|%s\n' "$NOW" "$CMD" "${SUMMARY:-exit $RC}" > "$STATUS_FILE" 2>/dev/null || true
  # Record to AgentDB so the next session is pre-loaded with the failure.
  if [ -f "$(dirname "$0")/common.sh" ]; then
    source "$(dirname "$0")/common.sh" 2>/dev/null || true
    if type get_agentdb >/dev/null 2>&1 && type detect_vaults >/dev/null 2>&1; then
      AGENTDB="$(get_agentdb "$(detect_vaults)")"
      [ -x "$AGENTDB" ] && "$AGENTDB" learn failure "test suite red at auto-commit" "$CMD :: ${SUMMARY:-exit $RC}" 2>/dev/null || true
    fi
  fi
  rm -f "$LOG" 2>/dev/null
  exit 1
else
  printf 'PASS|%s|%s|%s\n' "$NOW" "$CMD" "${SUMMARY:-ok}" > "$STATUS_FILE" 2>/dev/null || true
  rm -f "$LOG" 2>/dev/null
  exit 0
fi
