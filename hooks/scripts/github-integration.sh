#!/bin/bash
set -eo pipefail
# KERNEL: GitHub integration library (sourced, not executed directly)
# Provides functions for Issues, Discussions, and labels.
# Profile-gated: local profiles get NO GitHub operations.
# AgentDB always runs; GitHub is additive visibility.

# Load shared functions
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# === Cached state (populated on first use) ===
_GH_REPO=""
_GH_REPO_ID=""
_GH_LABELS_ENSURED=""

# Discussion category IDs (resolved dynamically, cached after first lookup)
_GH_CAT_AGENT_LOGS=""
_GH_CAT_DECISIONS=""
_GH_CAT_LEARNINGS=""
_GH_CATS_RESOLVED=""

# === Internal helpers ===

# Derive owner/repo from git remote (cached after first call)
_gh_repo() {
  if [[ -n "$_GH_REPO" ]]; then
    echo "$_GH_REPO"
    return
  fi
  local remote
  remote=$(git remote get-url origin 2>/dev/null) || return 1
  local repo
  repo=$(parse_github_remote "$remote")
  [[ -z "${repo:-}" ]] && return 1
  _GH_REPO="$repo"
  echo "$_GH_REPO"
}

# Get repo node ID (cached, needed for GraphQL mutations)
_gh_repo_id() {
  if [[ -n "$_GH_REPO_ID" ]]; then
    echo "$_GH_REPO_ID"
    return
  fi
  local repo
  repo=$(_gh_repo) || return 1
  _GH_REPO_ID=$(gh api "repos/${repo}" --jq '.node_id' --cache 3600s 2>/dev/null) || return 1
  echo "$_GH_REPO_ID"
}

# === Core gate ===

# Returns 0 if gh CLI installed, authenticated, and profile is NOT local.
# All public functions call this first; return silently (0) if false.
_gh_available() {
  command -v gh >/dev/null 2>&1 || return 1
  gh auth status >/dev/null 2>&1 || return 1
  local profile
  profile=$(_gh_get_profile)
  [[ "$profile" == "local" ]] && return 1
  return 0
}

# Read cached profile. Does NOT call detect_profile (expensive).
# Falls back to "local" if no cache found.
_gh_get_profile() {
  local cache_dir="$HOME/.cache/kernel"
  if [[ -d "$cache_dir" ]]; then
    local latest
    latest=$(ls -t "$cache_dir"/profile-* 2>/dev/null | head -1)
    if [[ -n "${latest:-}" ]] && [[ -f "$latest" ]]; then
      cat "$latest"
      return
    fi
  fi
  echo "local"
}

# === Label management ===

# Creates agent/tier labels if they don't exist. Idempotent. Once per session.
_gh_ensure_labels() {
  _gh_available || return 0
  [[ -n "$_GH_LABELS_ENSURED" ]] && return 0

  local repo
  repo=$(_gh_repo) || return 0

  local labels=(
    "agent-contract:#1d76db"
    "tier-1:#0e8a16"
    "tier-2:#fbca04"
    "tier-3:#d93f0b"
    "agent:surgeon:#6f42c1"
    "agent:adversary:#b60205"
    "agent:researcher:#0075ca"
    "agent:dreamer:#e4e669"
  )

  # Fetch existing labels once
  local existing
  existing=$(gh api "repos/${repo}/labels" --paginate --jq '.[].name' --cache 300s 2>/dev/null) || existing=""

  for entry in "${labels[@]}"; do
    local name="${entry%%:*}"
    local color="${entry#*:}"
    color="${color#\#}"  # strip leading #

    if ! echo "$existing" | grep -qxF "$name"; then
      gh api "repos/${repo}/labels" \
        -f name="$name" \
        -f color="$color" \
        -f description="KERNEL auto-managed" \
        2>/dev/null || true
    fi
  done

  _GH_LABELS_ENSURED="1"
  return 0
}

# === Issues ===

# Create a GitHub Issue. Returns issue number on stdout.
# Args: title body labels(comma-separated)
_gh_create_issue() {
  _gh_available || return 0
  local title="${1:-}" body="${2:-}" labels
  labels="${3:-}"
  [[ -z "$title" ]] && return 0

  local repo
  repo=$(_gh_repo) || return 0

  local args=("issue" "create" "-R" "$repo" "--title" "$title" "--body" "${body:-}")
  [[ -n "${labels:-}" ]] && args+=("--label" "${labels}")

  local url
  url=$(gh "${args[@]}" 2>/dev/null) || return 0
  # Extract issue number from URL
  echo "$url" | grep -oE '[0-9]+$'
  return 0
}

# Add comment to existing issue.
# Args: issue_number body
_gh_comment_issue() {
  _gh_available || return 0
  local issue="${1:-}" body="${2:-}"
  [[ -z "$issue" || -z "$body" ]] && return 0

  local repo
  repo=$(_gh_repo) || return 0

  gh issue comment "$issue" -R "$repo" --body "$body" 2>/dev/null || true
  return 0
}

# Close issue with final comment.
# Args: issue_number comment
_gh_close_issue() {
  _gh_available || return 0
  local issue="${1:-}" comment="${2:-}"
  [[ -z "$issue" ]] && return 0

  local repo
  repo=$(_gh_repo) || return 0

  [[ -n "$comment" ]] && gh issue comment "$issue" -R "$repo" --body "$comment" 2>/dev/null || true
  gh issue close "$issue" -R "$repo" 2>/dev/null || true
  return 0
}

