#!/bin/bash
# KERNEL: Warn on hardcoded values in component/style files
# PreToolUse hook — runs before Write/Edit on component files

source "$(dirname "$0")/common.sh"

INPUT=$(cat)
while IFS= read -r RECORD; do
FILE_PATH=$(printf '%s' "$RECORD" | jq -r '.path // empty' 2>/dev/null)
CONTENT=$(printf '%s' "$RECORD" | jq -r '.content // empty' 2>/dev/null)
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
done < <(kernel_hook_file_records "$INPUT")

exit 0
