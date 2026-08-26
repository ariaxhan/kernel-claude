#!/bin/bash
# Build the Gemini CLI extension bundle uploaded as the release asset.
#
#   Usage: scripts/build-gemini-extension.sh [outdir]   (default: dist/)
#
# WHY A CURATED BUNDLE AND NOT THE SOURCE TARBALL
#
# `gemini extensions install <github-url>` resolves to the latest release. If that
# release carries exactly ONE asset whose name names no platform, Gemini downloads
# that asset; otherwise it falls back to GitHub's auto-generated source tarball.
# (gemini-cli 0.44.1, findReleaseAsset + downloadFromGitHubRelease.)
#
# The source tarball is the wrong thing to hand Gemini. Gemini discovers several
# directories by convention, relative to the extension root:
#
#   skills/            compatible -- SKILL.md name/description frontmatter matches
#   agents/            INCOMPATIBLE -- Claude's `tools: Read, Bash` is a string,
#                      Gemini's schema wants an array. Measured: 10 validation
#                      errors printed on every extension command and every session.
#   hooks/hooks.json   INCOMPATIBLE -- Gemini does not substitute
#                      ${CLAUDE_PLUGIN_ROOT} (unknown hydration keys are left
#                      literal), reads `timeout` as MILLISECONDS, and implements
#                      none of PreToolUse/PostToolUse/UserPromptSubmit/Stop/
#                      PreCompact/PermissionRequest/PostToolUseFailure. Measured on
#                      0.44.1: 7 "Invalid hook event name" warnings, SessionStart
#                      0/3 succeeded, SessionEnd 0/1 succeeded.
#
# So the bundle ships the manifest, the context file, the skills, and the license,
# and nothing else. It is packed FLAT (manifest at archive root) because Gemini
# only unwraps a single nested directory when the extracted tree has exactly two
# entries; flat needs no unwrapping at all.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:-$ROOT/dist}"
cd "$ROOT"

VERSION=$(python3 -c "import json; print(json.load(open('gemini-extension.json'))['version'])")
STAGE=$(mktemp -d)
cleanup() { [ -n "${STAGE:-}" ] && [ -d "$STAGE" ] && /bin/rm -rf -- "$STAGE"; }
trap cleanup EXIT

cp gemini-extension.json llms.txt LICENSE "$STAGE/"
mkdir -p "$STAGE/skills"
for skill in skills/*/; do
  # Strip the trailing slash: `cp -R dir/ dest/` copies the CONTENTS on BSD cp,
  # which flattens every skill into one directory.
  name=$(basename "$skill")
  cp -R "skills/$name" "$STAGE/skills/$name"
done

# Fail loudly rather than shipping a bundle that would reintroduce the errors above.
for forbidden in agents hooks commands policies .claude-plugin .codex-plugin; do
  if [ -e "$STAGE/$forbidden" ]; then
    echo "error: bundle contains $forbidden" >&2
    exit 1
  fi
done

mkdir -p "$OUT"
ASSET="$OUT/kernel-gemini-extension.tar.gz"
tar -czf "$ASSET" -C "$STAGE" .
echo "built $ASSET (kernel $VERSION, $(tar -tzf "$ASSET" | grep -c 'SKILL.md$') skills)"
echo "upload as the ONLY asset on the release, or Gemini falls back to the source tarball"
