# Debugging

> **When to use**: Diagnose flaky tests, failed assertions, network issues, and timing races in Cypress v13+.

## Debugging Stack (Priority Order)

1. Cypress command log and error snapshots.
2. Screenshots and video artifacts.
3. Network aliases with `cy.intercept()`.
4. Console and runtime exception hooks.
5. `cy.pause()` / `cy.debug()` in local interactive runs.

## Quick Reference

```bash
# Interactive debugging
npx cypress open

# Headless CI-style run
npx cypress run

# Single spec
npx cypress run --spec cypress/e2e/smoke/auth.cy.ts
```

## Fast Triage Workflow

1. Run failing spec in isolation.
2. Add/verify intercept aliases around failing step.
3. Assert request payload and response status.
4. Capture screenshot at the failing state.
5. Re-run in interactive mode and pause before failure.

## Network-Centric Debugging

```typescript
it('debugs checkout submit', () => {
  cy.intercept('GET', '**/api/cart').as('cart');
  cy.intercept('POST', '**/api/orders').as('createOrder');

  cy.visit('/checkout');
  cy.wait('@cart');

  cy.findByRole('button', { name: /place order/i }).click();

  cy.wait('@createOrder').then(({ request, response }) => {
    expect(request.body).to.have.property('items');
    expect(response && response.statusCode).to.be.oneOf([200, 201]);
  });
});
```

## Console and App Exceptions

```typescript
beforeEach(() => {
  cy.on('uncaught:exception', (err) => {
    console.error('App exception:', err.message);
    return false; // temporary while triaging
  });

  cy.window().then((win) => {
    cy.stub(win.console, 'error').as('consoleError');
  });
});

it('checks for console errors', () => {
  cy.visit('/dashboard');
  cy.get('@consoleError').should('not.have.been.called');
});
```

## Use `cy.pause()` and `cy.debug()`

```typescript
it('steps through flaky interaction', () => {
  cy.visit('/profile');
  cy.pause();

  cy.findByRole('button', { name: /edit profile/i }).click();
  cy.findByLabelText('Display name').clear().type('Jane Doe').debug();
  cy.findByRole('button', { name: /save/i }).click();
});
```

## Stabilize Timing Races

```typescript
// Prefer this
cy.intercept('GET', '**/api/recommendations').as('recs');
cy.visit('/home');
cy.wait('@recs');
cy.findByTestId('recommendation-list').should('be.visible');

// Avoid this
// cy.wait(3000)
```

## Artifact Capture Patterns

```typescript
it('captures checkpoint screenshots', () => {
  cy.visit('/checkout');
  cy.screenshot('checkout-step-1');

  cy.findByRole('button', { name: /continue/i }).click();
  cy.screenshot('checkout-step-2');
});
```

CI recommendation:

1. Keep video/screenshot-on-failure enabled.
2. Upload artifacts for failed jobs.
3. Keep artifact retention long enough for triage.

## Common Failure Patterns and Fixes

| Symptom | Likely Cause | Fix |
|---|---|---|
| Element not found | Wrong selector or precondition not met | Use role/label selectors and assert preconditions first |
| Intercept alias never fires | Route mismatch or registered too late | Register intercept before visit/action |
| Detached element | React/Vue rerender between query and action | Re-query right before action |
| Random pass/fail | Data/timing dependency | Stub external data and wait on aliases |
| URL assertion fails intermittently | Assertion too early | Assert via `cy.location()` after triggering action |

## Anti-Patterns

- Blanket `cy.wait(milliseconds)` usage.
- Suppressing all app exceptions permanently.
- Debugging only in full-suite runs (slow feedback).
- Ignoring network layer in UI failures.

## Related

- [core/assertions-and-waiting.md](assertions-and-waiting.md)
- [core/flaky-tests.md](flaky-tests.md)
- [core/network-mocking.md](network-mocking.md)
- [ci/reporting-and-artifacts.md](../ci/reporting-and-artifacts.md)
