#!/usr/bin/env bash
# Auto-push driver (kernel plugin). Two modes:
#   install  — copy the post-commit auto-push hook into every repo in the current
#              project's tree (root superproject + all submodules on disk). Run by the
#              plugin SessionStart hook → every machine with the plugin gets per-commit
#              auto-push with ZERO manual setup, and new submodules are covered each session.
#   sweep    — fetch + push every repo in the tree that has unpushed commits. Run by the
#              plugin Stop hook → no session ever ends with work left solely local.
#
# Portable: discovers the tree by walking up to the OUTERMOST superproject from the
# current project (no hardcoded vault path). Safe: origin-only, skips detached/mid-rebase,
# non-fatal. Set AUTOPUSH_OFF=1 to disable. DRY_RUN=1 previews sweep.
set -u

MODE="${1:-sweep}"
[ "${AUTOPUSH_OFF:-0}" = "1" ] && exit 0

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK_SRC="$SCRIPT_DIR/autopush-postcommit"

start="${CLAUDE_PROJECT_DIR:-$PWD}"
root="$(git -C "$start" rev-parse --show-toplevel 2>/dev/null)" || exit 0
[ -n "$root" ] || exit 0
# Climb to the outermost superproject so we cover the whole vault from anywhere inside it.
while :; do
  sp="$(git -C "$root" rev-parse --show-superproject-working-tree 2>/dev/null)"
  [ -n "$sp" ] || break
  root="$sp"
done

count=0
while IFS= read -r gitpath; do
  repo="$(dirname "$gitpath")"
  git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1 || continue

  if [ "$MODE" = "install" ]; then
    gitdir="$(git -C "$repo" rev-parse --absolute-git-dir 2>/dev/null)" || continue
    mkdir -p "$gitdir/hooks" 2>/dev/null || continue
    if [ -f "$HOOK_SRC" ] && cp "$HOOK_SRC" "$gitdir/hooks/post-commit" 2>/dev/null; then
      chmod +x "$gitdir/hooks/post-commit" 2>/dev/null; count=$((count+1))
    fi
  else
    # sweep
    local_gd="$(git -C "$repo" rev-parse --git-dir 2>/dev/null)" || continue
    case "$local_gd" in /*) : ;; *) local_gd="$repo/$local_gd" ;; esac
    skip=0; for m in rebase-merge rebase-apply MERGE_HEAD CHERRY_PICK_HEAD BISECT_LOG; do
      [ -e "$local_gd/$m" ] && skip=1; done; [ "$skip" = 1 ] && continue
    br="$(git -C "$repo" symbolic-ref --short HEAD 2>/dev/null)" || continue
    [ -n "$br" ] || continue
    # Hard gate (I0.15: hooks, not honor-system). If the test gate recorded a red verdict
    # for this repo, refuse to push it — red must never reach the remote. Clears itself when
    # the suite goes green (test-gate rewrites .test-status to PASS).
    if [ -f "$repo/_meta/.test-status" ]; then
      ts_status="$(cut -d'|' -f1 "$repo/_meta/.test-status" 2>/dev/null)"
      if [ "$ts_status" = "FAIL" ]; then
        name="${repo#"$root"/}"; [ "$name" = "$repo" ] && name="(root)"
        echo "[autopush-sweep] $name: ⚠️ tests RED → push BLOCKED (fix suite; see _meta/plans/tests-red.md)" >&2
        continue
      fi
    fi
    git -C "$repo" remote get-url origin >/dev/null 2>&1 || continue
    git -C "$repo" fetch origin "$br" --quiet 2>/dev/null || true
    ahead="$(git -C "$repo" rev-list --count "origin/$br..HEAD" 2>/dev/null || echo 0)"
    [ "${ahead:-0}" -gt 0 ] || continue
    name="${repo#"$root"/}"; [ "$name" = "$repo" ] && name="(root)"
    if [ "${DRY_RUN:-0}" = "1" ]; then echo "[autopush-sweep] WOULD push $name: $ahead on $br"; continue; fi
    echo "[autopush-sweep] $name: $ahead unpushed on $br → pushing…"
    git -C "$repo" push origin "$br" 2>&1 | sed 's/^/  /' || echo "  ✗ failed"
    count=$((count+1))
  fi
done < <(find "$root" -maxdepth 5 -name .git -not -path '*/node_modules/*' -not -path '*/.git/*' 2>/dev/null)

[ "$MODE" = "install" ] && echo "[autopush] post-commit installed in $count repo(s)"
exit 0
