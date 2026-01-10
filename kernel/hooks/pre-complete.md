---
trigger: Before marking task complete
---

# Pre-Complete Hook

Before marking a task as done:

1. Check `kernel/state.md` last validation section
2. If validation exists and status is not recent (>1 hour old or "never"):
   - Offer: "Run validation before completing? [y/n]"
   - On confirm: Run validation command from state.md
   - On reject: Skip
3. If no validation in state.md: Skip (no offer)

Never auto-validate. Always offer first.
