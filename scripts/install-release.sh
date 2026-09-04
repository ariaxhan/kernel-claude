#!/usr/bin/env bash
# Refresh Claude Code's installed KERNEL and prove a fresh process loads it.

set -euo pipefail

VERSION="${1:-}"
[[ "$VERSION" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]] || {
  echo "Usage: scripts/install-release.sh X.Y.Z" >&2
  exit 2
}

command -v claude >/dev/null 2>&1 || { echo "claude CLI not found" >&2; exit 1; }
CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
CACHE="$CONFIG_DIR/plugins/cache/kernel-marketplace/kernel"
RUNTIME="$CACHE/$VERSION"

claude plugin marketplace update kernel-marketplace
claude plugin update kernel@kernel-marketplace --yes

[ -d "$RUNTIME" ] || {
  echo "Claude cache lacks KERNEL $VERSION: $RUNTIME" >&2
  exit 1
}
KERNEL_CACHE_DIR="$CACHE" "$RUNTIME/scripts/select-runtime.sh" "$RUNTIME"

INSTALLED=$(claude plugin list --json | python3 -c '
import json, sys
data = json.load(sys.stdin)
items = data if isinstance(data, list) else data.get("plugins", [])
for item in items:
    if item.get("id") == "kernel@kernel-marketplace" or item.get("name") == "kernel":
        print(item.get("version", ""))
        break
')
[ "$INSTALLED" = "$VERSION" ] || {
  echo "Claude reports KERNEL ${INSTALLED:-missing}; expected $VERSION" >&2
  exit 1
}

DEBUG_LOG=$(mktemp)
trap 'rm -f "$DEBUG_LOG"' EXIT
claude --print --max-turns 1 --debug-file "$DEBUG_LOG" "Reply ok" >/dev/null 2>&1 || true
grep -F "Attempting to load skills from plugin kernel default skillsPath: $RUNTIME/skills" \
  "$DEBUG_LOG" >/dev/null || {
  echo "Fresh Claude process did not load KERNEL $VERSION" >&2
  exit 1
}

echo "Claude KERNEL $VERSION installed and selected: $RUNTIME"
echo "Fresh Claude process loaded: $RUNTIME/skills"
