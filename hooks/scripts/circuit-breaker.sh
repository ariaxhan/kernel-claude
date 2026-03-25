#!/bin/bash
# KERNEL: Circuit breaker for hooks
# Source this at the top of any guard hook that should degrade gracefully.
# After 3 consecutive failures, the hook is disabled for 10 minutes.
#
# Usage (in guard hooks only):
#   source "$(dirname "$0")/circuit-breaker.sh"
#   ... hook logic ...
#   _cb_record_success  # call before exit 0

# Find project root for breaker state
_CB_PROJECT_ROOT=""
_cb_dir="$PWD"
while [ "$_cb_dir" != "/" ]; do
  if [ -d "$_cb_dir/_meta" ] || [ -d "$_cb_dir/.claude" ]; then
    _CB_PROJECT_ROOT="$_cb_dir"
    break
  fi
  _cb_dir=$(dirname "$_cb_dir")
done
[ -z "$_CB_PROJECT_ROOT" ] && _CB_PROJECT_ROOT="$PWD"

BREAKER_DIR="$_CB_PROJECT_ROOT/_meta/.breakers"
mkdir -p "$BREAKER_DIR" 2>/dev/null || true

HOOK_NAME=$(basename "${BASH_SOURCE[1]:-$0}" .sh)
BREAKER_FILE="$BREAKER_DIR/$HOOK_NAME"
FAIL_COUNT_FILE="$BREAKER_DIR/${HOOK_NAME}.fails"

# Check if breaker is tripped
if [ -f "$BREAKER_FILE" ]; then
  TRIP_TIME=$(cat "$BREAKER_FILE" 2>/dev/null || echo "0")
  NOW=$(date +%s)
  COOLDOWN=600  # 10 minutes
  if [ $((NOW - TRIP_TIME)) -lt $COOLDOWN ]; then
    exit 0  # Still in cooldown — skip silently
  else
    rm -f "$BREAKER_FILE" "$FAIL_COUNT_FILE" 2>/dev/null
  fi
fi

# Record failure on ERR
_cb_record_failure() {
  local count=$(( $(cat "$FAIL_COUNT_FILE" 2>/dev/null || echo "0") + 1 ))
  echo "$count" > "$FAIL_COUNT_FILE"
  if [ "$count" -ge 3 ]; then
    date +%s > "$BREAKER_FILE"
    echo "CIRCUIT BREAKER: $HOOK_NAME disabled for 10min after $count consecutive failures" >&2
    rm -f "$FAIL_COUNT_FILE" 2>/dev/null
  fi
  # Emit hook failure timing (fire-and-forget)
  if [ -n "${_CB_START_MS:-}" ]; then
    local _cb_end_ms
    _cb_end_ms=$(python3 -c 'import time; print(int(time.time()*1000))' 2>/dev/null || true)
    if [ -n "$_cb_end_ms" ]; then
      local _cb_duration=$(( _cb_end_ms - _CB_START_MS ))
      local _cb_vaults_dir="$_CB_PROJECT_ROOT"
      while [ "$_cb_vaults_dir" != "/" ]; do
        [ -f "$_cb_vaults_dir/_meta/agentdb/agent.db" ] && break
        _cb_vaults_dir=$(dirname "$_cb_vaults_dir")
      done
      local _cb_agentdb="$_cb_vaults_dir/.claude/kernel/orchestration/agentdb/agentdb"
      [ ! -f "$_cb_agentdb" ] && _cb_agentdb="${_CB_PROJECT_ROOT}/orchestration/agentdb/agentdb"
      "$_cb_agentdb" emit hook "$HOOK_NAME" "$_cb_duration" "{\"exit_code\":1,\"failures\":$count}" "" "" 2>/dev/null &
    fi
  fi
}

# Reset failure count on success
_cb_record_success() {
  rm -f "$FAIL_COUNT_FILE" 2>/dev/null || true
  # Emit hook timing (fire-and-forget)
  if [ -n "${_CB_START_MS:-}" ]; then
    local _cb_end_ms
    _cb_end_ms=$(python3 -c 'import time; print(int(time.time()*1000))' 2>/dev/null || true)
    if [ -n "$_cb_end_ms" ]; then
      local _cb_duration=$(( _cb_end_ms - _CB_START_MS ))
      # Find agentdb
      local _cb_vaults_dir="$_CB_PROJECT_ROOT"
      while [ "$_cb_vaults_dir" != "/" ]; do
        [ -f "$_cb_vaults_dir/_meta/agentdb/agent.db" ] && break
        _cb_vaults_dir=$(dirname "$_cb_vaults_dir")
      done
      local _cb_agentdb="$_cb_vaults_dir/.claude/kernel/orchestration/agentdb/agentdb"
      [ ! -f "$_cb_agentdb" ] && _cb_agentdb="${_CB_PROJECT_ROOT}/orchestration/agentdb/agentdb"
      "$_cb_agentdb" emit hook "$HOOK_NAME" "$_cb_duration" "{\"exit_code\":0}" "" "" 2>/dev/null &
    fi
  fi
}

# Timing capture (lightweight, no dependencies)
_CB_START_MS=$(python3 -c 'import time; print(int(time.time()*1000))' 2>/dev/null || echo "")

trap '_cb_record_failure' ERR
