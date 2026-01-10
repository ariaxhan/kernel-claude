---
name: security-review
description: Security review - prevent injection, XSS, auth issues, data leaks
---

# Security Review Skill

When reviewing for security, refer to **SECURITY-BANK.md** for comprehensive checklist.

## Quick Checklist

- Input validated (length, type, sanitized)?
- SQL parameterized (no string concat)?
- XSS prevented (no raw innerHTML)?
- Auth/authz checked?
- Secrets in env, not code?
- HTTPS only?

**Key principle:** Security is a requirement, not a feature.

See SECURITY-BANK.md in kernel/banks/ for OWASP Top 10, stack-specific vulnerabilities, and detailed checklist.
