---
name: backend
description: "Backend architecture patterns. Repository pattern, caching, queues, N+1 prevention, transactions. Triggers: backend, server, database, cache, redis, queue, repository, service."
allowed-tools: Read, Bash, Write, Edit, Grep, Glob
---

<skill id="backend">

<purpose>
Separate concerns: repositories for data, services for logic, handlers for HTTP.
N+1 queries kill performance. Batch fetch, don't loop.
Cache reads, not writes. Invalidate on mutation.
</purpose>

<prerequisite>
AgentDB read-start has run. Check existing patterns in codebase.
Identify ORM (Prisma, Drizzle, TypeORM) and cache (Redis, in-memory).
</prerequisite>

<reference>
Skill-specific: skills/backend/reference/backend-research.md
</reference>

<core_principles>
1. REPOSITORY PATTERN: Abstract data access. Swap implementations without changing logic.
2. SERVICE LAYER: Business logic separate from data access and HTTP handling.
3. N+1 PREVENTION: Never query in a loop. Batch fetch with IN clauses.
4. CACHE-ASIDE: Check cache, miss -> fetch from DB -> populate cache.
5. TRANSACTIONS: Atomic operations. All succeed or all fail.
</core_principles>

<repository_pattern>
```typescript
interface UserRepository {
  findAll(filters?: UserFilters): Promise<User[]>
  findById(id: string): Promise<User | null>
  create(data: CreateUserDto): Promise<User>
  update(id: string, data: UpdateUserDto): Promise<User>
  delete(id: string): Promise<void>
}

class SupabaseUserRepository implements UserRepository {
  async findAll(filters?: UserFilters): Promise<User[]> {
    let query = supabase.from('users').select('id, name, email')

    if (filters?.role) {
      query = query.eq('role', filters.role)
    }

    const { data, error } = await query
    if (error) throw new Error(error.message)
    return data
  }
}
```
</repository_pattern>

<service_layer>
```typescript
class UserService {
  constructor(
    private userRepo: UserRepository,
    private emailService: EmailService
  ) {}

  async createUser(data: CreateUserDto): Promise<User> {
    // Business logic: validate, transform, orchestrate
    const existing = await this.userRepo.findByEmail(data.email)
    if (existing) throw new ConflictError('Email already registered')

    const user = await this.userRepo.create(data)
    await this.emailService.sendWelcome(user.email)

    return user
  }
}
```
</service_layer>

<n_plus_one_prevention>
```typescript
// BAD: N+1 queries
const orders = await getOrders()
for (const order of orders) {
  order.customer = await getCustomer(order.customer_id)  // N queries!
}

// GOOD: Batch fetch
const orders = await getOrders()
const customerIds = [...new Set(orders.map(o => o.customer_id))]
const customers = await getCustomersByIds(customerIds)  // 1 query
const customerMap = new Map(customers.map(c => [c.id, c]))

orders.forEach(order => {
  order.customer = customerMap.get(order.customer_id)
})
```

```typescript
// GOOD: Select only needed columns
const { data } = await supabase
  .from('orders')
  .select('id, total, status, customer:customers(id, name)')
  .eq('status', 'active')
  .limit(10)
```
</n_plus_one_prevention>

<caching>
```typescript
// Cache-aside pattern
class CachedUserRepository implements UserRepository {
  constructor(
    private baseRepo: UserRepository,
    private redis: RedisClient
  ) {}

  async findById(id: string): Promise<User | null> {
    const cacheKey = `user:${id}`

    // Check cache
    const cached = await this.redis.get(cacheKey)
    if (cached) return JSON.parse(cached)

    // Cache miss - fetch from DB
    const user = await this.baseRepo.findById(id)

    if (user) {
      // Cache for 5 minutes
      await this.redis.setex(cacheKey, 300, JSON.stringify(user))
    }

    return user
  }

  async update(id: string, data: UpdateUserDto): Promise<User> {
    const user = await this.baseRepo.update(id, data)
    // Invalidate cache on mutation
    await this.redis.del(`user:${id}`)
    return user
  }
}
```
</caching>

