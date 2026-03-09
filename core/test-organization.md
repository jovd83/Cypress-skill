# Test Organization

> **When to use**: Structure Cypress tests for maintainability, fast feedback, and clear ownership as your suite scales.

## Recommended Layout

```text
cypress/
  e2e/
    smoke/
      auth.cy.ts
      checkout.cy.ts
    regression/
      users/
        create-user.cy.ts
        edit-user.cy.ts
      billing/
        invoices.cy.ts
  fixtures/
    users.json
    products.json
  support/
    commands.ts
    e2e.ts
```

## Naming Conventions

- Specs: `feature-action.cy.ts` (or `.cy.js`).
- One dominant behavior per spec file.
- Keep test names outcome-oriented (`it('shows validation error for invalid VAT')`).

## Test Layers

| Layer | Purpose | Typical Runtime |
|---|---|---|
| Smoke | Release gate for critical paths | Fast |
| Regression | Broad behavior coverage | Medium/High |
| Visual (optional) | UI drift detection | Medium |
| Component (if used) | Isolated component behavior | Fast |

## Tagging Strategy

Use naming or grep tags to select suites.

```typescript
it('user can sign in @smoke', () => {
  // ...
});

it('admin can export invoices @regression', () => {
  // ...
});
```

```bash
# Run all
npx cypress run

# Run one spec
npx cypress run --spec cypress/e2e/smoke/auth.cy.ts

# Open interactive runner
npx cypress open
```

## Reuse Patterns

### Custom Commands for Repeated UI Flows

```typescript
// cypress/support/commands.ts
Cypress.Commands.add('loginUI', (email: string, password: string) => {
  cy.visit('/login');
  cy.findByLabelText('Email').clear().type(email);
  cy.findByLabelText('Password').clear().type(password);
  cy.findByRole('button', { name: 'Sign in' }).click();
  cy.location('pathname').should('include', '/dashboard');
});
```

### Session Caching

```typescript
beforeEach(() => {
  cy.session('admin', () => {
    cy.request('POST', '/api/login', {
      email: 'admin@example.com',
      password: 'secure-password'
    }).its('status').should('eq', 200);
  });
});
```

## Data Strategy

1. Keep fixtures small and behavior-specific.
2. Use factories for generated data when values need variation.
3. Reset database state per test run (or per spec) for determinism.

## Isolation Rules

- Tests must not depend on order.
- Avoid shared mutable state across specs.
- Never rely on data created by a previous test unless explicitly seeded.

## Example Spec Structure

```typescript
describe('checkout', () => {
  beforeEach(() => {
    cy.intercept('GET', '**/api/cart', { fixture: 'cart-single-item.json' }).as('cart');
    cy.session('buyer', () => {
      cy.request('POST', '/api/login', {
        email: 'buyer@example.com',
        password: 'secure-password'
      });
    });
  });

  it('completes payment with valid card @smoke', () => {
    cy.visit('/checkout');
    cy.wait('@cart');

    cy.findByLabelText('Card number').clear().type('4242424242424242');
    cy.findByLabelText('Expiration').clear().type('12/28');
    cy.findByLabelText('CVC').clear().type('123');
    cy.findByRole('button', { name: 'Place order' }).click();

    cy.findByText('Order confirmed').should('be.visible');
  });
});
```

## CI-Friendly Practices

- Split by spec groups (smoke/regression/visual).
- Keep flaky tests quarantined and tracked.
- Save screenshots/videos for failed specs.
- Use retries only after root-cause analysis.

## Anti-Patterns

- One giant spec file with unrelated flows.
- Overuse of `before` hooks that hide test setup.
- Assertions only at the end of long tests.
- Naming like `test1.cy.ts`, `new.cy.ts`, `final-final.cy.ts`.

## Related

- [core/test-architecture.md](test-architecture.md)
- [core/fixtures-and-hooks.md](fixtures-and-hooks.md)
- [core/flaky-tests.md](flaky-tests.md)
- [ci/parallel-and-sharding.md](../ci/parallel-and-sharding.md)
