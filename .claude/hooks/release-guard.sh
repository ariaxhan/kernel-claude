#!/bin/bash
# PreToolUse(Bash) guard for kernel-claude releases.
# A version bump or tag push auto-upgrades the Codex plugin cache, which deletes the old
# cache dir under every live Codex session and makes each of its hooks exit 127 until
# the session restarts (2026-08-28: eight sessions broken by v9.6.6; docs/upgrading.md).
# Denies bump-version.sh, git tag, and tag pushes while Codex is live. KERNEL_RELEASE_OK=1 overrides.
set -u
INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -n "$CMD" ] || exit 0
[ "${KERNEL_RELEASE_OK:-0}" = "1" ] && exit 0
# Real invocations only: a version argument or a tag ref. Prose mentions never match.
printf '%s' "$CMD" | grep -qE 'bump-version\.sh[[:space:]]+[0-9]+\.[0-9]+\.[0-9]+|git[[:space:]]+tag[[:space:]]+(-a[[:space:]]+)?v?[0-9]+\.[0-9]+\.[0-9]+|git[[:space:]]+push[^;&|]*(--tags|[[:space:]]v[0-9]+\.[0-9]+\.[0-9]+)' || exit 0
# Count PROCESSES, not lines. `pgrep -fl` prints each match's whole command line, so a
# session carrying a multi-line prompt that merely mentions codex contributed one count per
# line of that prompt: on 2026-09-10 this reported 208, then 146, "live Codex processes"
# while three were running. A gate that fires on noise trains everyone to override it, and
# the same prose-mention trap the CMD regex above was written to dodge was live here.
# `pgrep -f` prints one pid per line, which is the number this always meant.
PIDS=$(pgrep -f 'node /opt/homebrew/bin/codex$|codex app-server' 2>/dev/null | tr '\n' ' ')
LIVE=$(printf '%s' "$PIDS" | wc -w | tr -d ' ')
[ "${LIVE:-0}" -gt 0 ] || exit 0
echo "release-guard: $LIVE live Codex session(s) [pids: $PIDS]. A bump or tag push auto-upgrades the Codex plugin cache, deletes the version directory those sessions are running out of, and every hook in them exits 127 until restart (v9.6.6 broke eight). Restart them first, or rerun with KERNEL_RELEASE_OK=1 after Aria says go." >&2
exit 2