<transactions>
```typescript
// Supabase RPC for atomic operations
async function transferFunds(fromId: string, toId: string, amount: number) {
  const { data, error } = await supabase.rpc('transfer_funds', {
    from_id: fromId,
    to_id: toId,
    amount: amount
  })

  if (error) throw new Error('Transfer failed')
  return data
}

// SQL function
CREATE OR REPLACE FUNCTION transfer_funds(
  from_id uuid,
  to_id uuid,
  amount decimal
)
RETURNS jsonb
LANGUAGE plpgsql
AS $$
BEGIN
  -- Deduct from sender
  UPDATE accounts SET balance = balance - amount WHERE id = from_id;
  -- Add to receiver
  UPDATE accounts SET balance = balance + amount WHERE id = to_id;
  RETURN jsonb_build_object('success', true);
EXCEPTION
  WHEN OTHERS THEN
    -- Automatic rollback
    RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;
```
</transactions>

<error_handling>
```typescript
class ApiError extends Error {
  constructor(
    public statusCode: number,
    public message: string,
    public code: string
  ) {
    super(message)
  }
}

export function errorHandler(error: unknown): Response {
  if (error instanceof ApiError) {
    return NextResponse.json({
      error: { code: error.code, message: error.message }
    }, { status: error.statusCode })
  }

  if (error instanceof z.ZodError) {
    return NextResponse.json({
      error: {
        code: 'validation_error',
        message: 'Validation failed',
        details: error.errors
      }
    }, { status: 400 })
  }

  // Log unexpected errors, don't expose details
  console.error('Unexpected error:', error)
  return NextResponse.json({
    error: { code: 'internal_error', message: 'Internal server error' }
  }, { status: 500 })
}
```
</error_handling>

<retry_pattern>
```typescript
async function fetchWithRetry<T>(
  fn: () => Promise<T>,
  maxRetries = 3
): Promise<T> {
  let lastError: Error

  for (let i = 0; i < maxRetries; i++) {
    try {
      return await fn()
    } catch (error) {
      lastError = error as Error
      if (i < maxRetries - 1) {
        // Exponential backoff: 1s, 2s, 4s
        const delay = Math.pow(2, i) * 1000
        await new Promise(r => setTimeout(r, delay))
      }
    }
  }

  throw lastError!
}
```
</retry_pattern>

<queue_pattern>
```typescript
class JobQueue<T> {
  private queue: T[] = []
  private processing = false

  async add(job: T): Promise<void> {
    this.queue.push(job)
    if (!this.processing) this.process()
  }

  private async process(): Promise<void> {
    this.processing = true

    while (this.queue.length > 0) {
      const job = this.queue.shift()!
      try {
        await this.execute(job)
      } catch (error) {
        console.error('Job failed:', error)
        // Optionally: retry, dead-letter queue
      }
    }

    this.processing = false
  }

  private async execute(job: T): Promise<void> {
    // Implement job execution
  }
}
```
</queue_pattern>

<anti_patterns>
<block id="n_plus_one">Querying in loops. Batch fetch with IN clauses or joins.</block>
<block id="select_star">SELECT * is wasteful. Select only needed columns.</block>
<block id="no_transactions">Multi-step mutations without transactions. All or nothing.</block>
<block id="cache_writes">Caching write-heavy data. Cache reads, invalidate on writes.</block>
<block id="business_in_handlers">Business logic in HTTP handlers. Use service layer.</block>
<block id="expose_errors">Stack traces to users. Log details, return generic message.</block>
</anti_patterns>

<on_complete>
agentdb write-end '{"skill":"backend","patterns_used":["repository","service","cache-aside"],"n_plus_one_fixed":<N>,"cache_keys":["<list>"]}'

Record patterns applied and performance improvements.
</on_complete>

</skill>
