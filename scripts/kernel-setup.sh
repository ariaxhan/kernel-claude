#!/usr/bin/env bash
# KERNEL setup: one command from installed plugin to working memory.
#
# Does exactly what skills/init/SKILL.md describes, by calling the same helpers in
# hooks/scripts/common.sh, without needing an agent session to interpret prose.
#
#   kernel-setup.sh [--vaults PATH] [--yes] [--quiet]
#
# Idempotent. Creates missing directories and links; never replaces a user-owned
# path; never edits a shell startup file.

set -uo pipefail

VAULTS_ARG=""
ASSUME_YES=0
QUIET=0

while [ $# -gt 0 ]; do
  case "$1" in
    --vaults) VAULTS_ARG="${2:-}"; shift 2 ;;
    --vaults=*) VAULTS_ARG="${1#*=}"; shift ;;
    -y|--yes) ASSUME_YES=1; shift ;;
    -q|--quiet) QUIET=1; shift ;;
    -h|--help)
      sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) echo "kernel-setup: unknown argument: $1" >&2; exit 2 ;;
  esac
done

say() { [ "$QUIET" = 1 ] || printf '%s\n' "$*"; }
die() { printf 'kernel-setup: %s\n' "$*" >&2; exit 1; }

# ---------------------------------------------------------------- requirements
missing=""
for dep in git sqlite3 jq python3 bash; do
  command -v "$dep" >/dev/null 2>&1 || missing="$missing $dep"
done
if [ -n "$missing" ]; then
  echo "kernel-setup: missing required tools:$missing" >&2
  echo "  macOS:  brew install${missing}" >&2
  echo "  Debian: sudo apt install${missing}" >&2
  exit 1
fi

