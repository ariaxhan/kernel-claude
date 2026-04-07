#!/bin/bash
set -eo pipefail
# PreCompact hook: Save agent context + commit before compaction

# Load shared functions
source "$(dirname "$0")/common.sh"
_kernel_hook_start

# Detect paths
VAULTS=$(detect_vaults)
AGENTDB=$(get_agentdb "$VAULTS")
PROJECT_ROOT=$(get_project_root)
AGENTS_DIR="$VAULTS/_meta/agents"
AGENTDB_PATH="$VAULTS/_meta/agentdb/agent.db"
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

# === STEP 1b: TOKEN ESTIMATION + KEY TERM EXTRACTION ===
# Token estimate: bytes / 4 (±20% for mixed code/prose). Documented margin.
SNAPSHOT_BYTES=$(wc -c < "$SNAPSHOT" 2>/dev/null | tr -d ' ')
TOKENS_BEFORE=$(( SNAPSHOT_BYTES / 4 ))

# Extract key terms for retention scoring after compaction.
# Terms: branch name, commit hashes, file paths from status, contract goal words.
KEYTERMS_FILE="$PROJECT_ROOT/_meta/.compact-keyterms"
{
  # Branch name
  cd "$PROJECT_ROOT" && git branch --show-current 2>/dev/null
  # Recent commit short hashes (unique identifiers)
  cd "$PROJECT_ROOT" && git log --format='%h' -5 2>/dev/null
  # Changed file paths (basenames for fuzzy matching)
  cd "$PROJECT_ROOT" && git status --short 2>/dev/null | awk '{print $NF}' | head -10
  # Active contract goal keywords (split on spaces, take significant words)
  if [ -n "${ACTIVE_GOAL:-}" ]; then
    echo "$ACTIVE_GOAL" | tr ' ,:;' '\n' | grep -E '^[a-zA-Z_-]{4,}' | head -10
  fi
} 2>/dev/null | sort -u | grep -v '^$' > "$KEYTERMS_FILE" 2>/dev/null || true

KEYTERMS_COUNT=$(wc -l < "$KEYTERMS_FILE" 2>/dev/null | tr -d ' ')

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
git reset HEAD -- '*.zip' '*.tar.gz' '*.tar.bz2' '**/.DS_Store' \
    '.env*' '*.pem' '*.key' '*.p12' 'credentials*' 'secrets*' '*.secret' \
    'node_modules/' 2>/dev/null

if git diff --cached --quiet 2>/dev/null; then
    exit 0
fi

FILES_CHANGED=$(git diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
REPO_NAME=$(basename "$PROJECT_ROOT")
# --no-verify: intentional. Avoids infinite hook loops during pre-compact cleanup.
git commit -m "chore(checkpoint): $REPO_NAME pre-compact [$AGENT] ($TRIGGER, $FILES_CHANGED files) $TIMESTAMP_SHORT" --no-verify 2>/dev/null
git push 2>/dev/null || true

# === STEP 4: AUTO-CHECKPOINT TO AGENTDB ===
# This replaces manual handoff - auto-save context before compaction
# AGENTDB already defined at top of script

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
    # Escape single quotes in all variables to prevent SQL injection
    # (ACTIVE_GOAL comes from a previous query and may contain quotes)
    _AGENT="${AGENT//\'/\'\'}"
    _TRIGGER="${TRIGGER//\'/\'\'}"
    _BRANCH="${BRANCH//\'/\'\'}"
    _ACTIVE_GOAL="${ACTIVE_GOAL//\'/\'\'}"
    _TIMESTAMP="${TIMESTAMP//\'/\'\'}"
    _RECENT_FILES="${RECENT_FILES//\'/\'\'}"

    sqlite3 "$AGENTDB_PATH" <<SQL 2>/dev/null || true
INSERT INTO context (id, type, content, agent) VALUES (
    'CMP-$(date +%Y%m%d%H%M%S)-$$',
    'checkpoint',
    json_object(
        'event', 'compaction',
        'agent', '$_AGENT',
        'trigger', '$_TRIGGER',
        'branch', '$_BRANCH',
        'goal', '$_ACTIVE_GOAL',
        'uncommitted_files', $UNCOMMITTED,
        'files_committed', ${FILES_CHANGED:-0},
        'tokens_before', ${TOKENS_BEFORE:-0},
        'key_terms', ${KEYTERMS_COUNT:-0},
        'timestamp', '$_TIMESTAMP'
    ),
    '$_AGENT'
);
SQL
fi

# === STEP 5: WRITE COMPACTION MARKER FOR CONTEXT RESTORATION ===
# post-compact-restore.sh (UserPromptSubmit) reads this on next user message
MARKER="$PROJECT_ROOT/_meta/.compact-marker"
BRANCH=$(cd "$PROJECT_ROOT" && git branch --show-current 2>/dev/null || echo "none")

{
  echo "**Branch:** $BRANCH"
  echo "**Compacted at:** $TIMESTAMP"
  echo "**Tokens before:** ~${TOKENS_BEFORE:-0} (±20%)"
  echo ""
  if [ -n "$ACTIVE_GOAL" ]; then
    echo "### Active Contract"
    echo '```'
    echo "$ACTIVE_GOAL"
    echo '```'
    echo ""
  fi
  RECENT_LEARNINGS=$("$AGENTDB" query "SELECT type || ': ' || insight FROM learnings ORDER BY ts DESC LIMIT 5" 2>/dev/null || echo "")
  if [ -n "$RECENT_LEARNINGS" ]; then
    echo "### Recent Learnings"
    echo "$RECENT_LEARNINGS"
    echo ""
  fi
  echo "**Resume from where you left off. Run \`agentdb read-start\` for full context.**"
} > "$MARKER" 2>/dev/null || true

# === STEP 6: OUTPUT CRITICAL CONTEXT (survives compaction) ===
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

_kernel_hook_end "pre-compact-commit" 0

exit 0
