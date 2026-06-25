#!/bin/bash
# SessionStart hook: initialize this session's killswitch counter + sweep stale state.
# Events: SessionStart (matcher: "")
#
# WHY: a brand-new session must start with a fresh counter so it can never inherit
# a stale over-cap counter and get instantly bricked (design doc failure #8/#21).
# Each Claude window has its own session_id (UUID) -> naturally isolated counters,
# so multi-window sessions don't trip each other (canon: kill-autopush-multiwindow).
#
# Fully fail-open + side-effect-light: a crash here must never block a session.
# Reads stdin once and discards (SessionStart provides session_id + source).
#
# Mirrors killswitch.sh state-dir derivation EXACTLY (must agree):
#   ${CLAUDE_PROJECT_DIR}/.claude/.killswitch   if set, else ${TMPDIR:-/tmp}/claude-killswitch

INPUT=$(cat 2>/dev/null)

if [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
  STATE_DIR="${CLAUDE_PROJECT_DIR}/.claude/.killswitch"
else
  STATE_DIR="${TMPDIR:-/tmp}/claude-killswitch"
fi
mkdir -p "$STATE_DIR" 2>/dev/null || true
[ -d "$STATE_DIR" ] || exit 0   # can't make state dir -> nothing to do, allow

# Sweep stale state files older than 24h (count/start/warned). Prevents unbounded
# growth and guarantees a reused-on-disk id can't carry an old over-cap counter.
find "$STATE_DIR" -maxdepth 1 -type f \( -name '*.count' -o -name '*.start' -o -name '*.warned' \) -mtime +1 -delete 2>/dev/null || true
# Sweep abandoned lock dirs older than 24h too.
find "$STATE_DIR" -maxdepth 1 -type d -name '*.lockd' -mtime +1 -exec rmdir {} \; 2>/dev/null || true

# Initialize THIS session's counter to 0 (only when not resuming). On resume the
# session continues -> preserve the counter (budget does not reset mid-session).
if command -v jq >/dev/null 2>&1 && [ -n "$INPUT" ]; then
  SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
  SOURCE=$(printf '%s' "$INPUT" | jq -r '.source // empty' 2>/dev/null)
  SESSION_ID=$(printf '%s' "$SESSION_ID" | tr -cd 'A-Za-z0-9._-')
  if [ -n "$SESSION_ID" ] && [ "$SOURCE" != "resume" ]; then
    echo "0" > "$STATE_DIR/$SESSION_ID.count" 2>/dev/null || true
    date +%s > "$STATE_DIR/$SESSION_ID.start" 2>/dev/null || true
    rm -f "$STATE_DIR/$SESSION_ID.warned" 2>/dev/null || true
  fi
fi

exit 0
