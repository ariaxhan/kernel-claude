#!/bin/bash
# Hooks run in parallel and are killed on timeout. A read-only `git status` still takes
# .git/index.lock to write the refreshed index, so a killed or racing hook leaves a zero-byte
# orphan behind and the next foreground `git commit` blocks on it. GIT_OPTIONAL_LOCKS=0 makes
# git skip that optional index write; real writes (add/commit) still take the lock normally.
# Reproduced 2026-08-30: 25 parallel hook git reads orphaned a lock; with this set, none did.
export GIT_OPTIONAL_LOCKS=0
# KERNEL 9: provider-neutral UserPromptSubmit activation.
#
# Classifies the current request against the active session's last route plus
# cheap observable state. Direct + normal stays silent. State is ephemeral and
# session-scoped: it is evidence for reassessment, never an authoritative plan.

set -u
umask 077

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ROUTER="${KERNEL_ROUTER_PATH:-$PLUGIN_ROOT/orchestration/router/kernel_router.py}"
INPUT=$(cat)

emit_fallback() {
  local reason="${1:-routing prerequisite unavailable}"
  local fallback
  fallback=$(printf '{"event":"kernel.route","status":"fallback","work_shape":"gated","safety":"protected","reason":"%s"}' "$reason")
  [ -n "${KERNEL_ROUTER_RECEIPT_PATH:-}" ] &&
    printf '%s\n' "$fallback" >> "$KERNEL_ROUTER_RECEIPT_PATH" 2>/dev/null
  printf '%s\n' \
    "## KERNEL route unavailable" \
    "Use gated work for this request. Keep every safety and read-only constraint; reassess before expanding scope."
}

command -v jq >/dev/null 2>&1 || { emit_fallback "jq unavailable"; exit 0; }
[ -f "$ROUTER" ] || { emit_fallback "router unavailable"; exit 0; }

PROMPT=$(printf '%s' "$INPUT" | jq -r '
  .prompt // .user_prompt // .message // .input // empty
' 2>/dev/null || true)

# Distinguish "this event legitimately carries no prompt" from "the host changed its payload
# shape and we no longer recognise it". Both used to `exit 0` silently, which meant a host
# update could turn adaptive routing off for every request, permanently, with no signal
# anywhere. jq/router unavailability two lines above already fails loudly; schema drift is the
# same class of problem and gets the same treatment.
if [ -z "$PROMPT" ]; then
  PAYLOAD_KEYS=$(printf '%s' "$INPUT" | jq -r 'if type=="object" then (keys_unsorted | join(",")) else "" end' 2>/dev/null || true)
  if [ -z "$PAYLOAD_KEYS" ]; then
    # Unparseable or non-object input. Not a prompt event; stay quiet.
    exit 0
  fi
  case ",$PAYLOAD_KEYS," in
    *,prompt,*|*,user_prompt,*|*,message,*|*,input,*)
      # A known prompt field is present but empty. Genuinely nothing to classify.
      exit 0 ;;
    *)
      emit_fallback "unrecognised payload shape (keys: $PAYLOAD_KEYS); routing disabled, host schema may have drifted"
      exit 0 ;;
  esac
fi

