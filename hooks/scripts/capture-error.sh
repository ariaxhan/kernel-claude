#!/bin/bash
# KERNEL: Capture tool errors to AgentDB
# Convention: ~/Vaults/ is required.

# Fixed paths - check for initialized agentdb
if [ -f "$HOME/Vaults/_meta/agentdb/agent.db" ]; then
  VAULTS="$HOME/Vaults"
elif [ -f "$HOME/Downloads/Vaults/_meta/agentdb/agent.db" ]; then
  VAULTS="$HOME/Downloads/Vaults"
else
  VAULTS="${KERNEL_VAULTS:-$HOME/Vaults}"
fi
AGENTDB="$VAULTS/.claude/kernel/orchestration/agentdb/agentdb"

# Fallback
if [ ! -f "$AGENTDB" ]; then
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
  AGENTDB="${PLUGIN_ROOT}/orchestration/agentdb/agentdb"
fi

# Parse input JSON for tool name and error
TOOL=$(echo "$CLAUDE_TOOL_USE_RESULT" | jq -r '.tool // "unknown"' 2>/dev/null)
ERROR=$(echo "$CLAUDE_TOOL_USE_RESULT" | jq -r '.error // .message // "unknown error"' 2>/dev/null)
FILE=$(echo "$CLAUDE_TOOL_USE_RESULT" | jq -r '.file_path // .path // ""' 2>/dev/null)

# Only log if agentdb is initialized
if [ -f "$VAULTS/_meta/agentdb/agent.db" ]; then
  "$AGENTDB" error "$TOOL" "$ERROR" "$FILE" 2>/dev/null
fi
