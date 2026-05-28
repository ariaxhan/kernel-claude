#!/bin/bash
# PreToolUse hook: Guard .claude/ directory
# Allows config edits, blocks generated content
# Events: PreToolUse (matcher: Write|Edit)

# Does NOT source circuit-breaker.sh: a blocking safety guard must always run
# and must never auto-disable itself (I0.15). Narrow guard, so on a jq failure
# it warns and allows rather than blocking every write (which would brick the session).

INPUT=$(cat)

if ! command -v jq >/dev/null 2>&1; then
  echo "guard-config: warning -- jq not found, .claude/ write guard is degraded (install jq)." >&2
  exit 0
fi

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

[ -z "$FILE_PATH" ] && exit 0

# Only care about .claude/ paths
if ! echo "$FILE_PATH" | grep -q '\.claude/'; then
    exit 0
fi

# Allow: CLAUDE.md, rules/*.md, commands/*.md, agents/*.md, skills/*.md, hooks/*.sh, settings*.json
if echo "$FILE_PATH" | grep -qE '\.claude/(CLAUDE\.md|rules/.*\.md|commands/.*\.md|agents/.*\.md|skills/.*\.md|hooks/.*\.sh|settings.*\.json|projects/.*/memory/.*)$'; then
    exit 0
fi

# Block: anything else in .claude/ (generated content should go to _meta/)
echo "BLOCKED: .claude/ is for config only. Generated content goes to _meta/" >&2
echo "  Attempted: $FILE_PATH" >&2
echo "  Allowed: CLAUDE.md, rules/*.md, commands/*.md, agents/*.md, skills/*.md, hooks/*.sh, settings*.json" >&2
exit 2
