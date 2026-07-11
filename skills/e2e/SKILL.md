---
name: e2e
description: "End-to-end testing with Playwright. Page Object Model, flaky test strategies, CI integration. Triggers: e2e, playwright, browser, end-to-end, integration-test, ui-test."
allowed-tools: Read, Bash, Write, Edit, Grep, Glob
kernel:
  kind: methodology
  version: 1
  side_effects: none
  confirmation: none
---

<skill id="e2e">

<on_start>
agentdb read-start
Grep for existing Page Objects (pages/*.ts). Check playwright.config.ts exists.
</on_start>

<reference>
Skill-specific: skills/e2e/reference/e2e-research.md
</reference>

## Steps

1. **Scope** — identify critical user paths only (auth, checkout, core workflows). E2E tests are slow; reject requests to test everything.
   (gate: list of paths defined, count ≤ what team can maintain)

2. **Check existing Page Objects** — `grep -r "class.*Page" tests/pages/` or equivalent. Extend existing POM before creating new.
   (gate: no duplicate selector sets)

3. **Create/update Page Objects** — one file per page/component. Locators use `data-testid` > role > text > CSS (last resort). Selectors in constructor; actions and assertions as methods.
   (gate: no inline selectors in test files)

4. **Write tests** — `test.describe` blocks per feature. `beforeEach` for setup via POM. Each test asserts one outcome.
   (gate: no `waitForTimeout` in any test)

5. **Async correctness** — replace all arbitrary timeouts with condition waits:
   - network: `waitForResponse(r => r.url().includes('/api/...'))`
   - visibility: `locator(...).waitFor({ state: 'visible' })`
   - navigation: `waitForURL(/pattern/)`
   - load: `waitForLoadState('networkidle')`
   (gate: `grep -r "waitForTimeout" tests/` returns nothing)

6. **Handle flaky tests** — detect with `--repeat-each=10`. Fix root cause (race condition, animation timing, network timing). If fix deferred: `test.fixme(true, 'Flaky - Issue #NNN')`. Never silent-skip.
   (gate: no `test.skip()` without issue reference)

7. **Configure Playwright** — verify `playwright.config.ts` has: `retries: CI ? 2 : 0`, `forbidOnly: !!CI`, `trace: 'on-first-retry'`, `screenshot: 'only-on-failure'`. See reference for full config template.
   (gate: config file present, CI retries ≥ 2)

8. **CI integration** — add/verify GitHub Actions workflow: install with `--with-deps`, upload `playwright-report/` as artifact `if: always()`. See reference for full YAML.
   (gate: artifact upload step present)

9. **Run suite** — `npx playwright test`. All tests pass or are explicitly quarantined with issue refs.
   (gate: exit 0, or all failures are `test.fixme`)

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
