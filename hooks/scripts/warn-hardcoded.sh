#!/bin/bash
# KERNEL: Warn on hardcoded values in component/style files
# PreToolUse hook — runs before Write/Edit on component files

source "$(dirname "$0")/common.sh"

INPUT=$(cat)
FILE_PATH=$(kernel_hook_file_path "$INPUT")
CONTENT=$(kernel_hook_content "$INPUT")

# Only check component/style files
case "$FILE_PATH" in
  *.tsx|*.jsx|*.svelte|*.vue|*.css)
    # Check for hardcoded hex colors
    if echo "$CONTENT" | grep -qE '#[0-9a-fA-F]{3,8}[^-]' 2>/dev/null; then
      echo "WARN: Hardcoded hex color in $FILE_PATH — use theme tokens instead"
    fi
    # Check for hardcoded pixel values (common anti-pattern)
    if echo "$CONTENT" | grep -qE '[0-9]+px' 2>/dev/null; then
      echo "WARN: Hardcoded px value in $FILE_PATH — consider using spacing tokens"
    fi
    ;;
esac

exit 0
