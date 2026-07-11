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

if ! echo "$INPUT" | jq -e 'type == "object" and (.tool_input | type == "object")' >/dev/null 2>&1; then
  echo "BLOCKED: config guard received unreadable or malformed hook JSON." >&2
  exit 2
fi

FILE_PATHS=$(echo "$INPUT" | jq -r '
  if (.tool_input.file_path | type) == "string" then .tool_input.file_path
  elif (.tool_input.patch | type) == "string" then
    .tool_input.patch
    | split("\n")[]
    | select(test("^\\*\\*\\* (Add File|Update File|Delete File|Move to): "))
    | sub("^\\*\\*\\* (Add File|Update File|Delete File|Move to): "; "")
  else empty end
')

[ -z "$FILE_PATHS" ] && exit 0

while IFS= read -r FILE_PATH; do
  [ -z "$FILE_PATH" ] && continue
  # Only care about .claude/ paths.
  echo "$FILE_PATH" | grep -q '\.claude/' || continue

  # Reject lexical traversal before applying the allowlist. A path such as
  # .claude/rules/../generated/x.md resolves outside the apparently allowed tree.
  if echo "$FILE_PATH" | grep -qE '(^|/)\.\.?(/|$)'; then
    echo "BLOCKED: dot segments are not allowed in .claude/ write paths." >&2
    echo "  Attempted: $FILE_PATH" >&2
    exit 2
  fi

  # Allow: CLAUDE.md, rules/*.md, commands/*.md, agents/*.md, skills/*.md, hooks/*.sh, settings*.json
  if echo "$FILE_PATH" | grep -qE '\.claude/(CLAUDE\.md|rules/.*\.md|commands/.*\.md|agents/.*\.md|skills/.*\.md|hooks/.*\.sh|settings.*\.json|projects/.*/memory/.*)$'; then
    continue
  fi

  # Block: anything else in .claude/ (generated content should go to _meta/).
  echo "BLOCKED: .claude/ is for config only. Generated content goes to _meta/" >&2
  echo "  Attempted: $FILE_PATH" >&2
  echo "  Allowed: CLAUDE.md, rules/*.md, commands/*.md, agents/*.md, skills/*.md, hooks/*.sh, settings*.json" >&2
  exit 2
done <<< "$FILE_PATHS"

exit 0
