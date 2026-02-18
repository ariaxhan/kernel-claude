#!/usr/bin/env bash
# session-summary.sh — end-of-session summary to stdout (markdown)
# Usage: ./orchestration/session-summary.sh [since-ref]
# since-ref defaults to HEAD~10 or session start commit if provided

set -euo pipefail

SINCE="${1:-HEAD~10}"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

echo "# Session Summary"
echo ""
echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# Commits made
COMMIT_COUNT="$(git log "${SINCE}..HEAD" --oneline 2>/dev/null | wc -l | tr -d ' ')"
echo "## Commits"
echo ""
echo "Total: ${COMMIT_COUNT}"
echo ""
git log "${SINCE}..HEAD" --oneline 2>/dev/null | sed 's/^/- /' || true
echo ""

# Files changed
echo "## Files Changed"
echo ""
git diff "${SINCE}" HEAD --name-only 2>/dev/null | sort -u | sed 's/^/- /' || true
echo ""

# Last 3 learnings from agentdb
echo "## Recent Learnings"
echo ""
DB_PATH="${REPO_ROOT}/_meta/agentdb/agent.db"
if command -v agentdb &>/dev/null; then
  agentdb learnings 3 2>/dev/null | sed 's/^/- /' || echo "- No learnings recorded"
elif [ -f "$DB_PATH" ] && command -v sqlite3 &>/dev/null; then
  sqlite3 "$DB_PATH" \
    "SELECT '**' || type || ':** ' || insight FROM learnings ORDER BY ts DESC LIMIT 3;" \
    2>/dev/null | sed 's/^/- /' || echo "- No learnings recorded"
else
  echo "- agentdb not available"
fi
echo ""
