#!/bin/bash
# KERNEL setup — run once after plugin install
# Only sets up the agentdb CLI. Each project inits its own DB.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTDB_BIN="$SCRIPT_DIR/orchestration/agentdb/agentdb"
SYMLINK="/usr/local/bin/agentdb"

pass() { printf "\033[32m  ok\033[0m  %s\n" "$1"; }
info() { printf "\033[34m  --\033[0m  %s\n" "$1"; }
fail() { printf "\033[31m  !!\033[0m  %s\n" "$1"; }

echo ""
echo "KERNEL setup"
echo "------------"

# 1. Verify sqlite3
if command -v sqlite3 >/dev/null 2>&1; then
  pass "sqlite3 available"
else
  fail "sqlite3 not found — brew install sqlite3"
  exit 1
fi

# 2. Verify agentdb script exists
if [ ! -f "$AGENTDB_BIN" ]; then
  fail "agentdb script not found at $AGENTDB_BIN"
  exit 1
fi
pass "agentdb script found"

# 3. Symlink agentdb to /usr/local/bin
if [ -L "$SYMLINK" ] && [ "$(readlink "$SYMLINK")" = "$AGENTDB_BIN" ]; then
  info "symlink exists: $SYMLINK"
elif [ -e "$SYMLINK" ]; then
  fail "$SYMLINK exists but points elsewhere — remove manually"
  exit 1
else
  info "Creating symlink (requires sudo):"
  sudo ln -s "$AGENTDB_BIN" "$SYMLINK"
  pass "symlinked: agentdb → $AGENTDB_BIN"
fi

echo ""
echo "Done. In each project, run: agentdb init"
echo ""
