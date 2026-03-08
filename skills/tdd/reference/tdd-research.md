# TDD Research

Deep reference for Test-Driven Development methodology.

## The TDD Cycle

### Red Phase
Write a failing test that defines expected behavior.
- Test must fail for the right reason
- Test should be minimal - test one thing
- Name describes the specification: `should_return_empty_array_when_no_users_exist`

### Green Phase
Write minimal code to make the test pass.
- No premature optimization
- No anticipatory features ("we might need this later")
- Code can be ugly - we'll clean it up

### Refactor Phase
Improve code while keeping tests green.
- Remove duplication
- Improve naming
- Extract methods/functions
- Run tests after EVERY change

## Test Organization Strategies

### Colocated Tests
```
src/
  components/
    Button/
      Button.tsx
      Button.test.tsx
      Button.stories.tsx
```

Pros: Easy to find, enforces module boundaries
Cons: Test noise in src tree

### Separate Test Directory
```
src/
  components/
    Button.tsx
tests/
  unit/
    components/
      Button.test.tsx
  integration/
  e2e/
```

Pros: Clean separation, clear test hierarchy
Cons: Path management, easier to forget tests

### Recommendation
Colocate unit tests. Separate integration and e2e.

## Mocking Strategies

### When to Mock
- External services (APIs, databases)
- Non-deterministic behavior (time, random)
- Slow operations
- Side effects (email, SMS)

### When NOT to Mock
- Internal implementation details
- Simple utilities without side effects
- The code under test itself

### Mock Levels

1. **Spy**: Observe calls without changing behavior
2. **Stub**: Return fixed values
3. **Mock**: Verify interactions
4. **Fake**: Simplified implementation (in-memory DB)

## Coverage Philosophy

### 80% Rule
Target 80% coverage as baseline. Beyond 80% shows diminishing returns.

### Coverage Lies
High coverage != good tests. Check:
- Are assertions meaningful?
- Are edge cases covered?
- Would a bug make any test fail?

### Mutation Testing
Inject bugs, verify tests catch them. If test passes with bug, test is weak.

## Common Pitfalls

### 1. Testing Implementation
```typescript
// BAD: Tests internal state
expect(component.state.count).toBe(5)

// GOOD: Tests observable behavior
expect(screen.getByText('Count: 5')).toBeInTheDocument()
```

### 2. Over-mocking
```typescript
// BAD: Mock everything
jest.mock('./utils')
jest.mock('./helpers')
jest.mock('./formatters')

// GOOD: Test real code, mock boundaries
jest.mock('@/lib/database')  // Only external boundary
```

### 3. Test Interdependence
```typescript
// BAD: Tests share state
let user
beforeAll(() => { user = createUser() })
test('update user', () => { updateUser(user) })
test('delete user', () => { deleteUser(user) })  // Depends on previous

// GOOD: Each test isolated
test('update user', () => {
  const user = createUser()
  updateUser(user)
  // verify
})
```

### 4. Snapshot Overuse
Snapshots are brittle. Use for:
- Complex generated output (error messages)
- Visual regression (with review process)

Don't use for:
- Simple values (use explicit assertions)
- Frequently changing UI
- Generated code

## Framework-Specific Patterns

### Jest + React Testing Library
```typescript
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'

test('form submission', async () => {
  const user = userEvent.setup()
  const onSubmit = jest.fn()

  render(<Form onSubmit={onSubmit} />)

  await user.type(screen.getByLabelText('Email'), 'test@example.com')
  await user.click(screen.getByRole('button', { name: 'Submit' }))

  await waitFor(() => {
    expect(onSubmit).toHaveBeenCalledWith({ email: 'test@example.com' })
  })
})
```

### Vitest
```typescript
import { describe, it, expect, vi, beforeEach } from 'vitest'

describe('UserService', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('creates user with hashed password', async () => {
    const hashSpy = vi.spyOn(crypto, 'hash')

    await userService.create({ email: 'test@example.com', password: 'secret' })

    expect(hashSpy).toHaveBeenCalledWith('secret')
  })
})
```

### pytest
```python
import pytest
from unittest.mock import Mock, patch

@pytest.fixture
def user_service():
    db = Mock()
    return UserService(db)

def test_create_user_hashes_password(user_service):
    with patch('app.services.hash_password') as mock_hash:
        mock_hash.return_value = 'hashed'

        user_service.create(email='test@example.com', password='secret')

        mock_hash.assert_called_once_with('secret')
```

## Resources

- Kent Beck, "Test-Driven Development By Example"
- Martin Fowler, "Mocks Aren't Stubs"
- Testing Library docs: testing-library.com
