#!/bin/bash
# PreToolUse hook: Block only the most dangerous bash commands
# Minimal guardrails — block rm -rf / and force push to main. That's it.
# Events: PreToolUse (matcher: Bash)

source "$(dirname "$0")/circuit-breaker.sh"

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

[ -z "$COMMAND" ] && exit 0

# Block force push to main/master only
if echo "$COMMAND" | grep -qE 'git\s+push\s+--force\s+.*\b(main|master)\b'; then
    echo "BLOCKED: Force push to main/master not allowed." >&2
    exit 2
fi

# Block rm -rf on root or home
if echo "$COMMAND" | grep -qE 'rm\s+-rf\s+(/\s*$|/\s|~/)'; then
    echo "BLOCKED: Refusing to rm -rf root or home." >&2
    exit 2
fi

_cb_record_success
exit 0
