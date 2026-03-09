# WebSockets and Realtime

> **When to use**: Chat, live dashboards, notifications, collaborative editing, and stream-based updates.
> **Prerequisites**: [network-mocking.md](network-mocking.md), [multi-user-and-collaboration.md](multi-user-and-collaboration.md)

## Cypress Approach

Cypress can reliably test realtime behavior by:

1. Asserting user-visible updates in the UI.
2. Simulating server events through test endpoints.
3. Using `cy.intercept` for SSE/polling HTTP transports.

Direct low-level WebSocket frame orchestration is limited in Cypress. Favor app-level signals and deterministic server-side test hooks.

## Quick Reference

```typescript
it('renders incoming chat message', () => {
  cy.visit('/chat/general');

  cy.request('POST', '/api/test/realtime/emit', {
    channel: 'chat:general',
    event: 'message.new',
    payload: { author: 'Bob', text: 'Hello from Bob' },
  });

  cy.findByText('Hello from Bob').should('be.visible');
});
```

## Pattern 1: Event Injection Endpoint

**TypeScript**
```typescript
it('shows toast from realtime notification', () => {
  cy.loginByApi(Cypress.env('USER_EMAIL'), Cypress.env('USER_PASSWORD'));
  cy.visit('/dashboard');

  cy.request('POST', '/api/test/realtime/emit', {
    channel: 'user:me',
    event: 'notification.created',
    payload: { title: 'Build completed' },
  });

  cy.findByRole('status').should('contain.text', 'Build completed');
});
```

**JavaScript**
```javascript
it('shows toast from realtime notification', () => {
  cy.visit('/dashboard');

  cy.request('POST', '/api/test/realtime/emit', {
    channel: 'user:me',
    event: 'notification.created',
    payload: { title: 'Build completed' },
  });

  cy.findByRole('status').should('contain.text', 'Build completed');
});
```

## Pattern 2: SSE with `cy.intercept`

If realtime transport is SSE or long-polling over HTTP, `cy.intercept` is straightforward.

```typescript
it('renders events from SSE stream response', () => {
  cy.intercept('GET', '/api/events', {
    statusCode: 200,
    headers: { 'content-type': 'text/event-stream' },
    body: [
      'data: {"type":"notice","text":"first"}\n\n',
      'data: {"type":"notice","text":"second"}\n\n',
    ].join(''),
  }).as('events');

  cy.visit('/live');
  cy.wait('@events');
  cy.findByText('first').should('be.visible');
  cy.findByText('second').should('be.visible');
});
```

## Pattern 3: Polling Realtime UI

```typescript
it('updates metrics after subsequent poll', () => {
  let call = 0;

  cy.intercept('GET', '/api/dashboard/stats', (req) => {
    call += 1;
    req.reply({
      statusCode: 200,
      body: call === 1
        ? { activeUsers: 100 }
        : { activeUsers: 142 },
    });
  }).as('stats');

  cy.visit('/dashboard');
  cy.wait('@stats');
  cy.findByTestId('active-users').should('have.text', '100');

  cy.wait('@stats');
  cy.findByTestId('active-users').should('have.text', '142');
});
```

## Pattern 4: Reconnection Behavior

Use app-level network flags, status badges, or backend hooks to verify reconnect logic.

```typescript
it('shows reconnecting state and recovers', () => {
  cy.visit('/app');

  cy.request('POST', '/api/test/realtime/connection', { state: 'down' });
  cy.findByText('Reconnecting...').should('be.visible');

  cy.request('POST', '/api/test/realtime/connection', { state: 'up' });
  cy.findByText('Connected').should('be.visible');
});
```

## Pattern 5: Outbound Message Validation

Validate outbound message behavior by asserting side effects:

1. UI optimistic update.
2. Backend persistence endpoint called.
3. Event acknowledgment reflected.

```typescript
it('sends message and shows delivery status', () => {
  cy.intercept('POST', '/api/messages').as('sendMessage');
  cy.visit('/chat/general');

  cy.findByRole('textbox', { name: /message/i }).type('hello{enter}');
  cy.wait('@sendMessage').its('response.statusCode').should('eq', 201);
  cy.findByText('hello').should('be.visible');
  cy.findByTestId('message-status').last().should('have.text', 'Delivered');
});
```

## Anti-Patterns

| Anti-pattern | Why it fails | Better pattern |
|---|---|---|
| `cy.wait(3000)` for message arrival | Timing guess, flaky CI | Assert eventual UI state with retries |
| Verifying low-level socket frames in every test | Coupled to transport internals | Verify user-visible outcomes |
| Using live external realtime services in PR tests | Unstable and slow | Use deterministic test hooks/mocks |
| Asserting only initial connection state | Misses reconnect regressions | Simulate disconnect and reconnect states |

## Troubleshooting

### Realtime message does not appear

- Ensure page subscribed before injecting event.
- Trigger event after `cy.visit` and any initial bootstrap request.
- Validate channel key/tenant/user IDs match app subscription.

### Polling assertions flaky

- Wait on request aliases, not fixed sleeps.
- Confirm polling interval in test env is reasonable for CI.

### Reconnection state never clears

- App may require successful heartbeat/ack event.
- Emit both connection-up and data event if UI logic depends on both.

## Related Guides

- [network-mocking.md](network-mocking.md)
- [multi-user-and-collaboration.md](multi-user-and-collaboration.md)
- [assertions-and-waiting.md](assertions-and-waiting.md)
- [debugging.md](debugging.md)