realpath_of() { python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$1"; }

SCRIPT_DIR=$(cd -P "$(dirname "$0")" && pwd) || die "cannot resolve script directory"
REPO_ROOT=$(cd -P "$SCRIPT_DIR/.." && pwd) || die "cannot resolve repository root"
CACHE="${KERNEL_CACHE_DIR:-$HOME/.claude/plugins/cache/kernel-marketplace/kernel}"

# ------------------------------------------------------------- runtime root
# Resolve to a REAL directory, never the `current` symlink itself:
# kernel_validate_runtime_root rejects a symlink at its first check, so a runtime
# root given as `.../kernel/current` makes the plugin refuse its own selector.
# Version declared by a runtime root, or empty if it is not a readable KERNEL tree.
runtime_version() {
  local manifest="$1/.claude-plugin/plugin.json"
  [ -f "$manifest" ] || return 0
  python3 -c 'import json,sys
try:
    print(json.load(open(sys.argv[1])).get("version",""))
except Exception:
    pass' "$manifest" 2>/dev/null
}

pick_runtime() {
  if [ -n "${KERNEL_RUNTIME_ROOT:-}" ]; then
    realpath_of "$KERNEL_RUNTIME_ROOT"; return 0
  fi
  if [ -L "$CACHE/current" ]; then
    realpath_of "$CACHE/current"; return 0
  fi
  local best="" d v
  for d in "$CACHE"/*; do
    [ -d "$d" ] || continue
    v=$(basename "$d")
    case "$v" in
      [0-9]*.[0-9]*.[0-9]*) ;;
      *) continue ;;
    esac
    if [ -z "$best" ] || [ "$(printf '%s\n%s\n' "$(basename "$best")" "$v" | sort -t. -k1,1n -k2,2n -k3,3n | tail -1)" = "$v" ]; then
      best="$d"
    fi
  done
  # Prefer the checkout this script was invoked from when it is NEWER than anything cached.
  #
  # Without this, running a 9.0.0 checkout's own setup script silently configured whatever
  # older release happened to be in the cache, because the cache was consulted first. The
  # user's intent when they run THIS repo's script is this repo, so a stale cache winning
  # silently is a upgrade-path trap rather than a safe default.
  local repo_v="" best_v=""
  repo_v=$(runtime_version "$REPO_ROOT")
  [ -n "$best" ] && best_v=$(basename "$best")
  if [ -n "$repo_v" ] && [ -f "$REPO_ROOT/hooks/scripts/common.sh" ]; then
    if [ -z "$best_v" ] || [ "$(printf '%s\n%s\n' "$best_v" "$repo_v" | sort -t. -k1,1n -k2,2n -k3,3n | tail -1)" = "$repo_v" ]; then
      if [ -n "$best_v" ] && [ "$best_v" != "$repo_v" ]; then
        printf 'kernel-setup: using this checkout (%s), newer than cached %s\n' "$repo_v" "$best_v" >&2
      fi
      realpath_of "$REPO_ROOT"; return 0
    fi
    printf 'kernel-setup: using cached runtime %s, newer than this checkout (%s)\n' "$best_v" "$repo_v" >&2
  fi
  if [ -n "$best" ]; then realpath_of "$best"; return 0; fi
  # Contributor path: run straight out of a checkout, nothing installed yet.
  realpath_of "$REPO_ROOT"
}

RUNTIME=$(pick_runtime) || die "could not locate a KERNEL runtime"
[ -f "$RUNTIME/hooks/scripts/common.sh" ] || die "not a KERNEL runtime: $RUNTIME"

# common.sh derives its root from BASH_SOURCE with a logical pwd, which resolves to
# the symlink path when sourced through `current`. Pin it explicitly instead.
export KERNEL_RUNTIME_ROOT="$RUNTIME"
export KERNEL_CACHE_DIR="$CACHE"
export KERNEL_RUNTIME_QUIET=1

# shellcheck source=/dev/null
source "$RUNTIME/hooks/scripts/common.sh" || die "could not load $RUNTIME/hooks/scripts/common.sh"

kernel_validate_runtime_root "$RUNTIME" >/dev/null || die "runtime failed validation: $RUNTIME"
VERSION=$(kernel_validate_runtime_root "$RUNTIME")

# ------------------------------------------------------------------- vaults
if [ -n "$VAULTS_ARG" ]; then
  VAULTS="$VAULTS_ARG"
else
  VAULTS=$(detect_vaults) || die "could not determine a Vaults directory"
fi
case "$VAULTS" in
  /*) ;;
  *) VAULTS="$PWD/$VAULTS" ;;
esac

say "KERNEL $VERSION"
say "  runtime: $RUNTIME"
say "  vaults:  $VAULTS"

if [ "$ASSUME_YES" != 1 ]; then
  if [ -t 0 ]; then
    printf 'Set up KERNEL data in %s? [Y/n] ' "$VAULTS"
    read -r reply
    case "${reply:-y}" in
      [Yy]*|"") ;;
      *) echo "kernel-setup: cancelled. Re-run with --vaults PATH to choose another directory." >&2; exit 1 ;;
    esac
  else
    die "no terminal to confirm on. Re-run with --yes (and --vaults PATH if $VAULTS is wrong)."
  fi
fi

# ------------------------------------------------------------------- writes
for d in \
  "$VAULTS/_meta/agentdb" "$VAULTS/_meta/research" "$VAULTS/_meta/plans" \
  "$VAULTS/_meta/handoffs" "$VAULTS/_meta/checkpoints" "$VAULTS/_meta/retrospectives" \
  "$VAULTS/_meta/agents" "$VAULTS/_meta/logs" "$VAULTS/.claude/kernel" "$VAULTS/.local/bin"
do
  mkdir -p "$d" || die "could not create $d"
done

kernel_update_current || die "could not select the runtime at $CACHE/current"

kernel_init_host_link "$VAULTS/.local/bin/agentdb" \
  "$CACHE/current/orchestration/agentdb/agentdb" "$CACHE" "orchestration/agentdb/agentdb" \
  || die "helper link blocked: $VAULTS/.local/bin/agentdb (inspect it, KERNEL will not overwrite it)"
kernel_init_host_link "$VAULTS/.claude/kernel/orchestration" \
  "$CACHE/current/orchestration" "$CACHE" "orchestration" \
  || die "helper link blocked: $VAULTS/.claude/kernel/orchestration"
kernel_init_host_link "$VAULTS/.claude/kernel/hooks" \
  "$CACHE/current/hooks" "$CACHE" "hooks" \
  || die "helper link blocked: $VAULTS/.claude/kernel/hooks"

kernel_init_agentdb "$VAULTS" "$CACHE" >/dev/null || die "could not initialize AgentDB in $VAULTS"

AGENTDB="$VAULTS/.local/bin/agentdb"
[ -x "$AGENTDB" ] || die "agentdb is not executable at $AGENTDB"

# ------------------------------------------------------ observable round trip
# Prove the install by writing a real learning and reading it back out.
export AGENTDB_ROOT="$VAULTS"
STAMP=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
"$AGENTDB" learn pattern \
  "KERNEL $VERSION installed on this machine" \
  "kernel-setup.sh completed at $STAMP; vaults $VAULTS" >/dev/null 2>&1 \
  || die "AgentDB accepted no writes. The database at $VAULTS/_meta/agentdb/agent.db is not usable."

PROOF=$("$AGENTDB" "$(printf 'recall')" "KERNEL installed machine" 2>&1)
case "$PROOF" in
  *"KERNEL $VERSION installed"*) ;;
  *) die "AgentDB wrote a learning but could not read it back. Output was: $PROOF" ;;
esac

say ""
say "$PROOF"
say ""
say "KERNEL is set up."
say "  memory:  $VAULTS/_meta/agentdb/agent.db"
say "  agentdb: $AGENTDB"
say ""
say "Optional, so you can type \`agentdb\` anywhere. Add to your shell config:"
say "  export PATH=\"$VAULTS/.local/bin:\$PATH\""
say ""
say "Next: run \`claude\` and type /kernel:help"
