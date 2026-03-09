# Test Data Management

> **When to use**: Any test that needs predictable users, products, orders, permissions, or environment state.
> **Prerequisites**: [fixtures-and-hooks.md](fixtures-and-hooks.md), [api-testing.md](api-testing.md)

## Goals

1. Deterministic test outcomes.
2. Fast setup and cleanup.
3. Isolation between tests and CI jobs.

## Quick Reference

```typescript
it('creates data by API before UI assertions', () => {
  const sku = `sku-${Date.now()}`;

  cy.request('POST', '/api/products', { name: 'Test Product', sku, price: 20 });
  cy.visit('/shop');
  cy.findByText('Test Product').should('be.visible');
});
```

## Data Strategy Order (Fastest to Slowest)

1. Inline data for one-off checks.
2. Factory helpers for reusable shapes.
3. `cy.fixture` files for static payloads.
4. API seeding (`cy.request`) for realistic backend state.
5. UI-only setup as last resort.

## Pattern 1: Factory Helpers

**TypeScript**
```typescript
// cypress/support/factories/userFactory.ts
export function buildUser(overrides: Partial<{ name: string; email: string; role: string }> = {}) {
  const id = Date.now();
  return {
    name: `User ${id}`,
    email: `user-${id}@example.com`,
    role: 'viewer',
    ...overrides,
  };
}
```

```typescript
// usage
import { buildUser } from '../support/factories/userFactory';

it('creates a custom admin user', () => {
  const user = buildUser({ role: 'admin' });
  cy.request('POST', '/api/users', user).its('status').should('eq', 201);
});
```

## Pattern 2: Static Fixtures

```typescript
it('submits billing form from fixture', () => {
  cy.fixture('billing-address').then((address) => {
    cy.visit('/checkout');
    cy.findByLabelText('Street').type(address.street);
    cy.findByLabelText('City').type(address.city);
    cy.findByLabelText('Zip code').type(address.zip);
    cy.findByRole('button', { name: /continue/i }).click();
  });
});
```

## Pattern 3: API Seeding and Cleanup

Create and tear down entities explicitly.

```typescript
let createdOrderId: number;

beforeEach(() => {
  cy.request('POST', '/api/orders', { items: [{ sku: 'seed-1', qty: 1 }] }).then((res) => {
    createdOrderId = res.body.id;
  });
});

afterEach(() => {
  if (!createdOrderId) return;
  cy.request({
    method: 'DELETE',
    url: `/api/orders/${createdOrderId}`,
    failOnStatusCode: false,
  });
});
```

## Pattern 4: Session-Aware Auth Data

```typescript
beforeEach(() => {
  cy.session('qa-user', () => {
    cy.request('POST', '/api/auth/login', {
      email: Cypress.env('USER_EMAIL'),
      password: Cypress.env('USER_PASSWORD'),
    }).then((res) => {
      window.localStorage.setItem('access_token', res.body.accessToken);
    });
  });
});
```

Use distinct seeded users per role (`admin`, `viewer`, `editor`) to avoid role mutation side effects.

## Pattern 5: CI Parallel Safety

When jobs run in parallel, namespace data:

```typescript
const runId = Cypress.env('CI_RUN_ID') || `local-${Date.now()}`;
const email = `qa+${runId}-${Math.floor(Math.random() * 10000)}@example.com`;
```

Use run-specific prefixes for entities (`order-${runId}-...`) so cleanup scripts can remove only related test data.

## Anti-Patterns

| Anti-pattern | Risk | Better approach |
|---|---|---|
| Hardcoded IDs from local DB | Fails in CI and shared envs | Create entities during test run |
| Shared mutable data across specs | Order-dependent failures | Isolate setup per test/spec |
| UI-only setup for every test | Slow and flaky | Seed with API then verify via UI |
| Skipping cleanup | Polluted environments | Delete created entities in hooks |
| Random data without traceability | Hard to debug | Prefix with run ID + timestamp |

## Decision Tree

1. Is data used in only one test?
   - Yes: Inline data.
2. Is shape reused often?
   - Yes: Factory helper.
3. Is payload static and long?
   - Yes: `cy.fixture`.
4. Must backend state exist before page loads?
   - Yes: API seed in `beforeEach`.
5. Is login repeated?
   - Yes: `cy.session`.

## Example: Full Seed -> Act -> Verify -> Cleanup

```typescript
describe('coupon flow', () => {
  let couponCode: string;

  beforeEach(() => {
    couponCode = `E2E-${Date.now()}`;
    cy.request('POST', '/api/coupons', { code: couponCode, percentOff: 10 }).its('status').should('eq', 201);
  });

  afterEach(() => {
    cy.request({
      method: 'DELETE',
      url: `/api/coupons/${couponCode}`,
      failOnStatusCode: false,
    });
  });

  it('applies seeded coupon in checkout', () => {
    cy.visit('/checkout');
    cy.findByLabelText('Coupon').type(couponCode);
    cy.findByRole('button', { name: /apply/i }).click();
    cy.findByText(/10% discount applied/i).should('be.visible');
  });
});
```

## Troubleshooting

### Flaky tests due to "already exists" conflicts

- Use unique suffixes (`Date.now()`, random IDs).
- Clean up aggressively in `afterEach`.
- Reset environment state via dedicated test endpoints.

### Orphaned data after failed CI jobs

- Add nightly cleanup for prefixed test entities.
- Track `runId` in test-created records.

### Slow suite from repeated data creation

- Reuse auth via `cy.session`.
- Seed only what each test needs.
- Move bulky test data generation to backend helper endpoints.

## Related Guides

- [fixtures-and-hooks.md](fixtures-and-hooks.md)
- [api-testing.md](api-testing.md)
- [authentication.md](authentication.md)
- [test-architecture.md](test-architecture.md)
