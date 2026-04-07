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

# Ensure auto-memory MEMORY.md exists (prevents first-session crash)
MEMORY_DIR="$HOME/.claude/projects/-$(echo "$PROJECT_ROOT" | tr '/' '-' | sed 's/^-//')/memory"
if [ ! -f "$MEMORY_DIR/MEMORY.md" ]; then
  mkdir -p "$MEMORY_DIR" 2>/dev/null || true
  [ ! -f "$MEMORY_DIR/MEMORY.md" ] && echo "# Memory Index" > "$MEMORY_DIR/MEMORY.md" 2>/dev/null || true
fi

# Generate agent name and persist for other hooks
AGENT_NAME="main-$$"
AGENTS_DIR="$VAULTS/_meta/agents"
mkdir -p "$AGENTS_DIR"
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
    echo "**Uncommitted:** $CHANGES file(s)"
    echo "**ASK USER:** $CHANGES uncommitted file(s). Stash, commit, or continue?"
  fi
  echo ""
  echo "**Recent commits:**"
  git log --oneline -5 2>/dev/null | sed 's/^/- /'
  echo ""
fi

# === SYSTEM HEALTH ===
HEALTH_WARNINGS=""
# Check dependencies
command -v jq >/dev/null 2>&1 || HEALTH_WARNINGS="${HEALTH_WARNINGS}\n⚠ jq not installed — some hooks will not function"
command -v gh >/dev/null 2>&1 || HEALTH_WARNINGS="${HEALTH_WARNINGS}\n⚠ gh CLI not installed — GitHub features unavailable (install: https://cli.github.com)"
if command -v gh >/dev/null 2>&1 && ! gh auth status >/dev/null 2>&1; then
  HEALTH_WARNINGS="${HEALTH_WARNINGS}\n⚠ gh not authenticated — run: gh auth login"
fi

if [ -n "$HEALTH_WARNINGS" ]; then
  echo "## System Health"
  printf "%b\n" "$HEALTH_WARNINGS"
  echo ""
fi

cat << 'KERNEL_CONTEXT'
<protocol>
  <agentdb>
    on_start: agentdb read-start
    on_end:   agentdb write-end '{"did":"X","learned":["Y"]}'
    on_learn: agentdb learn failure|pattern|gotcha "what" "evidence"
    confused: agentdb wtf
    history:  agentdb timeline 10
    cleanup:  agentdb prune all | agentdb contract close --stale
    reference: agentdb guide
  </agentdb>

  <decision_tree>
    1. READ context
       → agentdb read-start
       → ls _meta/research/ (check prior work)

    2. CLASSIFY request
       → bug?      load: /kernel:debug → /kernel:diagnose
       → feature?  load: /kernel:build
       → refactor? load: /kernel:refactor
       → review?   load: /kernel:review
       → unsure?   load: /kernel:build (default)

    3. RESEARCH (before coding)
       → check _meta/research/ for cached results
       → anti-patterns FIRST: "{tech} gotchas", "{tech} not working"
       → then solutions: official docs → github issues
       → load: /kernel:security if auth/validation/secrets involved

    4. SCOPE
       → count files that change
       → tier 1 (1-2 files): execute directly
       → tier 2 (3-5 files): contract + surgeon agent
       → tier 3 (6+ files):  contract + surgeon + adversary

    5. DEFINE SUCCESS (before coding)
       → load: /kernel:testing — tests BEFORE code
       → load: /kernel:tdd if red-green-refactor appropriate
       → edge cases first: null, empty, boundary, concurrent, timeout

    6. EXECUTE
       → load: /kernel:quality — Big 5 checks on all code
       → tier 1: implement directly
       → tier 2+: spawn surgeon, orchestrate via /kernel:orchestration

    7. SHIP
       → load: /kernel:git — atomic commits, profile-gated workflow
       → local: commit to main
       → github-oss/production: feature branch → PR → review

    8. LEARN
       → agentdb learn pattern|failure "what" "evidence"
       → agentdb write-end
       → update _meta/research/ if new findings
  </decision_tree>

  <skills index="true">
    always: /kernel:quality, /kernel:testing, /kernel:git
    by_task: /kernel:build, /kernel:debug, /kernel:refactor, /kernel:security
    by_domain: /kernel:api, /kernel:backend, /kernel:e2e, /kernel:tdd
    commands: /kernel:dream, /kernel:diagnose, /kernel:tearitapart, /kernel:review
    advanced: /kernel:orchestration, /kernel:architecture, /kernel:performance
  </skills>

  <rule>Load the relevant skill BEFORE acting. Skills ARE the methodology.</rule>
  <rule>Research anti-patterns BEFORE solutions. Tests BEFORE code.</rule>
  <rule>Built-in beats library. Library beats custom. Prove you need complexity.</rule>
