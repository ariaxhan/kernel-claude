#!/bin/bash
# SessionEnd hook: Deregister agent, batch commit, push
# Portable version - configure PROJECT_ROOT for your project

PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
AGENTS_DIR="$PROJECT_ROOT/_meta/agents"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M")

# Agent name from env (set by SessionStart)
AGENT="${AGENT_NAME:-unknown-$$}"

# === STEP 1: DEREGISTER THIS AGENT ===
rm -f "$AGENTS_DIR/${AGENT}.json" "$AGENTS_DIR/${AGENT}-snapshot.md" 2>/dev/null

# Clean stale agents while we're at it
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
    exit 0  # Nothing to commit
fi

git add -A 2>/dev/null
git reset HEAD -- '*.zip' '*.tar.gz' '*.tar.bz2' '**/.DS_Store' 2>/dev/null

if git diff --cached --quiet 2>/dev/null; then
    exit 0  # Nothing staged
fi

FILES_CHANGED=$(git diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
git commit -m "chore(session-end): [$AGENT] ($FILES_CHANGED files) $TIMESTAMP" --no-verify 2>/dev/null
git push 2>/dev/null || true

exit 0
