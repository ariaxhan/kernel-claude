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
# Catches: --force, -f, --force-with-lease, +refspec, before or after the refspec.
# The force flag AND the main/master target must appear in the SAME `git push`
# segment. Segmenting on shell separators (;|&, matching the rm-gate style below)
# is what stops a force flag elsewhere in a compound command from false-tripping
# -- e.g. `rm -f x && git push origin main` or `git push origin HEAD:main && rm -f y`
# are NOT force pushes and must pass.
while IFS= read -r _seg; do
  echo "$_seg" | grep -qE 'git[[:space:]].*\bpush\b' || continue
  echo "$_seg" | grep -qE '\b(main|master)\b'        || continue
  if echo "$_seg" | grep -qE '(^|[[:space:]])(-f|--force|--force-with-lease)([[:space:]]|=|$)' \
     || echo "$_seg" | grep -qE '[[:space:]]\+[^[:space:]]*(main|master)'; then
      echo "BLOCKED: Force push to main/master not allowed." >&2
      exit 2
  fi
done < <(echo "$COMMAND" | tr ';|&' '\n')

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

# --- Investigation gate: rm/rmdir of git submodules or tracked directories ---
# NOT a hard block. Surfaces what the target actually IS and requires a conscious
# CONFIRM_DELETE=1 re-issue, so an uninitialized submodule (an empty folder is
# uninitialized, NOT junk) or a whole tracked directory can't be removed on a
# tidy-up reflex. Scope is deliberately narrow -- submodules always; tracked
# paths only when it's a directory or a recursive rm -- so routine single-file
# `rm file.ts` (recoverable from git history) is never nagged.
# (vault rule: Vaults/.claude/rules/invariants.md -> "Destructive & structural ops")
if echo "$COMMAND" | grep -qE '(^|[^[:alnum:]_./-])(rm|rmdir)([[:space:]]|$)' \
   && ! echo "$COMMAND" | grep -qE '(^|[[:space:]])CONFIRM_DELETE=1([[:space:]]|$)'; then
  _recursive=0
  echo "$COMMAND" | grep -qE '\brm\b[^;&|]*(-[a-zA-Z]*[rR]|--recursive)' && _recursive=1
  echo "$COMMAND" | grep -qE '\brmdir\b' && _recursive=1
  # Candidate path tokens: per rm/rmdir segment, drop the command word + flags.
  _paths=$(echo "$COMMAND" | tr ';|&' '\n' \
    | grep -E '(^|[^[:alnum:]_./-])(rm|rmdir)([[:space:]])' \
    | sed -E 's/.*\b(rm|rmdir)[[:space:]]+//' \
    | tr ' \t' '\n' \
    | grep -vE '^(-|$)' \
    | sed -E "s/^[\"']//; s/[\"']$//")
  for _p in $_paths; do
    case "$_p" in /tmp/*|/var/folders/*|/private/var/*) continue;; esac
    [ -n "$_p" ] || continue
    # Submodule? mode 160000 is present in the index even for an uninitialized,
    # empty submodule folder -- the exact case that broke modelmind.
    if git ls-files --stage -- "$_p" 2>/dev/null | grep -q '^160000'; then
      echo "HALT -- investigate before deleting: '$_p' is a GIT SUBMODULE." >&2
      echo "  An empty submodule folder is UNINITIALIZED, not junk; deleting it breaks the parent repo." >&2
      echo "  Look:     git ls-files --stage -- '$_p'   (160000 = submodule)   |   cat .gitmodules" >&2
      echo "  Restore:  git submodule update --init -- '$_p'   (populate it in place -- do NOT re-clone elsewhere)" >&2
      echo "  If you have verified and truly intend to remove it, re-run with:  CONFIRM_DELETE=1 <cmd>" >&2
      exit 2
    fi
    # Tracked directory, or recursive rm of tracked content?
    if [ -n "$(git ls-files -- "$_p" 2>/dev/null | head -1)" ] && { [ -d "$_p" ] || [ "$_recursive" = 1 ]; }; then
      echo "HALT -- investigate before deleting: '$_p' is TRACKED in git (directory / recursive rm)." >&2
      echo "  Confirm it's safe:  git ls-files -- '$_p' | head   |   grep -rn '$(basename "$_p")' --include='*.sh' --include='*.ts' --include='*.js' --include='*.json' ." >&2
      echo "  Prefer:  git rm -r '$_p'  (keeps history)  -- or  git restore  if you meant to undo working changes." >&2
      echo "  If verified and intended, re-run with:  CONFIRM_DELETE=1 <cmd>" >&2
      exit 2
    fi
  done
fi

exit 0
