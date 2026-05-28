#!/bin/bash
# AgentDB bootstrap - single command setup
# Usage: ./init.sh [project_path]

set -e

PROJECT="${1:-.}"
AGENTDB_DIR="$PROJECT/_meta/agentdb"
DB="$AGENTDB_DIR/agent.db"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$AGENTDB_DIR"

# Delegate to `agentdb init` so the base schema AND every migration are applied
# in order. Running schema.sql alone left bootstrapped DBs stuck at 001, missing
# migrations 002-current. AGENTDB_ROOT pins the location regardless of PWD.
if [ -x "$SCRIPT_DIR/agentdb" ]; then
    AGENTDB_ROOT="$PROJECT" "$SCRIPT_DIR/agentdb" init
else
    echo "Error: agentdb script not found at $SCRIPT_DIR/agentdb" >&2
    exit 1
fi

sqlite3 "$DB" "SELECT count(*) FROM learnings;" >/dev/null 2>&1 && \
    echo "Schema verified" || \
    echo "Schema verification failed"
