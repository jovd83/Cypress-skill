# POM vs Custom Commands vs Helpers

> **When to use**: Choose the right abstraction for Cypress test maintainability.
> **Prerequisites**: [page-object-model.md](page-object-model.md), [../core/fixtures-and-hooks.md](../core/fixtures-and-hooks.md)

## Quick Answer

- Use **POM** for complex pages with repeated UI workflows.
- Use **custom commands** for cross-page repeated actions (login, seed, checkout shortcuts).
- Use **helpers/factories** for pure data transformation or request payload creation.

## Comparison

| Approach | Best for | Pros | Cons |
|---|---|---|---|
| Page Object Model | Complex page interactions | Encapsulates selectors and flows | Can become over-engineered |
| Custom Commands | Shared workflow shortcuts | Reusable across specs | Easy to hide bad selectors |
| Helpers/Factories | Data creation and pure logic | Fast and testable | No UI encapsulation |

## Pattern 1: Page Object Model

**TypeScript**
```typescript
// cypress/support/pages/LoginPage.ts
export class LoginPage {
  visit() {
    cy.visit('/login');
  }

  fillEmail(email: string) {
    cy.findByLabelText(/email/i).clear().type(email);
  }

  fillPassword(password: string) {
    cy.findByLabelText(/password/i).clear().type(password);
  }

  submit() {
    cy.findByRole('button', { name: /sign in/i }).click();
  }

  assertLoggedIn() {
    cy.findByRole('heading', { name: /dashboard/i }).should('be.visible');
  }
}
```

```typescript
// cypress/e2e/auth/login.cy.ts
import { LoginPage } from '../../support/pages/LoginPage';

it('logs in using POM', () => {
  const loginPage = new LoginPage();
  loginPage.visit();
  loginPage.fillEmail('qa.user@example.com');
  loginPage.fillPassword('Password123!');
  loginPage.submit();
  loginPage.assertLoggedIn();
});
```

**JavaScript**
```javascript
class LoginPage {
  visit() {
    cy.visit('/login');
  }
  fillEmail(email) {
    cy.findByLabelText(/email/i).clear().type(email);
  }
  fillPassword(password) {
    cy.findByLabelText(/password/i).clear().type(password);
  }
  submit() {
    cy.findByRole('button', { name: /sign in/i }).click();
  }
}
```

## Pattern 2: Custom Commands

```typescript
// cypress/support/commands.ts
Cypress.Commands.add('loginByApi', (email: string, password: string) => {
  cy.request('POST', '/api/auth/login', { email, password }).then((res) => {
    window.localStorage.setItem('access_token', res.body.accessToken);
  });
});
```

```typescript
// usage
beforeEach(() => {
  cy.loginByApi(Cypress.env('USER_EMAIL'), Cypress.env('USER_PASSWORD'));
});
```

Use custom commands for repeatable actions that are not tied to one specific page object.

## Pattern 3: Helper/Factory Functions

```typescript
// cypress/support/factories/orderFactory.ts
export const buildOrder = (overrides = {}) => ({
  customerEmail: `buyer-${Date.now()}@example.com`,
  items: [{ sku: 'shoe-001', qty: 1 }],
  couponCode: null,
  ...overrides,
});
```

```typescript
// usage
cy.request('POST', '/api/orders', buildOrder({ couponCode: 'WELCOME10' }))
  .its('status')
  .should('eq', 201);
```

## Decision Framework

1. Is this logic tied to a specific page's UI?
   - Yes: POM.
2. Is this reused across many pages/specs?
   - Yes: Custom command.
3. Is this pure data logic with no UI interaction?
   - Yes: Helper/factory.

## Combining All Three (Recommended for Large Suites)

```typescript
import { LoginPage } from '../support/pages/LoginPage';
import { buildOrder } from '../support/factories/orderFactory';

describe('checkout', () => {
  beforeEach(() => {
    cy.loginByApi(Cypress.env('USER_EMAIL'), Cypress.env('USER_PASSWORD'));
  });

  it('submits an order end-to-end', () => {
    cy.request('POST', '/api/orders/seed', buildOrder({ items: [{ sku: 'shoe-001', qty: 2 }] }));

    const loginPage = new LoginPage();
    loginPage.visit();
    loginPage.assertLoggedIn();

    cy.visit('/checkout');
    cy.findByRole('button', { name: /place order/i }).click();
    cy.findByText(/order confirmed/i).should('be.visible');
  });
});
```

## Anti-Patterns

| Anti-pattern | Problem | Better approach |
|---|---|---|
| POM stores long-lived element references | Cypress chains are lazy/retried and should be re-queried | Expose methods, not stored element handles |
| Huge god-class page objects | Hard to maintain | Split by page section or flow |
| Custom command wraps unstable selectors | Reuses flakiness globally | Build on semantic selectors |
| Helpers with side effects | Hidden setup/cleanup | Keep helpers pure; side effects in commands/hooks |

## Residual Legacy Mappings

If migrating from a fixture-driven framework:

- Fixture-style dependency injection -> Cypress hooks + custom commands.
- `page` methods -> POM methods using Cypress chainables.
- `request` fixture -> `cy.request`.

## Related Guides

- [page-object-model.md](page-object-model.md)
- [../core/fixtures-and-hooks.md](../core/fixtures-and-hooks.md)
- [../core/test-data-management.md](../core/test-data-management.md)
