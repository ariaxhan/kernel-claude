#!/bin/bash
# KERNEL: Shared functions for hooks
# Source this at the top of hook scripts: source "$(dirname "$0")/common.sh"

# Dependency check: jq is required by most hooks for JSON parsing
command -v jq >/dev/null 2>&1 || { echo "Warning: jq not found, some hooks may not work" >&2; }

# Runtime selection is based on the plugin Claude Code actually loaded. A cache
# directory that merely has the largest number is not proof that it is active.
kernel_loaded_root() {
  if [ -n "${KERNEL_RUNTIME_ROOT:-}" ]; then
    printf '%s\n' "$KERNEL_RUNTIME_ROOT"
  elif [ -n "${KERNEL_LOADED_ROOT:-}" ]; then
    printf '%s\n' "$KERNEL_LOADED_ROOT"
  else
    local common_dir
    common_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd) || return 1
    (cd "$common_dir/../.." && pwd)
  fi
}

kernel_cache_dir() {
  printf '%s\n' "${KERNEL_CACHE_DIR:-$HOME/.claude/plugins/cache/kernel-marketplace/kernel}"
}

kernel_semver() { [[ "$1" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]; }

kernel_validate_runtime_root() {
  local root="$1" manifest="$1/.claude-plugin/plugin.json" version base
  [ -d "$root" ] && [ -f "$manifest" ] && [ -f "$root/hooks/scripts/common.sh" ] && \
    [ -f "$root/orchestration/agentdb/agentdb" ] || return 1
  version=$(jq -er '.version | select(type == "string")' "$manifest" 2>/dev/null) || return 1
  [ "$(jq -er '.name' "$manifest" 2>/dev/null)" = kernel ] || return 1
  kernel_semver "$version" || return 1
  base=${root%/}; base=${base##*/}
  case "$root" in
    */plugins/cache/kernel-marketplace/kernel/*) [ "$base" = "$version" ] || return 1 ;;
  esac
  printf '%s\n' "$version"
}

kernel_version_lt() {
  [ "$(printf '%s\n%s\n' "$1" "$2" | sort -t. -k1,1n -k2,2n -k3,3n | head -1)" = "$1" ] && [ "$1" != "$2" ]
}

kernel_atomic_link() {
  local target="$1" dest="$2" tmp
  tmp="${dest}.kernel-tmp.$$.$RANDOM"
  [ -e "$tmp" ] || [ -L "$tmp" ] && return 1
  ln -s "$target" "$tmp" || return 1
  if [ "${KERNEL_ATOMIC_LINK_FAIL:-0}" = 1 ]; then rm -f "$tmp"; return 1; fi
  python3 - "$tmp" "$dest" <<'PY' || { rm -f "$tmp"; return 1; }
import os, sys
os.replace(sys.argv[1], sys.argv[2])
PY
}

kernel_update_current() {
  local root cache current current_root new_version current_version explicit=0
  root=$(kernel_loaded_root) || return 1
  new_version=$(kernel_validate_runtime_root "$root") || { echo "kernel: refusing invalid runtime root: $root" >&2; return 1; }
  cache=$(kernel_cache_dir); current="$cache/current"
  [ -n "${KERNEL_RUNTIME_ROOT:-}" ] && explicit=1
  mkdir -p "$cache" 2>/dev/null || return 1
  if [ -L "$current" ]; then
    current_root=$(readlink "$current")
    case "$current_root" in /*) ;; *) current_root="$cache/$current_root" ;; esac
    current_version=$(kernel_validate_runtime_root "$current_root" 2>/dev/null || true)
    [ "$current_root" = "$root" ] && return 0
    if [ "$explicit" -eq 0 ] && [ -n "$current_version" ] && kernel_version_lt "$new_version" "$current_version"; then
      return 0
    fi
  elif [ -e "$current" ]; then
    echo "kernel: refusing non-symlink runtime selector: $current" >&2; return 1
  fi
  kernel_atomic_link "$root" "$current" || { echo "kernel: could not update runtime selector: $current" >&2; return 1; }
  echo "KERNEL runtime selected: $new_version"
}

kernel_lexical_target() {
  python3 - "$1" "$2" <<'PY'
import os, sys
target, dest = sys.argv[1:]
if "\n" in target or "\r" in target or "\0" in target:
    raise SystemExit(1)
print(os.path.normpath(target if os.path.isabs(target) else os.path.join(os.path.dirname(dest), target)))
PY
}

kernel_owned_numbered_target() {
  python3 - "$1" "$2" "$3" <<'PY'
import os, re, sys
target, cache, suffix = map(os.path.normpath, sys.argv[1:])
prefix = cache + os.sep
if not target.startswith(prefix):
    raise SystemExit(1)
rest = target[len(prefix):].split(os.sep)
expected = suffix.split(os.sep)
if len(rest) != len(expected) + 1 or rest[1:] != expected:
    raise SystemExit(1)
if not re.fullmatch(r'(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)', rest[0]):
    raise SystemExit(1)
PY
}

kernel_repair_host_link() {
  local dest="$1" wanted="$2" cache="$3" suffix="$4" raw lexical
  if [ ! -e "$dest" ] && [ ! -L "$dest" ]; then return 0; fi
  if [ ! -L "$dest" ]; then
    echo "kernel: kept user-owned path $dest; run /kernel:init to resolve it" >&2; return 1
  fi
  raw=$(readlink "$dest") || return 1
  lexical=$(kernel_lexical_target "$raw" "$dest") || {
    echo "kernel: kept malformed link $dest; run /kernel:init to resolve it" >&2; return 1;
  }
  [ "$lexical" = "$wanted" ] && return 0
  if kernel_owned_numbered_target "$lexical" "$cache" "$suffix"; then
    kernel_atomic_link "$wanted" "$dest" || {
      echo "kernel: could not repair $dest; run /kernel:init" >&2; return 1;
    }
    echo "KERNEL repaired helper link: $dest"
    return 0
  fi
  echo "kernel: kept unrelated link $dest; run /kernel:init to resolve it" >&2
  return 1
}

kernel_init_host_link() {
  local dest="$1" wanted="$2" cache="$3" suffix="$4"
  if [ ! -e "$dest" ] && [ ! -L "$dest" ]; then
    mkdir -p "$(dirname "$dest")" || return 1
    kernel_atomic_link "$wanted" "$dest" || return 1
    echo "KERNEL created helper link: $dest"
    return 0
  fi
  kernel_repair_host_link "$dest" "$wanted" "$cache" "$suffix"
}

kernel_reconcile_runtime() {
  local vaults="$1" cache rc=0
  cache=$(kernel_cache_dir)
  kernel_update_current || rc=1
  kernel_repair_host_link "$vaults/.local/bin/agentdb" "$cache/current/orchestration/agentdb/agentdb" "$cache" "orchestration/agentdb/agentdb" || rc=1
  kernel_repair_host_link "$vaults/.claude/kernel/orchestration" "$cache/current/orchestration" "$cache" "orchestration" || rc=1
  kernel_repair_host_link "$vaults/.claude/kernel/hooks" "$cache/current/hooks" "$cache" "hooks" || rc=1
  return "$rc"
}

# Backward-compatible internal name used by existing checks.
update_current_symlink() { kernel_update_current; }

# Detect Vaults location - env var takes priority, then checks filesystem
detect_vaults() {
  # Explicit override always wins (for testing + custom setups)
  if [ -n "${KERNEL_VAULTS:-}" ] && [ -d "${KERNEL_VAULTS:-}" ]; then
    echo "$KERNEL_VAULTS"
  elif [ -f "$HOME/Documents/Vaults/_meta/agentdb/agent.db" ]; then
    echo "$HOME/Documents/Vaults"
  elif [ -f "$HOME/Vaults/_meta/agentdb/agent.db" ]; then
    echo "$HOME/Vaults"
  elif [ -f "$HOME/Downloads/Vaults/_meta/agentdb/agent.db" ]; then
    echo "$HOME/Downloads/Vaults"
  else
    # Canonical default. The fallback must point at the real vault: a bare
    # "$HOME/Vaults" default silently grew a stray tree of orphaned agent
    # registrations after the machine migration moved the vault to
    # ~/Documents/Vaults (and broke session identity + checkpoints for weeks).
    # Degradation must self-report: nothing matched, so say so on stderr.
    echo "kernel: no vault detected; falling back to $HOME/Documents/Vaults (set KERNEL_VAULTS to override)" >&2
    echo "$HOME/Documents/Vaults"
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
  # Keep the selector and the three known KERNEL helper links aligned. Refusals
  # are warnings: hooks continue, but mixed-version risk is never hidden.
  kernel_reconcile_runtime "$(detect_vaults)" || true
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
  # Read session_id from persisted file (written by session-start.sh)
  local session_id
  local project_root
  project_root=$(get_project_root)
  session_id=$(cat "$project_root/_meta/.session_id" 2>/dev/null || echo "")
  # Fire-and-forget: never block hook on telemetry
  "$agentdb" emit hook "$hook_name" "$duration_ms" "{\"exit_code\":$exit_code}" "" "$session_id" 2>/dev/null &
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

# Pure classification, no side effects, fully testable
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

  # API calls, all failure-safe with 5s timeout
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
      # Validate numeric, graphql errors return JSON strings that break arithmetic
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
