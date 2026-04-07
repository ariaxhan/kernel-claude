#!/bin/bash
# KERNEL: UserPromptSubmit hook
# Fires on every user message. Two jobs:
# 1. Fallback session-start if SessionStart hook didn't fire (Claude Code bug)
# 2. Restore context after compaction
#
# Both are one-shot: marker/flag checked, action taken, marker/flag removed.
# Fast exit (~1ms) when neither condition applies.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Load shared functions
source "$SCRIPT_DIR/common.sh"
_kernel_hook_start

# Detect paths
VAULTS=$(detect_vaults)
AGENTDB=$(get_agentdb "$VAULTS")
PROJECT_ROOT=$(get_project_root)
AGENTS_DIR="$VAULTS/_meta/agents"

# === FALLBACK SESSION-START ===
# If SessionStart hook didn't fire, .current agent file won't exist.
# Run session-start as fallback on first user message.
if [ ! -f "$AGENTS_DIR/.current" ] 2>/dev/null; then
  # Session-start never ran — execute it now as fallback
  if [ -x "$SCRIPT_DIR/session-start.sh" ]; then
    bash "$SCRIPT_DIR/session-start.sh" < /dev/null 2>/dev/null
  fi
  _kernel_hook_end "post-compact-restore" 0
  exit 0
fi

# === COMPACTION RESTORE ===
MARKER="$PROJECT_ROOT/_meta/.compact-marker"

# Fast exit if no compaction happened
[ ! -f "$MARKER" ] && _kernel_hook_end "post-compact-restore" 0 && exit 0

# Restore context
echo "## Context Restored After Compaction"
echo ""
cat "$MARKER"
echo ""

# === RETENTION SCORING ===
# Compare key terms from pre-compact snapshot against restored content.
# Score: survived_terms / total_terms. Bash-native, no Python deps.
KEYTERMS_FILE="$PROJECT_ROOT/_meta/.compact-keyterms"
if [ -f "$KEYTERMS_FILE" ]; then
  RESTORED_CONTENT=$(cat "$MARKER")
  TOTAL_TERMS=$(wc -l < "$KEYTERMS_FILE" | tr -d ' ')
  SURVIVED=0

  if [ "$TOTAL_TERMS" -gt 0 ] 2>/dev/null; then
    while IFS= read -r term; do
      [ -z "$term" ] && continue
      if echo "$RESTORED_CONTENT" | grep -qF "$term" 2>/dev/null; then
        SURVIVED=$(( SURVIVED + 1 ))
      fi
    done < "$KEYTERMS_FILE"

    # Retention score: 0-100 integer (avoids bash float math)
    RETENTION_PCT=$(( SURVIVED * 100 / TOTAL_TERMS ))

    echo "**Retention:** ${SURVIVED}/${TOTAL_TERMS} key terms survived (${RETENTION_PCT}%)"
    echo ""

    # Estimate tokens in restored content (bytes/4, ±20%)
    RESTORED_BYTES=$(echo "$RESTORED_CONTENT" | wc -c | tr -d ' ')
    TOKENS_AFTER=$(( RESTORED_BYTES / 4 ))

    # Extract tokens_before from marker if present
    TOKENS_BEFORE=$(echo "$RESTORED_CONTENT" | grep -o 'Tokens before:.*~[0-9]*' | grep -o '[0-9]*$' || echo "0")
    [ -z "$TOKENS_BEFORE" ] && TOKENS_BEFORE=0

    # Compression ratio (integer percentage to avoid float)
    if [ "$TOKENS_BEFORE" -gt 0 ] 2>/dev/null; then
      COMPRESSION_PCT=$(( TOKENS_AFTER * 100 / TOKENS_BEFORE ))
    else
      COMPRESSION_PCT=0
    fi

    # Log to compaction_events table (fire-and-forget)
    AGENTDB_PATH="$VAULTS/_meta/agentdb/agent.db"
    if [ -f "$AGENTDB_PATH" ]; then
      AGENT_NAME="unknown"
      [ -f "$AGENTS_DIR/.current" ] && AGENT_NAME=$(cat "$AGENTS_DIR/.current" 2>/dev/null | tr -cd 'a-zA-Z0-9_-')
      # Use awk for float division (bash can't do floats)
      RETENTION_FLOAT=$(awk "BEGIN {printf \"%.2f\", $SURVIVED / $TOTAL_TERMS}" 2>/dev/null || echo "0.0")
      COMPRESSION_FLOAT=$(awk "BEGIN {printf \"%.2f\", $TOKENS_AFTER / ($TOKENS_BEFORE > 0 ? $TOKENS_BEFORE : 1)}" 2>/dev/null || echo "0.0")

      sqlite3 "$AGENTDB_PATH" <<SQL 2>/dev/null || true
INSERT INTO compaction_events (id, tokens_before, tokens_after, compression_ratio, retention_score, key_terms_total, key_terms_survived, trigger, agent)
VALUES (
  'CMP-$(date +%Y%m%d%H%M%S)-$$',
  ${TOKENS_BEFORE:-0},
  ${TOKENS_AFTER:-0},
  ${COMPRESSION_FLOAT},
  ${RETENTION_FLOAT},
  ${TOTAL_TERMS},
  ${SURVIVED},
  'auto',
  '${AGENT_NAME:-unknown}'
);
SQL
    fi
  fi

  # Clean up keyterms (one-shot)
  rm -f "$KEYTERMS_FILE"
fi

# Clean up marker (one-shot restoration)
rm -f "$MARKER"

_kernel_hook_end "post-compact-restore" 0
exit 0
