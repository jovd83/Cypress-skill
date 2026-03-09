# Browser APIs

> **When to use**: Test browser-exposed APIs (storage, clipboard, geolocation, notifications, media devices, permissions-like behavior) in Cypress.

## Golden Rules

1. Stub browser APIs from `cy.window()` for deterministic behavior.
2. Prefer app-visible outcomes over low-level implementation checks.
3. Keep API mocks close to tests that depend on them.
4. Reset state between tests (localStorage, sessionStorage, IndexedDB as needed).

## Quick Reference

```typescript
// localStorage
cy.window().then((win) => {
  win.localStorage.setItem('theme', 'dark');
});

// clipboard stub
cy.window().then((win) => {
  cy.stub(win.navigator.clipboard, 'readText').resolves('copied value');
});

// geolocation stub
cy.window().then((win) => {
  cy.stub(win.navigator.geolocation, 'getCurrentPosition').callsFake((cb) => {
    cb({ coords: { latitude: 50.8503, longitude: 4.3517 } });
  });
});
```

## Storage APIs

### localStorage + sessionStorage

```typescript
it('persists user theme preference', () => {
  cy.visit('/settings');

  cy.findByLabelText('Theme').select('dark');
  cy.reload();

  cy.window().then((win) => {
    expect(win.localStorage.getItem('theme')).to.eq('dark');
  });
});

it('stores wizard step in sessionStorage', () => {
  cy.visit('/onboarding');
  cy.findByRole('button', { name: /next/i }).click();

  cy.window().then((win) => {
    expect(win.sessionStorage.getItem('onboardingStep')).to.eq('2');
  });
});
```

### IndexedDB Check

```typescript
it('writes draft note to indexeddb', () => {
  cy.visit('/notes');
  cy.findByLabelText('Title').clear().type('Draft');
  cy.findByRole('button', { name: /save draft/i }).click();

  cy.window().then(async (win) => {
    const dbs = await win.indexedDB.databases();
    expect(dbs.some((d) => d.name === 'notes-db')).to.eq(true);
  });
});
```

## Clipboard API

```typescript
it('copies api key to clipboard', () => {
  cy.visit('/settings/api');

  cy.window().then((win) => {
    cy.stub(win.navigator.clipboard, 'writeText').as('writeText');
  });

  cy.findByRole('button', { name: /copy api key/i }).click();
  cy.get('@writeText').should('have.been.calledOnce');
});

it('pastes clipboard value into input', () => {
  cy.visit('/imports');

  cy.window().then((win) => {
    cy.stub(win.navigator.clipboard, 'readText').resolves('ABC-123');
  });

  cy.findByRole('button', { name: /paste token/i }).click();
  cy.findByLabelText('Token').should('have.value', 'ABC-123');
});
```

## Geolocation API

```typescript
it('renders location-based content for Brussels', () => {
  cy.visit('/nearby-stores');

  cy.window().then((win) => {
    cy.stub(win.navigator.geolocation, 'getCurrentPosition').callsFake((cb) => {
      cb({ coords: { latitude: 50.8503, longitude: 4.3517 } });
    });
  });

  cy.findByRole('button', { name: /use my location/i }).click();
  cy.findByText(/brussels/i).should('be.visible');
});
```

## Notifications API

```typescript
it('requests notification permission and shows success state', () => {
  cy.visit('/notifications');

  cy.window().then((win) => {
    cy.stub(win.Notification, 'requestPermission').resolves('granted');
  });

  cy.findByRole('button', { name: /enable notifications/i }).click();
  cy.findByText(/notifications enabled/i).should('be.visible');
});
```

## Media Devices (`getUserMedia`)

```typescript
it('handles denied camera access gracefully', () => {
  cy.visit('/camera');

  cy.window().then((win) => {
    cy.stub(win.navigator.mediaDevices, 'getUserMedia').rejects(new Error('Permission denied'));
  });

  cy.findByRole('button', { name: /start camera/i }).click();
  cy.findByRole('alert').should('contain.text', 'Camera access denied');
});
```

## Online/Offline Behavior

```typescript
it('shows offline banner when app detects offline mode', () => {
  cy.visit('/dashboard');

  cy.window().then((win) => {
    cy.stub(win.navigator, 'onLine').value(false);
    win.dispatchEvent(new Event('offline'));
  });

  cy.findByText(/you are offline/i).should('be.visible');
});
```

## Anti-Patterns

- Relying on real permission dialogs in CI.
- Using global API stubs that leak into unrelated tests.
- Asserting internal browser implementation details instead of app behavior.
- Using fixed waits for async browser API callbacks.

## Related

- [core/network-mocking.md](network-mocking.md)
- [core/error-and-edge-cases.md](error-and-edge-cases.md)
- [core/flaky-tests.md](flaky-tests.md)
