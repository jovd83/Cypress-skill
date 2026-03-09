# Multi-Context and Popups

> **When to use**: Validate flows involving `target="_blank"`, `window.open`, cross-origin redirects, and multi-user behavior within Cypress constraints.

## Cypress Reality

Cypress runs in a single browser tab per test. It does not provide direct multi-tab/page control in one test.

Use these alternatives:

1. Assert link target + destination URL.
2. Remove `target` and navigate in same tab.
3. Stub `window.open` and assert called URL.
4. Use `cy.origin()` for cross-origin interactions (when needed).
5. Use separate sessions for multi-user behavior, not simultaneous tab control.

## Quick Reference

```typescript
// Assert external link without leaving app
cy.findByRole('link', { name: /privacy policy/i })
  .should('have.attr', 'target', '_blank')
  .and('have.attr', 'href')
  .and('include', '/privacy');

// Force same-tab navigation for test flow
cy.findByRole('link', { name: /help center/i }).invoke('removeAttr', 'target').click();
cy.location('pathname').should('include', '/help');

// Assert popup API usage
cy.window().then((win) => {
  cy.stub(win, 'open').as('windowOpen');
});
cy.findByRole('button', { name: /open receipt/i }).click();
cy.get('@windowOpen').should('have.been.calledWithMatch', /receipt/);
```

## Pattern 1: Validate `_blank` Links

### TypeScript

```typescript
it('validates documentation link configuration', () => {
  cy.visit('/settings');

  cy.findByRole('link', { name: 'API docs' })
    .should('have.attr', 'target', '_blank')
    .and('have.attr', 'rel')
    .and('match', /noopener|noreferrer/)
    .and('have.attr', 'href')
    .and('include', 'docs.example.com');
});
```

### JavaScript

```javascript
it('validates documentation link configuration', () => {
  cy.visit('/settings');

  cy.findByRole('link', { name: 'API docs' })
    .should('have.attr', 'target', '_blank')
    .and('have.attr', 'rel')
    .and('match', /noopener|noreferrer/)
    .and('have.attr', 'href')
    .and('include', 'docs.example.com');
});
```

## Pattern 2: Test Popup Navigation in Same Tab

```typescript
it('navigates to support center by removing target', () => {
  cy.visit('/account');

  cy.findByRole('link', { name: /support center/i })
    .should('have.attr', 'target', '_blank')
    .invoke('removeAttr', 'target')
    .click();

  cy.location('pathname').should('include', '/support');
  cy.findByRole('heading', { name: /support center/i }).should('be.visible');
});
```

## Pattern 3: Assert `window.open` Behavior

```typescript
it('opens report export URL with window.open', () => {
  cy.visit('/reports');

  cy.window().then((win) => {
    cy.stub(win, 'open').as('windowOpen');
  });

  cy.findByRole('button', { name: /export report/i }).click();

  cy.get('@windowOpen').should('have.been.calledOnce');
  cy.get('@windowOpen').should('have.been.calledWithMatch', /\/reports\/export\?format=pdf/);
});
```

## Pattern 4: Cross-Origin Flow (`cy.origin`)

```typescript
it('completes hosted payment confirmation flow', () => {
  cy.visit('/checkout');
  cy.findByRole('button', { name: /pay now/i }).click();

  cy.origin('https://payments.example.com', () => {
    cy.findByLabelText('Card number').type('4242424242424242');
    cy.findByLabelText('Expiration').type('12/28');
    cy.findByLabelText('CVC').type('123');
    cy.findByRole('button', { name: /confirm/i }).click();
  });

  cy.location('pathname').should('include', '/checkout/success');
});
```

## Pattern 5: Multi-User Context via Sessions

Use separate tests or explicit session switches instead of simultaneous popup/page control.

```typescript
it('admin creates announcement', () => {
  cy.session('admin', () => {
    cy.request('POST', '/api/login', { email: 'admin@example.com', password: 'secure-password' });
  });

  cy.visit('/admin/announcements/new');
  cy.findByLabelText('Title').clear().type('Scheduled maintenance');
  cy.findByRole('button', { name: /publish/i }).click();
  cy.findByText(/published/i).should('be.visible');
});
```

## Anti-Patterns

- Trying to use non-Cypress popup APIs in Cypress.
- Writing tests that depend on true multi-tab synchronization.
- Forcing brittle timing with sleep for popup events.
- Skipping link security checks (`rel=noopener/noreferrer`) when asserting `_blank` links.

## Related

- [core/authentication.md](authentication.md)
- [core/network-mocking.md](network-mocking.md)
- [core/error-and-edge-cases.md](error-and-edge-cases.md)
