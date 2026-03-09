# Browser Extensions

> **When to use**: Validate extension-driven behavior in web apps or test extension UI flows in controlled Chromium setups.

## Cypress Constraints

- Extension testing is Chromium-focused.
- Full background service worker orchestration is limited in Cypress.
- Prefer validating extension outcomes in the host app (DOM/network/storage side effects).

## Quick Reference

```typescript
// Validate extension-injected UI appears on page
cy.visit('https://app.example.com');
cy.get('[data-ext=injected-banner]').should('be.visible');
```

## Host-Page Integration Test

```typescript
it('shows extension-injected controls', () => {
  cy.visit('https://app.example.com');

  cy.get('[data-ext=toolbar]').should('be.visible');
  cy.get('[data-ext=toggle]').click();
  cy.get('[data-ext=panel]').should('be.visible');
});
```

## Extension Popup-Like UI Test

If your setup can open extension pages directly:

```typescript
it('opens extension options page', () => {
  cy.visit('chrome-extension://<EXTENSION_ID>/options.html');
  cy.findByRole('heading', { name: /settings/i }).should('be.visible');
});
```

## Message Passing Outcome Check

```typescript
it('reflects extension action in app state', () => {
  cy.visit('https://app.example.com');

  cy.window().then((win) => {
    win.postMessage({ source: 'extension-test', action: 'enableFeatureX' }, '*');
  });

  cy.get('[data-cy=feature-x-enabled]').should('contain.text', 'On');
});
```

## Storage Side-Effect Verification

```typescript
it('persists extension preference', () => {
  cy.visit('https://app.example.com');

  cy.get('[data-ext=theme-toggle]').click();
  cy.window().then((win) => {
    expect(win.localStorage.getItem('ext.theme')).to.eq('dark');
  });
});
```

## Anti-Patterns

- Depending on background service worker event orchestration APIs not available in Cypress.
- Running extension-critical tests outside Chromium and expecting parity.
- Hardcoding unstable extension IDs in shared CI without setup controls.

## Related

- [core/browser-apis.md](browser-apis.md)
- [core/network-mocking.md](network-mocking.md)
- [core/service-workers-and-pwa.md](service-workers-and-pwa.md)
