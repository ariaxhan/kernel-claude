#!/bin/bash
# KERNEL: Capture tool errors to AgentDB
# Called on PostToolUseFailure to log errors automatically

AGENTDB="${CLAUDE_PLUGIN_ROOT}/orchestration/agentdb/agentdb"

# Parse input JSON for tool name and error
TOOL=$(echo "$CLAUDE_TOOL_USE_RESULT" | jq -r '.tool // "unknown"' 2>/dev/null)
ERROR=$(echo "$CLAUDE_TOOL_USE_RESULT" | jq -r '.error // .message // "unknown error"' 2>/dev/null)
FILE=$(echo "$CLAUDE_TOOL_USE_RESULT" | jq -r '.file_path // .path // ""' 2>/dev/null)

# Only log if agentdb is initialized
if [ -f "_meta/agentdb/agent.db" ]; then
  "$AGENTDB" error "$TOOL" "$ERROR" "$FILE" 2>/dev/null
fi
