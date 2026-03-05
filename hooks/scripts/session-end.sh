#!/bin/bash
# SessionEnd hook: Write AgentDB checkpoint, deregister agent, batch commit, push
# Multi-agent safe: only removes THIS agent's registration
# Events: SessionEnd (all matchers)

# Find project root dynamically
PROJECT_ROOT="${CLAUDE_PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(dirname "$(dirname "$(dirname "$0")")")}"
AGENTS_DIR="$PROJECT_ROOT/_meta/agents"
AGENTDB="${PLUGIN_ROOT}/orchestration/agentdb/agentdb"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M")

# Agent name from file (set by SessionStart)
AGENT_FILE="$AGENTS_DIR/.current"
if [ -f "$AGENT_FILE" ]; then
    AGENT=$(cat "$AGENT_FILE")
else
    AGENT="unknown-$$"
fi

# === STEP 0: WRITE AGENTDB CHECKPOINT ===
if [ -f "$PROJECT_ROOT/_meta/agentdb/agent.db" ]; then
    BRANCH=$(git branch --show-current 2>/dev/null || echo "none")
    FILES_CHANGED=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    "$AGENTDB" write-end "{\"agent\":\"$AGENT\",\"event\":\"session-end\",\"branch\":\"$BRANCH\",\"uncommitted_files\":$FILES_CHANGED}" 2>/dev/null || true
fi

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
git reset HEAD -- '*.zip' '*.tar.gz' '*.tar.bz2' '**/.DS_Store' 2>/dev/null

if git diff --cached --quiet 2>/dev/null; then
    exit 0
fi

FILES_CHANGED=$(git diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
REPO_NAME=$(basename "$PROJECT_ROOT")
git commit -m "chore(session-end): $REPO_NAME [$AGENT] ($FILES_CHANGED files) $TIMESTAMP" --no-verify 2>/dev/null
git push 2>/dev/null || true

exit 0
