#!/bin/bash
# Killswitch ops helper: check / reset / override the runaway-agent killswitch.
# Manual tool for Aria (run from a shell). NOT a hook -- not wired into hooks.json.
#
# Usage:
#   killswitch-status.sh check [session_id]   # show count/max for a session (or all)
#   killswitch-status.sh reset [session_id]   # rm a session's counter (or all)
#   killswitch-status.sh override on|off      # engage / clear the override (bypass) file
#   killswitch-status.sh list                 # list all tracked sessions
#
# State dir matches killswitch.sh:
#   ${CLAUDE_PROJECT_DIR}/.claude/.killswitch  if set, else ${TMPDIR:-/tmp}/claude-killswitch

set -u

if [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
  STATE_DIR="${CLAUDE_PROJECT_DIR}/.claude/.killswitch"
else
  STATE_DIR="${TMPDIR:-/tmp}/claude-killswitch"
fi
MAX_TOOLS="${KILLSWITCH_MAX_TOOLS:-500}"
OVERRIDE_FILE="$STATE_DIR/.budget-override"

CMD="${1:-check}"
ARG="${2:-}"

_show_one() {
  local f="$1"
  local sid; sid=$(basename "$f" .count)
  local n; n=$(cat "$f" 2>/dev/null || echo "?")
  local started=""
  if [ -f "$STATE_DIR/$sid.start" ]; then
    local s; s=$(cat "$STATE_DIR/$sid.start" 2>/dev/null)
    case "$s" in ''|*[!0-9]*) ;; *) started=" (age $(( $(date +%s) - s ))s)";; esac
  fi
  printf '%s  %s/%s%s\n' "$sid" "$n" "$MAX_TOOLS" "$started"
}

case "$CMD" in
  check|list)
    if [ ! -d "$STATE_DIR" ]; then echo "no killswitch state ($STATE_DIR does not exist)"; exit 0; fi
    [ -f "$OVERRIDE_FILE" ] && echo "OVERRIDE ACTIVE (killswitch bypassed): $OVERRIDE_FILE"
    if [ -n "$ARG" ]; then
      f="$STATE_DIR/$ARG.count"
      [ -f "$f" ] && _show_one "$f" || echo "no counter for session $ARG"
    else
      found=0
      for f in "$STATE_DIR"/*.count; do
        [ -e "$f" ] || continue
        _show_one "$f"; found=1
      done
      [ "$found" = 0 ] && echo "no active session counters in $STATE_DIR"
    fi
    ;;
  reset)
    if [ -n "$ARG" ]; then
      rm -f "$STATE_DIR/$ARG.count" "$STATE_DIR/$ARG.start" "$STATE_DIR/$ARG.warned" 2>/dev/null
      echo "reset session $ARG"
    else
      rm -f "$STATE_DIR"/*.count "$STATE_DIR"/*.start "$STATE_DIR"/*.warned 2>/dev/null
      echo "reset ALL sessions"
    fi
    ;;
  override)
    case "$ARG" in
      on)  mkdir -p "$STATE_DIR" 2>/dev/null; touch "$OVERRIDE_FILE" && echo "override ON  -> killswitch bypassed ($OVERRIDE_FILE)";;
      off) rm -f "$OVERRIDE_FILE" && echo "override OFF -> killswitch active again";;
      *)   echo "usage: killswitch-status.sh override on|off"; exit 1;;
    esac
    ;;
  *)
    echo "usage: killswitch-status.sh check|reset|override|list [session_id|on|off]"; exit 1
    ;;
esac
