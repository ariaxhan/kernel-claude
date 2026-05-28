---
name: security
description: "Security best practices and vulnerability prevention. Input validation, authentication, secrets management, OWASP top 10. Triggers: security, auth, authentication, secrets, credentials, vulnerability, injection, XSS, CSRF, rate-limit."
allowed-tools: Read, Grep, Bash
---

<skill id="security">

<purpose>
Security is not a feature. It's a constraint on all features.
Never trust user input. Never hardcode secrets. Defense in depth.
45% of AI-generated code contains known security flaws - verify everything.
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

<flow>

  1. **Secrets check** — grep for hardcoded keys/passwords/tokens before any commit.
     (gate: `git grep -E "(api_key|apiKey|password|secret|token)\s*=\s*['\"][^'\"]{8,}"` returns empty)

  2. **Input validation** — all user input validated at API boundary with schema (Zod/Pydantic).
     (gate: every public endpoint parses input through schema before use; see code patterns in reference)

  3. **SQL injection** — all queries parameterized; no string concatenation with user data.
     (gate: grep for template literal SQL with user variables returns empty)

  4. **XSS prevention** — user-provided HTML sanitized (DOMPurify); CSP headers configured.
     (gate: `dangerouslySetInnerHTML` only appears with DOMPurify wrapping)

  5. **Authentication** — tokens in httpOnly cookies, not localStorage; auth checked per-request.
     (gate: no `localStorage.setItem('token'`; every protected route has auth check)

  6. **Authorization** — role/ownership check before every sensitive operation.
     (gate: no delete/update/admin endpoint without requester role verification)

  7. **CSRF protection** — tokens on state-changing requests; SameSite=Strict on session cookies.
     (gate: POST/PUT/DELETE endpoints verify X-CSRF-Token or use SameSite cookie)

  8. **Rate limiting** — enabled on all public endpoints; stricter on expensive ops.
     (gate: every `/api/` route has rate limit middleware)

  9. **Error handling** — generic messages in responses; stack traces only in server logs.
     (gate: no `error.stack` or internal paths in HTTP response bodies)

  10. **Dependency audit** — `npm audit` / `pip-audit` clean; lockfile committed.
      (gate: audit exits 0 or all findings are acknowledged with justification)

  11. **Supply chain** — verify package existence + download counts before installing AI-suggested packages.
      (gate: no packages added without explicit npm/pypi verification; see supply chain patterns in reference)

  12. **Prompt injection** (AI-integrated features) — user text never interpolated into system prompts; LLM output validated before use.
      (gate: no f-string/template system prompt with raw user input; see prompt injection patterns in reference)

  13. **Agent permissions** — every spawned agent has explicit tool allowlist + file scope; no admin-by-default.
      (gate: spawn contract lists allowed tools ≤5; sensitive scopes named explicitly)

</flow>

<pre_deployment_checklist>
Before ANY production deployment:
- [ ] **Secrets**: No hardcoded secrets, all in env vars
- [ ] **Input Validation**: All user inputs validated with Zod/Pydantic
- [ ] **SQL Injection**: All queries parameterized
- [ ] **XSS**: User content sanitized, CSP configured
- [ ] **CSRF**: Protection on state-changing operations
- [ ] **Authentication**: Tokens in httpOnly cookies, not localStorage
- [ ] **Authorization**: Role checks before sensitive operations
- [ ] **Rate Limiting**: Enabled on all endpoints
- [ ] **HTTPS**: Enforced in production
- [ ] **Error Handling**: No sensitive data in responses
- [ ] **Logging**: No passwords, tokens, or PII in logs
- [ ] **Dependencies**: npm audit clean, no known vulnerabilities
- [ ] **RLS**: Row Level Security enabled (Supabase)
- [ ] **File Uploads**: Validated (size, type, extension)
</pre_deployment_checklist>

<anti_patterns>
- "We'll add security later" (you won't)
- Disabling security for development (gets shipped)
- Rolling your own crypto (use established libraries)
- Security through obscurity (it's not security)
- Trusting client-side validation alone
- Logging sensitive data
- Installing AI-suggested packages without verifying they exist and are legitimate
- Giving agents more tools or file access than their task requires
</anti_patterns>

<on_complete>
agentdb write-end '{"skill":"security","vectors_checked":["injection","xss","authz","secrets"],"findings":N}'
</on_complete>

</skill>
