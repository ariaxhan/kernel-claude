#!/bin/bash
# PreToolUse hook: Block destructive bash commands
# Safety net for irreversible operations. Blocks force-push, hard reset, etc.
# Events: PreToolUse (matcher: Bash)

source "$(dirname "$0")/circuit-breaker.sh"

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

[ -z "$COMMAND" ] && exit 0

# Block force push (any form)
if echo "$COMMAND" | grep -qE 'git\s+push\s+.*(-f|--force)'; then
    echo "BLOCKED: Force push not allowed. Use regular push or ask Aria first." >&2
    exit 2
fi

# Block hard reset
if echo "$COMMAND" | grep -qE 'git\s+reset\s+--hard'; then
    echo "BLOCKED: git reset --hard discards changes. Use --soft or git stash." >&2
    exit 2
fi

# Block git clean -f (deletes untracked files)
if echo "$COMMAND" | grep -qE 'git\s+clean\s+-[a-zA-Z]*f'; then
    echo "BLOCKED: git clean -f deletes untracked files permanently. Review manually." >&2
    exit 2
fi

# Block discard-all-changes patterns
if echo "$COMMAND" | grep -qE 'git\s+(checkout|restore)\s+\.\s*$'; then
    echo "BLOCKED: This discards all working tree changes. Use git stash instead." >&2
    exit 2
fi

# Block deleting main/master branch
if echo "$COMMAND" | grep -qE 'git\s+branch\s+-D\s+(main|master)\s*$'; then
    echo "BLOCKED: Cannot delete main/master branch." >&2
    exit 2
fi

# Block recursive force delete of root/home
if echo "$COMMAND" | grep -qE 'rm\s+-[a-zA-Z]*r[a-zA-Z]*f[a-zA-Z]*\s+(/\s|/\s*$|~/|"\$HOME"|"\$\{HOME\}")'; then
    echo "BLOCKED: Refusing to recursively delete root or home directory." >&2
    exit 2
fi

_cb_record_success
exit 0
