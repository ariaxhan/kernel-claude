#!/bin/bash
# PreToolUse hook: Block only the most dangerous bash commands.
# Minimal, robust guardrails -- block force-push to main/master and recursive
# forced deletion of root/home. That is the whole scope; it is not a sandbox.
# Events: PreToolUse (matcher: Bash)
#
# Does NOT source circuit-breaker.sh: a safety gate must always run and must
# never auto-disable itself (I0.15). It is also intentionally narrow, so on a
# parser (jq) failure it WARNS and allows rather than blocking every bash
# command (which would brick the session) -- the high-value secret gate is the
# one that fails closed.

INPUT=$(cat)

if ! command -v jq >/dev/null 2>&1; then
  echo "guard-bash: warning -- jq not found, destructive-command guard is degraded (install jq)." >&2
  exit 0
fi

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[ -z "$COMMAND" ] && exit 0

# --- Block force push to main/master (any flag form, any position) ---
# Catches: --force, -f, --force-with-lease, before or after the refspec.
if echo "$COMMAND" | grep -qE 'git[[:space:]].*\bpush\b' \
   && echo "$COMMAND" | grep -qE '(^|[[:space:]])(-f|--force|--force-with-lease)([[:space:]]|=|$)' \
   && echo "$COMMAND" | grep -qE '\b(main|master)\b'; then
    echo "BLOCKED: Force push to main/master not allowed." >&2
    exit 2
fi

# --- Block recursive+forced rm of root or home (common flag orderings) ---
# recursive+force in one token (-rf/-fr/-Rf), as separate flags, long flags,
# or --no-preserve-root.
rm_recursive_force() {
  echo "$COMMAND" | grep -qE '\brm\b' || return 1
  echo "$COMMAND" | grep -qE '\brm\b[^;&|]*(-[a-zA-Z]*[rR][a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*[rR])' && return 0
  { echo "$COMMAND" | grep -qE '\brm\b[^;&|]*-[a-zA-Z]*[rR]([[:space:]]|$)' \
    && echo "$COMMAND" | grep -qE '\brm\b[^;&|]*-[a-zA-Z]*f([[:space:]]|$)'; } && return 0
  { echo "$COMMAND" | grep -qE '\brm\b[^;&|]*--recursive' \
    && echo "$COMMAND" | grep -qE '\brm\b[^;&|]*--force'; } && return 0
  echo "$COMMAND" | grep -qE '\brm\b[^;&|]*--no-preserve-root' && return 0
  return 1
}
# Targets root or home ITSELF (not a subdir): / , /* , ~ , ~/ , ~/* , $HOME .
# Deliberately does NOT match ~/subdir or /subdir -- deleting those is the
# user's call; only wiping the whole root/home tree is catastrophic enough to block.
rm_targets_root_home() {
  echo "$COMMAND" | grep -qE '(^|[[:space:]])(/|/\*|~|~/|~/\*|\$HOME/?|\$\{HOME\}/?)([[:space:]]|$)'
}
if rm_recursive_force && rm_targets_root_home; then
    echo "BLOCKED: Refusing recursive forced delete of root or home." >&2
    exit 2
fi

exit 0
