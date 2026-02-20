#!/bin/bash
# KERNEL: Session start hook
# 1. Outputs git state
# 2. Outputs core philosophy (since plugin CLAUDE.md isn't loaded)
# 3. Runs agentdb read-start to surface learnings, checkpoints, contracts, errors

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(dirname "$(dirname "$(dirname "$0")")")}"
AGENTDB="${PLUGIN_ROOT}/orchestration/agentdb/agentdb"

# Git state (if in a git repo)
if git rev-parse --git-dir >/dev/null 2>&1; then
  echo "## Git State"
  BRANCH=$(git branch --show-current 2>/dev/null)
  echo "Branch: $BRANCH"

  CHANGES=$(git status --porcelain 2>/dev/null | head -5)
  if [ -n "$CHANGES" ]; then
    echo "Changes:"
    echo "$CHANGES" | while read line; do echo "  $line"; done
  fi

  echo ""
  echo "Recent:"
  git log --oneline -3 2>/dev/null | while read line; do echo "  $line"; done
  echo ""
  echo "---"
  echo ""
fi

# Core philosophy (condensed)
cat << 'PHILOSOPHY'
## KERNEL Philosophy

**AgentDB-first. Read at start. Write at end.**

| Tier | Files | Action |
|------|-------|--------|
| 1 | 1-2 | Execute directly |
| 2 | 3-5 | Spawn surgeon agent |
| 3 | 6+ | Contract → surgeon → adversary |

Flow: READ → SCOPE → WORK → VERIFY → WRITE

Anti-patterns: skip read (repeat failures), skip write (lose context)

---

PHILOSOPHY

# Run agentdb read-start if initialized
if [ -f "_meta/agentdb/agent.db" ]; then
  "$AGENTDB" read-start
else
  echo "## AgentDB Status"
  echo "Not initialized. Run: agentdb init"
fi
