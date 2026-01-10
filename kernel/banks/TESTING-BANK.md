# Testing Bank

**Test strategy: What, When, How**

---

## The Testing Pyramid

```
        /\
       /E2E\         Few (slow, brittle, expensive)
      /------\
     /        \
    /Integration\    Some (medium speed, medium cost)
   /------------\
  /              \
 /  Unit Tests    \  Many (fast, cheap, reliable)
/------------------\
```

**Rule: More unit tests, fewer integration tests, minimal E2E tests.**

---

## When to Write Tests

### Always Test
✅ Core business logic
✅ Data transformations
✅ Edge cases (null, empty, boundaries)
✅ Error handling paths
✅ Public APIs

### Sometimes Test
⚠️ Integration between components (if complex)
⚠️ Database queries (if complex logic)
⚠️ External API calls (mock them)

### Rarely Test
❌ Simple getters/setters
❌ Framework boilerplate
❌ UI layout (use visual regression instead)
❌ Third-party library internals

---

## What to Test

### Test Behavior, Not Implementation

```javascript
// BAD: Testing implementation details
test('uses array.map internally', () => {
  const spy = jest.spyOn(Array.prototype, 'map')
  transform(data)
  expect(spy).toHaveBeenCalled()
})

// GOOD: Testing behavior
test('transforms data correctly', () => {
  const input = [1, 2, 3]
  const output = transform(input)
  expect(output).toEqual([2, 4, 6])
})
```

### Test Cases to Cover

1. **Happy Path** - Normal, expected input
2. **Edge Cases** - Empty, null, undefined, zero, negative
3. **Boundaries** - Min, max values
4. **Errors** - Invalid input, failures, exceptions
5. **State** - Different initial states

---

## Test Structure: AAA Pattern

```javascript
test('adds item to cart', () => {
  // ARRANGE: Set up test data
  const cart = createEmptyCart()
  const item = { id: 1, name: 'Widget', price: 10 }

  // ACT: Perform the action
  const result = addToCart(cart, item)

  // ASSERT: Verify the outcome
  expect(result.items).toHaveLength(1)
  expect(result.items[0]).toEqual(item)
  expect(result.total).toBe(10)
})
```

---

## Stack-Specific Examples

### JavaScript/TypeScript (Jest)
```typescript
describe('calculateTotal', () => {
  it('sums item prices', () => {
    const items = [
      { price: 10 },
      { price: 20 },
      { price: 30 }
    ]
    expect(calculateTotal(items)).toBe(60)
  })

  it('returns 0 for empty cart', () => {
    expect(calculateTotal([])).toBe(0)
  })

  it('throws on invalid price', () => {
    expect(() => calculateTotal([{ price: -10 }]))
      .toThrow('Invalid price')
  })
})
```

### Python (pytest)
```python
def test_calculate_total_sums_prices():
    items = [
        {'price': 10},
        {'price': 20},
        {'price': 30}
    ]
    assert calculate_total(items) == 60

def test_calculate_total_empty_cart():
    assert calculate_total([]) == 0

def test_calculate_total_invalid_price():
    with pytest.raises(ValueError, match="Invalid price"):
        calculate_total([{'price': -10}])
```

### Go
```go
func TestCalculateTotal(t *testing.T) {
    items := []Item{
        {Price: 10},
        {Price: 20},
        {Price: 30},
    }
    result := CalculateTotal(items)
    if result != 60 {
        t.Errorf("Expected 60, got %d", result)
    }
}

func TestCalculateTotalEmptyCart(t *testing.T) {
    result := CalculateTotal([]Item{})
    if result != 0 {
        t.Errorf("Expected 0, got %d", result)
    }
}
```

---

## Mocking External Dependencies

### Mock HTTP Requests
```javascript
// Mock fetch
global.fetch = jest.fn(() =>
  Promise.resolve({
    json: () => Promise.resolve({ data: 'mocked' })
  })
)

test('fetches user data', async () => {
  const user = await fetchUser(123)
  expect(user.data).toBe('mocked')
  expect(fetch).toHaveBeenCalledWith('/api/users/123')
})
```

### Mock Database
```python
# Mock database with fixture
@pytest.fixture
def db():
    return MockDatabase()

def test_get_user(db):
    db.add_user(id=1, name='Alice')
    user = get_user(db, id=1)
    assert user.name == 'Alice'
```

---

## Test Coverage Guidelines

### Minimum Coverage by Tier

**Tier 1 (Hackathon):**
- Core logic: 50%+
- Edge cases: As time allows

**Tier 2 (Production):**
- Core logic: 80%+
- Edge cases: Critical paths covered
- Integration: Key flows tested

**Tier 3 (Critical):**
- Core logic: 95%+
- Edge cases: All covered
- Integration: All flows tested
- E2E: Critical user journeys

---

## Common Testing Patterns

### Test Data Builders
```javascript
// Builder pattern for test data
function userBuilder(overrides = {}) {
  return {
    id: 1,
    name: 'Test User',
    email: 'test@example.com',
    role: 'user',
    ...overrides
  }
}

test('admin can delete users', () => {
  const admin = userBuilder({ role: 'admin' })
  expect(canDelete(admin)).toBe(true)
})
```

### Parameterized Tests
```python
@pytest.mark.parametrize("input,expected", [
    (0, "zero"),
    (1, "one"),
    (2, "two"),
    (100, "many"),
])
def test_number_to_word(input, expected):
    assert number_to_word(input) == expected
```

---

## Integration Testing

### Test Database Integration
```javascript
// Setup/teardown for DB tests
beforeEach(async () => {
  await db.migrate()
  await db.seed()
})

afterEach(async () => {
  await db.reset()
})

test('creates user in database', async () => {
  const user = await createUser({ name: 'Alice' })
  const found = await db.users.findById(user.id)
  expect(found.name).toBe('Alice')
})
```

### Test API Endpoints
```javascript
test('POST /users creates user', async () => {
  const response = await request(app)
    .post('/users')
    .send({ name: 'Alice', email: 'alice@example.com' })
    .expect(201)

  expect(response.body.name).toBe('Alice')
  expect(response.body.id).toBeDefined()
})
```

---

## Red Flags in Tests

❌ **Flaky tests** (pass sometimes, fail others)
- Usually timing issues, shared state, or async problems

❌ **Tests that test nothing**
```javascript
test('function runs', () => {
  myFunction() // No assertion!
})
```

❌ **Overly complex tests**
- If test is hard to understand, the code probably is too

❌ **Testing implementation details**
- Breaks when refactoring, even if behavior unchanged

---

## When to Use This Bank

✅ Writing tests for new feature
✅ Deciding what to test
✅ Improving test coverage
✅ Debugging failing tests
✅ Setting up test infrastructure

---

**Remember: Good tests give you confidence to refactor and ship.**
