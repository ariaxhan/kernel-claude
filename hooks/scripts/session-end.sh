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

# Agent name from file (set by SessionStart)
AGENT_FILE="$AGENTS_DIR/.current"
if [ -f "$AGENT_FILE" ]; then
    AGENT=$(cat "$AGENT_FILE")
else
    AGENT="unknown-$$"
fi

# === STEP 0: WRITE AGENTDB CHECKPOINT ===
if [ -f "$VAULTS/_meta/agentdb/agent.db" ]; then
    BRANCH=$(git branch --show-current 2>/dev/null || echo "none")
    FILES_CHANGED=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    "$AGENTDB" write-end "{\"agent\":\"$AGENT\",\"event\":\"session-end\",\"branch\":\"$BRANCH\",\"uncommitted_files\":$FILES_CHANGED}" 2>/dev/null || true
fi

# Emit session end event with duration
SESSION_DURATION_S=""
AGENT_JSON="$AGENTS_DIR/${AGENT}.json"
if [ -f "$AGENT_JSON" ]; then
  STARTED=$(jq -r '.started // empty' "$AGENT_JSON" 2>/dev/null)
  if [ -n "$STARTED" ]; then
    START_EPOCH=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$STARTED" +%s 2>/dev/null || python3 -c "from datetime import datetime; print(int(datetime.fromisoformat('$STARTED'.replace('Z','+00:00')).timestamp()))" 2>/dev/null || echo "")
    if [ -n "$START_EPOCH" ]; then
      NOW_EPOCH=$(date +%s)
      SESSION_DURATION_S=$(( NOW_EPOCH - START_EPOCH ))
    fi
  fi
fi
"$AGENTDB" emit session "session:end" "${SESSION_DURATION_S:+$(( SESSION_DURATION_S * 1000 ))}" "{\"branch\":\"$BRANCH\",\"files_changed\":$FILES_CHANGED,\"agent\":\"$AGENT\"}" "" "" 2>/dev/null &

# === GITHUB LAYER: Post session summary for non-local profiles ===
if type _gh_available &>/dev/null && _gh_available; then
    DURATION_DISPLAY=""
    [ -n "$SESSION_DURATION_S" ] && DURATION_DISPLAY=" (${SESSION_DURATION_S}s)"
    _gh_post_session_summary "$AGENT" "$BRANCH" \
        "${FILES_CHANGED} files changed${DURATION_DISPLAY}" "" "" &
fi

_kernel_hook_end "session-end" 0

# === STEP 1: DEREGISTER THIS AGENT ===
rm -f "$AGENTS_DIR/${AGENT}.json" "$AGENTS_DIR/${AGENT}-snapshot.md" "$AGENTS_DIR/.current" 2>/dev/null

# Also clean any stale agents while we're at it
for f in "$AGENTS_DIR"/*.json; do
    [ -f "$f" ] || continue
    OLD_PID=$(jq -r '.pid // 0' "$f" 2>/dev/null)
    if [ "$OLD_PID" -gt 0 ] 2>/dev/null && ! kill -0 "$OLD_PID" 2>/dev/null; then
        NAME=$(jq -r '.agent_name // "unknown"' "$f" 2>/dev/null)
        rm -f "$f" "$AGENTS_DIR/${NAME}-snapshot.md"
    fi
done

# === STEP 2: BATCH COMMIT AND PUSH ===
cd "$PROJECT_ROOT" 2>/dev/null || exit 0

if ! git status --porcelain 2>/dev/null | grep -q .; then
    exit 0
fi

git add -A 2>/dev/null
git reset HEAD -- '*.zip' '*.tar.gz' '*.tar.bz2' '**/.DS_Store' \
    '.env*' '*.pem' '*.key' '*.p12' 'credentials*' 'secrets*' '*.secret' \
    'node_modules/' 2>/dev/null

if git diff --cached --quiet 2>/dev/null; then
    exit 0
fi

FILES_CHANGED=$(git diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
REPO_NAME=$(basename "$PROJECT_ROOT")
# --no-verify: intentional. Avoids infinite hook loops during session-end cleanup.
git commit -m "chore(session-end): $REPO_NAME [$AGENT] ($FILES_CHANGED files) $TIMESTAMP" --no-verify 2>/dev/null
if ! git push 2>/dev/null; then
    echo "WARNING: git push failed. Changes committed locally but not pushed." >&2
    echo "Run 'git push' manually or check for rebase conflicts." >&2
fi

exit 0
