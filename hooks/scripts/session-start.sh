#!/bin/bash
set -eo pipefail
# KERNEL: Session start hook

# Load shared functions
source "$(dirname "$0")/common.sh"
_kernel_hook_start

# Detect paths
VAULTS=$(detect_vaults)
AGENTDB=$(get_agentdb "$VAULTS")
PROJECT_ROOT=$(get_project_root)
VAULTS_CONTINUITY_ACTIVE=0
kernel_vaults_continuity_active "$VAULTS" "$PROJECT_ROOT" && VAULTS_CONTINUITY_ACTIVE=1

# Ensure auto-memory MEMORY.md exists (prevents first-session crash)
MEMORY_DIR="$HOME/.claude/projects/-$(echo "$PROJECT_ROOT" | tr '/' '-' | sed 's/^-//')/memory"
if [ ! -f "$MEMORY_DIR/MEMORY.md" ]; then
  mkdir -p "$MEMORY_DIR" 2>/dev/null || true
  [ ! -f "$MEMORY_DIR/MEMORY.md" ] && echo "# Memory Index" > "$MEMORY_DIR/MEMORY.md" 2>/dev/null || true
fi

# Generate session ID and persist for other hooks
KERNEL_SESSION_ID="sess-$(date +%Y%m%d%H%M%S)-$$"
echo "$KERNEL_SESSION_ID" > "$PROJECT_ROOT/_meta/.session_id" 2>/dev/null || true
export KERNEL_SESSION_ID

# Generate agent name and persist for other hooks.
# Keyed by Claude's session_id (hook stdin JSON): the shared .current file is a
# race under concurrent sessions, any parallel SessionStart overwrites it and any
# SessionEnd deletes it, which is how ~43% of commits ended up tagged "unknown-*".
AGENT_NAME="main-$$"
AGENTS_DIR="$VAULTS/_meta/agents"
mkdir -p "$AGENTS_DIR/by-session"
if [ ! -t 0 ]; then
    CLAUDE_SESSION_ID=$(cat 2>/dev/null | jq -r '.session_id // empty' 2>/dev/null || true)
fi
if [ -n "${CLAUDE_SESSION_ID:-}" ]; then
    echo "$AGENT_NAME" > "$AGENTS_DIR/by-session/$CLAUDE_SESSION_ID"
fi
echo "$AGENT_NAME" > "$AGENTS_DIR/.current"

cat > "$AGENTS_DIR/${AGENT_NAME}.json" << EOF
{
  "agent_name": "$AGENT_NAME",
  "started": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "started_epoch": $(date +%s),
  "branch": "$(git branch --show-current 2>/dev/null || echo "none")",
  "project": "$PROJECT_ROOT"
}
EOF

# Detect project profile (cached 1hr)
PROFILE=$(detect_profile "$PROJECT_ROOT")

echo "# KERNEL"
echo "**Profile:** $PROFILE"
echo ""

# === TEAMMATE SYNC: Pull latest from remotes ===
sync_repo() {
  local DIR="$1"
  local NAME="$2"
  cd "$DIR" 2>/dev/null || return
  if git rev-parse --git-dir >/dev/null 2>&1; then
    if git remote get-url origin >/dev/null 2>&1; then
      if git diff --quiet 2>/dev/null && git diff --cached --quiet 2>/dev/null; then
        PULL_OUTPUT=$(git pull --rebase 2>&1) || true
        if echo "$PULL_OUTPUT" | grep -q "Fast-forward\|rewinding\|Updating"; then
          echo "**Synced $NAME:** Pulled latest"
        fi
      fi
    fi
  fi
}

# Sync Vaults (shared configs) and current project
sync_repo "$VAULTS" "Vaults"
sync_repo "$PROJECT_ROOT" "Project"
cd "$PROJECT_ROOT" 2>/dev/null || true

# Git state
if git rev-parse --git-dir >/dev/null 2>&1; then
  BRANCH=$(git branch --show-current 2>/dev/null)
  echo "**Branch:** $BRANCH"
  CHANGES=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  if [ "$CHANGES" -gt 0 ]; then
    echo "**Uncommitted:** $CHANGES file(s) on branch $BRANCH"
  fi
  echo ""
  echo "**Recent commits:**"
  git log --oneline -5 2>/dev/null | sed 's/^/- /'
  echo ""
fi

