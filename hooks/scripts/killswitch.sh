#!/bin/bash
# PreToolUse hook: Runaway-agent killswitch (tool-call + wall-clock budget cap).
# Events: PreToolUse (matcher: "" -- ALL tools)
#
# WHY THIS EXISTS
#   Honor-system budget caps are worthless (real incidents: $6K overnight, 14k
#   redundant tool calls, 50-deep subagent recursion). A PreToolUse hook fires
#   once per tool call and is the only enforcement point OUTSIDE the model loop.
#   It counts TOOL CALLS per session and the session WALL-CLOCK; over cap it
#   blocks new expensive tools (exit 2) but ALLOWS save-work tools so the agent
#   can checkpoint + stop without losing work.
#   Design doc: _meta/research/runaway-agent-killswitch-2026.md
#
# WHAT IT ENFORCES (reliable signals only)
#   - tool-call count per session  (HIGH confidence)
#   - session wall-clock duration  (~1s precision)
#   It deliberately does NOT enforce COST: transcript_path token fields are
#   broken placeholders (100x off, claude-code#28197) and llm-traces.db only
#   covers subprocess calls, not the main agent loop. See KILLSWITCH.md.
#
# FAIL-OPEN POLICY (critical -- this runs on EVERY tool call)
#   ANY internal error (missing jq, unparseable stdin, unwritable state, lock
#   timeout) -> exit 0 with a stderr note. A bug in this guard must NEVER block
#   a tool call. The ONLY exit-2 path is a confirmed over-cap read of a
#   successfully-incremented counter against a non-allowlisted tool.
#
# Does NOT source common.sh or circuit-breaker.sh: a safety gate must always run,
# must never auto-disable, and must not inherit a bug from shared code (I0.15).
#
# CONFIG (env var > default). Defaults sized so a legit long T3/forge (several
# hundred tool calls) does NOT false-trip:
#   KILLSWITCH_MAX_TOOLS     hard cap, tool calls per session   (default 500)
#   KILLSWITCH_WARN_PERCENT  warn threshold, % of max           (default 80)
#   KILLSWITCH_MAX_DURATION  wall-clock seconds, 0=off           (default 7200 = 2h)
#   KILLSWITCH_OFF=1         disable entirely (escape hatch)
#
# OPS (see killswitch-status.sh + KILLSWITCH.md):
#   check:    killswitch-status.sh check
#   reset:    killswitch-status.sh reset
#   override: killswitch-status.sh override on|off

# --- Everything below runs inside fail-open guards. Default outcome = allow. ---

# Defaults (env override).
MAX_TOOLS="${KILLSWITCH_MAX_TOOLS:-500}"
WARN_PERCENT="${KILLSWITCH_WARN_PERCENT:-80}"
MAX_DURATION="${KILLSWITCH_MAX_DURATION:-7200}"

# Sanity: any non-numeric / empty config -> fail open with safe fallbacks.
case "$MAX_TOOLS"    in ''|*[!0-9]*) MAX_TOOLS=500;;  esac
case "$WARN_PERCENT" in ''|*[!0-9]*) WARN_PERCENT=80;; esac
case "$MAX_DURATION" in ''|*[!0-9]*) MAX_DURATION=7200;; esac

# --- Escape hatch 1: env disable (checked before any parsing) ---
if [ "${KILLSWITCH_OFF:-}" = "1" ]; then
  echo "killswitch: BYPASSED (KILLSWITCH_OFF=1)." >&2
  exit 0
fi

# jq required to parse stdin; missing -> fail open (matches guard-bash.sh).
if ! command -v jq >/dev/null 2>&1; then
  echo "killswitch: warning -- jq not found, budget guard degraded (install jq). Allowing." >&2
  exit 0
fi

INPUT=$(cat 2>/dev/null)
[ -z "$INPUT" ] && exit 0  # nothing on stdin -> allow

# Parse fields. Any parse failure -> empty -> fail open below.
SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
TOOL_NAME=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
TOOL_COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

# No session_id -> can't key a counter safely -> fail open.
if [ -z "$SESSION_ID" ]; then
  echo "killswitch: warning -- no session_id in stdin, allowing." >&2
  exit 0
fi
# Defensively sanitize session_id for use as a filename (UUIDs are safe already).
SESSION_ID=$(printf '%s' "$SESSION_ID" | tr -cd 'A-Za-z0-9._-')
[ -z "$SESSION_ID" ] && exit 0

