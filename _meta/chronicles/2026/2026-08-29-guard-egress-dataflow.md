---
type: chronicle
status: active
created: 2026-08-29
---

# Keychain egress policing removed

**What mattered:** guard-bash.sh blocked Supabase password login because password grants place a keychain value in the request body. Keychain egress policing is removed; literal-secret and credential-file guards remain.

**Shipped**
- Working branch fix/guard-egress-dataflow: keychain branch removed; focused allow/deny regressions retained.

**Verified how:** full tests/run-tests.sh all: 495/495; branch state only.

**Wrong or surprising**
- First two regressions used invalid helper JSON and falsely passed; corrected tests then failed red before the fix.

**Open:** Independent safety review, merge to main, then release outside the active-session release guard.
