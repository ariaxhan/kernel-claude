#!/bin/bash
# KERNEL: Capture tool errors to AgentDB
# Called on PostToolUseFailure to log errors automatically

# Self-locate the plugin (works regardless of how hook is invoked)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
AGENTDB="${PLUGIN_ROOT}/orchestration/agentdb/agentdb"

# User's project root (where _meta/ lives)
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"

# Parse input JSON for tool name and error
TOOL=$(echo "$CLAUDE_TOOL_USE_RESULT" | jq -r '.tool // "unknown"' 2>/dev/null)
ERROR=$(echo "$CLAUDE_TOOL_USE_RESULT" | jq -r '.error // .message // "unknown error"' 2>/dev/null)
FILE=$(echo "$CLAUDE_TOOL_USE_RESULT" | jq -r '.file_path // .path // ""' 2>/dev/null)

# Only log if agentdb is initialized
if [ -f "_meta/agentdb/agent.db" ]; then
  "$AGENTDB" error "$TOOL" "$ERROR" "$FILE" 2>/dev/null
fi