SESSION_ID=$(printf '%s' "$INPUT" | jq -r '
  .session_id // .conversation_id // .thread_id // .threadId // empty
' 2>/dev/null || true)
REQUEST_CWD=$(printf '%s' "$INPUT" | jq -r '
  .cwd // .workspace_root // .workspace.current_dir // empty
' 2>/dev/null || true)
[ -d "$REQUEST_CWD" ] 2>/dev/null || REQUEST_CWD="$PWD"

STATE_ROOT="${KERNEL_ROUTER_STATE_DIR:-${TMPDIR:-/tmp}/kernel-router-${UID:-user}}"
mkdir -p "$STATE_ROOT" 2>/dev/null && chmod 700 "$STATE_ROOT" 2>/dev/null || STATE_ROOT=""

STATE_FILE=""
PREVIOUS_FILE=""
STARTED_AT=$(date +%s)
cleanup() {
  [ -n "$PREVIOUS_FILE" ] && rm -f "$PREVIOUS_FILE"
}
trap cleanup EXIT

if [ -n "$STATE_ROOT" ] && [ -n "$SESSION_ID" ]; then
  SESSION_KEY=$(printf '%s' "$SESSION_ID" | python3 -c \
    'import hashlib,sys; print(hashlib.sha256(sys.stdin.buffer.read()).hexdigest())')
  STATE_FILE="$STATE_ROOT/$SESSION_KEY.json"
  if [ -f "$STATE_FILE" ]; then
    SAVED_START=$(jq -r '.started_at // empty' "$STATE_FILE" 2>/dev/null || true)
    [[ "$SAVED_START" =~ ^[0-9]+$ ]] && STARTED_AT="$SAVED_START"
    PREVIOUS_FILE=$(mktemp "$STATE_ROOT/.previous.XXXXXX") || PREVIOUS_FILE=""
    if [ -n "$PREVIOUS_FILE" ]; then
      jq '.classification' "$STATE_FILE" > "$PREVIOUS_FILE" 2>/dev/null || {
        rm -f "$PREVIOUS_FILE"
        PREVIOUS_FILE=""
      }
    fi
  fi
fi

NOW=$(date +%s)
SESSION_AGE_MINUTES=$(( (NOW - STARTED_AT) / 60 ))
[ "$SESSION_AGE_MINUTES" -ge 0 ] 2>/dev/null || SESSION_AGE_MINUTES=0

WORKING_TREE_CHANGES=0
if [ -n "$PREVIOUS_FILE" ] &&
  printf '%s' "$PROMPT" | grep -Eiq \
    'actually|instead|new evidence|we found|turns out|was wrong|stale|scope (expanded|changed)|back out|revert that|fresh process|regression' &&
  command -v git >/dev/null 2>&1 &&
  git -C "$REQUEST_CWD" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  WORKING_TREE_CHANGES=$(
    git -C "$REQUEST_CWD" status --porcelain --ignore-submodules=dirty --untracked-files=normal 2>/dev/null |
      awk 'END { print NR + 0 }'
  )
fi

ARGS=(
  classify
  --session-age-minutes "$SESSION_AGE_MINUTES"
  --working-tree-changes "$WORKING_TREE_CHANGES"
  --compact
)
[ -n "$PREVIOUS_FILE" ] && ARGS+=(--previous "$PREVIOUS_FILE")

if ! CLASSIFICATION=$(printf '%s' "$PROMPT" | python3 "$ROUTER" "${ARGS[@]}" 2>/dev/null); then
  emit_fallback "router failed; safety retained"
  exit 0
fi

TRANSIENT=$(printf '%s' "$CLASSIFICATION" | jq -r '.transient // false')
if [ "$TRANSIENT" != "true" ] && [ -n "$STATE_FILE" ]; then
  NEXT_STATE=$(mktemp "$STATE_ROOT/.state.XXXXXX") || NEXT_STATE=""
  if [ -n "$NEXT_STATE" ]; then
    jq -n \
      --argjson started_at "$STARTED_AT" \
      --argjson updated_at "$NOW" \
      --argjson classification "$CLASSIFICATION" \
      '{started_at:$started_at, updated_at:$updated_at, classification:$classification}' \
      > "$NEXT_STATE" 2>/dev/null &&
      mv "$NEXT_STATE" "$STATE_FILE"
    [ -e "$NEXT_STATE" ] && rm -f "$NEXT_STATE"
  fi
fi

if [ -n "${KERNEL_ROUTER_RECEIPT_PATH:-}" ]; then
  printf '%s' "$CLASSIFICATION" |
    jq -c --arg event "kernel.route" --arg status "classified" \
      '{event:$event,status:$status} + .' \
      >> "$KERNEL_ROUTER_RECEIPT_PATH" 2>/dev/null
fi

ANNOUNCED=$(printf '%s' "$CLASSIFICATION" | jq -r '.announced // false')
[ "$ANNOUNCED" = "true" ] || exit 0

DOMAIN=$(printf '%s' "$CLASSIFICATION" | jq -r '.domain')
SHAPE=$(printf '%s' "$CLASSIFICATION" | jq -r '.work_shape')
SAFETY=$(printf '%s' "$CLASSIFICATION" | jq -r '.safety')
REASON=$(printf '%s' "$CLASSIFICATION" | jq -r '.reasons[0]')

printf '## KERNEL active route\n'
printf 'Shape: %s | safety: %s | domain: %s\n' "$SHAPE" "$SAFETY" "$DOMAIN"
printf 'Evidence: %s\n' "$REASON"
printf 'Load only %s/packs/%s/PACK.md for domain-specific method.\n' "$PLUGIN_ROOT" "$DOMAIN"

case "$SHAPE" in
  gated)
    printf '%s\n' \
      "Bound the deliverable and name its check before changing state." \
      "Treat plans as provisional; reclassify when current evidence changes the boundary."
    ;;
  trajectory)
    printf '%s\n' \
      "Select the next intervention from the current objective, verified state, evidence, capability, constraints, resources, and entropy." \
      "Plans are non-authoritative. Observe, validate, revise, then reassess after every meaningful revision."
    ;;
esac

if [ "$SAFETY" = "protected" ]; then
  printf '%s\n' \
    "Safety is a separate hard boundary. Name the check that distinguishes safe from unsafe before acting." \
    "A read-only or no-write instruction remains binding regardless of work shape."
fi
