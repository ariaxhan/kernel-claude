# Compaction Patterns

**Type:** reference | **Load:** on-demand via skills/context/SKILL.md

Worked examples of good compaction, anti-patterns, and recovery strategies.

---

## Worked Examples: Good Compaction

### Example 1: Research Phase to Implementation

**Before (800 tokens):**
```
I'll search for authentication patterns in the codebase.
[Read: src/auth/middleware.ts - 200 lines]
[Read: src/auth/jwt.ts - 150 lines]
[Read: src/auth/session.ts - 180 lines]
[Grep: "Bearer" found in 12 files]
[Read: tests/auth.test.ts - 300 lines]
The authentication flow uses JWT with refresh tokens. The middleware
checks for Bearer tokens in the Authorization header. Sessions are
stored in Redis with a 24-hour TTL. The refresh endpoint at /auth/refresh
handles token rotation. Tests cover happy path but miss edge cases
for expired refresh tokens.
```

**After (80 tokens):**
```
Auth research complete. JWT + refresh tokens, Redis sessions (24h TTL).
Key files: src/auth/{middleware,jwt,session}.ts
Gap found: tests miss expired refresh token edge cases.
Details in AgentDB:findings:auth-research-001
```

### Example 2: Debugging Session

**Before (600 tokens):**
```
User reports 500 error on /api/users endpoint.
[Read: src/api/users.ts]
[Read: logs/error.log - last 50 lines]
Found error: "Cannot read property 'id' of undefined"
[Read: src/models/user.ts]
[Grep: "findById" - 8 matches]
The issue is in getUserById when user doesn't exist.
[Read: src/api/users.ts lines 45-60]
Line 52 calls user.id without null check.
Tried adding: if (!user) return res.status(404)
[Run: npm test - 42 passed, 1 failed]
Test failure in user.test.ts:78 - expected 404, got 500
[Read: tests/user.test.ts lines 75-85]
Test was checking wrong status code.
[Edit: tests/user.test.ts line 78]
[Run: npm test - 43 passed]
```

**After (60 tokens):**
```
Fixed: /api/users 500 error
Root cause: null check missing at src/api/users.ts:52
Fix: added early return for missing user (404)
Test updated: tests/user.test.ts:78
Commit: fix(api): handle missing user in getUserById
```

### Example 3: Multi-File Feature Implementation

**Before (1200 tokens):**
```
[Full exploration of 8 files, multiple iterations, false starts]
```

**After (100 tokens):**
```
Implemented: rate limiting middleware
Files changed:
- src/middleware/rate-limit.ts (new, 45 lines)
- src/app.ts:12 (added middleware import)
- src/config/index.ts:8 (added RATE_LIMIT_WINDOW env)
- tests/rate-limit.test.ts (new, 60 lines)
Tests: 6/6 passing
Contract: RATE-001 | Branch: feature/rate-limiting
```

---

## Anti-Patterns: What NOT to Do

### Anti-Pattern 1: Over-Compacting (Losing Critical Context)

**Bad:**
```
Did some auth work. Files changed. Tests pass.
```

**Why bad:** No file paths, no decisions captured, no way to resume.

**Good:**
```
Auth middleware refactored.
Changed: src/auth/middleware.ts, src/auth/types.ts
Decision: kept existing JWT validation, added refresh token rotation.
Open question: should refresh tokens be single-use? (deferred)
Branch: refactor/auth-middleware | Contract: AUTH-042
```

### Anti-Pattern 2: Under-Compacting (Keeping Noise)

**Bad:** Keeping full file contents, every grep result, intermediate debug output.

**Why bad:** Context rot. Critical info drowns in noise.

**Good:** Keep conclusions, discard exploration traces.

### Anti-Pattern 3: Losing Blocking Issues

**Bad:**
```
Made progress on feature. Some issues remain.
```

**Why bad:** "Some issues" is useless. Next agent won't know what's blocked.

**Good:**
```
Feature 80% complete. BLOCKED: need API key for external service.
Blocking: Cannot test src/integrations/stripe.ts without STRIPE_SECRET_KEY.
Workaround attempted: mock responses work for unit tests only.
Next: user to provide env var, then complete integration tests.
```

### Anti-Pattern 4: Compacting Mid-Implementation

**Bad:** Compacting while halfway through a multi-file change.

**Why bad:** Lose variable names, partial state, what's modified vs pending.

**Good:** Complete the logical unit, commit, then compact.

---

## Recovery Strategies

### When Context is Lost

1. **Check AgentDB first:**
   ```
   agentdb read-start
   agentdb query "SELECT * FROM context WHERE type='checkpoint' ORDER BY ts DESC LIMIT 5"
   ```

2. **Check git for recent state:**
   ```
   git log --oneline -10
   git diff HEAD~3..HEAD --stat
   ```

3. **Check snapshot file:**
   ```
   cat _meta/agents/{agent}-snapshot.md
   ```

4. **Check active.md:**
   ```
   cat _meta/context/active.md
   ```

### When Blocking Issue is Lost

1. **Query AgentDB for blockers:**
   ```
   agentdb query "SELECT content FROM context WHERE content LIKE '%blocked%' ORDER BY ts DESC LIMIT 3"
   ```

2. **Check commit messages:**
   ```
   git log --oneline --grep="blocked\|TODO\|FIXME" -5
   ```

### When Decision Rationale is Lost

1. **Check AgentDB patterns:**
   ```
   agentdb query "SELECT * FROM context WHERE type='pattern' AND content LIKE '%decision%'"
   ```

2. **Check handoff files:**
   ```
   ls _meta/handoffs/
   cat _meta/handoffs/latest.md
   ```

---

## Strategic Compaction Timing

### Compact After These Phases

| Phase Complete | Why Compact |
|----------------|-------------|
| Research/exploration | Bulk context served its purpose |
| Planning finalized | Plan is in contract/file |
| Feature milestone | Clean slate for next unit |
| Bug fixed and tested | Debug traces no longer needed |
| Failed approach abandoned | Clear dead-end reasoning |

### Do NOT Compact During

| Phase | Why Wait |
|-------|----------|
| Mid-implementation | Lose partial state, file paths |
| Active debugging | Lose trace context |
| Waiting for user input | Lose the question context |
| Uncommitted changes | Risk losing work |

---

## AgentDB Offloading Pattern

When context is growing heavy:

```bash
# 1. Write detailed findings
agentdb learn pattern "auth-flow-analysis" "JWT rotation: access 15min, refresh 7d. Redis session store. See src/auth/."

# 2. Write blocking issues
agentdb write-end '{"agent":"researcher","status":"blocked","blocker":"need STRIPE_KEY","attempted":"mock tests pass"}'

# 3. Reference in conversation
# "Auth analysis complete. See AgentDB:patterns:auth-flow-analysis for details."
```

The conversation stays light. The details persist in AgentDB.