# --- State dir: GENERAL (kernel plugin is not vault-specific) ---
# Prefer the project dir if Claude Code provides it, else a tmp dir.
if [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
  STATE_DIR="${CLAUDE_PROJECT_DIR}/.claude/.killswitch"
else
  STATE_DIR="${TMPDIR:-/tmp}/claude-killswitch"
fi
mkdir -p "$STATE_DIR" 2>/dev/null || true
# State dir unusable -> fail open.
if [ ! -d "$STATE_DIR" ] || [ ! -w "$STATE_DIR" ]; then
  echo "killswitch: warning -- state dir not writable ($STATE_DIR), allowing." >&2
  exit 0
fi

COUNT_FILE="$STATE_DIR/$SESSION_ID.count"
START_FILE="$STATE_DIR/$SESSION_ID.start"
WARN_FILE="$STATE_DIR/$SESSION_ID.warned"
LOCK_DIR="$STATE_DIR/$SESSION_ID.lockd"
OVERRIDE_FILE="$STATE_DIR/.budget-override"

# --- Escape hatch 2: override file present ---
if [ -f "$OVERRIDE_FILE" ]; then
  echo "killswitch: BYPASSED (override file present: $OVERRIDE_FILE)." >&2
  exit 0
fi

# --- Atomic increment via mkdir spinlock (flock is absent on macOS) ---
# mkdir is atomic on POSIX: only one process can create the lock dir. Spin
# briefly; if we cannot get the lock fast, FAIL OPEN (never block on a lock).
COUNT=""
_acquired=0
_i=0
while [ "$_i" -lt 50 ]; do            # ~50 * 5ms = 250ms max wait
  if mkdir "$LOCK_DIR" 2>/dev/null; then
    _acquired=1
    break
  fi
  # Steal a stale lock dir (>30s old) left by a crashed process.
  if [ -d "$LOCK_DIR" ]; then
    _stale=$(find "$LOCK_DIR" -maxdepth 0 -mmin +0.5 2>/dev/null)
    [ -n "$_stale" ] && rmdir "$LOCK_DIR" 2>/dev/null
  fi
  _i=$((_i + 1))
  sleep 0.005 2>/dev/null || sleep 1
done

if [ "$_acquired" = 1 ]; then
  C=$(cat "$COUNT_FILE" 2>/dev/null)
  case "$C" in ''|*[!0-9]*) C=0;; esac   # corrupt/empty counter -> treat as 0
  C=$((C + 1))
  if echo "$C" > "$COUNT_FILE" 2>/dev/null; then
    COUNT="$C"
  fi
  # Record session start epoch on first sight (for wall-clock cap).
  if [ ! -f "$START_FILE" ]; then
    date +%s > "$START_FILE" 2>/dev/null || true
  fi
  rmdir "$LOCK_DIR" 2>/dev/null || true
fi

# Could not acquire lock or could not write counter -> FAIL OPEN.
if [ -z "$COUNT" ]; then
  echo "killswitch: warning -- could not update counter, allowing." >&2
  exit 0
fi

# --- Wall-clock duration check ---
DURATION=0
if [ "$MAX_DURATION" -gt 0 ] && [ -f "$START_FILE" ]; then
  START_EPOCH=$(cat "$START_FILE" 2>/dev/null)
  case "$START_EPOCH" in ''|*[!0-9]*) START_EPOCH="";; esac
  if [ -n "$START_EPOCH" ]; then
    NOW=$(date +%s 2>/dev/null)
    case "$NOW" in ''|*[!0-9]*) NOW="";; esac
    [ -n "$NOW" ] && DURATION=$((NOW - START_EPOCH))
  fi
fi

# Warn threshold (count). WARN_PERCENT of MAX_TOOLS.
WARN_AT=$(( MAX_TOOLS * WARN_PERCENT / 100 ))
[ "$WARN_AT" -lt 1 ] && WARN_AT=1

OVER_DURATION=0
if [ "$MAX_DURATION" -gt 0 ] && [ "$DURATION" -ge "$MAX_DURATION" ]; then
  OVER_DURATION=1
fi

# --- Save-work allowlist (permitted even when over-cap) ---
# Read / Write / Edit / TodoWrite always allowed. Bash allowed ONLY for
# explicit save/report commands. Everything else blocked over-cap.
is_allowlisted() {
  case "$TOOL_NAME" in
    Read|Write|Edit|TodoWrite) return 0;;
    Bash)
      # Strip leading env-var assignments + whitespace so "FOO=1 git commit" matches.
      local cmd
      cmd=$(printf '%s' "$TOOL_COMMAND" | sed -E 's/^([[:space:]]*[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*//')
      case "$cmd" in
        "git commit"*|"git add"*|"git push"*|"git status"*|"git diff"*|"git log"*) return 0;;
        agentdb*|"echo "*|echo|"cat "*|cat) return 0;;
        *) return 1;;
      esac
      ;;
    *) return 1;;
  esac
}

# --- DECISION ---
if [ "$COUNT" -ge "$MAX_TOOLS" ] || [ "$OVER_DURATION" = 1 ]; then
  # OVER CAP.
  if [ "$OVER_DURATION" = 1 ]; then
    REASON="wall-clock ${DURATION}s >= ${MAX_DURATION}s"
  else
    REASON="tool calls ${COUNT}/${MAX_TOOLS}"
  fi
  if is_allowlisted; then
    echo "killswitch: OVER BUDGET ($REASON) but allowing save-work tool ($TOOL_NAME). Checkpoint now + end the session." >&2
    exit 0
  fi
  echo "🛑 KILLSWITCH: session budget exceeded ($REASON)." >&2
  echo "STOP making new expensive calls ($TOOL_NAME is blocked). Save your work and END:" >&2
  echo "  - commit (git add / git commit / git push), write a handoff/chronicle (Write/Edit)," >&2
  echo "    record state (agentdb write-end). Read/Write/Edit/TodoWrite + git/agentdb are still allowed." >&2
  echo "  - Override (only if intentional): touch \"$OVERRIDE_FILE\"  or  KILLSWITCH_OFF=1." >&2
  exit 2
fi

# --- Warn threshold (once per crossing) ---
if [ "$COUNT" -ge "$WARN_AT" ] && [ ! -f "$WARN_FILE" ]; then
  echo "⚠ killswitch: $COUNT/$MAX_TOOLS tool calls this session -- wrap up + checkpoint soon (hard stop at $MAX_TOOLS)." >&2
  touch "$WARN_FILE" 2>/dev/null || true
fi

# Under cap -> allow silently.
exit 0
