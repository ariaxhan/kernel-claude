---
name: api
description: "REST API design patterns. Resource naming, status codes, pagination, error responses, versioning. Triggers: api, rest, endpoint, route, http, status-code, pagination."
allowed-tools: Read, Bash, Write, Edit, Grep, Glob
---

<skill id="api">

<purpose>
APIs are contracts. Breaking changes break consumers.
Resources are nouns, not verbs. HTTP methods define actions.
Status codes are not decorative. 200 for errors is a lie.
</purpose>

<prerequisite>
AgentDB read-start has run. Check existing API patterns in codebase.
Identify API versioning strategy in use (URL path, header, none).
</prerequisite>

<reference>
Skill-specific: skills/api/reference/api-research.md
</reference>

<core_principles>
1. RESOURCES ARE NOUNS: /users, /orders, /products. Not /getUsers, /createOrder.
2. HTTP METHODS MATTER: GET reads, POST creates, PUT replaces, PATCH updates, DELETE removes.
3. STATUS CODES ARE SEMANTIC: 200 OK, 201 Created, 400 Bad Request, 401 Unauthorized, 404 Not Found, 500 Internal Error.
4. PAGINATION BY DEFAULT: Lists return paginated results. Cursor > offset for scale.
5. VALIDATE BEFORE PROCESS: Schema validation (Zod, Pydantic) on all inputs.
</core_principles>

<url_structure>
```
# Resource-based URLs
GET    /api/v1/users              # List
GET    /api/v1/users/:id          # Get one
POST   /api/v1/users              # Create
PUT    /api/v1/users/:id          # Replace
PATCH  /api/v1/users/:id          # Update
DELETE /api/v1/users/:id          # Delete

# Sub-resources for relationships
GET    /api/v1/users/:id/orders   # User's orders
POST   /api/v1/users/:id/orders   # Create order for user

# Actions (use sparingly)
POST   /api/v1/orders/:id/cancel  # Verb for non-CRUD action
POST   /api/v1/auth/login         # Auth endpoints
```

```
# GOOD: kebab-case, plural, no verbs
/api/v1/team-members
/api/v1/orders?status=active

# BAD: verbs, singular, snake_case in URL
/api/v1/getUser
/api/v1/user
/api/v1/team_members
```
</url_structure>

<status_codes>
```
# Success
200 OK                    - GET, PUT, PATCH with response body
201 Created               - POST (include Location header)
204 No Content            - DELETE, PUT without response body

# Client Errors
400 Bad Request           - Malformed JSON, validation failure
401 Unauthorized          - Missing or invalid auth token
403 Forbidden             - Authenticated but not authorized
404 Not Found             - Resource doesn't exist
409 Conflict              - Duplicate entry, state conflict
422 Unprocessable Entity  - Valid JSON but semantically invalid
429 Too Many Requests     - Rate limit exceeded

# Server Errors
500 Internal Server Error - Unexpected failure (never expose details)
502 Bad Gateway           - Upstream service failed
503 Service Unavailable   - Overloaded, include Retry-After
```
</status_codes>

<response_format>
<!-- Success -->
```json
{
  "data": {
    "id": "abc-123",
    "email": "user@example.com",
    "name": "Alice"
  }
}
```

<!-- Collection with pagination -->
```json
{
  "data": [
    { "id": "abc-123", "name": "Alice" },
    { "id": "def-456", "name": "Bob" }
  ],
  "meta": {
    "total": 142,
    "page": 1,
    "per_page": 20,
    "total_pages": 8
  },
  "links": {
    "self": "/api/v1/users?page=1",
    "next": "/api/v1/users?page=2",
    "last": "/api/v1/users?page=8"
  }
}
```

<!-- Error -->
```json
{
  "error": {
    "code": "validation_error",
    "message": "Request validation failed",
    "details": [
      { "field": "email", "message": "Must be valid email", "code": "invalid_format" }
    ]
  }
}
```
</response_format>

<pagination>
<!-- Offset-based (simple, small datasets) -->
```
GET /api/v1/users?page=2&per_page=20

SELECT * FROM users ORDER BY created_at DESC LIMIT 20 OFFSET 20;
```

<!-- Cursor-based (scalable, large datasets) -->
```
GET /api/v1/users?cursor=eyJpZCI6MTIzfQ&limit=20

SELECT * FROM users WHERE id > :cursor_id ORDER BY id LIMIT 21;
```

Use cursor for: infinite scroll, feeds, >10K rows.
Use offset for: admin dashboards, search results with page numbers.
</pagination>

<implementation>
```typescript
import { z } from "zod"
import { NextRequest, NextResponse } from "next/server"

const createUserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1).max(100),
})

export async function POST(req: NextRequest) {
  const body = await req.json()
  const parsed = createUserSchema.safeParse(body)

  if (!parsed.success) {
    return NextResponse.json({
      error: {
        code: "validation_error",
        message: "Request validation failed",
        details: parsed.error.issues.map(i => ({
          field: i.path.join("."),
          message: i.message,
          code: i.code,
        })),
      },
    }, { status: 422 })
  }

  const user = await createUser(parsed.data)

  return NextResponse.json(
    { data: user },
    {
      status: 201,
      headers: { Location: `/api/v1/users/${user.id}` },
    },
  )
}
```
</implementation>

<versioning>
```
# URL path versioning (recommended)
/api/v1/users
/api/v2/users

# Rules
1. Start with /api/v1/ - don't version until needed
2. Max 2 active versions (current + previous)
3. Non-breaking changes don't need new version:
   - Adding new response fields
   - Adding optional query params
   - Adding new endpoints
4. Breaking changes require new version:
   - Removing/renaming fields
   - Changing field types
   - Changing URL structure
```
</versioning>

<rate_limiting>
```
HTTP/1.1 200 OK
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1640000000

HTTP/1.1 429 Too Many Requests
Retry-After: 60
{
  "error": {
    "code": "rate_limit_exceeded",
    "message": "Rate limit exceeded. Try again in 60 seconds."
  }
}
```
</rate_limiting>

<anti_patterns>
<block id="verbs_in_urls">/getUsers, /createOrder. Use HTTP methods for actions.</block>
<block id="200_for_errors">{ "status": 200, "success": false }. Use HTTP status codes.</block>
<block id="no_validation">Trusting user input. Validate everything with schemas.</block>
<block id="leaking_details">Stack traces in error responses. Generic messages for users.</block>
<block id="no_pagination">Returning all records. Pagination is mandatory for lists.</block>
</anti_patterns>

<on_complete>
agentdb write-end '{"skill":"api","endpoints_created":<N>,"validation":"zod|pydantic|none","pagination":"cursor|offset|none","versioning":"v1|none"}'

Record endpoints added and patterns used.
</on_complete>

</skill>
