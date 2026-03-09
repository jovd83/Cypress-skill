# Flaky Tests

> **When to use**: Diagnose and prevent intermittent Cypress failures caused by timing races, unstable data, shared state, or brittle selectors.

## Flake Prevention Rules

1. Use deterministic network synchronization (`cy.intercept` + `cy.wait('@alias')`).
2. Prefer semantic selectors (role/label/data-cy), avoid DOM index chains.
3. Isolate tests and reset state predictably.
4. Assert intermediate states for long workflows.
5. Treat retries as mitigation, not a root-cause fix.

## Common Flake Causes

| Cause | Symptom | Fix |
|---|---|---|
| Request race | Alias wait timeout or missing UI data | Register intercept before action and wait on alias |
| Stale selectors | "Detached from DOM" | Re-query before action |
| Shared data | Fails only in suite/full run | Isolate fixtures and seed per test |
| Dynamic UI noise | Visual/assertion drift | Freeze time, hide dynamic elements |
| Blind sleeps | Random pass/fail timing | Replace with state/network assertions |

## Deterministic Network Pattern

```typescript
it('waits on API signal, not time', () => {
  cy.intercept('GET', '**/api/projects').as('projects');

  cy.visit('/projects');
  cy.wait('@projects').its('response.statusCode').should('eq', 200);

  cy.findByRole('heading', { name: /projects/i }).should('be.visible');
});
```

## Selector Stability Pattern

```typescript
// Good
cy.findByRole('button', { name: 'Save' }).click();
cy.get('[data-cy=save-button]').click();

// Avoid
// cy.get('.form > div:nth-child(3) > button').click();
```

## Isolate Auth and State with `cy.session()`

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

## Stabilize Dynamic Data

```typescript
beforeEach(() => {
  cy.clock(new Date('2026-01-01T10:00:00Z').getTime(), ['Date']);
});

it('renders stable dashboard values', () => {
  cy.intercept('GET', '**/api/dashboard', { fixture: 'dashboard-stable.json' }).as('dashboard');
  cy.visit('/dashboard');
  cy.wait('@dashboard');
  cy.findByText('Revenue').should('be.visible');
});
```

## Flake Triage Playbook

1. Re-run failing spec alone (`cypress run --spec ...`).
2. Add intercept aliases around failing step.
3. Verify request payload + response status.
4. Capture screenshots before and after failing action.
5. Minimize test to smallest reproducer.

## Retry Policy

Use retries only after identifying likely transient behavior.

```typescript
// cypress.config.ts
export default {
  e2e: {
    retries: {
      runMode: 2,
      openMode: 0
    }
  }
};
```

Retries should not hide deterministic bugs.

## Anti-Patterns

- `cy.wait(5000)` to "fix" async timing.
- Global exception suppression for all tests.
- Tests that depend on execution order.
- Hidden side effects in `before` hooks across many specs.

## Related

- [core/debugging.md](debugging.md)
- [core/assertions-and-waiting.md](assertions-and-waiting.md)
- [core/network-mocking.md](network-mocking.md)
- [core/test-organization.md](test-organization.md)
