# Security Bank

**Security review checklist: Prevent common vulnerabilities**

---

## OWASP Top 10 Quick Reference

1. **Broken Access Control** - Users accessing unauthorized data
2. **Cryptographic Failures** - Weak encryption, exposed secrets
3. **Injection** - SQL, XSS, command injection
4. **Insecure Design** - Missing security requirements
5. **Security Misconfiguration** - Default credentials, verbose errors
6. **Vulnerable Components** - Outdated dependencies
7. **Authentication Failures** - Weak passwords, session issues
8. **Data Integrity Failures** - Untrusted data sources
9. **Logging Failures** - Missing security logs
10. **SSRF** - Server-side request forgery

---

## Input Validation Checklist

### User Input
- [ ] Length limits enforced?
- [ ] Type validation (string, number, email, etc.)?
- [ ] Whitelist allowed characters (don't blacklist)?
- [ ] Sanitize before storage/display?
- [ ] Validate on server (never trust client)?

### File Uploads
- [ ] File type validated (check content, not just extension)?
- [ ] File size limited?
- [ ] Filename sanitized?
- [ ] Stored outside webroot?
- [ ] Scanned for malware?

---

## Injection Prevention

### SQL Injection
```javascript
// BAD: String concatenation
const query = `SELECT * FROM users WHERE id = ${userId}`
db.query(query)  // SQL injection!

// GOOD: Parameterized queries
const query = 'SELECT * FROM users WHERE id = ?'
db.query(query, [userId])  // Safe
```

```python
# BAD: String formatting
cursor.execute(f"SELECT * FROM users WHERE id = {user_id}")

# GOOD: Parameterized
cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))
```

### XSS (Cross-Site Scripting)
```javascript
// BAD: Raw HTML insertion
element.innerHTML = userInput  // XSS vulnerability!

// GOOD: Text content or sanitized HTML
element.textContent = userInput  // Safe for text

// Or use a sanitizer
import DOMPurify from 'dompurify'
element.innerHTML = DOMPurify.sanitize(userInput)
```

### Command Injection
```javascript
// BAD: Shell command with user input
exec(`convert ${userFile} output.jpg`)  // Command injection!

// GOOD: Use safe APIs or validate strictly
const sanitized = path.basename(userFile)  // Only filename
exec(`convert ${sanitized} output.jpg`)
```

---

## Authentication & Authorization

### Authentication Checklist
- [ ] Passwords hashed (bcrypt, argon2)?
- [ ] Min password length (12+ characters)?
- [ ] Rate limiting on login attempts?
- [ ] Session tokens random and long?
- [ ] Tokens expire (don't live forever)?
- [ ] HTTPS only (no plaintext passwords)?

### Authorization Checklist
- [ ] User authenticated before action?
- [ ] User authorized for THIS resource?
- [ ] Check on every request (don't cache)?
- [ ] Default deny (whitelist, not blacklist)?

```javascript
// BAD: Trust user ID from client
app.post('/users/:id', (req, res) => {
  const userId = req.params.id
  updateUser(userId, req.body)  // Anyone can update anyone!
})

// GOOD: Check session user matches
app.post('/users/:id', (req, res) => {
  const userId = req.params.id
  const sessionUser = req.session.userId

  if (userId !== sessionUser) {
    return res.status(403).send('Forbidden')
  }

  updateUser(userId, req.body)
})
```

---

## Secrets Management

### Do NOT Commit
❌ API keys
❌ Database passwords
❌ Private keys
❌ OAuth secrets
❌ JWT signing keys
❌ Encryption keys

### DO Use Environment Variables
```javascript
// BAD: Hardcoded secret
const apiKey = 'sk_live_abc123...'

// GOOD: From environment
const apiKey = process.env.API_KEY
if (!apiKey) throw new Error('API_KEY not configured')
```

### Check for Leaks
```bash
# Scan for accidentally committed secrets
git log -p | grep -i "api.key\|password\|secret"

# Use tools
npm install -g gitleaks
gitleaks detect
```

---

## Cryptography Best Practices

### Hashing Passwords
```javascript
// Use bcrypt (slow by design)
const bcrypt = require('bcrypt')
const saltRounds = 10

// Hash password
const hash = await bcrypt.hash(password, saltRounds)

// Verify password
const match = await bcrypt.compare(password, hash)
```

```python
# Use argon2 (modern, secure)
from argon2 import PasswordHasher
ph = PasswordHasher()

# Hash password
hash = ph.hash(password)

# Verify password
try:
    ph.verify(hash, password)
except:
    # Invalid password
    pass
```

### Encryption
```javascript
// Use established libraries (crypto, sodium)
const crypto = require('crypto')

// Encrypt
const algorithm = 'aes-256-gcm'
const key = crypto.randomBytes(32)
const iv = crypto.randomBytes(16)
const cipher = crypto.createCipheriv(algorithm, key, iv)
const encrypted = Buffer.concat([cipher.update(text), cipher.final()])

// Don't roll your own crypto!
```

---

## Session Security

### Session Tokens
- [ ] Random, cryptographically secure?
- [ ] Long enough (128+ bits)?
- [ ] Expire after inactivity?
- [ ] Invalidate on logout?
- [ ] HttpOnly cookie (no JavaScript access)?
- [ ] Secure flag (HTTPS only)?
- [ ] SameSite attribute (CSRF protection)?

```javascript
// Secure session cookie
res.cookie('sessionId', token, {
  httpOnly: true,      // No JavaScript access
  secure: true,        // HTTPS only
  sameSite: 'strict',  // CSRF protection
  maxAge: 3600000      // 1 hour
})
```

---

## API Security

### Rate Limiting
```javascript
// Prevent brute force and DoS
const rateLimit = require('express-rate-limit')

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,  // 15 minutes
  max: 100                    // Max 100 requests
})

app.use('/api/', limiter)
```

### CORS
```javascript
// Restrict allowed origins
const cors = require('cors')

app.use(cors({
  origin: 'https://yourdomain.com',  // Not '*'!
  credentials: true
}))
```

### Headers
```javascript
// Security headers
app.use(helmet())  // Sets multiple security headers

// Or manually:
res.setHeader('X-Content-Type-Options', 'nosniff')
res.setHeader('X-Frame-Options', 'DENY')
res.setHeader('Content-Security-Policy', "default-src 'self'")
```

---

## Data Protection

### Sensitive Data
- [ ] Encrypt at rest (database encryption)?
- [ ] Encrypt in transit (HTTPS)?
- [ ] Minimal data collected (GDPR)?
- [ ] Secure deletion (no soft deletes for sensitive data)?
- [ ] Access logged (audit trail)?

### Logging
```javascript
// BAD: Log sensitive data
logger.info('User login', { email, password })  // Don't log passwords!

// GOOD: Log safely
logger.info('User login', { email })  // No sensitive data

// Sanitize before logging
function sanitize(obj) {
  const { password, ssn, creditCard, ...safe } = obj
  return safe
}
logger.info('User data', sanitize(user))
```

---

## Dependency Security

### Keep Dependencies Updated
```bash
# Check for vulnerabilities
npm audit
pip check
go list -json -m all | nancy sleuth

# Update dependencies
npm update
pip install --upgrade -r requirements.txt
```

### Use Lock Files
- `package-lock.json` (Node)
- `Pipfile.lock` (Python)
- `go.sum` (Go)
- `Cargo.lock` (Rust)

**Commit lock files** to ensure reproducible builds.

---

## Security Review Checklist

### Before Deploying
- [ ] All user input validated?
- [ ] SQL queries parameterized?
- [ ] XSS prevented (sanitized output)?
- [ ] Secrets in environment, not code?
- [ ] Authentication required for protected routes?
- [ ] Authorization checked for each resource?
- [ ] HTTPS enabled?
- [ ] Security headers set?
- [ ] Dependencies up to date?
- [ ] Sensitive data encrypted?
- [ ] Rate limiting enabled?
- [ ] Error messages don't leak info?

---

## Common Vulnerabilities by Stack

### Node.js/Express
```javascript
// Prototype pollution
const merge = require('lodash.merge')
merge({}, JSON.parse(userInput))  // Dangerous!

// Use safe parse
const data = JSON.parse(userInput)
if (typeof data !== 'object' || data.__proto__) {
  throw new Error('Invalid data')
}
```

### Python/Flask
```python
# Pickle deserialization
import pickle
data = pickle.loads(user_input)  # Remote code execution!

# Use JSON instead
import json
data = json.loads(user_input)
```

### General
```javascript
// Path traversal
fs.readFile(`./uploads/${userFilename}`)  // Can access ../../../etc/passwd

// Sanitize paths
const safe = path.basename(userFilename)
fs.readFile(`./uploads/${safe}`)
```

---

## When to Use This Bank

✅ Reviewing code for security issues
✅ Before deploying new feature
✅ Security audit/penetration test prep
✅ Implementing authentication/authorization
✅ Handling sensitive data

---

**Remember: Security is not a feature, it's a requirement.**
