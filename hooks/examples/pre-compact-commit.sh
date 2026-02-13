#!/bin/bash
# PreCompact hook: Save agent context + commit before compaction
# Portable version - configure PROJECT_ROOT for your project

PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
AGENTS_DIR="$PROJECT_ROOT/_meta/agents"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
TIMESTAMP_SHORT=$(date +"%Y-%m-%d %H:%M")

INPUT=$(cat)
TRIGGER=$(echo "$INPUT" | jq -r '.trigger // "auto"')

# Agent name from env (set by SessionStart) or fallback
AGENT="${AGENT_NAME:-unknown-$$}"

mkdir -p "$AGENTS_DIR"

# === STEP 1: SAVE THIS AGENT'S CONTEXT SNAPSHOT ===
SNAPSHOT="$AGENTS_DIR/${AGENT}-snapshot.md"

cat > "$SNAPSHOT" << SNAP
# Context Snapshot: $AGENT
**Saved**: $TIMESTAMP
**Trigger**: $TRIGGER compact
**Branch**: $(git branch --show-current 2>/dev/null || echo 'unknown')

## Recent Commits
$(git log --oneline -5 2>/dev/null || echo 'No commits')

## Uncommitted Changes
$(git status --short 2>/dev/null | head -15 || echo 'None')

## Other Active Agents
$(ls "$AGENTS_DIR"/*.json 2>/dev/null | while read f; do
    NAME=$(jq -r '.agent_name' "$f" 2>/dev/null)
    BRANCH=$(jq -r '.branch // "?"' "$f" 2>/dev/null)
    STARTED=$(jq -r '.started // "?"' "$f" 2>/dev/null)
    echo "- $NAME (branch: $BRANCH, since: $STARTED)"
done)
SNAP

# === STEP 2: UPDATE AGENT REGISTRY STATUS ===
REG_FILE="$AGENTS_DIR/${AGENT}.json"
if [ -f "$REG_FILE" ]; then
    TMP=$(mktemp)
    jq --arg ts "$TIMESTAMP" --arg trigger "$TRIGGER" \
        '. + {last_compact: $ts, last_compact_trigger: $trigger}' \
        "$REG_FILE" > "$TMP" 2>/dev/null && mv "$TMP" "$REG_FILE"
fi

# === STEP 3: COMMIT CHECKPOINT ===
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
git commit -m "chore(checkpoint): pre-compact [$AGENT] ($TRIGGER, $FILES_CHANGED files) $TIMESTAMP_SHORT" --no-verify 2>/dev/null
git push 2>/dev/null || true

exit 0
