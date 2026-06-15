#!/bin/bash
set -eo pipefail
# SessionEnd hook: Write AgentDB checkpoint, deregister agent, batch commit, push

# Load shared functions
source "$(dirname "$0")/common.sh"
source "$(dirname "$0")/github-integration.sh" 2>/dev/null || true
_kernel_hook_start

# Detect paths
VAULTS=$(detect_vaults)
AGENTDB=$(get_agentdb "$VAULTS")
PROJECT_ROOT=$(get_project_root)
AGENTS_DIR="$VAULTS/_meta/agents"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M")

# Agent name: prefer the session-keyed file (immune to concurrent-session races),
# fall back to the legacy shared .current, then unknown.
if [ ! -t 0 ]; then
    CLAUDE_SESSION_ID=$(cat 2>/dev/null | jq -r '.session_id // empty' 2>/dev/null || true)
fi
AGENT=""
if [ -n "${CLAUDE_SESSION_ID:-}" ] && [ -f "$AGENTS_DIR/by-session/$CLAUDE_SESSION_ID" ]; then
    AGENT=$(cat "$AGENTS_DIR/by-session/$CLAUDE_SESSION_ID")
elif [ -f "$AGENTS_DIR/.current" ]; then
    AGENT=$(cat "$AGENTS_DIR/.current")
fi
[ -n "$AGENT" ] || AGENT="unknown-$$"

# === STEP 0: WRITE AGENTDB CHECKPOINT ===
if [ -f "$VAULTS/_meta/agentdb/agent.db" ]; then
    BRANCH=$(git branch --show-current 2>/dev/null || echo "none")
    FILES_CHANGED=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    "$AGENTDB" write-end "{\"agent\":\"$AGENT\",\"event\":\"session-end\",\"branch\":\"$BRANCH\",\"uncommitted_files\":$FILES_CHANGED}" 2>/dev/null || true
fi

# Compute session duration from epoch stored at session start (no date parsing needed)
SESSION_DURATION_MS=""
AGENT_JSON="$AGENTS_DIR/${AGENT}.json"
if [ -f "$AGENT_JSON" ]; then
  START_EPOCH=$(jq -r '.started_epoch // empty' "$AGENT_JSON" 2>/dev/null)
  if [ -n "$START_EPOCH" ] && [ "$START_EPOCH" -gt 0 ] 2>/dev/null; then
    NOW_EPOCH=$(date +%s)
    SESSION_DURATION_MS=$(( (NOW_EPOCH - START_EPOCH) * 1000 ))
  fi
fi
"$AGENTDB" emit session "session:end" "${SESSION_DURATION_MS:-}" "{\"branch\":\"$BRANCH\",\"files_changed\":$FILES_CHANGED,\"agent\":\"$AGENT\",\"duration_s\":${SESSION_DURATION_MS:+$(( SESSION_DURATION_MS / 1000 ))}}" "" "" 2>/dev/null &

# === GITHUB LAYER: Post session summary for non-local profiles ===
if type _gh_available &>/dev/null && _gh_available; then
    DURATION_DISPLAY=""
    [ -n "$SESSION_DURATION_MS" ] && DURATION_DISPLAY=" ($(( SESSION_DURATION_MS / 1000 ))s)"
    _gh_post_session_summary "$AGENT" "$BRANCH" \
        "${FILES_CHANGED} files changed${DURATION_DISPLAY}" "" "" &
fi

_kernel_hook_end "session-end" 0

# === STEP 1: DEREGISTER THIS AGENT ===
rm -f "$AGENTS_DIR/${AGENT}.json" "$AGENTS_DIR/${AGENT}-snapshot.md" 2>/dev/null
if [ -n "${CLAUDE_SESSION_ID:-}" ]; then
    rm -f "$AGENTS_DIR/by-session/$CLAUDE_SESSION_ID" 2>/dev/null
else
    # Only the legacy path may remove the shared file (a session-keyed end must not
    # delete another live session's fallback).
    rm -f "$AGENTS_DIR/.current" 2>/dev/null
