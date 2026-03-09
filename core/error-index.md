# Cypress Error Index

Quick reference for common Cypress failures and actionable fixes.

> **When to use**: When a Cypress run fails and you need a fast mapping from error text to a deterministic fix pattern.
> **How to use**: Search by the key text from your failing error message, then apply the listed fix pattern.

## 1) "Timed out retrying after ... expected to find element"

**Cause**: Selector mismatch, wrong page state, or missing precondition.

**Fix**:

```typescript
cy.intercept('GET', '**/api/profile').as('profile');
cy.visit('/profile');
cy.wait('@profile');
cy.findByRole('heading', { name: /profile/i }).should('be.visible');
```

## 2) "`cy.click()` failed because this element is not visible"

**Cause**: Element covered, hidden, disabled, or stale after rerender.

**Fix**:

```typescript
cy.findByRole('button', { name: /submit/i })
  .should('be.visible')
  .and('not.be.disabled')
  .click();
```

Avoid defaulting to `force: true`.

## 3) "`cy.type()` can only be called on a single element"

**Cause**: Selector returns multiple nodes.

**Fix**:

```typescript
cy.findByLabelText('Email').clear().type('user@example.com');
// or
cy.get('[data-cy=email-input]').first().clear().type('user@example.com');
```

## 4) "Cannot read properties of undefined" inside `.then(...)`

**Cause**: Assumed value shape from fixture/intercept response is wrong.

**Fix**:

```typescript
cy.wait('@getUsers').then(({ response }) => {
  expect(response && response.body).to.be.an('array');
  const first = response?.body?.[0];
  expect(first).to.have.property('name');
});
```

## 5) "`cy.wait()` timed out waiting ... for the 1st request to the route"

**Cause**: Alias never triggered (wrong URL/method or intercept registered too late).

**Fix**:

```typescript
cy.intercept('POST', '**/api/login').as('login');
cy.visit('/login');
cy.findByRole('button', { name: /sign in/i }).click();
cy.wait('@login');
```

## 6) "A request was made to ... but no response was provided"

**Cause**: Bad intercept handler branch without `req.reply()`/`req.continue()`.

**Fix**:

```typescript
cy.intercept('**/api/users', (req) => {
  if (req.method === 'GET') {
    req.reply({ statusCode: 200, body: [] });
    return;
  }
  req.continue();
});
```

## 7) "The following error originated from your application code"

**Cause**: Real app runtime exception.

**Fix**:

```typescript
cy.on('uncaught:exception', (err) => {
  // keep temporary while triaging
  console.error(err.message);
  return false;
});
```

Then fix app code and remove exception suppression.

## 8) "`cy.visit()` failed trying to load ..."

**Cause**: Base URL mismatch, server down, or blocked host.

**Fix checklist**:

1. Confirm `baseUrl` in Cypress config.
2. Verify app is running before test starts.
3. Check CI networking/proxy restrictions.

## 9) "Detached from DOM"

**Cause**: Element rerendered between query and action.

**Fix**:

```typescript
cy.findByRole('button', { name: /save/i }).should('be.visible').click();
// re-query instead of storing stale references in variables
```

## 10) "Expected ... to include ..." URL assertion failures

**Cause**: Assertion runs before navigation settles.

**Fix**:

```typescript
cy.findByRole('button', { name: /continue/i }).click();
cy.location('pathname').should('include', '/checkout');
```

## 11) Screenshot mismatch noise (visual tests)

**Cause**: Dynamic UI (time, random IDs, animations).

**Fix**:

```typescript
cy.clock(new Date('2026-01-01T10:00:00Z').getTime(), ['Date']);
cy.get('[data-cy=current-time]').invoke('css', 'visibility', 'hidden');
cy.document().then((doc) => {
  const style = doc.createElement('style');
  style.innerHTML = '* { animation: none !important; transition: none !important; }';
  doc.head.appendChild(style);
});
cy.screenshot('stable-dashboard');
```

## 12) Cross-origin errors (OAuth/SSO)

**Cause**: Attempting to automate third-party auth UI directly.

**Fix**:

1. Prefer programmatic login endpoint in test env.
2. Stub callback exchange with `cy.intercept()`.
3. Reuse auth via `cy.session()`.

## 13) Flaky tests with random pass/fail

**Cause**: Race conditions, mutable seed data, or reliance on timing.

**Fix checklist**:

1. Alias all critical requests and `cy.wait('@alias')`.
2. Seed deterministic test data.
3. Assert stable UI signals, not elapsed time.

## 14) "`cy.task(...)` failed"

**Cause**: Missing plugin task registration or incorrect return type.

**Fix**:

```typescript
// cypress.config.ts
on('task', {
  log(message: string) {
    console.log(message);
    return null;
  }
});
```

## 15) "Cannot call Cypress command outside a running test"

**Cause**: Cypress commands invoked at module scope.

**Fix**:

```typescript
// Wrong: top-level cy.visit('/login')

beforeEach(() => {
  cy.visit('/login');
});
```

## Diagnostic Flow

1. Re-run failing spec alone.
2. Enable screenshots/video artifacts.
3. Add targeted intercept aliases around failing step.
4. Compare request payload/response with expected state.
5. Minimize test to smallest reproducer.

## Anti-Patterns

| Anti-pattern | Why it hurts | Better approach |
|---|---|---|
| Blindly adding `cy.wait(2000)` after failures | Hides root cause and increases flakiness | Add alias waits and retryable UI assertions |
| Applying `{ force: true }` for all interaction errors | Masks actionability bugs | Fix overlays/disabled state and assert interactability |
| Leaving `uncaught:exception` suppression permanently | Silences real regressions | Use temporary suppression only while triaging |
| Debugging only from stack trace text | Misses runtime/network context | Inspect artifacts, aliases, and minimal reproducer flow |

## Related

- [core/assertions-and-waiting.md](assertions-and-waiting.md)
- [core/debugging.md](debugging.md)
- [core/flaky-tests.md](flaky-tests.md)
- [core/network-mocking.md](network-mocking.md)
