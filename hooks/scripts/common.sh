#!/bin/bash
# KERNEL: Shared functions for hooks
# Source this at the top of hook scripts: source "$(dirname "$0")/common.sh"

# Dependency check: jq is required by most hooks for JSON parsing
command -v jq >/dev/null 2>&1 || { echo "Warning: jq not found, some hooks may not work" >&2; }

# Auto-update current symlink to latest version (fixes stale hook issue)
# Claude Code downloads new versions but doesn't update the symlink
update_current_symlink() {
  local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
  local CACHE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

  # Only run if we're in the plugin cache (not dev mode)
  [[ "$CACHE_DIR" == *"plugins/cache"* ]] || return 0

  # Find highest semver directory
  local LATEST
  LATEST=$(ls -d "$CACHE_DIR"/[0-9]*/ 2>/dev/null \
    | xargs -n1 basename 2>/dev/null \
    | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' \
    | sort -t. -k1,1n -k2,2n -k3,3n \
    | tail -1)

  [ -z "$LATEST" ] && return 0

  # Check if current symlink needs updating
  local CURRENT_TARGET
  CURRENT_TARGET=$(readlink "$CACHE_DIR/current" 2>/dev/null | xargs basename 2>/dev/null)

  if [ "$CURRENT_TARGET" != "$LATEST" ]; then
    ln -sfn "$CACHE_DIR/$LATEST" "$CACHE_DIR/current" 2>/dev/null && \
      echo "**KERNEL auto-updated:** ${CURRENT_TARGET:-none} → $LATEST"
  fi
}

# Detect Vaults location - env var takes priority, then checks filesystem
detect_vaults() {
  # Explicit override always wins (for testing + custom setups)
  if [ -n "$KERNEL_VAULTS" ] && [ -d "$KERNEL_VAULTS" ]; then
    echo "$KERNEL_VAULTS"
  elif [ -f "$HOME/Vaults/_meta/agentdb/agent.db" ]; then
    echo "$HOME/Vaults"
  elif [ -f "$HOME/Downloads/Vaults/_meta/agentdb/agent.db" ]; then
    echo "$HOME/Downloads/Vaults"
  else
    echo "$HOME/Vaults"
  fi
}

# Get agentdb CLI path - finds binary via symlink or plugin root
get_agentdb() {
  local VAULTS="$1"
  local AGENTDB="$VAULTS/.claude/kernel/orchestration/agentdb/agentdb"

  if [ ! -f "$AGENTDB" ]; then
    local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
    local PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
    AGENTDB="${PLUGIN_ROOT}/orchestration/agentdb/agentdb"
  fi

  echo "$AGENTDB"
}

# Get project root - uses CLAUDE_PROJECT_DIR or git root
get_project_root() {
  echo "${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
}
