# Fixtures and Hooks

> **When to use**: Share setup, reuse test data, and keep tests deterministic in Cypress.
> **Prerequisites**: [test-data-management.md](test-data-management.md), [authentication.md](authentication.md)

## Cypress Terminology

- Fixture-style dependency injection is not available in Cypress.
- In Cypress, reusable setup is built with:
  - hooks (`before`, `beforeEach`, `afterEach`, `after`)
  - custom commands (`cypress/support/commands.*`)
  - fixture files (`cypress/fixtures/*.json`)
  - utility helpers (`cypress/support/*.ts`)
  - `cy.session()` for auth/session caching

## Quick Reference

```typescript
beforeEach(() => {
  cy.loginByApi('qa.user@example.com', 'Password123!');
});

it('shows dashboard widgets', () => {
  cy.visit('/dashboard');
  cy.findByRole('heading', { name: /dashboard/i }).should('be.visible');
});
```

## Pattern 1: Use Fixture Files for Static Data

**TypeScript**
```typescript
it('submits profile form from fixture data', () => {
  cy.fixture('profile').then((profile) => {
    cy.visit('/profile/edit');
    cy.findByLabelText('First name').clear().type(profile.firstName);
    cy.findByLabelText('Last name').clear().type(profile.lastName);
    cy.findByRole('button', { name: /save/i }).click();
    cy.findByText(/profile updated/i).should('be.visible');
  });
});
```

**JavaScript**
```javascript
it('submits profile form from fixture data', () => {
  cy.fixture('profile').then((profile) => {
    cy.visit('/profile/edit');
    cy.findByLabelText('First name').clear().type(profile.firstName);
    cy.findByLabelText('Last name').clear().type(profile.lastName);
    cy.findByRole('button', { name: /save/i }).click();
  });
});
```

## Pattern 2: Use Custom Commands for Shared Workflows

```typescript
// cypress/support/commands.ts
Cypress.Commands.add('loginByApi', (email: string, password: string) => {
  cy.request('POST', '/api/auth/login', { email, password }).then((res) => {
    window.localStorage.setItem('access_token', res.body.accessToken);
  });
});
```

```typescript
// cypress/e2e/account.cy.ts
beforeEach(() => {
  cy.loginByApi(Cypress.env('USER_EMAIL'), Cypress.env('USER_PASSWORD'));
});
```

Use custom commands when the same flow appears in many specs.

## Pattern 3: `cy.session()` for Fast Auth Setup

```typescript
beforeEach(() => {
  cy.session(['standard-user'], () => {
    cy.request('POST', '/api/auth/login', {
      email: Cypress.env('USER_EMAIL'),
      password: Cypress.env('USER_PASSWORD'),
    }).then((res) => {
      window.localStorage.setItem('access_token', res.body.accessToken);
    });
  });
});

it('opens orders page as authenticated user', () => {
  cy.visit('/orders');
  cy.findByRole('heading', { name: /orders/i }).should('be.visible');
});
```

## Pattern 4: Hook Scope Selection

Use `before` for one-time read-only prep:

```typescript
before(() => {
  cy.request('/api/health').its('status').should('eq', 200);
});
```

Use `beforeEach` for per-test setup:

```typescript
beforeEach(() => {
  cy.task('resetDb');
});
```

Use `afterEach` for cleanup that must happen after every test:

```typescript
afterEach(() => {
  cy.clearCookies();
  cy.clearLocalStorage();
});
```

## Pattern 5: API Seeding in Hooks

```typescript
beforeEach(() => {
  cy.request('POST', '/api/test-data/reset');
  cy.request('POST', '/api/test-data/seed', { scenario: 'checkout-basic' });
});

it('completes checkout', () => {
  cy.visit('/checkout');
  cy.findByRole('button', { name: /place order/i }).click();
  cy.findByText(/order confirmed/i).should('be.visible');
});
```

## Anti-Patterns

| Anti-pattern | Why it fails | Cypress approach |
|---|---|---|
| Translating fixture-DI patterns directly | Cypress has no fixture DI container | Use hooks + custom commands + helpers |
| Doing expensive setup in every test | Slow and unstable suite | Use `cy.session()` and API seeding |
| Sharing mutable global variables across specs | Cross-test coupling | Create data inside each test or per-spec hook |
| Cleanup only on happy path | Leaves polluted state | Put cleanup in `afterEach`/backend reset endpoint |
| Hiding flaky selectors in commands | Reuses unstable behavior | Build commands on stable locators only |

## Decision Guide

Use this quick rule:

1. Static data payload? Use `cy.fixture`.
2. Repeated user flow? Use custom command.
3. Login/session reuse? Use `cy.session`.
4. Environment reset or seed? Use hooks + API/task.
5. Cross-spec orchestration? Use `cy.task` in Node process.

## Minimal `commands.d.ts` Typing (TypeScript)

```typescript
// cypress/support/commands.d.ts
declare global {
  namespace Cypress {
    interface Chainable {
      loginByApi(email: string, password: string): Chainable<void>;
    }
  }
}

export {};
```

## Troubleshooting

### Hook runs but app is still unauthenticated

- Ensure `cy.visit()` occurs after login storage/cookie setup.
- Verify auth token key name matches app expectations.
- Confirm same domain for cookie/localStorage writes.

### `cy.session()` appears to rerun every test

- Check session key stability.
- Confirm app is not clearing auth state on load.
- Validate with `validate` callback if needed:

```typescript
cy.session('admin', loginFn, {
  validate() {
    cy.request('/api/me').its('status').should('eq', 200);
  },
});
```

### Data from one test leaks into another

- Reset data in `beforeEach` or use isolated tenant/test user IDs.
- Avoid shared mutable objects outside tests.

## Related Guides

- [test-data-management.md](test-data-management.md)
- [authentication.md](authentication.md)
- [api-testing.md](api-testing.md)
- [common-pitfalls.md](common-pitfalls.md)
