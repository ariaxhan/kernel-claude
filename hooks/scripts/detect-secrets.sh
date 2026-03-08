#!/bin/bash
# PreToolUse hook: Detect secrets in content before writing
# Blocks writes containing API keys, tokens, or credentials
# Events: PreToolUse (matcher: Write|Edit)

INPUT=$(cat)
CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // .tool_input.new_string // empty')

[ -z "$CONTENT" ] && exit 0

# Secret patterns to detect
PATTERNS=(
  'sk-[a-zA-Z0-9]{20,}'                    # OpenAI API keys
  'sk-proj-[a-zA-Z0-9]{20,}'               # OpenAI project keys
  'ghp_[a-zA-Z0-9]{36,}'                   # GitHub PATs
  'github_pat_[a-zA-Z0-9_]{20,}'           # GitHub fine-grained PATs
  'AKIA[A-Z0-9]{16}'                       # AWS access keys
  'xox[bpsa]-[a-zA-Z0-9-]+'                # Slack tokens
  'eyJ[a-zA-Z0-9_-]*\.eyJ'                 # JWT tokens
  'sk_live_[a-zA-Z0-9]{24,}'               # Stripe live keys
  'sk_test_[a-zA-Z0-9]{24,}'               # Stripe test keys
  '-----BEGIN (RSA |EC )?PRIVATE KEY-----' # Private keys
)

for pattern in "${PATTERNS[@]}"; do
  if echo "$CONTENT" | grep -qE -- "$pattern"; then
    echo "BLOCKED: Potential secret detected (pattern: $pattern)" >&2
    echo "Remove the secret before writing. Use environment variables instead." >&2
    exit 2
  fi
done

exit 0
