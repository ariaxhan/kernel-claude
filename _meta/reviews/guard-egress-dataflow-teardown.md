---
type: review
status: active
created: 2026-08-29
reviewed: 2026-08-29
tier: 3
scope: 2 source/test files
---

# Tear Down: guard egress dataflow

## Big 5

- input validation: pass, hook input already parsed by `jq`
- edge cases: require unrelated body, search text, loops, staged files, direct pipes
- error handling: preserve fail-closed blocks for proven flow
- duplication: pass, one keychain decision path
- complexity: revise, replace the option allowlist with named-variable flow checks

## Verdict: PROCEED

Block proven keychain-value flow into URL/body/upload/plaintext/raw payload. Allow mere lexical co-occurrence and unrelated payload variables. Preserve approval-store isolation.

## Checks

1. New false-positive tests fail before implementation, pass after.
2. Existing exfiltration negatives remain green.
3. Real hook payload reproduces both allow and block paths.
