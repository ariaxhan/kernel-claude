#!/usr/bin/env bash
# health-check.sh — quick system health check
# Returns exit 0 if healthy, exit 1 if any issues found.

set -uo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
DB_PATH="${REPO_ROOT}/_meta/agentdb/kernel.db"
ISSUES=0

check() {
  local label="$1"
  local ok="$2"
  if [ "$ok" -eq 0 ]; then
    echo "OK    $label"
  else
    echo "FAIL  $label"
    ISSUES=$((ISSUES + 1))
  fi
}

# agentdb exists and is readable
if [ -f "$DB_PATH" ] && [ -r "$DB_PATH" ]; then
  check "agentdb exists and readable" 0
else
  check "agentdb exists and readable ($DB_PATH)" 1
fi

# sqlite3 available
command -v sqlite3 &>/dev/null
check "sqlite3 available" $?

# _meta structure
[ -d "${REPO_ROOT}/_meta" ]
check "_meta/ directory exists" $?

[ -d "${REPO_ROOT}/_meta/agentdb" ]
check "_meta/agentdb/ directory exists" $?

[ -d "${REPO_ROOT}/_meta/plans" ]
check "_meta/plans/ directory exists" $?

# agentdb CLI available
command -v agentdb &>/dev/null
check "agentdb CLI available" $?

echo ""
if [ "$ISSUES" -eq 0 ]; then
  echo "Health: OK"
  exit 0
else
  echo "Health: DEGRADED ($ISSUES issue(s))"
  exit 1
fi
