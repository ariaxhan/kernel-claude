#!/bin/bash
# KERNEL: Shared functions for hooks
# Source this at the top of hook scripts: source "$(dirname "$0")/common.sh"

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
