#!/bin/bash
# PreToolUse hook: Detect secrets in content before writing
# Blocks writes containing API keys, tokens, or credentials
# Events: PreToolUse (matcher: Write|Edit)
#
# Fail-closed by design (I0.15 + "scanner fails -> block"): this is a safety
# gate, so it deliberately does NOT source circuit-breaker.sh -- a security gate
# must always run and must never auto-disable itself. If its JSON parser (jq) is
# unavailable it BLOCKS rather than letting a possible secret through silently.

INPUT=$(cat)

if ! command -v jq >/dev/null 2>&1; then
  echo "BLOCKED: secret scanner cannot run (jq not found). Install jq, or set the secret via an environment variable instead of writing it." >&2
  exit 2
fi

if ! echo "$INPUT" | jq -e 'type == "object" and (.tool_input | type == "object")' >/dev/null 2>&1; then
  echo "BLOCKED: secret scanner received unreadable or malformed hook JSON." >&2
  exit 2
fi

# Claude sends Write/Edit text as content/new_string. Codex maps those hook
# matchers to apply_patch and sends the complete patch in tool_input.patch.
CONTENT=$(echo "$INPUT" | jq -r '
  [.tool_input.content, .tool_input.new_string,
   (if (.tool_input.patch | type) == "string" then
      [.tool_input.patch | split("\n")[] | select(startswith("+"))] | join("\n")
    else empty end)]
  | map(select(type == "string"))
  | join("\n")
')

[ -z "$CONTENT" ] && exit 0

# Secret patterns to detect
PATTERNS=(
  'sk-[a-zA-Z0-9_-]{20,}'                  # OpenAI / Anthropic keys (incl. sk-ant-api03-, sk-proj-; hyphen/underscore allowed)
  'ghp_[a-zA-Z0-9]{36,}'                   # GitHub PATs
  'github_pat_[a-zA-Z0-9_]{20,}'           # GitHub fine-grained PATs
  'AKIA[A-Z0-9]{16}'                       # AWS access keys
  'xox[bpsa]-[a-zA-Z0-9-]+'                # Slack tokens
  'eyJ[a-zA-Z0-9_-]*\.eyJ'                 # JWT tokens
  'sk_live_[a-zA-Z0-9]{24,}'               # Stripe live keys
  'sk_test_[a-zA-Z0-9]{24,}'               # Stripe test keys
  '-----BEGIN (RSA |EC )?PRIVATE KEY-----' # Private keys
  '-----BEGIN CERTIFICATE-----'            # TLS certificates (often bundled with keys)
  'AIza[a-zA-Z0-9_-]{35}'                  # Google/GCP API keys
  'ya29\.[a-zA-Z0-9_-]+'                   # Google OAuth access tokens
  '[a-zA-Z0-9_-]*\.apps\.googleusercontent\.com' # Google OAuth client IDs
  'az[a-zA-Z0-9]{10,}\.[a-zA-Z0-9]{10,}'   # Azure connection strings (partial)
  'AccountKey=[a-zA-Z0-9+/=]{40,}'         # Azure storage account keys
)

for pattern in "${PATTERNS[@]}"; do
  if echo "$CONTENT" | grep -qE -- "$pattern"; then
    echo "BLOCKED: Potential secret detected (pattern: $pattern)" >&2
    echo "Remove the secret before writing. Use environment variables instead." >&2
    exit 2
  fi
done

exit 0