# === Discussion category resolution ===

# Resolve discussion category IDs from repo (cached after first call)
_gh_resolve_categories() {
  [[ -n "$_GH_CATS_RESOLVED" ]] && return 0
  local repo
  repo=$(_gh_repo) || return 1
  local owner="${repo%%/*}" name="${repo##*/}"

  local cats_json
  cats_json=$(gh api graphql -f query='
    query($owner: String!, $name: String!) {
      repository(owner: $owner, name: $name) {
        discussionCategories(first: 20) { nodes { id name } }
      }
    }' -f owner="$owner" -f name="$name" \
    --jq '.data.repository.discussionCategories.nodes' \
    --cache 3600s 2>/dev/null) || return 1

  _GH_CAT_AGENT_LOGS=$(echo "$cats_json" | jq -r '.[] | select(.name == "Agent Logs") | .id' 2>/dev/null)
  _GH_CAT_DECISIONS=$(echo "$cats_json" | jq -r '.[] | select(.name == "Decisions") | .id' 2>/dev/null)
  _GH_CAT_LEARNINGS=$(echo "$cats_json" | jq -r '.[] | select(.name == "Learnings") | .id' 2>/dev/null)
  _GH_CATS_RESOLVED="1"
  return 0
}

# === Discussions (GraphQL) ===

# Create a Discussion via GraphQL. Returns discussion URL.
# Args: category_id title body
_gh_post_discussion() {
  _gh_available || return 0
  _gh_resolve_categories || return 0
  local category_id="${1:-}" title="${2:-}" body="${3:-}"
  [[ -z "$category_id" || -z "$title" ]] && return 0

  local repo_id
  repo_id=$(_gh_repo_id) || return 0

  local result
  result=$(gh api graphql -f query='
    mutation($repoId: ID!, $catId: ID!, $title: String!, $body: String!) {
      createDiscussion(input: {
        repositoryId: $repoId,
        categoryId: $catId,
        title: $title,
        body: $body
      }) {
        discussion { url }
      }
    }' \
    -f repoId="$repo_id" \
    -f catId="$category_id" \
    -f title="$title" \
    -f body="${body:-}" \
    --jq '.data.createDiscussion.discussion.url' \
    2>/dev/null) || return 0

  echo "$result"
  return 0
}

# === High-level posting functions ===

# Agent personality voice hints for session summaries
_gh_agent_voice() {
  case "${1:-}" in
    surgeon)    echo "Minimal diff. In and out." ;;
    adversary)  echo "Assumed broken until proven otherwise." ;;
    researcher) echo "Searched before building." ;;
    dreamer)    echo "Explored the edges." ;;
    *)          echo "Session complete." ;;
  esac
}

# Post formatted session summary to Agent Logs.
# Args: agent_name branch did learned next
_gh_post_session_summary() {
  _gh_available || return 0
  local agent="${1:-unknown}" branch="${2:-main}"
  local did="${3:-}" learned="${4:-}" next="${5:-}"

  local voice
  voice=$(_gh_agent_voice "$agent")
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  local body
  body=$(cat <<EOF
## Session Summary: \`${agent}\`

> _${voice}_

**Branch:** \`${branch}\`
**Timestamp:** ${timestamp}

### What was done
${did:-Nothing recorded.}

### What was learned
${learned:-Nothing new.}

### What's next
${next:-No follow-up identified.}
EOF
)

  _gh_post_discussion "$_GH_CAT_AGENT_LOGS" "Session: ${agent} @ ${branch} ($(date +%Y-%m-%d))" "$body" &
  return 0
}

# Post high-hit learning to Learnings discussion category.
# Args: insight evidence hit_count
_gh_post_learning() {
  _gh_available || return 0
  local insight="${1:-}" evidence="${2:-}" hit_count="${3:-1}"
  [[ -z "$insight" ]] && return 0

  local body
  body=$(cat <<EOF
## Learning

**Insight:** ${insight}
**Hit count:** ${hit_count}

### Evidence
${evidence:-No evidence provided.}

---
_Auto-posted by KERNEL when hit_count >= threshold._
EOF
)

  _gh_post_discussion "$_GH_CAT_LEARNINGS" "Learning: ${insight%%. *}" "$body" &
  return 0
}

# Post to Decisions discussion category.
# Args: title body
_gh_post_decision() {
  _gh_available || return 0
  local title="${1:-}" body="${2:-}"
  [[ -z "$title" ]] && return 0

  _gh_post_discussion "$_GH_CAT_DECISIONS" "$title" "$body" &
  return 0
}

# Post handoff to Agent Logs discussion category.
# Args: title body
_gh_post_handoff() {
  _gh_available || return 0
  local title="${1:-}" body="${2:-}"
  [[ -z "$title" ]] && return 0

  local body_with_meta
  body_with_meta=$(cat <<EOF
## Handoff

${body:-No details provided.}

---
_Posted: $(date -u +"%Y-%m-%dT%H:%M:%SZ")_
EOF
)

  _gh_post_discussion "$_GH_CAT_AGENT_LOGS" "Handoff: ${title}" "$body_with_meta" &
  return 0
}
