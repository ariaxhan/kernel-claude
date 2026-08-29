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
- edge cases: password body, search text, loops, staged files, direct pipes
- error handling: preserve literal-secret and credential-file blocks
- duplication: pass, keychain branch removed
- complexity: pass, 87-line special case deleted

## Verdict: PROCEED

Remove keychain egress policing. Keychain reads are user-authorized credential access; the Bash guard cannot infer whether a password body is a login or exfiltration. Preserve literal-secret, credential-file, approval-store, and destructive-operation guards.

## Checks

1. New false-positive tests fail before implementation, pass after.
2. Existing exfiltration negatives remain green.
3. Real hook payload reproduces both allow and block paths.
