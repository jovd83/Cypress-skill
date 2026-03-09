# Multi-User and Collaboration Testing

> **When to use**: Chat, comments, shared editing, presence indicators, and concurrent updates.
> **Prerequisites**: [websockets-and-realtime.md](websockets-and-realtime.md), [test-data-management.md](test-data-management.md)

## Cypress Reality

Cypress runs one primary browser context per test. Do not copy multi-page patterns from other frameworks directly.

Recommended strategy in Cypress:

1. Drive one real UI user in Cypress.
2. Simulate other users via API calls, seeded events, or mocked realtime transport.
3. Assert the UI reflects remote changes.

## Quick Reference

```typescript
it('shows new comment posted by another user', () => {
  cy.loginByApi(Cypress.env('ALICE_EMAIL'), Cypress.env('ALICE_PASSWORD'));
  cy.visit('/docs/123');

  cy.request('POST', '/api/comments', {
    docId: 123,
    text: 'Comment from Bob',
    author: 'Bob',
  });

  cy.findByText('Comment from Bob').should('be.visible');
});
```

## Pattern 1: API-Simulated Second User

**TypeScript**
```typescript
it('updates presence list when another user joins', () => {
  cy.loginByApi(Cypress.env('ALICE_EMAIL'), Cypress.env('ALICE_PASSWORD'));
  cy.visit('/chat/general');

  cy.findByTestId('online-users').should('contain.text', 'Alice');
  cy.findByTestId('online-users').should('not.contain.text', 'Bob');

  cy.request('POST', '/api/test/realtime/presence', {
    room: 'general',
    user: 'Bob',
    status: 'online',
  });

  cy.findByTestId('online-users').should('contain.text', 'Bob');
});
```

**JavaScript**
```javascript
it('updates presence list when another user joins', () => {
  cy.loginByApi(Cypress.env('ALICE_EMAIL'), Cypress.env('ALICE_PASSWORD'));
  cy.visit('/chat/general');

  cy.request('POST', '/api/test/realtime/presence', {
    room: 'general',
    user: 'Bob',
    status: 'online',
  });

  cy.findByTestId('online-users').should('contain.text', 'Bob');
});
```

## Pattern 2: Typing Indicator from External Event

```typescript
it('shows and clears typing indicator', () => {
  cy.loginByApi(Cypress.env('ALICE_EMAIL'), Cypress.env('ALICE_PASSWORD'));
  cy.visit('/chat/general');

  cy.request('POST', '/api/test/realtime/typing', {
    room: 'general',
    user: 'Bob',
    typing: true,
  });
  cy.findByText('Bob is typing...').should('be.visible');

  cy.request('POST', '/api/test/realtime/typing', {
    room: 'general',
    user: 'Bob',
    typing: false,
  });
  cy.findByText('Bob is typing...').should('not.exist');
});
```

## Pattern 3: Conflict Resolution

```typescript
it('shows conflict toast when stale update is submitted', () => {
  cy.loginByApi(Cypress.env('ALICE_EMAIL'), Cypress.env('ALICE_PASSWORD'));

  cy.intercept('PUT', '/api/docs/123', {
    statusCode: 409,
    body: { error: 'Version conflict' },
  }).as('saveDoc');

  cy.visit('/docs/123/edit');
  cy.findByLabelText('Title').clear().type('Alice title');
  cy.findByRole('button', { name: /save/i }).click();

  cy.wait('@saveDoc').its('response.statusCode').should('eq', 409);
  cy.findByRole('alert').should('contain.text', 'Version conflict');
});
```

## Pattern 4: Server-Sent Events / WebSocket Event Injection

If your test backend supports it, push events directly through test-only endpoints.

```typescript
it('renders remote edit event', () => {
  cy.visit('/docs/123');

  cy.request('POST', '/api/test/realtime/emit', {
    channel: 'doc:123',
    event: 'doc.updated',
    payload: { editor: 'Bob', summary: 'Updated introduction' },
  });

  cy.findByText('Updated by Bob').should('be.visible');
});
```

## Pattern 5: Role-Based Collaboration Flows

```typescript
it('reviewer sees pending approval after author submits', () => {
  cy.request('POST', '/api/test/workflow/submit', { docId: 456, actor: 'author' });

  cy.loginByApi(Cypress.env('REVIEWER_EMAIL'), Cypress.env('REVIEWER_PASSWORD'));
  cy.visit('/reviews');
  cy.findByText('Document 456').should('be.visible');
  cy.findByText('Pending approval').should('be.visible');
});
```

## Anti-Patterns

| Anti-pattern | Why it fails | Better strategy |
|---|---|---|
| Two independent UI tabs as two users in one test | Cypress does not provide direct multi-page control in one test | One UI user + API/mock events for second user |
| Fixed waits for realtime sync | Flaky and slow | Assert on eventual UI state with retries |
| Shared mutable test globals for user states | Hidden coupling | Create explicit test data and events per test |
| Live third-party realtime dependency in every test | Unstable CI behavior | Use controlled mock/seed endpoints |

## Troubleshooting

### Presence updates do not show in UI

- Ensure event channel/room IDs match exactly.
- Confirm app subscribes before event emission.
- Emit event after page load and subscription-ready indicator.

### Typing indicator test flakes

- Debounce behavior may delay hide/show state.
- Assert with explicit timeout:

```typescript
cy.findByText('Bob is typing...', { timeout: 7000 }).should('not.exist');
```

### Race condition test is nondeterministic

- Assert acceptable outcomes, not exact winner identity.
- Validate server-side conflict handling (`409`, merge result, or lock state).

## Related Guides

- [websockets-and-realtime.md](websockets-and-realtime.md)
- [test-data-management.md](test-data-management.md)
- [network-mocking.md](network-mocking.md)
- [multi-context-and-popups.md](multi-context-and-popups.md)
