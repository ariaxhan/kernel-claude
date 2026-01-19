# Bug Memory

Searchable record of bugs encountered and solutions. Check here FIRST when hitting errors.

---

<!--
Entry format:

## [Date] - Bug Title

**Issue:** What went wrong (symptoms, error message)
**Root Cause:** Why it happened
**Solution:** How it was fixed
**Prevention:** How to avoid it next time

Example:

## 2026-01-15 - Timezone offset in date parsing

**Issue:** Dates showing one day behind in UI
**Root Cause:** Date constructor parsing ISO string in local timezone, not UTC
**Solution:** Use `new Date(dateString + 'Z')` or `parseISO` from date-fns
**Prevention:** Always use date-fns for parsing. Added to patterns.md.

-->

---

*Check this file before debugging. The answer might already be here.*
