#!/bin/bash
# KERNEL: UserPromptSubmit hook
# Fires on every user message. Two jobs:
# 1. Fallback session-start if SessionStart hook didn't fire (Claude Code bug)
# 2. Restore context after compaction
#
# Both are one-shot: marker/flag checked, action taken, marker/flag removed.
# Fast exit (~1ms) when neither condition applies.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Load shared functions
source "$SCRIPT_DIR/common.sh"

# Detect paths
VAULTS=$(detect_vaults)
AGENTDB=$(get_agentdb "$VAULTS")
PROJECT_ROOT=$(get_project_root)
AGENTS_DIR="$VAULTS/_meta/agents"

# === FALLBACK SESSION-START ===
# If SessionStart hook didn't fire, .current agent file won't exist.
# Run session-start as fallback on first user message.
if [ ! -f "$AGENTS_DIR/.current" ] 2>/dev/null; then
  # Session-start never ran — execute it now as fallback
  if [ -x "$SCRIPT_DIR/session-start.sh" ]; then
    bash "$SCRIPT_DIR/session-start.sh" < /dev/null 2>/dev/null
  fi
  exit 0
fi

# === COMPACTION RESTORE ===
MARKER="$PROJECT_ROOT/_meta/.compact-marker"

# Fast exit if no compaction happened
[ ! -f "$MARKER" ] && exit 0

# Restore context
echo "## Context Restored After Compaction"
echo ""
cat "$MARKER"
echo ""

# Clean up marker (one-shot restoration)
rm -f "$MARKER"

exit 0
