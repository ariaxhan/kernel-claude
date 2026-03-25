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
TOOL=$(echo "$INPUT" | jq -r '.tool // "unknown"' 2>/dev/null)
ERROR=$(echo "$INPUT" | jq -r '.error // .message // "unknown error"' 2>/dev/null)
FILE=$(echo "$INPUT" | jq -r '.file_path // .path // ""' 2>/dev/null)

# Only log if agentdb is initialized
if [ -f "$VAULTS/_meta/agentdb/agent.db" ]; then
  "$AGENTDB" error "$TOOL" "$ERROR" "$FILE" 2>/dev/null
fi

_kernel_hook_end "capture-error" 0
