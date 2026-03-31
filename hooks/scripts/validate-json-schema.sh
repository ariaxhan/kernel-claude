#!/bin/bash
# KERNEL: Validate JSON structure on writes to content/config files
# PostToolUse hook — runs after Write/Edit on JSON/YAML files

source "$(dirname "$0")/common.sh"

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.file_path // .path // ""' 2>/dev/null)

# Only validate JSON files
case "$FILE_PATH" in
  *.json)
    if [ -f "$FILE_PATH" ]; then
      if ! jq empty "$FILE_PATH" 2>/dev/null; then
        echo "WARN: Invalid JSON after write: $FILE_PATH"
        echo "Run: jq . '$FILE_PATH' to see the error"
      fi
    fi
    ;;
  */agentdb/*.sql)
    # Validate SQL syntax if sqlite3 available
    if [ -f "$FILE_PATH" ] && command -v sqlite3 >/dev/null 2>&1; then
      if ! sqlite3 ":memory:" ".read $FILE_PATH" 2>/dev/null; then
        echo "WARN: SQL syntax error in: $FILE_PATH"
      fi
    fi
    ;;
esac

exit 0
