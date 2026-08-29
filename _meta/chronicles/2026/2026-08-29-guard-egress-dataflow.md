---
type: chronicle
status: active
created: 2026-08-29
---

# Keychain egress now follows the secret, not nearby words

**What mattered:** guard-bash.sh rejected unrelated request bodies, search text, and .sh data-heredoc targets. The guard now blocks proven keychain flow while permitting operational auth.

**Shipped**
- Working branch fix/guard-egress-dataflow: guard + seven focused regressions.

**Verified how:** full tests/run-tests.sh all: 502/502; branch state only.

**Wrong or surprising**
- First two regressions used invalid helper JSON and falsely passed; corrected tests then failed red before the fix.

**Open:** Independent safety review, merge to main, then release outside the active-session release guard.
