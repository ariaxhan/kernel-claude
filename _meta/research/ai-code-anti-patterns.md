# AI Code Anti-Patterns Research

**Research Date:** 2026-03-12
**Sources:** CodeRabbit State Report, SonarSource, METR Study, Endor Labs Security, MIT 2025
**Purpose:** What AI actually breaks, not generic concerns

---

## CRITICAL STATS

| Metric | Finding | Source |
|--------|---------|--------|
| Security flaws | 40-62% of AI code | CSA, Veracode |
| Buggier than human | 1.7x more issues | CodeRabbit 2025 |
| Technical debt | +30-41% after adoption | SonarSource |
| Perceived vs actual speed | Think 20% faster, actually 19% slower | METR 2025 |
| Code review burden | 2-3x longer | CodeRabbit |

---

## THE BIG 5: What AI Actually Breaks

### 1. INPUT VALIDATION OMISSION (Systematic)

**Frequency:** Nearly universal unless explicitly prompted.

```yaml
symptoms:
  - No Zod/Pydantic schema for user input
  - Missing null checks on API responses
  - String concatenation instead of parameterized queries
  - No length limits on text fields
  - File uploads without type/size validation

why_ai_does_this:
  - Training data includes insecure patterns from public repos
  - Happy path dominates training examples
  - "Make it work" prompts don't include "make it secure"
  - AI optimizes for functional, not defensive

detection:
  - grep -r "req\\.body" | grep -v "parse\\|validate\\|z\\."
  - Search for raw db.query with string interpolation
  - Check file upload handlers for mime/size checks

fix:
  - MANDATORY: Zod schema for every API endpoint
  - MANDATORY: Parameterized queries, never string concat
  - Add to code review checklist: "Where is validation?"
```

### 2. EDGE CASE BLINDNESS

**Frequency:** Almost all AI code misses edge cases on first pass.

```yaml
symptoms:
  - Empty array crashes loop logic
  - Null user object in authenticated routes
  - Zero-length string treated as valid
  - Concurrent access corrupts state
  - Timeout handling missing entirely
  - Unicode characters break string processing

why_ai_does_this:
  - GitHub training data is mostly happy path
  - Edge cases underrepresented in public code
  - AI doesn't think adversarially
  - Tests in training data test success, not failure

detection:
  - Search for array access without length check
  - Look for optional chaining overuse (?.?.?. chain = smell)
  - Find async functions without try-catch
  - Check for Promise.all without error boundaries

fix:
  - Test edge cases FIRST, not last
  - Template: null, empty, boundary, concurrent, timeout
  - Add to prompt: "Handle: null, empty array, unicode, timeout"
```

### 3. ERROR HANDLING GAPS

**Frequency:** ~70% of AI functions have incomplete error handling.

```yaml
symptoms:
  - Empty catch blocks (swallowed errors)
  - Generic catch without logging
  - No error boundaries in React
  - API errors returned as 500 without context
  - Background jobs fail silently
  - No retry logic for transient failures

why_ai_does_this:
  - "Make it work" doesn't mean "make it fail gracefully"
  - Error handling is boilerplate AI skips
  - Training examples rarely show production error handling
  - AI doesn't know your monitoring/alerting setup

detection:
  - grep -r "catch.*{}" (empty catch)
  - Search for async without await in try-catch
  - Look for functions that return undefined on error
  - Check for console.log in catch (not proper logging)

fix:
  - Every catch: log error, set response status, return useful message
  - Background jobs: retry + dead letter queue
  - Add error boundaries at component level
  - Structured logging (not console.log)
```

### 4. DUPLICATION EXPLOSION (8x Increase)

**Frequency:** AI generates copy-paste code readily.

```yaml
symptoms:
  - Same validation logic in 5 endpoints
  - Copy-pasted error handling
  - Repeated database queries with slight variations
  - Similar components with minor differences
  - No shared utilities, everything inline

why_ai_does_this:
  - AI generates "complete" solutions per prompt
  - Doesn't see the bigger picture of reuse
  - No incentive to refactor in generation
  - Each prompt treated independently

detection:
  - jscpd or similar duplication detector
  - Look for functions > 50 lines (often contain duplication)
  - Search for identical import blocks
  - Find 3+ similar switch/if chains

fix:
  - Prompt: "Before implementing, check for existing utilities"
  - Extract common patterns into shared modules
  - Set duplication threshold in CI (e.g., <5%)
  - 20-30% sprint time for debt reduction
```

### 5. COMPLEXITY SPIRAL (+15-25% Cyclomatic)

**Frequency:** AI code trends toward higher complexity over time.