</protocol>
KERNEL_CONTEXT

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
  "$AGENTDB" read-start 2>/dev/null
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
  LAST_CHECKPOINT=$("$AGENTDB" query "SELECT content FROM context WHERE type='checkpoint' ORDER BY ts DESC LIMIT 1" 2>/dev/null)
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
    echo "**Resume or close before starting new work.**"
    echo ""
    echo "**ASK USER:** Stale contract detected. Resume, close, or start fresh?"
    echo ""
  fi

  # === BLOCKER SURFACING ===
  # Tell Claude to ask about blockers instead of assuming
  BLOCKERS=""

  # Check for stale contracts (>24h with no checkpoint)
  STALE_COUNT=$("$AGENTDB" query "SELECT COUNT(*) FROM context WHERE type='contract' AND ts < datetime('now', '-1 day') AND contract_id NOT IN (SELECT COALESCE(contract_id, '') FROM context WHERE type='verdict');" 2>/dev/null || echo "0")
  if [ "$STALE_COUNT" -gt 0 ]; then
    BLOCKERS="${BLOCKERS}\n- $STALE_COUNT stale contract(s) >24h without verdict"
  fi

  # Check for recent errors (>3 in last hour)
  ERROR_COUNT=$("$AGENTDB" query "SELECT COUNT(*) FROM errors WHERE ts > datetime('now', '-1 hour');" 2>/dev/null || echo "0")
  if [ "$ERROR_COUNT" -gt 3 ]; then
    BLOCKERS="${BLOCKERS}\n- $ERROR_COUNT errors in last hour (possible loop)"
  fi

  if [ -n "$BLOCKERS" ]; then
    echo "## Blockers Detected"
    printf "%b\n" "$BLOCKERS"
    echo ""
    echo "**ASK USER:** Use AskUserQuestion to confirm: address blockers first, or proceed with new work?"
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
  echo "## ⚠️ KERNEL NOT INITIALIZED"
  echo ""
  echo "**STOP. Run:** \`mkdir -p _meta/{agentdb,research,plans,handoffs,agents} && agentdb init\`"
  echo ""
fi

# === PROFILE-GATED REFERENCE ===
# local: compact reference. github+: full reference with GitHub features.

cat << 'REFERENCE'
---

## Commands

```yaml
commands:
  /kernel:ingest: guided flow, human confirms each phase
  /kernel:forge: autonomous engine — heat/hammer/quench/anneal until antifragile
  /kernel:dream: creative exploration — 3 perspectives + 4-persona stress test
  /kernel:diagnose: systematic debugging + refactor analysis before fixing
  /kernel:retrospective: cross-session learning synthesis + pattern promotion
  /kernel:metrics: observability dashboard — sessions, agents, hooks, learnings
  /kernel:validate: pre-commit quality gates
  /kernel:tearitapart: critical review before implementation
  /kernel:review: code review for PRs
  /kernel:handoff: context brief for session continuity
```

## Tiers

```yaml
tiers:
  1: {files: 1-2, role: execute directly}
  2: {files: 3-5, role: orchestrate → surgeon}
  3: {files: 6+, role: orchestrate → surgeon → adversary}

rule: tier 2+ you orchestrate, agents implement, don't write code yourself
```

REFERENCE

# Profile-gated sections — only show what's relevant
if [ "$PROFILE" != "local" ]; then
cat << 'GITHUB_REF'

## Agents

```yaml
agents:
  researcher: find proven solutions, anti-patterns (spawn: unfamiliar tech)
  surgeon: implement contract scope (spawn: tier 2+)
  adversary: QA, find edge cases (spawn: tier 3)
  dreamer: multi-perspective debate (spawn: /kernel:dream tier 2+)
```

GITHUB_REF
fi

if [ "$PROFILE" = "github-oss" ] || [ "$PROFILE" = "github-production" ]; then
cat << 'OSS_REF'

## Git Workflow (OSS/Production)

```yaml
workflow:
  branch: feature/{type}/{name} for all changes
  pr: required before merge to main
  review: /kernel:review + CI checks
  merge: squash merge to main
```

OSS_REF
fi

if [ "$PROFILE" = "github-production" ]; then
  echo "## Team Signals"
  echo "Production profile detected: >2 collaborators or environments configured."
  echo "Use GitHub Issues for work tracking. Enforce branch protection."
  echo ""
fi

# Emit session start event
"$AGENTDB" emit session "session:start" "" "{\"branch\":\"$(git branch --show-current 2>/dev/null || echo none)\",\"profile\":\"$PROFILE\",\"project\":\"$PROJECT_ROOT\"}" "" "" 2>/dev/null &
_kernel_hook_end "session-start" 0