# Test gate verdict, surface red FIRST so it's addressed before any new work.
if [ -f "$PROJECT_ROOT/_meta/.test-status" ]; then
  TS_STATUS=$(cut -d'|' -f1 "$PROJECT_ROOT/_meta/.test-status" 2>/dev/null)
  if [ "$TS_STATUS" = "FAIL" ]; then
    TS_SUMMARY=$(cut -d'|' -f4 "$PROJECT_ROOT/_meta/.test-status" 2>/dev/null)
    echo "## ⚠️ TESTS RED, auto-push is BLOCKED"
    echo "**${TS_SUMMARY:-test suite failing}**"
    echo "Pushes are withheld until the suite is green (details: _meta/plans/tests-red.md)."
    echo ""
  fi
fi

# === SYSTEM HEALTH ===
HEALTH_WARNINGS=""
# Check dependencies
command -v jq >/dev/null 2>&1 || HEALTH_WARNINGS="${HEALTH_WARNINGS}\n⚠ jq not installed, some hooks will not function"
command -v gh >/dev/null 2>&1 || HEALTH_WARNINGS="${HEALTH_WARNINGS}\n⚠ gh CLI not installed, GitHub features unavailable (install: https://cli.github.com)"
if command -v gh >/dev/null 2>&1 && ! gh auth status >/dev/null 2>&1; then
  HEALTH_WARNINGS="${HEALTH_WARNINGS}\n⚠ gh not authenticated, run: gh auth login"
fi

if [ -n "$HEALTH_WARNINGS" ]; then
  echo "## System Health"
  printf "%b\n" "$HEALTH_WARNINGS"
  echo ""
fi

# BEGIN GENERATED KERNEL AMBIENT
cat << 'KERNEL_CONTEXT'
## KERNEL quick reference

```
agentdb recall "<task keywords>" [--global]        # relevance lookup before acting
agentdb learn failure|pattern|gotcha "what" "why"  # capture as discovered
agentdb write-end '{"did":"X","learned":["Y"]}'    # at session end
agentdb wtf                                        # confused? full ref: agentdb guide
```

Optimize for the fastest correct, robust path. Tier by reversibility x blast radius, NOT file count. Gate hard only where an op is irreversible. T1 execute, T2 plan+verify, T3 confirm.
Default is inline. Spawn a subagent only to protect context, to buy real wall-clock on heavy file-disjoint work, when explicitly asked, or for independent verification, never for independence alone. When work is genuinely high-blast-radius or delegated, contract it, then verify with an adversary.
Claude invokes skills as /kernel:name; Codex invokes them as $kernel:name. Use the matching form; /kernel:help or $kernel:help lists them.
KERNEL_CONTEXT
# END GENERATED KERNEL AMBIENT

# =============================================================================
# AGENTDB CONTEXT (if initialized)
# =============================================================================
# Preflight: validate schema integrity, apply pending migrations, auto-repair drift
PREFLIGHT_OUTPUT=$("$AGENTDB" preflight 2>/dev/null || true)
if echo "$PREFLIGHT_OUTPUT" | grep -q "preflight:ok"; then
  : # all good, no output needed
elif [ -n "$PREFLIGHT_OUTPUT" ]; then
  # Filter to only warnings/repairs (skip the "ok" line)
  PREFLIGHT_ISSUES=$(echo "$PREFLIGHT_OUTPUT" | grep -v "preflight:ok" | grep -v "preflight:done")
  if [ -n "$PREFLIGHT_ISSUES" ]; then
    echo "## AgentDB Preflight"
    echo "$PREFLIGHT_ISSUES" | sed 's/^preflight:/- ⚠ /'
    echo ""
  fi
fi