```yaml
symptoms:
  - Nested ternaries 3+ levels deep
  - Functions > 100 lines
  - God components doing everything
  - Deeply nested if/else chains
  - Overly clever one-liners

why_ai_does_this:
  - AI generates "complete" solutions
  - No pressure to simplify
  - Training includes complex production code
  - Doesn't refactor after generation

detection:
  - eslint complexity rule
  - Functions with > 10 parameters
  - Files > 500 lines
  - Components with > 5 useState calls

fix:
  - Prompt: "Keep functions < 30 lines"
  - Extract early returns for guard clauses
  - Split large components
  - Set complexity thresholds in CI
```

---

## VELOCITY CALIBRATION

### Speed is Task-Dependent

| Task Type | AI Speed Gain | Review Burden |
|-----------|---------------|---------------|
| Boilerplate/scaffolding | 10x | Low (mostly correct) |
| Configuration/Docker | 8-10x | Low |
| Feature variants/A-B | 10x | Low |
| API integration | 3-5x | Medium (check auth/errors) |
| Complex domain logic | 2-5x | High (edge cases) |
| Debugging | 2-5x | Medium |
| Architecture/design | 1x | N/A (human-led) |
| Novel algorithms | 1x | N/A (human-led) |

### Timeline Baselines (Greenfield, 2026)

| Project Type | Traditional | With AI | Speedup |
|--------------|-------------|---------|---------|
| Simple CRUD | 2-3 weeks | 2-3 days | 5-7x |
| MVP with payment | 4-6 weeks | 5-7 days | 5-6x |
| SaaS custom logic | 8-12 weeks | 10-14 days | 4-6x |
| Full-stack complex | 3-6 months | 3-4 weeks | 4-6x |

**Critical:** These assume greenfield + clear requirements + established patterns.
Legacy refactoring is slower. Unclear requirements = no speed gain.

---

## PRODUCTION READINESS CHECKLIST

Before ANY AI code ships:

```yaml
security:
  - [ ] Input validation with Zod/Pydantic
  - [ ] Parameterized queries (no string concat)
  - [ ] Auth tokens in httpOnly cookies
  - [ ] Rate limiting on all endpoints
  - [ ] Secrets in env vars, not code
  - [ ] File uploads validated (size, type, extension)

edge_cases:
  - [ ] Null/undefined handling
  - [ ] Empty arrays don't crash
  - [ ] Zero-length strings rejected
  - [ ] Unicode works correctly
  - [ ] Concurrent access safe
  - [ ] Timeout handling present

error_handling:
  - [ ] No empty catch blocks
  - [ ] Errors logged with context
  - [ ] User-facing messages are generic
  - [ ] Background jobs have retry logic
  - [ ] Error boundaries at component level

quality:
  - [ ] Functions < 30 lines
  - [ ] No duplication > 3 instances
  - [ ] Cyclomatic complexity < 10
  - [ ] Tests cover edge cases (not just happy path)
  - [ ] Assertions are specific (not toBeTruthy)
```

---

## SLOW DOWN TO SPEED UP

### The Paradox

**METR Study (2025):** Developers perceived 20% faster, measured 19% slower.

**Why:**
- Time saved generating code
- Time lost reviewing, debugging, fixing
- Net negative when AI code quality is worse

### The Fix

```yaml
planning_ratio:
  old: 10% planning, 90% coding
  new: 50-70% planning, 30-50% coding

result: 50% fewer refactors, 3x faster overall

principle: "95% planning, 5% building"
  - Humans shape product through specs
  - AI handles execution
  - Clear spec = fast implementation
  - Vague spec = endless iteration
```

### Review Time Increases

**Expect code review to take 2-3x longer initially.**

AI code has:
- 10.83 findings per PR vs 6.45 human
- 40% more critical issues
- 70% more major issues
- 3x more readability issues

**Solution:** Quality gates BEFORE review. Automated checks catch 80% of issues.

---

## SKILL REFERENCES

When reviewing AI code, load:

| Concern | Skill | Key Check |
|---------|-------|-----------|
| Input validation | security | Zod schema for every endpoint |
| Error handling | debug | No empty catch blocks |
| Edge cases | testing | null, empty, boundary, concurrent |
| Complexity | architecture | Functions < 30 lines |
| Security | security | OWASP checklist |

---

## SOURCES

- CodeRabbit State of AI Code 2025
- SonarSource AI Code Quality Analysis
- METR Study 2025 (19% slower finding)
- Endor Labs Security Vulnerabilities
- CSA AI Security Risks
- MIT 2025 AI Failure Rate (95%)
