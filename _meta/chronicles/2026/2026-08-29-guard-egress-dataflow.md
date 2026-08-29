---
type: chronicle
status: active
created: 2026-08-29
---

# Keychain egress policing removed

**What mattered:** guard-bash.sh blocked Supabase password login because password grants place a keychain value in the request body. Keychain egress policing is removed; literal-secret and credential-file guards remain.

**Shipped**
- Draft PR #233: keychain branch removed; focused allow/deny regressions retained.

**Verified how:** full tests/run-tests.sh all: 495/495 before independent review; focused security_hooks: 134/134 after repair; branch state only.

**Wrong or surprising**
- First two regressions used invalid helper JSON and falsely passed; corrected tests then failed red before the fix.
- Independent review caught `bash<<EOF` escaping heredoc code scanning; repaired the executor regex and added a regression.

**Open:** Restart active Codex sessions, bump 9.6.7, rerun gates, independent safety review, mark PR #233 ready.

**Round 2 (same day)**
- Adversary (opus, outcome axis) on 45a7aca: backtick or brace before the executor (`X=\`bash<<EOF\``) still stripped the body as data. Fixed 945cf39, two regressions added, security_hooks 136/136.
- Pre-existing, not gated here: `cat <<EOF | bash` and write-then-execute heredocs bypass the executor regex; `<<"EOF"` data heredocs false-block. Tracked in agentdb.
