---
type: chronicle
status: active
created: 2026-08-29
---

# Keychain egress policing removed

**What mattered:** guard-bash.sh blocked Supabase password login because password grants place a keychain value in the request body. Keychain egress policing is removed; literal-secret and credential-file guards remain.

**Shipped**
- Draft PR #233: keychain branch removed; focused allow/deny regressions retained.

**Verified how:** full tests/run-tests.sh all: 495/495; branch state only.

**Wrong or surprising**
- First two regressions used invalid helper JSON and falsely passed; corrected tests then failed red before the fix.

**Open:** Restart active Codex sessions, bump 9.6.7, rerun gates, independent safety review, mark PR #233 ready.