if [ -f "$VAULTS/_meta/agentdb/agent.db" ]; then
  echo ""
  # Cap the always-loaded agentdb dump so the static rules always survive; only the
  # dynamic memory tail is truncated (uncapped dumps were the SessionStart truncation cause).
  # Cap to 50 printed lines WITHOUT closing the pipe early: awk reads all input and
  # only emits the first 50, so upstream `read-start` never gets SIGPIPE (which, under
  # `set -eo pipefail`, would abort the whole hook with exit 141). `head -n` closed the
  # pipe early and did exactly that on Codex boot.
  if [ "$VAULTS_CONTINUITY_ACTIVE" -eq 1 ]; then
    "$AGENTDB" read-start 2>/dev/null | awk '
      /^## Last Checkpoint/ { skip=1; next }
      skip && /^## / { skip=0 }
      !skip { if (n < 50) print; n++ }
    '
  else
    "$AGENTDB" read-start 2>/dev/null | awk 'NR<=50'
  fi
  echo ""

  # Prune stale learnings (0 hits, >30 days old)
  "$AGENTDB" query "DELETE FROM learnings WHERE hit_count = 0 AND ts < datetime('now', '-30 days');" 2>/dev/null || true

  # Surface high-hit learnings
  TOP_LEARNINGS=$("$AGENTDB" query "SELECT '- ' || insight FROM learnings WHERE hit_count >= 3 ORDER BY hit_count DESC LIMIT 3;" 2>/dev/null)
  if [ -n "$TOP_LEARNINGS" ]; then
    echo "## Top Learnings"
    echo "$TOP_LEARNINGS"
    echo ""
  fi

  # Check for recent compaction checkpoint (auto-handoff)
  LAST_CHECKPOINT=""
  if [ "$VAULTS_CONTINUITY_ACTIVE" -eq 0 ]; then
    LAST_CHECKPOINT=$("$AGENTDB" query "SELECT content FROM context WHERE type='checkpoint' ORDER BY ts DESC LIMIT 1" 2>/dev/null)
  fi
  if [ -n "$LAST_CHECKPOINT" ]; then
    # Check if it was a pre-compact checkpoint
    if echo "$LAST_CHECKPOINT" | grep -q "pre-compact\|compaction"; then
      echo "## Resume From Checkpoint"
      echo ""
      echo '```yaml'
      echo "$LAST_CHECKPOINT" | python3 -c "import sys,json; d=json.loads(sys.stdin.read()); print('\n'.join(f'{k}: {v}' for k,v in d.items()))" 2>/dev/null || echo "$LAST_CHECKPOINT"
      echo '```'
      echo ""
      echo "**Continue from where you left off. Goal and files above.**"
      echo ""
    fi
  fi

  ACTIVE_CONTRACT=$("$AGENTDB" query "SELECT id, content FROM context WHERE type='contract' ORDER BY ts DESC LIMIT 1" 2>/dev/null)
  if [ -n "$ACTIVE_CONTRACT" ]; then
    echo "## Active Contract"
    echo "$ACTIVE_CONTRACT"
    echo ""
    echo "Open contract found. Resume or close it before starting new work."
    echo ""
  fi

  # === BLOCKER SURFACING ===
  # State the facts; the model decides what to do with them.
  BLOCKERS=""

  # Check for stale contracts (>24h with no checkpoint)
  # `agentdb query` prints a formatted table (header + separator + value), so pull the
  # last numeric line and coerce to an int (+0) before any `-gt` comparison.
  STALE_COUNT=$("$AGENTDB" query "SELECT COUNT(*) FROM context WHERE type='contract' AND ts < datetime('now', '-1 day') AND contract_id NOT IN (SELECT COALESCE(contract_id, '') FROM context WHERE type='verdict');" 2>/dev/null | awk '/^[0-9]/{v=$1} END{print v+0}')
  STALE_COUNT=${STALE_COUNT:-0}
  if [ "$STALE_COUNT" -gt 0 ]; then
    BLOCKERS="${BLOCKERS}\n- $STALE_COUNT stale contract(s) >24h without verdict"
  fi

  # Check for recent errors (>3 in last hour)
  ERROR_COUNT=$("$AGENTDB" query "SELECT COUNT(*) FROM errors WHERE ts > datetime('now', '-1 hour');" 2>/dev/null | awk '/^[0-9]/{v=$1} END{print v+0}')
  ERROR_COUNT=${ERROR_COUNT:-0}
  if [ "$ERROR_COUNT" -gt 3 ]; then
    BLOCKERS="${BLOCKERS}\n- $ERROR_COUNT errors in last hour (possible loop)"
  fi

  if [ -n "$BLOCKERS" ]; then
    echo "## Blockers Detected"
    printf "%b\n" "$BLOCKERS"
    echo ""
  fi

  PENDING=$("$AGENTDB" query "SELECT agent, content FROM context WHERE type='checkpoint' AND ts > (SELECT COALESCE(MAX(ts), '1970-01-01') FROM context WHERE type='verdict') ORDER BY ts DESC LIMIT 1" 2>/dev/null)
  if [ -n "$PENDING" ] && ! echo "$PENDING" | grep -q "pre-compact"; then
    echo "## Pending Review"
    echo "$PENDING"
    echo ""
  fi
else
  echo ""
  echo "## ⚠️ KERNEL not initialized (no agent.db at $VAULTS/_meta/agentdb/)"
  echo "Repair: \`mkdir -p _meta/{agentdb,research,plans,handoffs,agents} && agentdb init\`"
  echo ""
fi

# Emit session start event
"$AGENTDB" emit session "session:start" "" "{\"branch\":\"$(git branch --show-current 2>/dev/null || echo none)\",\"profile\":\"$PROFILE\",\"project\":\"$PROJECT_ROOT\"}" "" "$KERNEL_SESSION_ID" 2>/dev/null &
_kernel_hook_end "session-start" 0
