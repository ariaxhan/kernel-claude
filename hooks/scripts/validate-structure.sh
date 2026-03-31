#!/bin/bash
# KERNEL: Validate file structure on writes
# Pre-tool hook for Write/Edit — checks structural conventions

set -e

source "$(dirname "$0")/common.sh"

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.file_path // .path // ""' 2>/dev/null)

# Only validate files we care about
case "$FILE_PATH" in
  */commands/*.md)
    # Commands must have frontmatter with name and user-invocable
    if [ -f "$FILE_PATH" ]; then
      if ! head -5 "$FILE_PATH" | grep -q "^---"; then
        echo "WARN: Command file missing frontmatter: $FILE_PATH"
      fi
    fi
    ;;
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

# Always pass — warnings only, never block
exit 0
