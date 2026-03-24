#!/bin/bash
# PermissionRequest hook: Auto-approve safe bash commands
# Only fires for commands NOT already in the permissions allow list.
# Auto-approves read-only git, test runners, and diagnostics.
# Events: PermissionRequest (matcher: Bash)

source "$(dirname "$0")/circuit-breaker.sh"

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

[ -z "$COMMAND" ] && exit 0

# Auto-approve read-only git operations
if echo "$COMMAND" | grep -qE '^git\s+(status|log|diff|branch|remote|show|tag|describe|shortlog|rev-parse|rev-list)\b'; then
    echo '{"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"allow"}}}'
    exit 0
fi

# Auto-approve test commands
if echo "$COMMAND" | grep -qE '^(npm\s+test|npx\s+(jest|vitest|mocha)|python.*-m\s+pytest|go\s+test|cargo\s+test)'; then
    echo '{"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"allow"}}}'
    exit 0
fi

# Auto-approve linting and type checking
if echo "$COMMAND" | grep -qE '^(npx\s+tsc|npm\s+run\s+(lint|typecheck|check)|ruff\s+check|mypy|pylint|eslint)'; then
    echo '{"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"allow"}}}'
    exit 0
fi

# Auto-approve read-only diagnostics
if echo "$COMMAND" | grep -qE '^(pwd|whoami|uname|df|du|free|uptime|id|hostname)'; then
    echo '{"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"allow"}}}'
    exit 0
fi

# Don't interfere with other commands - let normal permission flow handle them
_cb_record_success
exit 0
