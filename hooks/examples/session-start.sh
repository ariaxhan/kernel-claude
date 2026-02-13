#!/bin/bash
# SessionStart hook - loads context, sets env vars, registers agent
# Portable version - configure PROJECT_ROOT and AGENTS_DIR for your project

PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
ACTIVE_MD="$PROJECT_ROOT/_meta/context/active.md"
AGENTS_DIR="$PROJECT_ROOT/_meta/agents"

# Read hook input from stdin
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
MODEL=$(echo "$INPUT" | jq -r '.model // "unknown"')
SOURCE=$(echo "$INPUT" | jq -r '.source // "startup"')

# Generate memorable agent name from session ID
ADJECTIVES=(swift bright calm dark keen sharp warm cool bold free wild deep fast glad pure soft true)
NOUNS=(aurora blaze cedar drift ember flame grove haze iris jade kite loom mesa nova opal pulse rune spark tide veil)

HASH=$(echo -n "$SESSION_ID" | md5 | head -c 8)
ADJ_IDX=$(( 16#${HASH:0:4} % ${#ADJECTIVES[@]} ))
NOUN_IDX=$(( 16#${HASH:4:4} % ${#NOUNS[@]} ))
AGENT_NAME="${ADJECTIVES[$ADJ_IDX]}-${NOUNS[$NOUN_IDX]}"

# === REGISTER THIS AGENT ===
mkdir -p "$AGENTS_DIR"

# Clean stale agents (PID no longer running)
for f in "$AGENTS_DIR"/*.json; do
    [ -f "$f" ] || continue
    OLD_PID=$(jq -r '.pid // 0' "$f" 2>/dev/null)
    if [ "$OLD_PID" -gt 0 ] 2>/dev/null && ! kill -0 "$OLD_PID" 2>/dev/null; then
        rm -f "$f" "${f%.json}-snapshot.md"
    fi
done

# Register this agent
cat > "$AGENTS_DIR/$AGENT_NAME.json" << EOF
{
  "session_id": "$SESSION_ID",
  "model": "$MODEL",
  "agent_name": "$AGENT_NAME",
  "pid": $PPID,
  "started": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "cwd": "$(pwd)",
  "branch": "$(git branch --show-current 2>/dev/null || echo 'unknown')",
  "source": "$SOURCE",
  "status": "active"
}
EOF

# === OUTPUT CONTEXT ===
if [ -f "$ACTIVE_MD" ]; then
    echo "## Session Context"
    echo ""
    cat "$ACTIVE_MD"
    echo ""
    echo "---"
fi

# Show git state
BRANCH=$(git branch --show-current 2>/dev/null)
STATUS=$(git status --short 2>/dev/null | head -10)
if [ -n "$BRANCH" ]; then
    echo ""
    echo "## Git State"
    echo "Branch: $BRANCH"
    if [ -n "$STATUS" ]; then
        echo "Changes:"
        echo "$STATUS"
    else
        echo "Working tree clean."
    fi
    echo "---"
fi

# Show other active agents
OTHER_AGENTS=$(ls "$AGENTS_DIR"/*.json 2>/dev/null | grep -v "$AGENT_NAME" | wc -l | tr -d ' ')
if [ "$OTHER_AGENTS" -gt 0 ]; then
    echo ""
    echo "## Active Agents ($OTHER_AGENTS others)"
    for f in "$AGENTS_DIR"/*.json; do
        [ -f "$f" ] || continue
        NAME=$(jq -r '.agent_name' "$f" 2>/dev/null)
        [ "$NAME" = "$AGENT_NAME" ] && continue
        ABRANCH=$(jq -r '.branch // "?"' "$f" 2>/dev/null)
        echo "- $NAME (branch: $ABRANCH)"
    done
    echo "---"
fi

# === SET ENVIRONMENT VARIABLES ===
if [ -n "$CLAUDE_ENV_FILE" ]; then
    echo "export AGENT_NAME=$AGENT_NAME" >> "$CLAUDE_ENV_FILE"
    echo "export PROJECT_ROOT=$PROJECT_ROOT" >> "$CLAUDE_ENV_FILE"
fi

exit 0
