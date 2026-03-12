#!/bin/bash
set -e  # Fail fast on errors
# PreCompact hook: Save agent context + commit before compaction
# Multi-agent safe: each agent writes its OWN snapshot, never overwrites active.md
# Events: PreCompact (all matchers: manual + auto)
#
# Key behaviors:
# 1. Commit any uncommitted work before compaction (preserve work)
# 2. Log compaction event to AgentDB (track patterns)
# 3. Save context snapshot for post-compaction restoration
# 4. Output critical context to conversation (survives compaction)

# Find project root dynamically
PROJECT_ROOT="${CLAUDE_PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
AGENTS_DIR="$PROJECT_ROOT/_meta/agents"
AGENTDB_PATH="$PROJECT_ROOT/_meta/agentdb/agent.db"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
TIMESTAMP_SHORT=$(date +"%Y-%m-%d %H:%M")

INPUT=$(cat)
TRIGGER=$(echo "$INPUT" | jq -r '.trigger // "auto"')
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')

# Agent name from file (set by SessionStart) or fallback
AGENT_FILE="$AGENTS_DIR/.current"
if [ -f "$AGENT_FILE" ]; then
    AGENT=$(cat "$AGENT_FILE")
else
    AGENT="unknown-$$"
fi

mkdir -p "$AGENTS_DIR"

# === STEP 1: SAVE THIS AGENT'S CONTEXT SNAPSHOT ===
SNAPSHOT="$AGENTS_DIR/${AGENT}-snapshot.md"

cat > "$SNAPSHOT" << SNAP
# Context Snapshot: $AGENT
**Saved**: $TIMESTAMP
**Trigger**: $TRIGGER compact
**Branch**: $(cd "$PROJECT_ROOT" && git branch --show-current 2>/dev/null)

## Recent Commits
$(cd "$PROJECT_ROOT" && git log --oneline -5 2>/dev/null)

## Uncommitted Changes
$(cd "$PROJECT_ROOT" && git status --short 2>/dev/null | head -15)

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
    # Update last_compact timestamp (atomic: write temp then move)
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
REPO_NAME=$(basename "$PROJECT_ROOT")
git commit -m "chore(checkpoint): $REPO_NAME pre-compact [$AGENT] ($TRIGGER, $FILES_CHANGED files) $TIMESTAMP_SHORT" --no-verify 2>/dev/null
git push 2>/dev/null || true

# === STEP 4: AUTO-CHECKPOINT TO AGENTDB ===
# This replaces manual handoff - auto-save context before compaction
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(dirname "$(dirname "$(dirname "$0")")")}"
AGENTDB="${PLUGIN_ROOT}/orchestration/agentdb/agentdb"

if [ -f "$AGENTDB_PATH" ]; then
    BRANCH=$(cd "$PROJECT_ROOT" && git branch --show-current 2>/dev/null || echo "unknown")
    UNCOMMITTED=$(cd "$PROJECT_ROOT" && git status --porcelain 2>/dev/null | wc -l | tr -d ' ')

    # Get active contract goal if exists
    ACTIVE_GOAL=$(sqlite3 "$AGENTDB_PATH" "SELECT json_extract(content, '$.goal') FROM context WHERE type='contract' ORDER BY ts DESC LIMIT 1;" 2>/dev/null || echo "")

    # Get recent files changed
    RECENT_FILES=$(cd "$PROJECT_ROOT" && git diff --name-only HEAD~3 2>/dev/null | head -10 | tr '\n' ',' | sed 's/,$//')

    # Write checkpoint (this is the auto-handoff)
    "$AGENTDB" write-end "{\"event\":\"pre-compact\",\"agent\":\"$AGENT\",\"trigger\":\"$TRIGGER\",\"branch\":\"$BRANCH\",\"goal\":\"$ACTIVE_GOAL\",\"uncommitted_files\":$UNCOMMITTED,\"files_committed\":${FILES_CHANGED:-0},\"recent_files\":\"$RECENT_FILES\"}" 2>/dev/null || true

    # Also record compaction pattern for analysis
    sqlite3 "$AGENTDB_PATH" <<SQL 2>/dev/null || true
INSERT INTO context (id, type, content, agent) VALUES (
    'CMP-$(date +%Y%m%d%H%M%S)-$$',
    'checkpoint',
    json_object(
        'event', 'compaction',
        'agent', '$AGENT',
        'trigger', '$TRIGGER',
        'branch', '$BRANCH',
        'goal', '$ACTIVE_GOAL',
        'uncommitted_files', $UNCOMMITTED,
        'files_committed', ${FILES_CHANGED:-0},
        'timestamp', '$TIMESTAMP'
    ),
    '$AGENT'
);
SQL
fi

# === STEP 5: OUTPUT CRITICAL CONTEXT (survives compaction) ===
# This YAML block survives compaction and provides immediate context
cat << YAML
---
## Auto-Checkpoint (Pre-Compaction)

\`\`\`yaml
saved:
  agent: $AGENT
  branch: $(cd "$PROJECT_ROOT" && git branch --show-current 2>/dev/null)
  time: $TIMESTAMP_SHORT
  trigger: $TRIGGER
  files_committed: ${FILES_CHANGED:-0}
  goal: "${ACTIVE_GOAL:-unknown}"

recent_commits:
$(cd "$PROJECT_ROOT" && git log --oneline -3 2>/dev/null | sed 's/^/  - /')

$(REMAINING=$(cd "$PROJECT_ROOT" && git status --porcelain 2>/dev/null | head -5); [ -n "$REMAINING" ] && echo "uncommitted:" && echo "$REMAINING" | sed 's/^/  - /')

restore: agentdb read-start
resume: /kernel:ingest (continue from checkpoint)
\`\`\`
---
YAML

exit 0
