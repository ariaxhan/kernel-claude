#!/usr/bin/env bash
# knowledge-graph driver (kernel plugin). Keeps a deterministic CODE-layer knowledge graph
# fresh so agents navigate by query instead of burning orientation tokens on file crawls.
#
# Modes:
#   install : stamp the graphify post-commit refresh into every repo in the current tree.
#             OPT-IN — does nothing unless KERNEL_GRAPH_ON=1 (mirrors autopush; a plugin that
#             silently stamps hooks into every user's repos is exactly the surprise we avoid).
#   refresh : build/refresh the graph for the current repo right now (code-only, free).
#
# Deterministic AST only — no LLM, no API key, no network, no cost. Degrades to a no-op if
# graphify is absent. KERNEL_GRAPH_OFF=1 hard-disables. Never clobbers a foreign post-commit.
set -u
[ "${KERNEL_GRAPH_OFF:-0}" = "1" ] && exit 0

MODE="${1:-refresh}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK_SRC="$SCRIPT_DIR/graphify-postcommit"
MARKER="kernel-knowledge-graph"

if [ "$MODE" = "refresh" ]; then
  command -v graphify >/dev/null 2>&1 || { echo "[knowledge-graph] graphify not installed (uv tool install graphifyy)"; exit 0; }
  root="$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")"
  graphify extract "$root" --code-only 2>&1 | grep -E "wrote|cached/unchanged" || true
  exit 0
fi

# install mode — opt-in only
[ "$MODE" = "install" ] || exit 0
[ "${KERNEL_GRAPH_ON:-0}" = "1" ] || exit 0
[ -f "$HOOK_SRC" ] || exit 0

start="${CLAUDE_PROJECT_DIR:-$PWD}"
root="$(git -C "$start" rev-parse --show-toplevel 2>/dev/null)" || exit 0
[ -n "$root" ] || exit 0
while :; do
  sp="$(git -C "$root" rev-parse --show-superproject-working-tree 2>/dev/null)"
  [ -n "$sp" ] || break
  root="$sp"
done

count=0
while IFS= read -r gitpath; do
  repo="$(dirname "$gitpath")"
  git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1 || continue
  gitdir="$(git -C "$repo" rev-parse --absolute-git-dir 2>/dev/null)" || continue
  mkdir -p "$gitdir/hooks" 2>/dev/null || continue
  hook="$gitdir/hooks/post-commit"
  # never clobber a FOREIGN post-commit (e.g. autopush) — only install where free or already ours
  if [ -f "$hook" ] && ! grep -q "$MARKER" "$hook" 2>/dev/null; then
    continue
  fi
  cp "$HOOK_SRC" "$hook" 2>/dev/null && chmod +x "$hook" 2>/dev/null && count=$((count+1))
done < <(find "$root" -maxdepth 5 -name .git -not -path '*/node_modules/*' -not -path '*/.git/*' 2>/dev/null)

echo "[knowledge-graph] code-graph post-commit installed in $count repo(s)"
exit 0
