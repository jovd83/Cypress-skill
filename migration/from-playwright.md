# Migrating from Playwright to Cypress

> **When to use**: When converting a Playwright suite to Cypress v13+.
> **Prerequisites**: [core/locators.md](../core/locators.md), [core/assertions-and-waiting.md](../core/assertions-and-waiting.md)

## Key Mindset Shifts

### 1. Async/Await vs Cypress Command Queue

Playwright uses direct `async`/`await`. Cypress queues commands and executes them in order.

- Playwright: imperative promise flow.
- Cypress: chainable command flow with built-in retries.
- In Cypress, avoid `await cy...` patterns and keep assertions inside the chain.

### 2. Locator + Expect vs Chain + Should

Playwright typically uses `locator` + `expect(locator)` assertions. Cypress uses `cy.get/findBy...` + `.should(...)`.

### 3. Route Handling Differences

Playwright uses `page.route`. Cypress uses `cy.intercept` and aliases.

### 4. Test Isolation Setup

Playwright fixtures (`test.extend`) map to Cypress hooks, custom commands, and `cy.session()`.

### 5. Browser Context Capabilities

Playwright has multi-context, popup, and multi-tab control. Cypress has more constraints around multi-tab flows; design tests around in-app behavior and server state.

## Incremental Migration Strategy

1. Freeze flaky Playwright tests and migrate stable core flows first.
2. Keep selectors semantic (`findByRole`, `findByLabelText`) before converting edge-case selectors.
3. Migrate assertions and waits together so retries remain deterministic.
4. Convert network behavior to `cy.intercept` aliases before replacing helper abstractions.
5. Replace fixture-style setup with hooks/custom commands and stabilize auth with `cy.session()`.

## Command Mapping

| Playwright | Cypress | Notes |
|---|---|---|
| `page.goto('/x')` | `cy.visit('/x')` | Uses `baseUrl` from config |
| `page.getByRole('button', { name: 'Save' })` | `cy.findByRole('button', { name: 'Save' })` | Requires `@testing-library/cypress` |
| `page.getByLabel('Email')` | `cy.findByLabelText('Email')` | Semantic locator parity |
| `page.getByText('Done')` | `cy.findByText('Done')` | Use for non-interactive content |
| `page.getByTestId('row')` | `cy.get('[data-testid="row"]')` | Keep stable test id strategy |
| `locator.click()` | `cy.get(...).click()` | Cypress retries until actionable |
| `locator.fill('abc')` | `cy.get(...).clear().type('abc')` | Use `.type` for user-like behavior |
| `expect(locator).toBeVisible()` | `cy.get(...).should('be.visible')` | Retryable assertion |
| `expect(locator).toHaveText('x')` | `cy.get(...).should('have.text', 'x')` | `contain.text` for partial |
| `expect(locator).toHaveCount(3)` | `cy.get(...).should('have.length', 3)` | Collection length assertion |
| `page.route('**/api/**', handler)` | `cy.intercept('**/api/**', stub).as('api')` | Alias + `cy.wait('@api')` |
| `page.waitForResponse(...)` | `cy.wait('@alias')` | Register intercept first |
| `test.beforeEach` | `beforeEach` | Same hook idea |
| `test.extend(...)` | Custom commands + helpers + hooks | No fixture DI equivalent |
| `storageState` reuse | `cy.session()` | Cache login session |

## Example: Login Flow

**Playwright (TypeScript)**
```typescript
import { test, expect } from '@playwright/test';

test('login succeeds', async ({ page }) => {
  await page.goto('/login');
  await page.getByLabel('Email').fill('user@example.com');
  await page.getByLabel('Password').fill('password123');
  await page.getByRole('button', { name: 'Sign In' }).click();
  await expect(page.getByRole('heading', { name: 'Dashboard' })).toBeVisible();
});
```

**Playwright (JavaScript)**
```javascript
const { test, expect } = require('@playwright/test');

test('login succeeds', async ({ page }) => {
  await page.goto('/login');
  await page.getByLabel('Email').fill('user@example.com');
  await page.getByLabel('Password').fill('password123');
  await page.getByRole('button', { name: 'Sign In' }).click();
  await expect(page.getByRole('heading', { name: 'Dashboard' })).toBeVisible();
});
```

**Cypress (TypeScript)**
```typescript
describe('login', () => {
  it('succeeds', () => {
    cy.visit('/login');
    cy.findByLabelText('Email').type('user@example.com');
    cy.findByLabelText('Password').type('password123');
    cy.findByRole('button', { name: 'Sign In' }).click();
    cy.findByRole('heading', { name: 'Dashboard' }).should('be.visible');
  });
});
```

**Cypress (JavaScript)**
```javascript
describe('login', () => {
  it('succeeds', () => {
    cy.visit('/login');
    cy.findByLabelText('Email').type('user@example.com');
    cy.findByLabelText('Password').type('password123');
    cy.findByRole('button', { name: 'Sign In' }).click();
    cy.findByRole('heading', { name: 'Dashboard' }).should('be.visible');
  });
});
```

## Example: Network Stub

**Playwright**
```typescript
await page.route('**/api/profile', async (route) => {
  await route.fulfill({
    status: 200,
    contentType: 'application/json',
    body: JSON.stringify({ name: 'Jane Doe' }),
  });
});
```

**Playwright (JavaScript)**
```javascript
await page.route('**/api/profile', async (route) => {
  await route.fulfill({
    status: 200,
    contentType: 'application/json',
    body: JSON.stringify({ name: 'Jane Doe' }),
  });
});
```

**Cypress (TypeScript)**
```typescript
cy.intercept('GET', '**/api/profile', {
  statusCode: 200,
  body: { name: 'Jane Doe' },
}).as('profile');

cy.visit('/account');
cy.wait('@profile').its('response.statusCode').should('eq', 200);
cy.findByText('Jane Doe').should('be.visible');
```

**Cypress (JavaScript)**
```javascript
cy.intercept('GET', '**/api/profile', {
  statusCode: 200,
  body: { name: 'Jane Doe' },
}).as('profile');

cy.visit('/account');
cy.wait('@profile').its('response.statusCode').should('eq', 200);
cy.findByText('Jane Doe').should('be.visible');
```

## Anti-Patterns During Migration

| Anti-pattern | Why it fails | Correct approach |
|---|---|---|
| Porting `await` style directly into Cypress chains | Breaks Cypress execution model | Use chained Cypress commands and `.then(...)` |
| Mixing Promise utilities with Cypress commands in the same chain | Executes out of order and breaks retry behavior | Keep async work inside `cy.then(...)` or a custom command |
| Replacing assertions with raw DOM snapshots | Removes retry safety | Keep `.should(...)` assertions |
| Blind `cy.wait(2000)` replacements | Introduces flakiness | Use `cy.intercept` aliases and deterministic UI assertions |
| Overusing `{ force: true }` | Masks actionability defects | Fix overlays/disabled state root cause |

## Checklist

1. Replace Playwright locators with Cypress semantic locators.
2. Replace Playwright `expect(locator)...` assertions with Cypress `.should(...)`.
3. Convert network mocking to `cy.intercept` + aliases.
4. Replace fixture DI with hooks/custom commands.
5. Introduce `cy.session()` for stable auth reuse.

