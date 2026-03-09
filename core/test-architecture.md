# Test Architecture

> **When to use**: Define what to test at API, component, and E2E levels so the suite stays fast and reliable.
> **Prerequisites**: [api-testing.md](api-testing.md), [component-testing.md](component-testing.md), [test-data-management.md](test-data-management.md)

## Architecture Goals

1. Catch defects early at the cheapest layer.
2. Keep E2E coverage focused on critical user journeys.
3. Avoid duplicated assertions across layers.

## Recommended Layer Split

- **API tests (largest)**: business rules, error codes, contracts.
- **Component tests (large)**: UI logic in isolation.
- **E2E tests (thin)**: cross-page workflows and integration points.

## Decision Matrix

| Scenario | Best layer | Why |
|---|---|---|
| Validation rules for payload fields | API | Fast, no browser cost |
| Button enable/disable logic | Component | Isolated and deterministic |
| Login + checkout happy path | E2E | Verifies full user flow |
| Role-based backend access | API | Clear status and permission checks |
| Form error rendering | Component + small E2E | Fast coverage + one end-to-end confirmation |
| Third-party payment integration shell | E2E + API intercept | Validate host behavior and backend side effects |

## Pattern 1: API-First Coverage

```typescript
describe('POST /api/orders', () => {
  it('returns 422 for invalid quantity', () => {
    cy.request({
      method: 'POST',
      url: '/api/orders',
      failOnStatusCode: false,
      body: { items: [{ sku: 'A1', qty: 0 }] },
    }).then((res) => {
      expect(res.status).to.eq(422);
      expect(res.body.error).to.match(/quantity/i);
    });
  });
});
```

## Pattern 2: Component-Level UI Logic

```typescript
// Example with Cypress Component Testing
import { mount } from 'cypress/react';
import LoginForm from '../../src/components/LoginForm';

it('shows validation errors when required fields are empty', () => {
  mount(<LoginForm />);
  cy.findByRole('button', { name: /sign in/i }).click();
  cy.findByText(/email is required/i).should('be.visible');
  cy.findByText(/password is required/i).should('be.visible');
});
```

## Pattern 3: Thin E2E for Critical Paths

```typescript
it('user completes checkout', () => {
  cy.intercept('POST', '/api/orders').as('createOrder');

  cy.visit('/shop');
  cy.findByText('Running Shoes').click();
  cy.findByRole('button', { name: /add to cart/i }).click();
  cy.findByRole('link', { name: /cart/i }).click();
  cy.findByRole('button', { name: /place order/i }).click();

  cy.wait('@createOrder').its('response.statusCode').should('eq', 201);
  cy.findByRole('heading', { name: /order confirmed/i }).should('be.visible');
});
```

## Coverage Heuristic

Use this rough split for most teams:

- API: 50-65%
- Component: 25-35%
- E2E: 10-20%

Adjust when:

- UI is highly dynamic -> increase component tests.
- Backend is unstable -> increase API negative-path coverage.
- Compliance-critical flow -> add E2E checks for user-visible outcomes.

## How to Avoid Duplicate Tests

Do not test the same rule in all layers.

Example:

- API validates `email` format and returns `400`.
- Component validates empty email field and shows inline message.
- E2E keeps one login failure scenario only.

## Mapping Requirements to Layers

1. Write requirement.
2. Mark primary risk (logic, rendering, integration).
3. Assign layer:
   - logic -> API
   - rendering -> component
   - integration/user journey -> E2E
4. Add one fallback layer only if risk is high.

## Anti-Patterns

| Anti-pattern | Why it hurts | Better pattern |
|---|---|---|
| Testing every branch only in E2E | Slow and flaky | Push business rules to API tests |
| Copying API assertions into UI tests | Redundant checks | Keep UI tests focused on user outcomes |
| Over-mocking critical integrations | False confidence | Keep core flow with real backend paths |
| Large E2E setup through UI | Slow and brittle | Seed by API and assert in UI |
| Cross-spec dependencies | Order-sensitive failures | Independent setup and teardown |

## Example Folder Layout

```text
cypress/
  e2e/
    critical/
      checkout.cy.ts
      auth.cy.ts
    smoke/
      navigation.cy.ts
  component/
    forms/
      login-form.cy.tsx
  support/
    commands.ts
    factories/
      userFactory.ts
```

## CI Execution Strategy

1. Run API + component tests on every PR.
2. Run smoke E2E on every PR.
3. Run full E2E regression nightly or before release.
4. Parallelize by spec and keep E2E shards balanced.

## Troubleshooting

### Suite is too slow

- Move repeated validation checks from E2E to API/component.
- Remove duplicated happy-path E2E scenarios.
- Use `cy.session` and API seed endpoints.

### Flaky E2E scenarios

- Replace fixed waits with alias-based waits (`cy.wait('@alias')`).
- Reduce scope to user-visible assertions.
- Validate async behavior in API tests separately.

### Gaps between requirements and tests

- Add coverage mapping table in docs:
  - requirement ID
  - chosen layer
  - test file path

## Related Guides

- [api-testing.md](api-testing.md)
- [component-testing.md](component-testing.md)
- [test-data-management.md](test-data-management.md)
- [when-to-mock.md](when-to-mock.md)
