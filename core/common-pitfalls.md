# Common Pitfalls

> **When to use**: Review and harden Cypress tests against the most frequent sources of flakiness and false confidence.

## Pitfall 1: Using fixed waits (`cy.wait(2000)`) as synchronization

**Problem**: Pass/fail depends on runtime speed.

**Fix**:

```typescript
cy.intercept('GET', '**/api/dashboard').as('dashboard');
cy.visit('/dashboard');
cy.wait('@dashboard');
cy.findByTestId('chart').should('be.visible');
```

## Pitfall 2: Treating Cypress commands like `async/await` promises

**Problem**: Awaiting Cypress chainables creates confusion and brittle code.

**Fix**: Use Cypress command chaining.

```typescript
cy.visit('/login');
cy.findByLabelText('Email').clear().type('user@example.com');
cy.findByLabelText('Password').clear().type('secret');
cy.findByRole('button', { name: 'Sign In' }).click();
```

## Pitfall 3: Registering intercepts after triggering actions

**Problem**: Alias waits timeout because request already fired.

**Fix**:

```typescript
cy.intercept('POST', '**/api/orders').as('createOrder');
cy.findByRole('button', { name: /place order/i }).click();
cy.wait('@createOrder');
```

## Pitfall 4: Overusing brittle selectors

**Problem**: UI refactors break tests without behavior changes.

**Fix**: prefer role/label/data-cy selectors.

```typescript
cy.findByRole('button', { name: 'Save' }).click();
cy.get('[data-cy=save-button]').click();
```

## Pitfall 5: Using `force: true` to bypass real UX constraints

**Problem**: Tests pass while real users cannot interact.

**Fix**: assert interactability first.

```typescript
cy.findByRole('button', { name: 'Submit' })
  .should('be.visible')
  .and('not.be.disabled')
  .click();
```

## Pitfall 6: Shared mutable state between tests

**Problem**: Tests fail only in suite runs.

**Fix**: isolate auth/data setup per test or per spec.

```typescript
beforeEach(() => {
  cy.session('admin', () => {
    cy.request('POST', '/api/login', {
      email: 'admin@example.com',
      password: 'secure-password'
    });
  });
});
```

## Pitfall 7: Ignoring request payload assertions

**Problem**: UI looks right while backend contract is wrong.

**Fix**:

```typescript
cy.intercept('POST', '**/api/users').as('createUser');
cy.findByRole('button', { name: 'Create' }).click();
cy.wait('@createUser').then(({ request }) => {
  expect(request.body).to.include.keys(['name', 'email']);
});
```

## Pitfall 8: Monolithic tests with too many responsibilities

**Problem**: Hard to debug and maintain.

**Fix**: one behavior per test.

```typescript
it('adds item to cart', () => { /* ... */ });
it('completes checkout', () => { /* ... */ });
```

## Pitfall 9: Suppressing all uncaught exceptions permanently

**Problem**: Masks real defects.

**Fix**: use temporary suppression only while triaging and track cleanup.

```typescript
cy.on('uncaught:exception', (err) => {
  console.error(err.message);
  return false; // temporary
});
```

## Pitfall 10: Blindly updating visual baselines

**Problem**: real regressions get accepted.

**Fix**: review diffs + expected UI change before baseline update.

## Pitfall 11: Only covering the happy path (MSS)

**Problem**: Test suite lacks resilience because error states and edge cases are missing.

**Fix**: Cover the happy path first as a foundation, then explicitly mock and assert fallback UI for failure scenarios.

```typescript
cy.intercept('GET', '**/api/items', { statusCode: 200, body: [] }).as('items');
cy.visit('/items');
cy.wait('@items');
cy.findByText(/no items found/i).should('be.visible');
```

## Pitfall 12: Keeping flaky tests in main gate without triage

**Problem**: noisy CI and low trust.

**Fix checklist**:

1. Reproduce in isolation.
2. Add network aliases.
3. Stabilize selectors.
4. Remove static waits.
5. Quarantine only if necessary with issue tracking.

## Anti-Patterns

| Anti-pattern | Why it hurts | Better pattern |
|---|---|---|
| Treating Cypress as promise-based `async/await` test code | Queue semantics become unclear and brittle | Use Cypress chaining and aliases |
| Stabilizing tests with blanket sleeps/retries | Masks root issues and slows pipeline | Fix selectors, setup, and deterministic waits |
| Accepting visual baseline updates without review | Regressions slip in silently | Review diffs with intentional change context |
| Suppressing all runtime exceptions globally | Hides app defects | Triage temporary exceptions and remove suppression |

## Review Checklist

- No arbitrary waits for synchronization.
- Intercepts registered before trigger actions.
- Assertions include both network and UI state when relevant.
- Selectors are semantic and stable.
- Tests are isolated and deterministic.

## Related

- [core/flaky-tests.md](flaky-tests.md)
- [core/network-mocking.md](network-mocking.md)
- [core/assertions-and-waiting.md](assertions-and-waiting.md)
- [core/test-organization.md](test-organization.md)
