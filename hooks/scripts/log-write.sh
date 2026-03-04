#!/bin/bash
# PostToolUse hook: Log file writes (async, non-blocking)
# Replaces the old post-write.sh. No git operations - that's SessionEnd's job.
# Events: PostToolUse (matcher: Write|Edit), async: true

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty')
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Find project root dynamically
PROJECT_ROOT="${CLAUDE_PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
LOG_DIR="$PROJECT_ROOT/_meta/logs"

mkdir -p "$LOG_DIR"
echo "{\"timestamp\":\"$TIMESTAMP\",\"tool\":\"$TOOL_NAME\",\"file\":\"$FILE_PATH\"}" >> "$LOG_DIR/actions.jsonl"

exit 0
