---
name: e2e
description: "End-to-end testing with Playwright. Page Object Model, flaky test strategies, CI integration. Triggers: e2e, playwright, browser, end-to-end, integration-test, ui-test."
allowed-tools: Read, Bash, Write, Edit, Grep, Glob
---

<skill id="e2e">

<purpose>
E2E tests verify critical user paths in real browsers. Use sparingly - they're slow.
Page Object Model separates selectors from test logic. Update selectors in one place.
Flaky tests are broken tests. Fix or delete, never ignore.
</purpose>

<prerequisite>
AgentDB read-start has run. Check for existing Page Objects.
Verify Playwright is configured (playwright.config.ts exists).
</prerequisite>

<reference>
Skill-specific: skills/e2e/reference/e2e-research.md
</reference>

<core_principles>
1. CRITICAL PATHS ONLY: E2E tests are expensive. Test checkout, auth, core workflows. Not everything.
2. PAGE OBJECT MODEL: Selectors in one place. Tests read like specifications.
3. NO ARBITRARY WAITS: waitForTimeout is flaky. Wait for specific conditions.
4. SEMANTIC SELECTORS: data-testid, role, text. Never CSS classes.
5. QUARANTINE FLAKY: Mark flaky tests with test.fixme(). Never skip silently.
</core_principles>

<page_object_pattern>
```typescript
import { Page, Locator } from '@playwright/test'

export class LoginPage {
  readonly page: Page
  readonly emailInput: Locator
  readonly passwordInput: Locator
  readonly submitButton: Locator
  readonly errorMessage: Locator

  constructor(page: Page) {
    this.page = page
    this.emailInput = page.locator('[data-testid="email-input"]')
    this.passwordInput = page.locator('[data-testid="password-input"]')
    this.submitButton = page.locator('[data-testid="submit-btn"]')
    this.errorMessage = page.locator('[data-testid="error-msg"]')
  }

  async goto() {
    await this.page.goto('/login')
    await this.page.waitForLoadState('networkidle')
  }

  async login(email: string, password: string) {
    await this.emailInput.fill(email)
    await this.passwordInput.fill(password)
    await this.submitButton.click()
    await this.page.waitForLoadState('networkidle')
  }
}
```
</page_object_pattern>

<test_structure>
```typescript
import { test, expect } from '@playwright/test'
import { LoginPage } from '../pages/LoginPage'

test.describe('Authentication', () => {
  let loginPage: LoginPage

  test.beforeEach(async ({ page }) => {
    loginPage = new LoginPage(page)
    await loginPage.goto()
  })

  test('successful login redirects to dashboard', async ({ page }) => {
    await loginPage.login('user@example.com', 'password123')
    await expect(page).toHaveURL(/\/dashboard/)
  })

  test('invalid credentials show error', async () => {
    await loginPage.login('wrong@example.com', 'wrongpassword')
    await expect(loginPage.errorMessage).toBeVisible()
    await expect(loginPage.errorMessage).toContainText('Invalid credentials')
  })
})
```
</test_structure>

<flaky_test_patterns>
<!-- Quarantine flaky tests -->
```typescript
test('flaky: complex async flow', async ({ page }) => {
  test.fixme(true, 'Flaky - Issue #123')
  // test code...
})

test('skip in CI only', async ({ page }) => {
  test.skip(process.env.CI === 'true', 'Flaky in CI - Issue #456')
  // test code...
})
```

<!-- Fix common causes -->
```typescript
// BAD: arbitrary timeout
await page.waitForTimeout(5000)

// GOOD: wait for specific condition
await page.waitForResponse(resp => resp.url().includes('/api/data'))

// BAD: race condition
await page.click('[data-testid="menu"]')

// GOOD: wait for visibility first
await page.locator('[data-testid="menu"]').waitFor({ state: 'visible' })
await page.locator('[data-testid="menu"]').click()
```

<!-- Identify flakiness -->
```bash
npx playwright test tests/auth.spec.ts --repeat-each=10
```
</flaky_test_patterns>

<playwright_config>
```typescript
import { defineConfig, devices } from '@playwright/test'

export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [
    ['html', { outputFolder: 'playwright-report' }],
    ['junit', { outputFile: 'test-results.xml' }]
  ],
  use: {
    baseURL: process.env.BASE_URL || 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    actionTimeout: 10000,
    navigationTimeout: 30000,
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
    { name: 'webkit', use: { ...devices['Desktop Safari'] } },
  ],
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
    timeout: 120000,
  },
})
```
</playwright_config>

<ci_integration>
```yaml
# .github/workflows/e2e.yml
name: E2E Tests
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
          name: playwright-report
          path: playwright-report/
          retention-days: 30
```
</ci_integration>

<anti_patterns>
<block id="test_everything">E2E tests are slow. Test critical paths, not every feature.</block>
<block id="arbitrary_waits">waitForTimeout is flaky. Wait for specific conditions.</block>
<block id="css_selectors">CSS classes change. Use data-testid, role, or text.</block>
<block id="ignore_flaky">Flaky tests erode confidence. Fix or quarantine immediately.</block>
<block id="no_page_objects">Selectors scattered = maintenance nightmare. Use Page Objects.</block>
</anti_patterns>

<on_complete>
agentdb write-end '{"skill":"e2e","tests_written":<N>,"page_objects":["<list>"],"flaky_fixed":<N>,"ci_configured":<bool>}'

Record tests added, page objects created, and CI status.
</on_complete>

</skill>
