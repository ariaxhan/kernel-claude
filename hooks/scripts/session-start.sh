#!/bin/bash
set -eo pipefail
# KERNEL: Session start hook

# Load shared functions
source "$(dirname "$0")/common.sh"

# Self-heal: update current symlink if newer version available
update_current_symlink

# Detect paths
VAULTS=$(detect_vaults)
AGENTDB=$(get_agentdb "$VAULTS")
PROJECT_ROOT=$(get_project_root)

# Generate agent name and persist for other hooks
AGENT_NAME="main-$$"
AGENTS_DIR="$VAULTS/_meta/agents"
mkdir -p "$AGENTS_DIR"
echo "$AGENT_NAME" > "$AGENTS_DIR/.current"

cat > "$AGENTS_DIR/${AGENT_NAME}.json" << EOF
{
  "agent_name": "$AGENT_NAME",
  "started": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
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
  [ "$CHANGES" -gt 0 ] && echo "**Uncommitted:** $CHANGES file(s)"
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
## AgentDB (MANDATORY)

```yaml
on_start: agentdb read-start  # MUST do first
on_end: agentdb write-end '{"did":"X","learned":["Y"]}'  # MUST do before stopping
on_learn:
  failure: agentdb learn failure "what" "evidence"
  pattern: agentdb learn pattern "what" "evidence"
  gotcha: agentdb learn gotcha "what" "context"
```

**AgentDB: read at start, write at end. Every session.**

---

## Workflow

```yaml
flow: READ → CLASSIFY → RESEARCH → SCOPE → TESTS → EXECUTE → LEARN

steps:
  1_read:
    do: agentdb read-start
    then: ls _meta/research/  # check prior work

  2_classify:
    task: what user wants
    type: bug|feature|refactor|question
    familiar: yes|no

  3_research:
    order:
      - anti_patterns: "{tech} not working", "{tech} gotchas"
      - solutions: official docs → github issues → stack overflow
    output: _meta/research/{topic}.md
    rule: search what BREAKS before what works

  4_scope:
    list: every file that changes
    count: N
    tier:
      1: 1-2 files → execute directly
      2: 3-5 files → contract + surgeon
      3: 6+ files → contract + surgeon + adversary

  5_tests:
    rule: tests BEFORE code
    cycle: red (fail) → green (pass) → refactor
    output: failing tests that define success

  6_execute:
    tier_1: implement using research + tests
    tier_2+: create contract, spawn surgeon, orchestrate

  7_learn:
    do: agentdb learn pattern "what worked"
    then: agentdb write-end
    update: _meta/research/ if new anti-patterns found
```

---

## Testing (Non-Negotiable)

```yaml
rule: tests before code
cycle:
  1: write failing test (red)
  2: write minimal code to pass (green)
  3: refactor while green
  4: repeat

principles:
  tests_first: code-then-tests validates bugs not requirements
  mock_boundaries_only: external APIs, DBs — NOT internal functions
  real_deps_preferred: test containers > mocks (mocks lie)
  edge_cases_first: null, empty, boundary, concurrent, timeout
  strong_assertions: specific values, not truthy/exists
  graceful_fallbacks: test degraded mode, not just success/fail

anti_patterns:  # AI generates these — avoid
  - happy_path_only → test failure modes first
  - weak_assertions → toBeTruthy catches nothing
  - mock_everything → mock at boundaries only
  - test_implementation → test behavior at public API
```

---

## Mindset

```yaml
core:
  - every AI line is liability
  - most SWE is solved problems
  - research anti-patterns BEFORE solutions
  - tests BEFORE code
  - built-in > library > custom
  - mock boundaries only, real deps when possible
  - capture learnings AFTER every task

mantra: find proven solution, test it works, don't reinvent
```

KERNEL_CONTEXT

# =============================================================================
# AGENTDB CONTEXT (if initialized)
# =============================================================================
# Auto-migrate: ensure schema is current (handles plugin updates seamlessly)
"$AGENTDB" init 2>/dev/null || true

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
  /kernel:auto: autonomous loop, tests first, iterate until green
  /kernel:dream: multi-perspective debate before implementation
  /kernel:diagnose: systematic debugging + refactor analysis
  /kernel:validate: pre-commit quality gates
  /kernel:tearitapart: critical review before implementation
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
