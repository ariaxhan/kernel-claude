#!/bin/bash
# KERNEL: Validate file structure on writes
# Pre-tool hook for Write/Edit — checks structural conventions

source "$(dirname "$0")/common.sh"

INPUT=$(cat)
while IFS= read -r RECORD; do
FILE_PATH=$(printf '%s' "$RECORD" | jq -r '.path // empty' 2>/dev/null)
case "$FILE_PATH" in
  */agents/*.md)
    # Agents must have frontmatter with name and description
    if [ -f "$FILE_PATH" ]; then
      if ! head -5 "$FILE_PATH" | grep -q "^---"; then
        echo "WARN: Agent file missing frontmatter: $FILE_PATH"
      fi
    fi
    ;;
  */skills/*/SKILL.md)
    # Skills should have triggers section
    if [ -f "$FILE_PATH" ]; then
      if ! grep -q "trigger" "$FILE_PATH" 2>/dev/null; then
        echo "WARN: Skill file missing triggers: $FILE_PATH"
      fi
    fi
    ;;
esac
done < <(kernel_hook_file_records "$INPUT")

# Always pass — warnings only, never block
exit 0
