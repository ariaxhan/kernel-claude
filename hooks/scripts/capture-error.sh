#!/bin/bash
# KERNEL: Capture tool errors to AgentDB

# Load shared functions
source "$(dirname "$0")/common.sh"
_kernel_hook_start

# Detect paths
VAULTS=$(detect_vaults)
AGENTDB=$(get_agentdb "$VAULTS")

# Read from stdin (same as all other hooks)
INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // .tool // "unknown"' 2>/dev/null)
ERROR=$(kernel_hook_error "$INPUT")
FILE=$(kernel_hook_file_path "$INPUT")

# Only log if agentdb is initialized
if [ -f "$VAULTS/_meta/agentdb/agent.db" ]; then
  "$AGENTDB" error "$TOOL" "$ERROR" "$FILE" 2>/dev/null
fi

_kernel_hook_end "capture-error" 0
