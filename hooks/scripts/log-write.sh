#!/bin/bash
_LW_START_MS=$(python3 -c 'import time; print(int(time.time()*1000))' 2>/dev/null || echo "")
# PostToolUse hook: Log file writes (synchronous, advisory)
# Replaces the old post-write.sh. No git operations - that's SessionEnd's job.
# Events: PostToolUse (matcher: Write|Edit)

source "$(dirname "$0")/common.sh"

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null || true)
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# CLAUDE_PROJECT_DIR is set by Claude Code hook executor
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
LOG_DIR="$PROJECT_ROOT/_meta/logs"

mkdir -p "$LOG_DIR" 2>/dev/null || true

while IFS= read -r RECORD; do
  FILE_PATH=$(printf '%s' "$RECORD" | jq -r '.path // empty' 2>/dev/null)
  jq -cn --arg timestamp "$TIMESTAMP" --arg tool "$TOOL_NAME" --arg file "$FILE_PATH" \
    '{timestamp:$timestamp,tool:$tool,file:$file}' >> "$LOG_DIR/actions.jsonl" 2>/dev/null || true

  _LW_END=$(python3 -c 'import time; print(int(time.time()*1000))' 2>/dev/null || true)
  if [ -n "$_LW_START_MS" ] && [ -n "$_LW_END" ]; then
    _LW_DUR=$(( _LW_END - _LW_START_MS ))
    _LW_AGENTDB="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}/orchestration/agentdb/agentdb"
    EMIT_JSON=$(jq -cn --arg file "$FILE_PATH" '{exit_code:0,file:$file}')
    "$_LW_AGENTDB" emit hook "log-write" "$_LW_DUR" "$EMIT_JSON" "" "" 2>/dev/null || true
  fi
done < <(kernel_hook_file_records "$INPUT")

exit 0
