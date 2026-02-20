#!/bin/bash
# KERNEL: Session start hook
# 1. Git state
# 2. Core philosophy + orchestration role
# 3. AgentDB context (failures, patterns, contracts, errors, checkpoints)
# 4. Active contract check + tier guidance

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(dirname "$(dirname "$(dirname "$0")")")}"
AGENTDB="${PLUGIN_ROOT}/orchestration/agentdb/agentdb"

echo "# KERNEL"
echo ""

# Git state (if in a git repo)
if git rev-parse --git-dir >/dev/null 2>&1; then
  BRANCH=$(git branch --show-current 2>/dev/null)
  echo "**Branch:** $BRANCH"

  CHANGES=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  if [ "$CHANGES" -gt 0 ]; then
    echo "**Uncommitted:** $CHANGES file(s)"
  fi

  RECENT=$(git log --oneline -1 2>/dev/null)
  if [ -n "$RECENT" ]; then
    echo "**Last commit:** $RECENT"
  fi
  echo ""
fi

# Philosophy
cat << 'PHILOSOPHY'
## Philosophy

**AgentDB-first. Read at start. Write at end.**

| Tier | Files | Your Role |
|------|-------|-----------|
| 1 | 1-2 | Execute directly |
| 2 | 3-5 | Orchestrate → surgeon |
| 3 | 6+ | Orchestrate → surgeon → adversary |

**Tier 2+:** You are the orchestrator. Create contracts, spawn agents, read their AgentDB output. Don't write code yourself.

PHILOSOPHY

# AgentDB context
if [ -f "_meta/agentdb/agent.db" ]; then
  echo ""
  "$AGENTDB" read-start
  echo ""

  # Check for active contract
  ACTIVE_CONTRACT=$("$AGENTDB" query "SELECT id, content FROM context WHERE type='contract' ORDER BY ts DESC LIMIT 1" 2>/dev/null)
  if [ -n "$ACTIVE_CONTRACT" ]; then
    echo "## Active Contract"
    echo "$ACTIVE_CONTRACT"
    echo ""
    echo "**Resume or close this contract before starting new work.**"
    echo ""
  fi

  # Check for pending checkpoints (agents finished but not reviewed)
  PENDING=$("$AGENTDB" query "SELECT agent, content FROM context WHERE type='checkpoint' AND ts > (SELECT COALESCE(MAX(ts), '1970-01-01') FROM context WHERE type='verdict') ORDER BY ts DESC LIMIT 1" 2>/dev/null)
  if [ -n "$PENDING" ]; then
    echo "## Pending Review"
    echo "Agent checkpoint awaiting your review:"
    echo "$PENDING"
    echo ""
  fi
else
  echo ""
  echo "## AgentDB"
  echo "Not initialized. Run: \`agentdb init\`"
  echo ""
fi

# Quick reference
cat << 'REFERENCE'
## Quick Reference

```
/kernel:ingest    → Universal entry (classify, scope, orchestrate)
/kernel:validate  → Pre-commit checks
/kernel:ship      → Commit, push, PR
```

**Commands:** ingest, validate, ship, tearitapart, branch, handoff
**Agents:** surgeon (implement), adversary (verify)

REFERENCE
