# When to Mock

> **When to use**: Decide whether to mock network dependencies in Cypress tests based on confidence goals, speed, and reliability.

## Decision Matrix

| Goal | Mock? | Why |
|---|---|---|
| Validate UI states (loading/empty/error) | Yes | Deterministic and fast |
| Validate request payload/headers | Partial | Intercept + inspect request |
| Validate end-to-end backend integration | No / minimal | Real confidence requires real backend |
| Isolate flaky third-party APIs | Yes | Remove external instability |

## Recommended Test Mix

1. **High-volume regression**: mostly mocked external dependencies.
2. **Critical smoke**: minimal mocking, real backend where feasible.
3. **Error state tests**: explicitly mocked failures (`500`, `401`, `forceNetworkError`).

## What to Mock

- Third-party analytics, ads, chat widgets.
- Payment provider callback endpoints in non-production test environments.
- Rare failure paths that are hard to reproduce reliably.

## What Not to Over-Mock

- Core business workflows in all environments.
- Contract behavior between your frontend and your backend (at least one real smoke path needed).

## Cypress Patterns

### Full Mock

```typescript
cy.intercept('GET', '**/api/products', { fixture: 'products.json' }).as('products');
cy.visit('/products');
cy.wait('@products');
```

### Spy + Real Backend

```typescript
cy.intercept('POST', '**/api/orders').as('createOrder');
cy.findByRole('button', { name: /place order/i }).click();
cy.wait('@createOrder').then(({ request, response }) => {
  expect(request.body).to.have.property('items');
  expect(response && response.statusCode).to.be.oneOf([200, 201]);
});
```

### Simulate Failure

```typescript
cy.intercept('GET', '**/api/profile', { statusCode: 500, body: { error: 'boom' } }).as('profile500');
cy.visit('/profile');
cy.wait('@profile500');
cy.findByRole('alert').should('contain.text', 'Something went wrong');
```

## Anti-Patterns

- Mocking everything and calling it E2E coverage.
- Using unrealistic fixture shapes.
- Registering intercepts after UI action is triggered.
- Hiding backend regressions by over-stubbing in smoke suites.

## Related

- [core/network-mocking.md](network-mocking.md)
- [core/test-architecture.md](test-architecture.md)
- [core/error-and-edge-cases.md](error-and-edge-cases.md)
- [core/flaky-tests.md](flaky-tests.md)
