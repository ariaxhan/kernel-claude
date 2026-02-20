#!/bin/bash
# AgentDB bootstrap - single command setup
# Usage: ./init.sh [project_path]

set -e

PROJECT="${1:-.}"
AGENTDB_DIR="$PROJECT/_meta/agentdb"
DB="$AGENTDB_DIR/agent.db"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$AGENTDB_DIR"

if [ ! -f "$DB" ]; then
    sqlite3 "$DB" < "$SCRIPT_DIR/schema.sql"
    echo "AgentDB initialized at $DB"
else
    echo "AgentDB already exists at $DB"
fi

sqlite3 "$DB" "SELECT count(*) FROM learnings;" >/dev/null 2>&1 && \
    echo "Schema verified" || \
    echo "Schema verification failed"
