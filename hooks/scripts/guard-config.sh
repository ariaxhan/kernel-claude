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

  # --- 8.2.0 sensitive-path writes (T4 MCP poisoning + T5 scope escape) ---
  # The block line: anything that makes code auto-run later without a human in the
  # loop, anything under a credential root, and the guard's own approval tokens.
  # Every block SURFACES — the agent reports it and the human makes the change.
  case "$FILE_PATH" in
    *".kernel/approvals/"*)
      echo "BLOCKED: write into the kernel approval-token store. Only the guard mints tokens; only the human reads them." >&2
      exit 2 ;;
  esac
  if echo "$FILE_PATH" | grep -qE '(^|/)\.(ssh|aws|gnupg)/'; then
    echo "BLOCKED: write into a credential root ($FILE_PATH)." >&2
    echo "  Changes under ~/.ssh, ~/.aws, ~/.gnupg (keys, authorized_keys, credentials) are quiet and security-critical -- the human makes these directly." >&2
    exit 2
  fi
  if echo "$FILE_PATH" | grep -qE '(^|/)\.(bashrc|zshrc|zshenv|zprofile|profile|bash_profile)$'; then
    echo "BLOCKED: write to a shell startup file ($FILE_PATH) -- auto-executed on every future shell (silent persistence)." >&2
    echo "  Show the human the exact line to add; they apply it." >&2
    exit 2
  fi
  if echo "$FILE_PATH" | grep -qE '/\.git/hooks/'; then
    echo "BLOCKED: direct write into .git/hooks/ (auto-executed by git)." >&2
    echo "  Hooks are installed by a reviewed installer script the human runs, never a silent write." >&2
    exit 2
  fi
  if echo "$FILE_PATH" | grep -qE '(^|/)(\.mcp\.json|\.cursor/mcp\.json)$'; then
    echo "BLOCKED: write to MCP server config ($FILE_PATH). MCP entries auto-execute (CurXecute / MCPoison attack class)." >&2
    echo "  The human reviews and applies MCP config changes." >&2
    exit 2
  fi
  if echo "$FILE_PATH" | grep -qE '/Library/(LaunchAgents|LaunchDaemons)/|^/etc/(cron|crontab)'; then
    echo "BLOCKED: write to launchd/cron persistence config ($FILE_PATH) -- installs code that runs on schedule/login, quietly." >&2
    echo "  Persistence changes go through the human: show them the plist/crontab content to apply." >&2
    exit 2
  fi

  # Only care about .claude/ paths beyond this point.
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
