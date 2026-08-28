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
  # Where this session started, so session-end can post a receipt naming exactly
  # what landed against which issue. Without this the receipt call is unreachable.
  _KERNEL_RUNTIME_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}/_meta/.runtime"
  # `|| true` is load-bearing: a repo with no commits has no HEAD, and under
  # `set -eo pipefail` this line's failure killed the entire SessionStart hook
  # with exit 128. A fresh repo got no context injection at all, which is
  # exactly the session that needs it most.
  mkdir -p "$_KERNEL_RUNTIME_DIR" 2>/dev/null && \
    { git rev-parse HEAD > "$_KERNEL_RUNTIME_DIR/session-start-sha" 2>/dev/null || true; }
  CHANGES=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  if [ "$CHANGES" -gt 0 ]; then
    echo "**Uncommitted:** $CHANGES file(s) on branch $BRANCH"
  fi
  echo ""
  echo "**Recent commits:**"
  # No commits means no log. Under `set -eo pipefail` the failure propagated
  # through the pipe and killed the hook, so `|| true` is not cosmetic here.
  git log --oneline -5 2>/dev/null | sed 's/^/- /' || true
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
agentdb recall "<feature> <subsystem> <files/symbols> <error/outcome>" [--global]
agentdb learn failure|pattern|gotcha "what" "why"  # capture as discovered
agentdb write-end '{"did":"X","learned":["Y"]}'    # at session end
agentdb wtf                                        # confused? full ref: agentdb guide
```

Recall with concrete nouns, not prose. Recall again after discovery, when scope/hypothesis changes, or on a new failure.

Optimize for the fastest correct, robust path. Tier by reversibility x blast radius, NOT file count. Gate hard only where an op is irreversible. T1 execute, T2 plan+verify, T3 confirm.
Inline for single-file, single-step work. Delegate by default when any of these hold: the work splits into file-disjoint slices, a read would dump more than a few hundred lines into your context (transcripts, logs, corpora), a verification must be blind to your reasoning, or two independent questions can be answered at once. Fan out in ONE message with several Agent calls; serial spawns cost wall-clock for nothing. Never spawn for independence alone. When work is genuinely high-blast-radius or delegated, contract it, then verify with an adversary.
Route model and effort by task shape and measured evidence, never prestige. Preserve the exact request; never silently substitute. Receipts keep `requested_model` and `requested_effort` separate from `observed_model` and `observed_effort`, and use `unavailable` when the runtime does not expose a value.
Protected receipts require distinct `builder_identity` and `verifier_identity`; the builder never grades its own protected work.
Claude invokes skills as /kernel:name; Codex invokes them as $kernel:name. Use the matching form; /kernel:help or $kernel:help lists them.
Structured questions are the default reply shape, not an escalation. End every unfinished turn with one; Claude uses the AskUserQuestion tool, Codex has no such tool and ends with a numbered QUESTION block instead. Skip only when the work is fully done, exactly one real option exists, or the session is non-interactive. The tool's absence from your tool list IS the non-interactive signal: never stall a headless run on an answer that cannot arrive.
Subagents never ask the user. They escalate through their contract's ESCALATE IF line and stop; the orchestrator answers what its own context can answer and batches the rest into ONE round. Guessing is the top defect source: an unstated assumption you acted on is a defect you shipped.
KERNEL_CONTEXT
# END GENERATED KERNEL AMBIENT

# --- This machine (9.5.2): the facts a model's Linux/GNU prior gets wrong here ------------
# Prevention, not catching. A 14-day audit found 135 path guesses from a shell whose cwd
# resets, 45 calls to GNU tools macOS does not ship, and a commit message eaten by backticks.
# Six lines at session start are cheaper than one retry. Only lines that are TRUE on this
# host are printed, so a Linux box with coreutils sees almost nothing.
{
  _mc=""
  # Printed only when the GNU forms actually fail here. A host with compat shims on PATH
  # (Vaults: _meta/services/install-agent-compat.sh) or GNU coreutils prints nothing.
  if [ "$(uname -s)" = "Darwin" ] && ! printf 'x\n' | cat -A >/dev/null 2>&1; then
    _mc="${_mc}- macOS BSD userland: \`cat -vet\` not \`-A\`; \`rg -P\` not \`grep -P\`; \`sed -i ''\` for in-place; \`date -j\`, no \`-d\`; \`stat -f\`, no \`-c\`.\n"
  fi
  command -v python >/dev/null 2>&1 || _mc="${_mc}- \`python\` is not on PATH: use \`python3\`.\n"
  command -v timeout >/dev/null 2>&1 || _mc="${_mc}- no \`timeout\`: use \`gtimeout\` (brew install coreutils) or the Bash tool's timeout parameter.\n"
  _mc="${_mc}- The Bash tool's cwd resets between calls. Always \`cd /absolute/path && ...\` or use absolute paths; never a bare relative \`cd\`.\n"
  _mc="${_mc}- Messages (\`git commit -m\`, \`gh ... -b\`) go in single quotes or \`-F file\`; backticks and \$( inside double quotes execute.\n"
  _mc="${_mc}- Stage files by name; \`git add -A\` picks up tracked binaries and runtime state that pre-commit guards refuse.\n"
  _mc="${_mc}- \`agentdb learn <type> \"what\" \"why\" [--global]\` (type first); \`graphify query|path|affected|stats\`.\n"
  echo "## This machine"
  printf "%b" "$_mc"
  echo ""
}

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
  # LEAN session surface (8.4.0): a count + recall pointer + the top few failures.
  # The old weighted-75 dump injected ~50 task-blind learnings (~2.8k tokens) into
  # EVERY session — obsolete now that recall is semantic (migration 015). The agent
  # recalls what its task needs; startup only surfaces the unconditional "avoid these"
  # failures. Explicit `agentdb read-start` still gives the full weighted dump on demand.
  # (--lean output is small, so the old 50-line SIGPIPE cap is no longer needed.)
  "$AGENTDB" read-start --lean 2>/dev/null
  echo ""

  # Prune stale learnings (0 hits, >30 days old)
  "$AGENTDB" query "DELETE FROM learnings WHERE hit_count = 0 AND ts < strftime('%Y-%m-%dT%H:%M:%fZ','now','-30 days');" 2>/dev/null || true

  # (Top-learnings surfacing folded into the --lean dump above — no separate section.)

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
  STALE_COUNT=$("$AGENTDB" query "SELECT COUNT(*) FROM context WHERE type='contract' AND ts < strftime('%Y-%m-%dT%H:%M:%fZ','now','-1 day') AND contract_id NOT IN (SELECT COALESCE(contract_id, '') FROM context WHERE type='verdict');" 2>/dev/null | awk '/^[0-9]/{v=$1} END{print v+0}')
  STALE_COUNT=${STALE_COUNT:-0}
  if [ "$STALE_COUNT" -gt 0 ]; then
    BLOCKERS="${BLOCKERS}\n- $STALE_COUNT stale contract(s) >24h without verdict"
  fi

  # Check for recent errors (>3 in last hour)
  ERROR_COUNT=$("$AGENTDB" query "SELECT COUNT(*) FROM errors WHERE ts > strftime('%Y-%m-%dT%H:%M:%fZ','now','-1 hour');" 2>/dev/null | awk '/^[0-9]/{v=$1} END{print v+0}')
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

# --- Knowledge-graph auto-orientation (8.6.1) ---
# If this repo has a code graph, inject its architectural spine so the agent boots ALREADY
# oriented instead of file-crawling to rebuild the map every session. This is the automatic
# half of the knowledge-graph capability: ambient context, not a tool the agent must remember
# to call. Self-gating: silent when no graph exists, so users without graphs see no change.
if command -v graphify >/dev/null 2>&1; then
  for _gj in "$PROJECT_ROOT/graphify-out/graph.json" "$PROJECT_ROOT/_meta/graphify-out/graph.json"; do
    [ -f "$_gj" ] || continue
    _hubs="$(graphify god-nodes --top 8 --graph "$_gj" 2>/dev/null | grep -E '^[[:space:]]*[0-9]+\.' | sed 's/^[[:space:]]*/  /')"
    [ -n "$_hubs" ] || continue
    echo "## Code map (auto-orientation)"
    echo "This repo has a knowledge graph — these are its architectural hubs. Consult the graph"
    echo "BEFORE crawling files to find where something lives:"
    echo "$_hubs"
    echo "Query without reading files: \`graphify query \"<question>\"\` · \`graphify path A B\` · \`graphify affected X\`"
    echo ""
    break
  done
fi
# --- end auto-orientation ---

# --- compression policy (always emitted, first thing the model reads) ---
cat <<'COMPRESSION'
## compression — mandatory

minimum text. zero meaningful loss.

* default: bullets + fragments.
* prose only when structure would lose meaning.
* delete anything removable.
* merge anything redundant.
* shorten anything compressible.
* never narrate work; report results, evidence, blockers, decisions.
* preserve correctness, clarity, decisions, evidence, uncertainty, action.
* length follows information. never pad; never omit.

before emitting:

1. convert prose → bullets/fragments wherever lossless.
2. delete every removable word, sentence, bullet, section, preamble, recap, transition, or explanation.
3. repeat until further compression would lose meaning.

do not emit while removable text remains.

verbosity is a defect.
omission is also a defect.
COMPRESSION
echo ""
# --- end compression policy ---

# Emit session start event
"$AGENTDB" emit session "session:start" "" "{\"branch\":\"$(git branch --show-current 2>/dev/null || echo none)\",\"profile\":\"$PROFILE\",\"project\":\"$PROJECT_ROOT\"}" "" "$KERNEL_SESSION_ID" 2>/dev/null &
_kernel_hook_end "session-start" 0
