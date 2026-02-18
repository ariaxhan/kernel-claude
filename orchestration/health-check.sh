#!/usr/bin/env bash
# health-check.sh — verify and auto-fix where possible
# Exit 0 = healthy, Exit 1 = needs manual action

set -uo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"
DB_PATH="${REPO_ROOT}/_meta/agentdb/agent.db"
SCHEMA="${PLUGIN_DIR}/orchestration/agentdb/schema.sql"
AGENTDB_BIN="${PLUGIN_DIR}/orchestration/agentdb/agentdb"
needs_manual=0

ok()   { printf "\033[32mOK\033[0m    %s\n" "$1"; }
fix()  { printf "\033[33mFIX\033[0m   %s\n" "$1"; }
fail() { printf "\033[31mFAIL\033[0m  %s\n" "$1"; needs_manual=1; }

echo "KERNEL Health Check"
echo "-------------------"

# 1. sqlite3
if command -v sqlite3 &>/dev/null; then
  ok "sqlite3 available"
else
  fail "sqlite3 missing"
  echo "     → brew install sqlite3"
fi

# 2. _meta structure (auto-create)
for dir in "${REPO_ROOT}/_meta/agentdb" "${REPO_ROOT}/_meta/plans" "${REPO_ROOT}/_meta/logs" "${REPO_ROOT}/_meta/context"; do
  if [ -d "$dir" ]; then
    ok "$(basename "$dir")/"
  else
    mkdir -p "$dir" 2>/dev/null && fix "created $(basename "$dir")/" || fail "cannot create $dir"
  fi
done

# 3. AgentDB file (auto-init)
if [ -f "$DB_PATH" ] && [ -r "$DB_PATH" ]; then
  ok "agent.db"
elif [ -f "$SCHEMA" ] && command -v sqlite3 &>/dev/null; then
  sqlite3 "$DB_PATH" < "$SCHEMA" 2>/dev/null && fix "initialized agent.db" || fail "cannot init DB"
else
  fail "agent.db missing and cannot auto-init"
  echo "     → run: agentdb init"
fi

# 4. agentdb CLI
if command -v agentdb &>/dev/null; then
  ok "agentdb in PATH"
else
  fail "agentdb not in PATH"
  echo ""
  echo "  Run this to fix:"
  echo "  sudo ln -s \"${AGENTDB_BIN}\" /usr/local/bin/agentdb"
  echo ""
fi

echo ""
if [ $needs_manual -eq 0 ]; then
  echo "Health: OK"
  exit 0
else
  echo "Health: NEEDS ACTION"
  exit 1
fi
