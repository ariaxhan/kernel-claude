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

<secrets_management>
```typescript
// BAD: Hardcoded secrets
const apiKey = "sk-proj-xxxxx"  // NEVER

// GOOD: Environment variables
const apiKey = process.env.OPENAI_API_KEY
if (!apiKey) throw new Error('OPENAI_API_KEY not configured')
```

Checklist before commit:
- [ ] No API keys in code
- [ ] No passwords in code
- [ ] No connection strings with credentials
- [ ] .env files in .gitignore
- [ ] Secrets in environment variables or vault
</secrets_management>

<input_validation>
```typescript
import { z } from 'zod'

const CreateUserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1).max(100),
  age: z.number().int().min(0).max(150)
})

export async function createUser(input: unknown) {
  const validated = CreateUserSchema.parse(input)
  return await db.users.create(validated)
}
```

```typescript
// File upload validation
function validateFileUpload(file: File) {
  const maxSize = 5 * 1024 * 1024  // 5MB
  if (file.size > maxSize) throw new Error('File too large')

  const allowedTypes = ['image/jpeg', 'image/png', 'image/gif']
  if (!allowedTypes.includes(file.type)) throw new Error('Invalid file type')

  const allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif']
  const ext = file.name.toLowerCase().match(/\.[^.]+$/)?.[0]
  if (!ext || !allowedExtensions.includes(ext)) throw new Error('Invalid extension')
}
```
</input_validation>

<sql_injection>
```typescript
// BAD: String concatenation
const query = `SELECT * FROM users WHERE email = '${userEmail}'`  // NEVER

// GOOD: Parameterized queries
const { data } = await supabase
  .from('users')
  .select('*')
  .eq('email', userEmail)

// Or with raw SQL
await db.query('SELECT * FROM users WHERE email = $1', [userEmail])
```
</sql_injection>

<xss_prevention>
```typescript
import DOMPurify from 'isomorphic-dompurify'

// ALWAYS sanitize user-provided HTML
function renderUserContent(html: string) {
  const clean = DOMPurify.sanitize(html, {
    ALLOWED_TAGS: ['b', 'i', 'em', 'strong', 'p'],
    ALLOWED_ATTR: []
  })
  return <div dangerouslySetInnerHTML={{ __html: clean }} />
}
```

```typescript
// Content Security Policy
const securityHeaders = [
  {
    key: 'Content-Security-Policy',
    value: `
      default-src 'self';
      script-src 'self' 'unsafe-eval' 'unsafe-inline';
      style-src 'self' 'unsafe-inline';
      img-src 'self' data: https:;
      connect-src 'self' https://api.example.com;
    `.replace(/\s{2,}/g, ' ').trim()
  }
]
```
</xss_prevention>

<authentication>
```typescript
// BAD: localStorage (vulnerable to XSS)
localStorage.setItem('token', token)  // NEVER

// GOOD: httpOnly cookies
res.setHeader('Set-Cookie',
  `token=${token}; HttpOnly; Secure; SameSite=Strict; Max-Age=3600`)
```

```typescript
// Authorization check
export async function deleteUser(userId: string, requesterId: string) {
  const requester = await db.users.findUnique({ where: { id: requesterId } })

  if (requester.role !== 'admin') {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 403 })
  }

  await db.users.delete({ where: { id: userId } })
}
```

```sql
-- Row Level Security (Supabase)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own data"
  ON users FOR SELECT
  USING (auth.uid() = id);
```
</authentication>

<csrf_protection>
```typescript
import { csrf } from '@/lib/csrf'

export async function POST(request: Request) {
  const token = request.headers.get('X-CSRF-Token')

  if (!csrf.verify(token)) {
    return NextResponse.json({ error: 'Invalid CSRF token' }, { status: 403 })
  }

  // Process request
}
```

```typescript
// SameSite cookies prevent CSRF
res.setHeader('Set-Cookie',
  `session=${sessionId}; HttpOnly; Secure; SameSite=Strict`)
```
</csrf_protection>

<rate_limiting>
```typescript
import rateLimit from 'express-rate-limit'

// General API rate limit
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,  // 15 minutes
  max: 100,                   // 100 requests per window
  message: 'Too many requests'
})

// Stricter limit for expensive operations
const searchLimiter = rateLimit({
  windowMs: 60 * 1000,  // 1 minute
  max: 10,              // 10 requests per minute
})

app.use('/api/', limiter)
app.use('/api/search', searchLimiter)
```
</rate_limiting>

<error_handling>
```typescript
// BAD: Exposing internals
catch (error) {
  return NextResponse.json({
    error: error.message,
    stack: error.stack  // NEVER
  }, { status: 500 })
}

// GOOD: Generic messages
catch (error) {
  console.error('Internal error:', error)  // Log for debugging
  return NextResponse.json({
    error: 'An error occurred. Please try again.'
  }, { status: 500 })
}
```

```typescript
// BAD: Logging sensitive data
console.log('User login:', { email, password })  // NEVER

// GOOD: Redact sensitive fields
console.log('User login:', { email, userId })
```
</error_handling>

<owasp_awareness>
Top vulnerabilities to prevent:
- Injection (SQL, command, LDAP) - parameterized queries, never string concat
- Broken auth - secure session management, MFA where possible
- Sensitive data exposure - encrypt at rest and in transit
- XSS - output encoding, CSP headers
- CSRF - tokens for state-changing requests
- Security misconfiguration - secure defaults, minimal exposure
</owasp_awareness>

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
</anti_patterns>

</skill>
