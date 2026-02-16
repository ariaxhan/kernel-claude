# Invariants

**Non-negotiable contracts: security, data integrity, interface stability**

<!--
TO EVOLVE: Add invariants as they're discovered, not assumed.
Examples:
- Auth tokens never logged (security)
- User IDs are UUIDs, never change (data integrity)
- API returns 200/400/500 only, never 300s (interface stability)
- Database writes always use transactions (data integrity)
- Passwords hashed with bcrypt, min 10 rounds (security)

Add only when confirmed via code review or architecture discussion.
Max 15 bullets. If full, consolidate or move to separate doc.
Violations of invariants should block merges.
-->

---

⚠️ **TEMPLATE NOTICE**
This file starts empty and grows from discovered non-negotiable contracts.
Invariants are critical - they must not be violated.
Check this file during code review. Violations = block merge.