fi
# Prune orphaned session-key files (sessions that died without a SessionEnd)
find "$AGENTS_DIR/by-session" -type f -mtime +7 -delete 2>/dev/null || true

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
git reset HEAD -- '*.zip' '*.tar.gz' '*.tar.bz2' '**/.DS_Store' \
    '.env*' '*.pem' '*.key' '*.p12' 'credentials*' 'secrets*' '*.secret' \
    'node_modules/' 2>/dev/null

if git diff --cached --quiet 2>/dev/null; then
    exit 0
fi

FILES_CHANGED=$(git diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
REPO_NAME=$(basename "$PROJECT_ROOT")

# === TEST GATE ===
# --no-verify (below) skips the pre-commit verify chain — a documented carve-out to avoid an
# infinite hook loop. That carve-out historically let a RED suite ride onto main via these
# auto-commits. Close the hole: run the suite out-of-band here. Only when real files changed
# (skip pure log/agentdb churn so doc-free sessions don't pay 30s). On red we still commit
# (never lose work) but tag the message + leave a breadcrumb; the .test-status file then
# blocks autopush so red never reaches the remote.
TEST_TAG=""
CODE_CHANGED=$(git diff --cached --name-only 2>/dev/null \
    | grep -vE '^_meta/(logs/|agentdb/|\.)' | head -1)
if [ -n "$CODE_CHANGED" ] && [ -f "$(dirname "$0")/test-gate.sh" ]; then
    if ! bash "$(dirname "$0")/test-gate.sh" "$PROJECT_ROOT" >/dev/null 2>&1; then
        TEST_TAG=" [TESTS RED]"
        _ts_summary=$(cut -d'|' -f4 "$PROJECT_ROOT/_meta/.test-status" 2>/dev/null)
        mkdir -p "$PROJECT_ROOT/_meta/plans" 2>/dev/null
        {
            echo "# ⚠️ Tests are RED — fix before shipping"
            echo ""
            echo "Detected at session-end $TIMESTAMP by the kernel test gate."
            echo "Auto-commit was made locally but **autopush is blocked** until green."
            echo ""
            echo "**Failure:** ${_ts_summary:-see test output}"
            echo ""
            echo "Run the suite, drive it to zero, then commit the fix (autopush unblocks automatically)."
        } > "$PROJECT_ROOT/_meta/plans/tests-red.md" 2>/dev/null
        echo "session-end: ⚠️ TESTS RED — committing locally but NOT pushing. See _meta/plans/tests-red.md" >&2
    else
        # Green (or no suite): clear any stale breadcrumb.
        rm -f "$PROJECT_ROOT/_meta/plans/tests-red.md" 2>/dev/null
    fi
fi

# --no-verify: intentional carve-out documented in CLAUDE.md <git><hook_carve_outs>.
# This hook fires inside SessionEnd; leaving verify enabled creates an infinite hook chain.
# Carve-out is limited to this script + pre-compact-commit.sh. Do NOT reuse elsewhere.
git commit -m "chore(session-end): $REPO_NAME [$AGENT] ($FILES_CHANGED files) $TIMESTAMP$TEST_TAG" --no-verify 2>/dev/null
# Do not auto-push main/master (I0.8: push to main needs explicit say-so).
# Feature branches push freely; main commits stay local until the user pushes.
# Red suite → never push (autopush.sh also enforces this independently via .test-status).
_se_branch=$(git branch --show-current 2>/dev/null || echo "")
if [ -n "$TEST_TAG" ]; then
    echo "session-end: red suite — push withheld until tests are green." >&2
elif [ "$_se_branch" = "main" ] || [ "$_se_branch" = "master" ]; then
    echo "session-end: committed locally on $_se_branch; not auto-pushing (I0.8 — push to main needs explicit say-so)." >&2
elif ! git push 2>/dev/null; then
    echo "WARNING: git push failed. Changes committed locally but not pushed." >&2
    echo "Run 'git push' manually or check for rebase conflicts." >&2
fi

exit 0
