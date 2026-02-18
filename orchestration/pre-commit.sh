#!/usr/bin/env bash
# pre-commit.sh — git pre-commit hook
# Runs agentdb checkpoint, validates no secrets in staged files.
# Install: ln -sf "$(pwd)/orchestration/pre-commit.sh" .git/hooks/pre-commit

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"

# 1. AgentDB checkpoint
if command -v agentdb &>/dev/null; then
  agentdb checkpoint "pre-commit: $(git diff --cached --name-only | head -5 | tr '\n' ' ')" 2>/dev/null || true
fi

# 2. Secret scan on staged files
STAGED_FILES="$(git diff --cached --name-only --diff-filter=ACM)"

if [ -z "$STAGED_FILES" ]; then
  exit 0
fi

SECRET_PATTERNS='(API_KEY|SECRET|TOKEN|PASSWORD|PRIVATE_KEY|AWS_ACCESS|STRIPE_|OPENAI_API)\s*[=:]\s*["\047]?[A-Za-z0-9+/._-]{8,}'

FOUND=0
while IFS= read -r file; do
  [ -z "$file" ] && continue
  if git show ":$file" 2>/dev/null | grep -qEi "$SECRET_PATTERNS"; then
    echo "BLOCKED: potential secret in staged file: $file"
    FOUND=1
  fi
done <<< "$STAGED_FILES"

if [ "$FOUND" -eq 1 ]; then
  echo "Pre-commit hook blocked commit. Remove secrets before committing."
  exit 1
fi

exit 0
