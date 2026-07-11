#!/bin/bash
# Bump the KERNEL plugin version across EVERY canonical declaration, in lockstep.
#
#   Usage: scripts/bump-version.sh X.Y.Z
#
# Canonical version declarations (kept in sync; drift FAILS test_version_sync_all
# in tests/run-tests.sh):
#   .claude-plugin/plugin.json        "version"
#   .claude-plugin/marketplace.json   plugins[0].version
#   CLAUDE.md                         <kernel version="X.Y.Z">
#   skills/help/SKILL.md                  KERNEL vX.Y.Z
#   README.md                         kernel-marketplace/kernel/X.Y.Z  (install example path)
#
# NOT touched here (human-authored per release, intentionally version-specific prose):
#   - plugin.json / marketplace.json `description` highlight (v7.x: ...)
#   - CHANGELOG.md release entry
# Pure-Python edits (no sed -i) so it runs identically on macOS and Linux.
set -euo pipefail

NEW="${1:?usage: scripts/bump-version.sh X.Y.Z}"
[[ "$NEW" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "error: '$NEW' is not semver X.Y.Z" >&2; exit 1; }

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

python3 - "$NEW" <<'PY'
import json, re, sys, pathlib
new = sys.argv[1]
old = json.load(open('.claude-plugin/plugin.json'))['version']
print(f"bump {old} -> {new}")

def sub(path, pattern, repl):
    p = pathlib.Path(path); t = p.read_text()
    t2, n = re.subn(pattern, repl, t)
    if n < 1:
        raise SystemExit(f"FAIL {path}: version pattern not found ({pattern})")
    p.write_text(t2)
    print(f"  {path}: {n} occurrence(s) updated")

sub('.claude-plugin/plugin.json',      r'("version":\s*")[0-9]+\.[0-9]+\.[0-9]+(")',     rf'\g<1>{new}\g<2>')
sub('.claude-plugin/marketplace.json', r'("version":\s*")[0-9]+\.[0-9]+\.[0-9]+(")',     rf'\g<1>{new}\g<2>')
sub('CLAUDE.md',                       r'(<kernel version=")[0-9]+\.[0-9]+\.[0-9]+(">)',  rf'\g<1>{new}\g<2>')
sub('skills/help/SKILL.md',                r'(KERNEL v)[0-9]+\.[0-9]+\.[0-9]+',               rf'\g<1>{new}')
sub('README.md',                       r'(kernel-marketplace/kernel/)[0-9]+\.[0-9]+\.[0-9]+', rf'\g<1>{new}')

# validate JSON still parses and carries the new version
assert json.load(open('.claude-plugin/plugin.json'))['version'] == new, "plugin.json"
assert json.load(open('.claude-plugin/marketplace.json'))['plugins'][0]['version'] == new, "marketplace.json"
print(f"OK: all canonical declarations at {new}")
print("Remember (human-authored): update the description highlight + add a CHANGELOG entry.")
PY
