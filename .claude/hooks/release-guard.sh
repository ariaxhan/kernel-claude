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
LIVE=$(pgrep -fl 'node /opt/homebrew/bin/codex|codex app-server' 2>/dev/null | wc -l | tr -d ' ')
[ "${LIVE:-0}" -gt 0 ] || exit 0
echo "release-guard: $LIVE live Codex process(es). A bump or tag push auto-upgrades the Codex plugin cache and kills every hook in those sessions (exit 127). Restart them first, or rerun with KERNEL_RELEASE_OK=1 after Aria says go." >&2
exit 2
