#!/bin/bash
_LW_START_MS=$(python3 -c 'import time; print(int(time.time()*1000))' 2>/dev/null || echo "")
# PostToolUse hook: Log file writes (async, non-blocking)
# Replaces the old post-write.sh. No git operations - that's SessionEnd's job.
# Events: PostToolUse (matcher: Write|Edit), async: true

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty')
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# CLAUDE_PROJECT_DIR is set by Claude Code hook executor
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
LOG_DIR="$PROJECT_ROOT/_meta/logs"

mkdir -p "$LOG_DIR"
echo "{\"timestamp\":\"$TIMESTAMP\",\"tool\":\"$TOOL_NAME\",\"file\":\"$FILE_PATH\"}" >> "$LOG_DIR/actions.jsonl"

# Emit hook timing
if [ -n "$_LW_START_MS" ]; then
  _LW_END=$(python3 -c 'import time; print(int(time.time()*1000))' 2>/dev/null || true)
  if [ -n "$_LW_END" ]; then
    _LW_DUR=$(( _LW_END - _LW_START_MS ))
    _LW_AGENTDB="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}/orchestration/agentdb/agentdb"
    "$_LW_AGENTDB" emit hook "log-write" "$_LW_DUR" "{\"exit_code\":0,\"file\":\"$FILE_PATH\"}" "" "" 2>/dev/null &
  fi
fi

exit 0
