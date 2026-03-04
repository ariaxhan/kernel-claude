#!/bin/bash
# PreToolUse hook: Guard .claude/ directory
# Allows config edits, blocks generated content
# Events: PreToolUse (matcher: Write|Edit)

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

[ -z "$FILE_PATH" ] && exit 0

# Only care about .claude/ paths
if ! echo "$FILE_PATH" | grep -q '\.claude/'; then
    exit 0
fi

# Allow: CLAUDE.md, rules/*.md, commands/*.md, agents/*.md, skills/*.md, hooks/*.sh, settings*.json
if echo "$FILE_PATH" | grep -qE '\.claude/(CLAUDE\.md|rules/.*\.md|commands/.*\.md|agents/.*\.md|skills/.*\.md|hooks/.*\.sh|settings.*\.json)$'; then
    exit 0
fi

# Block: anything else in .claude/ (generated content should go to _meta/)
echo "BLOCKED: .claude/ is for config only. Generated content goes to _meta/" >&2
echo "  Attempted: $FILE_PATH" >&2
echo "  Allowed: CLAUDE.md, rules/*.md, commands/*.md, agents/*.md, skills/*.md, hooks/*.sh, settings*.json" >&2
exit 2
