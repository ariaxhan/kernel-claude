---
type: chronicle
status: active
created: 2026-08-28
---

# A bracketed context label broke Codex UserPromptSubmit

**What mattered:** Codex parses stdout beginning with `[` as structured JSON. The context meter emitted `[context] ...`, causing the exact invalid-JSON hook failure.

**Shipped**
- 9.6.5 release candidate: hook fix, compression-protocol regression, generated manifests, and release metadata.

**Verified how:** Hook regression failed before the fix. Compression regression failed after its silence rule was removed in an isolated copy. Full suite: 494 passed; seeded audit: 16/16. Fresh Opus verifier reviewed the original hook fix: APPROVE.

**Wrong or surprising**
- Plain hook context is accepted unless its first non-whitespace byte is `[` or `{`; those sigils switch Codex into structured-output parsing.

**Open:** Push and tag 9.6.5, upgrade Claude and Codex, restart live sessions, then prove the installed payload no longer emits the failure.
