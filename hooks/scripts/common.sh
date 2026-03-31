#!/bin/bash
# KERNEL: Shared functions for hooks
# Source this at the top of hook scripts: source "$(dirname "$0")/common.sh"

# Dependency check: jq is required by most hooks for JSON parsing
command -v jq >/dev/null 2>&1 || { echo "Warning: jq not found, some hooks may not work" >&2; }

# Auto-update current symlink to latest version (fixes stale hook issue)
# Claude Code downloads new versions AFTER session-start hooks run,
# so we check on every hook invocation (throttled to once per 60s).
# Uses BASH_SOURCE[0] (common.sh itself) to find cache dir reliably,
# regardless of call depth or caller location.
update_current_symlink() {
  # common.sh lives at {cache}/{version}/hooks/scripts/common.sh
  # So 3 levels up from common.sh = the plugin parent dir (e.g. kernel/)
  local COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local CACHE_DIR="$(cd "$COMMON_DIR/../../.." && pwd)"

  # Only run if we're in the plugin cache (not dev mode)
  [[ "$CACHE_DIR" == *"plugins/cache"* ]] || return 0

  # Throttle: skip if checked within last 60 seconds
  local STAMP="$CACHE_DIR/.update_checked"
  if [ -f "$STAMP" ]; then
    local stamp_age
    stamp_age=$(( $(date +%s) - $(stat -f %m "$STAMP" 2>/dev/null || stat -c %Y "$STAMP" 2>/dev/null || echo 0) ))
    [ "$stamp_age" -lt 60 ] && return 0
  fi
  touch "$STAMP" 2>/dev/null || true

  local LATEST
  LATEST=$(ls -d "$CACHE_DIR"/[0-9]*/ 2>/dev/null \
    | xargs -n1 basename 2>/dev/null \
    | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' \
    | sort -t. -k1,1n -k2,2n -k3,3n \
    | tail -1 || true)

  [ -z "$LATEST" ] && return 0

  # Check if current symlink needs updating
  local CURRENT_TARGET
  CURRENT_TARGET=$(readlink "$CACHE_DIR/current" 2>/dev/null | xargs basename 2>/dev/null || true)

  if [ "$CURRENT_TARGET" != "$LATEST" ]; then
    ln -sfn "$CACHE_DIR/$LATEST" "$CACHE_DIR/current" 2>/dev/null && \
      echo "**KERNEL auto-updated:** ${CURRENT_TARGET:-none} → $LATEST"
  fi
}

# Detect Vaults location - env var takes priority, then checks filesystem
detect_vaults() {
  # Explicit override always wins (for testing + custom setups)
  if [ -n "${KERNEL_VAULTS:-}" ] && [ -d "${KERNEL_VAULTS:-}" ]; then
    echo "$KERNEL_VAULTS"
  elif [ -f "$HOME/Vaults/_meta/agentdb/agent.db" ]; then
    echo "$HOME/Vaults"
  elif [ -f "$HOME/Downloads/Vaults/_meta/agentdb/agent.db" ]; then
    echo "$HOME/Downloads/Vaults"
  else
    echo "$HOME/Vaults"
  fi
}

# Get agentdb CLI path - finds binary via symlink or plugin root
get_agentdb() {
  local VAULTS="$1"
  local AGENTDB="$VAULTS/.claude/kernel/orchestration/agentdb/agentdb"

  if [ ! -f "$AGENTDB" ]; then
    local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
    local PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
    AGENTDB="${PLUGIN_ROOT}/orchestration/agentdb/agentdb"
  fi

  echo "$AGENTDB"
}

# Get project root - uses CLAUDE_PROJECT_DIR or git root
get_project_root() {
  echo "${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
}

# === Hook Telemetry ===
# Lightweight timing for hook execution. Fire-and-forget.
# Usage: _kernel_hook_start at top, _kernel_hook_end at bottom.

_KERNEL_HOOK_START_MS=""

_kernel_hook_start() {
  # macOS date doesn't support %N, use python for ms precision
  _KERNEL_HOOK_START_MS=$(python3 -c 'import time; print(int(time.time()*1000))' 2>/dev/null || echo "")
  # Check for plugin updates on every hook (throttled to 60s in the function)
  update_current_symlink 2>/dev/null || true
}

_kernel_hook_end() {
  local hook_name="${1:-unknown}"
  local exit_code="${2:-0}"
  [ -z "$_KERNEL_HOOK_START_MS" ] && return
  local end_ms
  end_ms=$(python3 -c 'import time; print(int(time.time()*1000))' 2>/dev/null || return)
  local duration_ms=$(( end_ms - _KERNEL_HOOK_START_MS ))
  local vaults
  vaults=$(detect_vaults)
  local agentdb
  agentdb=$(get_agentdb "$vaults")
  # Fire-and-forget: never block hook on telemetry
  "$agentdb" emit hook "$hook_name" "$duration_ms" "{\"exit_code\":$exit_code}" "" "" 2>/dev/null &
}

# === Project Profile Detection ===
# Gates feature complexity: local projects get minimal overhead,
# OSS/production projects get full GitHub integration.

# Parse owner/repo from any GitHub remote URL format
# Handles: HTTPS, SSH (git@), SSH (ssh://), with/without .git suffix
parse_github_remote() {
  local url="$1"
  echo "$url" | grep -qi "github\.com" || return 0
  echo "$url" | sed -E 's#^(https?://|git@|ssh://git@)github\.com[:/]##; s/\.git$//'
}

# Pure classification — no side effects, fully testable
# Args: is_github visibility collab_count env_count has_projects
classify_profile() {
  local is_github="${1:-false}"
  local visibility="${2:-unknown}"
  local collab_count="${3:-0}"
  local env_count="${4:-0}"
  local has_projects="${5:-false}"

  [[ "$is_github" != "true" ]] && echo "local" && return

  if [[ "$collab_count" -gt 2 ]] || [[ "$env_count" -gt 0 ]] || [[ "$has_projects" == "true" ]]; then
    echo "github-production"
    return
  fi

  [[ "$visibility" == "public" ]] && echo "github-oss" && return
  echo "github"
}

# Full detection with API calls, caching, timeout protection
# Returns: local | github | github-oss | github-production
detect_profile() {
  local project_root="${1:-$(get_project_root)}"

  local cache_dir="$HOME/.cache/kernel"
  mkdir -p "$cache_dir" 2>/dev/null || cache_dir="/tmp"

  local remote_url
  remote_url=$(cd "$project_root" && git remote get-url origin 2>/dev/null) || true

  if [[ -z "${remote_url:-}" ]]; then
    echo "local"
    return
  fi

  # Hash-based cache key (works across projects)
  local repo_hash
  repo_hash=$(echo "$remote_url" | md5 2>/dev/null || echo "$remote_url" | md5sum 2>/dev/null | cut -d' ' -f1)
  local cache_file="$cache_dir/profile-${repo_hash}"

  if [[ -f "$cache_file" ]]; then
    local cache_age
    cache_age=$(( $(date +%s) - $(stat -f %m "$cache_file" 2>/dev/null || stat -c %Y "$cache_file" 2>/dev/null || echo 0) ))
    if [[ "$cache_age" -lt 3600 ]]; then
      cat "$cache_file"
      return
    fi
  fi

  local owner_repo
  owner_repo=$(parse_github_remote "$remote_url")
  if [[ -z "${owner_repo:-}" ]]; then
    echo "local"
    return
  fi

  local is_github="true"
  local visibility="unknown"
  local collab_count=0
  local env_count=0
  local has_projects="false"

  # API calls — all failure-safe with 5s timeout
  if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    local repo_json
    repo_json=$(GH_HTTP_TIMEOUT=5 gh api "repos/${owner_repo}" --cache 3600s 2>/dev/null) || true

    if [[ -n "${repo_json:-}" ]]; then
      visibility=$(echo "$repo_json" | jq -r '.visibility // "unknown"' 2>/dev/null) || true
      visibility="${visibility:-unknown}"

      collab_count=$(GH_HTTP_TIMEOUT=5 gh api "repos/${owner_repo}/collaborators" --jq 'length' --cache 3600s 2>/dev/null) || true
      [[ "${collab_count:-}" =~ ^[0-9]+$ ]] || collab_count=0

      env_count=$(GH_HTTP_TIMEOUT=5 gh api "repos/${owner_repo}/environments" --jq '.total_count // 0' --cache 3600s 2>/dev/null) || true
      [[ "${env_count:-}" =~ ^[0-9]+$ ]] || env_count=0

      local project_count
      project_count=$(GH_HTTP_TIMEOUT=5 gh api graphql -f query='query($owner:String!,$repo:String!){repository(owner:$owner,name:$repo){projectsV2(first:1){totalCount}}}' -f owner="${owner_repo%%/*}" -f repo="${owner_repo##*/}" --jq '.data.repository.projectsV2.totalCount // 0' 2>/dev/null) || true
      # Validate numeric — graphql errors return JSON strings that break arithmetic
      [[ "${project_count:-0}" =~ ^[0-9]+$ ]] && [[ "$project_count" -gt 0 ]] && has_projects="true"
    fi
  fi

  local profile
  profile=$(classify_profile "$is_github" "$visibility" "$collab_count" "$env_count" "$has_projects")

  # Atomic cache write
  local tmp_cache
  tmp_cache=$(mktemp "${cache_dir}/profile-tmp-XXXXXX" 2>/dev/null) || tmp_cache="${cache_dir}/profile-tmp-$$"
  echo "$profile" > "$tmp_cache"
  mv "$tmp_cache" "$cache_file" 2>/dev/null || true

  echo "$profile"
}
