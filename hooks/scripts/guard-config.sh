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

# Codex apply_patch carries the patch in tool_input.command, not .patch
# (live codex-cli 0.150.1 payload, 2026-08-27). Reading only .patch made this
# allowlist see no paths at all on Codex, so it guarded nothing there.
FILE_PATHS=$(echo "$INPUT" | jq -r '
  def patch_text:
    if (.tool_input.patch | type) == "string" then .tool_input.patch
    elif (.tool_input.command | type) == "string"
      and (.tool_input.command | test("^\\*\\*\\* Begin Patch")) then .tool_input.command
    else null end;
  if (.tool_input.file_path | type) == "string" then .tool_input.file_path
  elif (patch_text != null) then
    patch_text
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
  # System-wide persistence (root scope) and cron are never agent-writable.
  if echo "$FILE_PATH" | grep -qE '/Library/LaunchDaemons/|^/etc/(cron|crontab)'; then
    echo "BLOCKED: write to system-wide persistence ($FILE_PATH) -- runs as root, on schedule, quietly." >&2
    echo "  Show the human the exact plist/crontab content; they apply it." >&2
    exit 2
  fi
  # User LaunchAgents: the risk is scheduling ARBITRARY code, not scheduling at all.
  # A project's own automation is the normal, legitimate case and blocking it outright
  # just taught agents to hand humans copy-paste chores. So the test is provenance:
  # every path the job executes must live inside the project being worked on.
  if echo "$FILE_PATH" | grep -q '/Library/LaunchAgents/'; then
    PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
    CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // .tool_input.new_string // ""')

    if [ -z "$CONTENT" ]; then
      echo "BLOCKED: launchd plist write with no readable content ($FILE_PATH)." >&2
      echo "  Cannot verify what it would execute. Write the plist inside the project first, then install it." >&2
      exit 2
    fi

    # Fetch-and-execute in a scheduled job is the payload shape worth refusing outright.
    if echo "$CONTENT" | grep -qE 'curl[^|]*\||wget[^|]*\||base64[[:space:]]+(-d|--decode)|\|[[:space:]]*(sh|bash)([[:space:]]|$)|osascript -e'; then
      echo "BLOCKED: launchd plist contains a fetch-or-decode-then-execute pattern ($FILE_PATH)." >&2
      exit 2
    fi

    # Every absolute path in the plist must be a system interpreter the agent cannot
    # rewrite, or live in the project.
    #
    # This list is deliberately EXACT PATHS, never directory wildcards. A previous
    # version allowed /usr/local/bin/* and /opt/homebrew/bin/*, which defeated the whole
    # guard on any normal Mac: /opt/homebrew/bin is owned by the login user, so the agent
    # could write its own payload there and then schedule it, gaining persistent arbitrary
    # execution while this script printed "all executed paths resolve inside <project>".
    # The risk being controlled is scheduling code the agent authored, so an allowed path
    # must be one the agent cannot author.
    OUTSIDE=""
    while IFS= read -r P; do
      [ -z "$P" ] && continue
      case "$P" in
        /bin/sh|/bin/bash|/bin/zsh|/usr/bin/env|/usr/bin/python3|/usr/bin/open) continue ;;
      esac
      case "$P" in
        "$PROJECT_ROOT"/*) continue ;;
      esac
      # Defence in depth for interpreters installed outside the system prefix (Homebrew
      # python3, node): permitted only when the binary exists, is NOT writable by this
      # user, AND its directory is not writable either. The directory check matters as
      # much as the file check: a read-only binary inside a writable directory can simply
      # be deleted and replaced, which is the same bypass one level up. A path that does
      # not exist is refused rather than assumed safe.
      if [ -f "$P" ] && [ ! -w "$P" ] && [ ! -w "$(dirname "$P")" ]; then
        continue
      fi
      OUTSIDE="$OUTSIDE $P"
    done <<EOF
$(echo "$CONTENT" | grep -oE '<string>[^<]*</string>' | sed -e 's|</\{0,1\}string>||g' | grep -E '^/')
EOF

    if [ -n "$OUTSIDE" ]; then
      echo "BLOCKED: launchd plist would run code the agent can author ($FILE_PATH)." >&2
      echo "  Not a system interpreter, not inside $PROJECT_ROOT, and agent-writable:$OUTSIDE" >&2
      echo "  Move the script into the project, or have the human install this one." >&2
      exit 2
    fi

    echo "guard-config: allowing LaunchAgent write -- every executed path is a system interpreter or inside $PROJECT_ROOT." >&2
    continue
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

  # Harness-managed session data (~/.claude/projects/): transcripts, per-project
  # memory, workflow scripts, subagent state. Machine-owned state, not config --
  # the config allowlist does not apply. Placed AFTER the dot-segment check so a
  # traversal like ~/.claude/projects/../settings.json is still blocked. (8.5.2:
  # the guard wrongly blocked the harness editing its own workflow scripts.)
  case "$FILE_PATH" in
    "$HOME/.claude/projects/"*) continue ;;
  esac

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
