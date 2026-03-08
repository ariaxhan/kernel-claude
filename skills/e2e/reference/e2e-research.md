# E2E Research

Deep reference for End-to-End testing with Playwright.

## Testing Pyramid

```
     /\
    /E2E\        Few, slow, expensive
   /------\
  /Integrat\     Some, medium speed
 /------------\
/    Unit      \ Many, fast, cheap
----------------
```

### E2E Position
- Top of pyramid: fewest tests
- Test critical user journeys only
- Most expensive to maintain
- Most realistic but slowest

## Playwright Architecture

### Browser Contexts
Isolated browser environments. Each context:
- Fresh cookies/localStorage
- Independent network state
- Parallel execution safe

```typescript
const context = await browser.newContext({
  viewport: { width: 1920, height: 1080 },
  locale: 'en-US',
  timezoneId: 'America/New_York',
})
const page = await context.newPage()
```

### Auto-waiting
Playwright auto-waits for:
- Elements to be attached to DOM
- Elements to be visible
- Elements to be stable (not animating)
- Elements to receive events

DON'T add manual waits unless necessary.

## Page Object Model (POM)

### Philosophy
Separate "what" (test) from "how" (selectors).

### Structure
```typescript
// pages/LoginPage.ts
export class LoginPage {
  // Selectors in one place
  readonly page: Page
  readonly emailInput: Locator
  readonly passwordInput: Locator
  readonly submitButton: Locator
  readonly errorMessage: Locator
  readonly successMessage: Locator

  constructor(page: Page) {
    this.page = page
    this.emailInput = page.locator('[data-testid="email"]')
    this.passwordInput = page.locator('[data-testid="password"]')
    this.submitButton = page.locator('[data-testid="submit"]')
    this.errorMessage = page.locator('[data-testid="error"]')
    this.successMessage = page.locator('[data-testid="success"]')
  }

  // Actions as methods
  async goto() {
    await this.page.goto('/login')
  }

  async login(email: string, password: string) {
    await this.emailInput.fill(email)
    await this.passwordInput.fill(password)
    await this.submitButton.click()
  }

  // Assertions as methods
  async expectError(message: string) {
    await expect(this.errorMessage).toContainText(message)
  }

  async expectLoggedIn() {
    await expect(this.page).toHaveURL(/\/dashboard/)
  }
}
```

### Test Usage
```typescript
test('valid login', async ({ page }) => {
  const loginPage = new LoginPage(page)
  await loginPage.goto()
  await loginPage.login('user@example.com', 'password')
  await loginPage.expectLoggedIn()
})
```

## Selector Strategies

### Priority (Best to Worst)
1. `data-testid` - Explicit, stable
2. `role` - Semantic, accessible
3. `text` - User-visible, readable
4. `CSS selector` - Last resort

### Examples
```typescript
// BEST: data-testid
page.locator('[data-testid="submit-button"]')

// GOOD: role
page.getByRole('button', { name: 'Submit' })

// OK: text
page.getByText('Submit')

// AVOID: CSS (fragile)
page.locator('.btn-primary.submit')
page.locator('#form-submit-btn')
```

### Chaining
```typescript
// Find button inside specific section
page.locator('[data-testid="checkout-section"]')
    .getByRole('button', { name: 'Pay' })
```

## Handling Async Operations

### Bad: Arbitrary Timeouts
```typescript
// NEVER DO THIS
await page.waitForTimeout(5000)
```

### Good: Wait for Conditions
```typescript
// Wait for network
await page.waitForResponse(r => r.url().includes('/api/users'))

// Wait for element state
await page.locator('[data-testid="modal"]').waitFor({ state: 'visible' })

// Wait for navigation
await page.waitForURL(/\/dashboard/)

// Wait for network idle
await page.waitForLoadState('networkidle')
```

## Flaky Test Strategies

### Detection
```bash
# Repeat test to identify flakiness
npx playwright test tests/checkout.spec.ts --repeat-each=10

# Run with retries
npx playwright test --retries=3
```

### Common Causes

1. **Race Conditions**
```typescript
// BAD
await page.click('[data-testid="button"]')

// GOOD
await page.locator('[data-testid="button"]').waitFor({ state: 'visible' })
await page.locator('[data-testid="button"]').click()
```

2. **Animation Timing**
```typescript
// BAD
await page.click('[data-testid="dropdown-item"]')

// GOOD
await page.locator('[data-testid="dropdown"]').waitFor({ state: 'visible' })
await page.waitForLoadState('networkidle')
await page.locator('[data-testid="dropdown-item"]').click()
```

3. **Network Timing**
```typescript
// BAD
await page.click('[data-testid="save"]')
expect(/* immediate check */)

// GOOD
const responsePromise = page.waitForResponse('/api/save')
await page.click('[data-testid="save"]')
await responsePromise
expect(/* check after response */)
```

### Quarantine Pattern
```typescript
test('known flaky test', async ({ page }) => {
  test.fixme(true, 'Flaky - tracking in #123')
  // ...
})

test('flaky in CI only', async ({ page }) => {
  test.skip(process.env.CI === 'true', 'Flaky in CI - #456')
  // ...
})
```

## Debugging

### Traces
```typescript
// playwright.config.ts
use: {
  trace: 'on-first-retry'  // Captures trace on failures
}
```

View: `npx playwright show-trace trace.zip`

### Screenshots
```typescript
await page.screenshot({ path: 'debug.png' })
await page.screenshot({ path: 'full.png', fullPage: true })
await page.locator('[data-testid="chart"]').screenshot({ path: 'chart.png' })
```

### Video
```typescript
use: {
  video: 'retain-on-failure'
}
```

### Debug Mode
```bash
# Step through test
npx playwright test --debug

# Open browser, pause at start
npx playwright test --headed --pause
```

## CI/CD Integration

### GitHub Actions
```yaml
name: E2E
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      - run: npm ci
      - run: npx playwright install --with-deps
      - run: npx playwright test
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: test-results
          path: |
            playwright-report/
            test-results/
```

### Parallelization
```typescript
// playwright.config.ts
export default defineConfig({
  fullyParallel: true,
  workers: process.env.CI ? 1 : undefined,  // Single worker in CI
})
```

### Sharding
```bash
# Split across 4 machines
npx playwright test --shard=1/4
npx playwright test --shard=2/4
npx playwright test --shard=3/4
npx playwright test --shard=4/4
```

## Resources

- Playwright docs: playwright.dev
- Testing Library philosophy: testing-library.com/docs/guiding-principles
- Page Object Model: martinfowler.com/bliki/PageObject.html
