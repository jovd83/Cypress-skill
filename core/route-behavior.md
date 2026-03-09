# Route Behavior and Parity

> **When to use**: Validating complex navigation, redirects, and ensuring consistency between different route representations (e.g., UUID-based URLs vs alias-based slugs).

## Patterns

### 1. URL Settling and Redirects

Never assert on a URL immediately after a click if a redirect might happen and you rely on synchronous state. Cypress will automatically retry assertions like `.should('include', '/dashboard')`, making it safe to assert directly without explicit waits.

```typescript
// GOOD: Cypress auto-retries the assertion while redirects happen
cy.findByRole('button', { name: 'Submit' }).click();
cy.location('pathname').should('include', '/dashboard');
```

### 2. Route Parity (UUID vs Slugs)

Ensure that different ways of accessing the same resource result in the same UI state.

```typescript
it('route parity: uuid vs alias', () => {
  const resourceUuid = '123e4567-e89b-12d3-a456-426614174000';
  const resourceAlias = 'my-cool-resource';

  // Check UUID route
  cy.visit(`/resources/${resourceUuid}`);
  cy.findByRole('heading').should('have.text', 'Resource Details');

  // Check Alias route
  cy.visit(`/resources/${resourceAlias}`);
  cy.findByRole('heading').should('have.text', 'Resource Details');
  
  // Verify they both resolve to the same canonical data-testid
  cy.get('[data-testid="resource-id"]').should('have.attr', 'data-id', resourceUuid);
});
```

### 3. Negative Path Parity

Ensure `404` and `403` handlers behave consistently across similar routes.

```typescript
const routesToTest = [
  '/admin/settings',
  '/admin/users',
  '/admin/billing'
];

routesToTest.forEach((route) => {
  it(`unauthorized access to ${route} redirects to login`, () => {
    // Unauthenticated context
    cy.visit(route);
    cy.url().should('include', '/login');
  });
});
```

## Checklist

- [ ] **Redirect Wait**: Used Cypress's built-in assertion retries (`cy.location().should()`) for multi-step redirects.
- [ ] **Parser Helpers**: Created utility functions to extract parameters from current URL for assertions.
- [ ] **Fallback Validation**: Verified that invalid UUIDs or expired slugs trigger correct 404/Fallback UI rather than a crash.
- [ ] **Dynamic State**: Verified that query parameters (e.g., `?tab=settings`) are preserved or correctly handled during navigation.
