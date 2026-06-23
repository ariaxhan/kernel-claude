#!/bin/bash
set -eo pipefail
# SessionEnd hook: Write AgentDB checkpoint, deregister agent, batch commit, push

# Load shared functions
source "$(dirname "$0")/common.sh"
source "$(dirname "$0")/github-integration.sh" 2>/dev/null || true
_kernel_hook_start

# Detect paths
VAULTS=$(detect_vaults)
AGENTDB=$(get_agentdb "$VAULTS")
PROJECT_ROOT=$(get_project_root)
AGENTS_DIR="$VAULTS/_meta/agents"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M")

# Agent name: prefer the session-keyed file (immune to concurrent-session races),
# fall back to the legacy shared .current, then unknown.
if [ ! -t 0 ]; then
    CLAUDE_SESSION_ID=$(cat 2>/dev/null | jq -r '.session_id // empty' 2>/dev/null || true)
fi
AGENT=""
if [ -n "${CLAUDE_SESSION_ID:-}" ] && [ -f "$AGENTS_DIR/by-session/$CLAUDE_SESSION_ID" ]; then
    AGENT=$(cat "$AGENTS_DIR/by-session/$CLAUDE_SESSION_ID")
elif [ -f "$AGENTS_DIR/.current" ]; then
    AGENT=$(cat "$AGENTS_DIR/.current")
fi
[ -n "$AGENT" ] || AGENT="unknown-$$"

# === STEP 0: WRITE AGENTDB CHECKPOINT ===
if [ -f "$VAULTS/_meta/agentdb/agent.db" ]; then
    BRANCH=$(git branch --show-current 2>/dev/null || echo "none")
    FILES_CHANGED=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    "$AGENTDB" write-end "{\"agent\":\"$AGENT\",\"event\":\"session-end\",\"branch\":\"$BRANCH\",\"uncommitted_files\":$FILES_CHANGED}" 2>/dev/null || true
fi

# Compute session duration from epoch stored at session start (no date parsing needed)
SESSION_DURATION_MS=""
AGENT_JSON="$AGENTS_DIR/${AGENT}.json"
if [ -f "$AGENT_JSON" ]; then
  START_EPOCH=$(jq -r '.started_epoch // empty' "$AGENT_JSON" 2>/dev/null)
  if [ -n "$START_EPOCH" ] && [ "$START_EPOCH" -gt 0 ] 2>/dev/null; then
    NOW_EPOCH=$(date +%s)
    SESSION_DURATION_MS=$(( (NOW_EPOCH - START_EPOCH) * 1000 ))
  fi
fi
"$AGENTDB" emit session "session:end" "${SESSION_DURATION_MS:-}" "{\"branch\":\"$BRANCH\",\"files_changed\":$FILES_CHANGED,\"agent\":\"$AGENT\",\"duration_s\":${SESSION_DURATION_MS:+$(( SESSION_DURATION_MS / 1000 ))}}" "" "" 2>/dev/null &

# === GITHUB LAYER: Post session summary for non-local profiles ===
if type _gh_available &>/dev/null && _gh_available; then
    DURATION_DISPLAY=""
    [ -n "$SESSION_DURATION_MS" ] && DURATION_DISPLAY=" ($(( SESSION_DURATION_MS / 1000 ))s)"
    _gh_post_session_summary "$AGENT" "$BRANCH" \
        "${FILES_CHANGED} files changed${DURATION_DISPLAY}" "" "" &
fi

_kernel_hook_end "session-end" 0

# === STEP 1: DEREGISTER THIS AGENT ===
rm -f "$AGENTS_DIR/${AGENT}.json" "$AGENTS_DIR/${AGENT}-snapshot.md" 2>/dev/null
if [ -n "${CLAUDE_SESSION_ID:-}" ]; then
    rm -f "$AGENTS_DIR/by-session/$CLAUDE_SESSION_ID" 2>/dev/null
else
    # Only the legacy path may remove the shared file (a session-keyed end must not
    # delete another live session's fallback).
    rm -f "$AGENTS_DIR/.current" 2>/dev/null
fi
# Prune orphaned session-key files (sessions that died without a SessionEnd)
find "$AGENTS_DIR/by-session" -type f -mtime +7 -delete 2>/dev/null || true

# Also clean any stale agents while we're at it
for f in "$AGENTS_DIR"/*.json; do
    [ -f "$f" ] || continue
    OLD_PID=$(jq -r '.pid // 0' "$f" 2>/dev/null)
    if [ "$OLD_PID" -gt 0 ] 2>/dev/null && ! kill -0 "$OLD_PID" 2>/dev/null; then
        NAME=$(jq -r '.agent_name // "unknown"' "$f" 2>/dev/null)
        rm -f "$f" "$AGENTS_DIR/${NAME}-snapshot.md"
    fi
done

# === STEP 2: (REMOVED) AUTO-COMMIT / AUTO-PUSH ===
# Auto-commit at session end was removed per user directive 2026-06-23.
# The hook no longer runs `git add -A` / `git commit` / `git push`. It still writes the
# AgentDB checkpoint and cleans up agent registration above — only the git mutation is gone.
# Committing and pushing is now an explicit, human-driven decision. Uncommitted work is left
# in place for the user to review and commit; nothing is staged or written to history here.

exit 0
