---
trigger: After Write tool use (file created or modified)
---

# Post-Write Hook

When a file is written:

1. Check `kernel/state.md` tooling inventory for formatter
2. If formatter exists and status is "✓ available":
   - Offer: "Format [filename] with [formatter]? [y/n]"
   - On confirm: Run formatter command
   - On reject: Skip
3. If formatter unknown or unchecked: Skip (no offer)

Never auto-format. Always offer first.
