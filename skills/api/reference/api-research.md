# API Research

Deep reference for REST API design.

## REST Principles

### 1. Uniform Interface
- Resources identified by URIs
- Manipulation through representations (JSON)
- Self-descriptive messages (status codes, headers)
- HATEOAS (links to related resources)

### 2. Statelessness
Each request contains all info needed. No server-side sessions.

### 3. Cacheability
Responses declare cacheability. Improves performance, reduces load.

### 4. Layered System
Client doesn't know if talking to origin or proxy.

## HTTP Method Semantics

### Safe Methods (No Side Effects)
- GET: Retrieve resource
- HEAD: Retrieve headers only
- OPTIONS: Discover capabilities

### Idempotent Methods
Multiple identical requests = same result
- GET, HEAD, OPTIONS (safe = idempotent)
- PUT: Replace resource completely
- DELETE: Remove resource

### Non-Idempotent
- POST: Create resource (each call creates new)
- PATCH: Partial update (depends on implementation)

### Method Selection

| Action | Method | Idempotent | Notes |
|--------|--------|------------|-------|
| List resources | GET | Yes | Query params for filtering |
| Get single | GET | Yes | Return 404 if not found |
| Create | POST | No | Return 201 + Location header |
| Full update | PUT | Yes | Replace entire resource |
| Partial update | PATCH | No* | Only change specified fields |
| Delete | DELETE | Yes | Return 204 on success |

*PATCH can be idempotent with proper design (JSON Merge Patch)

## Pagination Deep Dive

### Offset Pagination
```
GET /api/users?page=5&per_page=20
```

SQL:
```sql
SELECT * FROM users
ORDER BY created_at DESC
LIMIT 20 OFFSET 80;  -- page 5 * 20 per_page = 80 offset
```

Response:
```json
{
  "data": [...],
  "meta": {
    "total": 500,
    "page": 5,
    "per_page": 20,
    "total_pages": 25
  },
  "links": {
    "first": "/api/users?page=1&per_page=20",
    "prev": "/api/users?page=4&per_page=20",
    "self": "/api/users?page=5&per_page=20",
    "next": "/api/users?page=6&per_page=20",
    "last": "/api/users?page=25&per_page=20"
  }
}
```

Pros:
- Simple to implement
- Users can jump to any page
- Total count available

Cons:
- O(n) performance for high offsets
- Inconsistent with concurrent inserts/deletes
- "Page 5" might show different items over time

### Cursor Pagination
```
GET /api/users?cursor=abc123&limit=20
```

Cursor encodes position (e.g., base64 of last ID + timestamp):
```typescript
const cursor = Buffer.from(JSON.stringify({
  id: lastItem.id,
  created_at: lastItem.created_at
})).toString('base64')
```

SQL:
```sql
SELECT * FROM users
WHERE (created_at, id) < (:cursor_timestamp, :cursor_id)
ORDER BY created_at DESC, id DESC
LIMIT 21;  -- +1 to check if there's more
```

Response:
```json
{
  "data": [...],
  "meta": {
    "has_next": true,
    "next_cursor": "eyJpZCI6MTIzfQ=="
  }
}
```

Pros:
- O(1) performance regardless of position
- Stable with concurrent mutations
- Natural for infinite scroll

Cons:
- No jump to arbitrary page
- No total count (usually)
- Cursor is opaque to client

### Keyset Pagination (Seek Method)
Variation of cursor using actual values:
```
GET /api/users?created_after=2024-01-15T10:00:00Z&id_after=abc123&limit=20
```

More transparent than encoded cursor.

## Filtering Patterns

### Simple Equality
```
GET /api/orders?status=pending
GET /api/products?category=electronics
```

### Comparison Operators
```
# Bracket notation
GET /api/products?price[gte]=10&price[lte]=100
GET /api/orders?created_at[after]=2024-01-01

# Or suffix notation
GET /api/products?price_gte=10&price_lte=100
```

### Multiple Values
```
# Comma-separated (OR)
GET /api/products?category=electronics,clothing

# Array notation
GET /api/products?category[]=electronics&category[]=clothing
```

### Full-Text Search
```
GET /api/products?q=wireless+headphones
```

## Error Response Standards

### Problem Details (RFC 7807)
```json
{
  "type": "https://api.example.com/errors/validation",
  "title": "Validation Error",
  "status": 422,
  "detail": "Request body failed validation",
  "instance": "/api/users",
  "errors": [
    {
      "field": "email",
      "message": "Must be a valid email",
      "code": "invalid_format"
    }
  ]
}
```

### Simple Error Format
```json
{
  "error": {
    "code": "validation_error",
    "message": "Request validation failed",
    "details": [
      { "field": "email", "message": "Invalid format" }
    ]
  }
}
```

### Error Codes
- Machine-readable, stable
- Don't change codes (breaking)
- Add new codes, deprecate old

```
validation_error
not_found
unauthorized
forbidden
rate_limit_exceeded
internal_error
```

## Versioning Strategies

### URL Path (Recommended)
```
/api/v1/users
/api/v2/users
```

Pros: Explicit, easy routing, cacheable
Cons: URL changes

### Header
```
Accept: application/vnd.myapp.v2+json
```

Pros: Clean URLs
Cons: Easy to forget, harder to test

### Query Parameter
```
/api/users?version=2
```

Pros: Explicit
Cons: Pollutes query, caching issues

### Versioning Rules
1. Don't version until necessary
2. Keep max 2 versions active
3. Provide migration path
4. Add Sunset header before removal

Non-breaking changes (no new version):
- Adding fields to responses
- Adding optional parameters
- Adding new endpoints

Breaking changes (new version):
- Removing/renaming fields
- Changing field types
- Changing URL structure
- Changing auth method

## Rate Limiting Implementation

### Token Bucket Algorithm
```typescript
class TokenBucket {
  private tokens: number
  private lastRefill: number

  constructor(
    private capacity: number,
    private refillRate: number  // tokens per second
  ) {
    this.tokens = capacity
    this.lastRefill = Date.now()
  }

  consume(tokens = 1): boolean {
    this.refill()

    if (this.tokens >= tokens) {
      this.tokens -= tokens
      return true
    }
    return false
  }

  private refill() {
    const now = Date.now()
    const elapsed = (now - this.lastRefill) / 1000
    this.tokens = Math.min(
      this.capacity,
      this.tokens + elapsed * this.refillRate
    )
    this.lastRefill = now
  }
}
```

### Headers
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1640000000  // Unix timestamp
Retry-After: 60  // Seconds (on 429)
```

### Tiers
| Tier | Limit | Window | Use Case |
|------|-------|--------|----------|
| Anonymous | 30/min | Per IP | Public |
| Free | 100/min | Per user | Free tier |
| Pro | 1000/min | Per API key | Paid |
| Enterprise | Custom | Per contract | Enterprise |

## Authentication Patterns

### Bearer Token
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
```

### API Key
```
X-API-Key: sk_live_abc123
```

### OAuth 2.0 Flows
- Authorization Code: Web apps
- PKCE: Mobile/SPA
- Client Credentials: Server-to-server

### Best Practices
- Tokens in Authorization header, not query
- Short-lived access tokens (15min)
- Longer refresh tokens (7d)
- Rotate API keys periodically

## Resources

- Zalando API Guidelines
- Microsoft REST API Guidelines
- JSON:API specification
- RFC 7807 (Problem Details)
