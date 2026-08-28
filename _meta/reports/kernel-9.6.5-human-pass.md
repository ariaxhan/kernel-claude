---
type: report
status: active
created: 2026-08-28
---

# Kernel 9.6.5 hook acceptance

**Time:** one minute after restarting Codex.

1. Send `testing hooks` in a fresh Codex session.
2. Expect no `UserPromptSubmit hook (failed)` notice.
3. Expect the context meter, when shown, to begin `context:` rather than `[context]`.

If hooks exit `127`, that session still points at the removed 9.6.4 cache. Restart it once.
