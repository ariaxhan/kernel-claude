#!/bin/bash
# KERNEL setup — idempotent, run after plugin install
# Usage: ./setup.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTDB_BIN="$SCRIPT_DIR/orchestration/agentdb/agentdb"
SCHEMA="$SCRIPT_DIR/orchestration/agentdb/schema.sql"
META="$SCRIPT_DIR/_meta"
DB="$META/agentdb/kernel.db"
SYMLINK="/usr/local/bin/agentdb"

pass() { printf "\033[32m  ok\033[0m  %s\n" "$1"; }
info() { printf "\033[34m  --\033[0m  %s\n" "$1"; }
fail() { printf "\033[31m  !!\033[0m  %s\n" "$1"; }

echo ""
echo "KERNEL setup"
echo "------------"

# 1. Verify sqlite3
if command -v sqlite3 >/dev/null 2>&1; then
  pass "sqlite3 available ($(sqlite3 --version | cut -d' ' -f1))"
else
  fail "sqlite3 not found — install via: brew install sqlite3"
  exit 1
fi

# 2. Create _meta structure
for dir in "$META/agentdb" "$META/context" "$META/logs"; do
  if [ ! -d "$dir" ]; then
    mkdir -p "$dir"
    pass "created $dir"
  else
    info "exists  $dir"
  fi
done

# 3. Initialize AgentDB (kernel.db)
if [ ! -f "$DB" ]; then
  sqlite3 "$DB" < "$SCHEMA"
  pass "initialized $DB"
else
  info "exists  $DB"
  # Verify schema is intact
  if sqlite3 "$DB" "SELECT count(*) FROM _migrations;" >/dev/null 2>&1; then
    info "schema  verified"
  else
    fail "schema corrupt — remove $DB and re-run"
    exit 1
  fi
fi

# 4. Symlink agentdb to /usr/local/bin
if [ ! -f "$AGENTDB_BIN" ]; then
  fail "agentdb binary not found at $AGENTDB_BIN"
  exit 1
fi

if [ -L "$SYMLINK" ] && [ "$(readlink "$SYMLINK")" = "$AGENTDB_BIN" ]; then
  info "exists  $SYMLINK -> $AGENTDB_BIN"
elif [ -e "$SYMLINK" ]; then
  fail "$SYMLINK exists but points elsewhere — remove it manually and re-run"
  exit 1
else
  echo ""
  info "Creating symlink requires sudo:"
  sudo ln -s "$AGENTDB_BIN" "$SYMLINK"
  pass "symlinked $SYMLINK -> $AGENTDB_BIN"
fi

echo ""
echo "Done. Start every session with: agentdb read-start"
echo ""
