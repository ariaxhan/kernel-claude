---
name: security
description: "Security best practices and vulnerability prevention. Input validation, authentication, secrets management, OWASP top 10 awareness. Triggers: security, auth, authentication, secrets, credentials, vulnerability, injection, XSS, CSRF."
allowed-tools: Read, Grep, Bash
---

<skill id="security">

<purpose>
Security is not a feature. It's a constraint on all features.
Never trust user input. Never hardcode secrets. Defense in depth.
45% of AI-generated code contains known security flaws—verify everything.
</purpose>

<prerequisite>
Check for existing security patterns in codebase. Follow them.
Never bypass security checks "for now" or "temporarily."
</prerequisite>

<reference>
Skill-specific: skills/security/reference/security-research.md
</reference>

<core_principles>
1. NO HARDCODED SECRETS: Environment variables or secure vaults only.
2. INPUT VALIDATION: Validate at system boundaries. Reject invalid, don't sanitize.
3. LEAST PRIVILEGE: Minimum access needed. No admin-by-default.
4. DEFENSE IN DEPTH: Multiple layers. Don't rely on single control.
5. FAIL SECURE: Errors should deny access, not grant it.
</core_principles>

<owasp_awareness>
Top vulnerabilities to prevent:
- Injection (SQL, command, LDAP) → parameterized queries, never string concat
- Broken auth → secure session management, MFA where possible
- Sensitive data exposure → encrypt at rest and in transit
- XSS → output encoding, CSP headers
- CSRF → tokens for state-changing requests
- Security misconfiguration → secure defaults, minimal exposure
</owasp_awareness>

<secrets_checklist>
Before commit:
- [ ] No API keys in code
- [ ] No passwords in code
- [ ] No connection strings with credentials
- [ ] No private keys in repo
- [ ] .env files in .gitignore
- [ ] Secrets in environment variables or vault
</secrets_checklist>

<anti_patterns>
- "We'll add security later" (you won't)
- Disabling security for development (gets shipped)
- Rolling your own crypto (use established libraries)
- Security through obscurity (it's not security)
- Trusting client-side validation alone
- Logging sensitive data
</anti_patterns>

</skill>
