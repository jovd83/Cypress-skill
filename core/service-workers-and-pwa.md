# Service Workers and PWA

> **When to use**: Validate service worker registration, offline fallback behavior, cache usage, update flow, and install prompts in Cypress.

## Cypress Constraints

- Cypress does not expose service worker event APIs in this style.
- Prefer browser API checks via `navigator.serviceWorker` and app-observable behavior.
- Run PWA/offline tests in Chromium-first pipelines when needed.

## Quick Reference

```typescript
cy.visit('/');
cy.window().then(async (win) => {
  await win.navigator.serviceWorker.ready;
  const reg = await win.navigator.serviceWorker.getRegistration();
  expect(reg).to.not.equal(undefined);
});
```

## Registration Check

```typescript
it('registers service worker', () => {
  cy.visit('/');

  cy.window().then(async (win) => {
    expect('serviceWorker' in win.navigator).to.eq(true);
    await win.navigator.serviceWorker.ready;
    const reg = await win.navigator.serviceWorker.getRegistration();
    expect(reg).to.not.equal(undefined);
  });
});
```

## Offline Fallback Behavior

```typescript
it('shows offline page when network is unavailable', () => {
  cy.intercept('GET', '**/api/**', { forceNetworkError: true }).as('offlineApi');

  cy.visit('/dashboard');
  cy.wait('@offlineApi');
  cy.findByText(/you appear to be offline/i).should('be.visible');
});
```

## Cache API Validation

```typescript
it('stores shell assets in cache', () => {
  cy.visit('/');

  cy.window().then(async (win) => {
    await win.navigator.serviceWorker.ready;
    const keys = await win.caches.keys();
    expect(keys.length).to.be.greaterThan(0);
  });
});
```

## Update Flow

```typescript
it('shows update available banner when new sw is detected', () => {
  cy.visit('/');
  cy.findByRole('button', { name: /check for updates/i }).click();
  cy.findByText(/update available/i).should('be.visible');
});
```

## Install Prompt UX

```typescript
it('shows install CTA when installable', () => {
  cy.visit('/');
  cy.findByRole('button', { name: /install app/i }).should('be.visible');
});
```

## Push Notification UX (App-Level)

```typescript
it('handles push-notification permission denial', () => {
  cy.visit('/notifications');

  cy.window().then((win) => {
    cy.stub(win.Notification, 'requestPermission').resolves('denied');
  });

  cy.findByRole('button', { name: /enable notifications/i }).click();
  cy.findByRole('alert').should('contain.text', 'Permission denied');
});
```

## Anti-Patterns

- Relying on non-Cypress SW event APIs in Cypress docs.
- Assuming true browser-wide offline simulation without controlled network stubs.
- Mixing SW install/update checks with unrelated business flow tests.

## Related

- [core/network-mocking.md](network-mocking.md)
- [core/error-and-edge-cases.md](error-and-edge-cases.md)
- [core/flaky-tests.md](flaky-tests.md)
