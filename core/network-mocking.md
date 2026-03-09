# Network Mocking

> **When to use**: Control network behavior in Cypress tests with `cy.intercept()` for deterministic UI tests, error-path validation, and third-party isolation.

## Golden Rules

1. Register intercepts before `cy.visit()` or before the user action that triggers the request.
2. Prefer alias-based waits (`cy.wait('@alias')`) over fixed time waits.
3. Mock external dependencies aggressively; mock your own API selectively.
4. Keep mocked payloads realistic and versioned with fixtures.

## Quick Reference

```typescript
// Static mock
cy.intercept('GET', '**/api/users', { statusCode: 200, body: [{ id: 1, name: 'Jane' }] }).as('getUsers');

// Conditional mock
cy.intercept('POST', '**/api/login', (req) => {
  if (req.body?.email === 'admin@example.com') {
    req.reply({ statusCode: 200, body: { token: 'test-token' } });
    return;
  }
  req.reply({ statusCode: 401, body: { error: 'Invalid credentials' } });
}).as('login');

// Pass-through with assertion
cy.intercept('GET', '**/api/profile', (req) => {
  req.continue((res) => {
    expect(res.statusCode).to.eq(200);
  });
}).as('profile');
```

## When To Mock vs Not Mock

| Scenario | Recommended Approach |
|---|---|
| UI behavior depends on unstable third-party APIs | Mock with `cy.intercept()` |
| Validate frontend state transitions for loading/empty/error | Mock with deterministic payloads |
| Validate request contract your app sends | Spy/intercept + assert request body/headers |
| End-to-end confidence against real backend | Use real backend (minimal mocking) |

## Static API Stubs

### TypeScript

```typescript
it('renders users from mocked API', () => {
  cy.intercept('GET', '**/api/users', {
    statusCode: 200,
    body: [
      { id: 1, name: 'Jane Doe', email: 'jane@example.com' },
      { id: 2, name: 'John Doe', email: 'john@example.com' }
    ]
  }).as('getUsers');

  cy.visit('/users');
  cy.wait('@getUsers').its('response.statusCode').should('eq', 200);

  cy.findByRole('row', { name: /jane doe/i }).should('be.visible');
  cy.findByRole('row', { name: /john doe/i }).should('be.visible');
});
```

### JavaScript

```javascript
it('renders users from mocked API', () => {
  cy.intercept('GET', '**/api/users', {
    statusCode: 200,
    body: [
      { id: 1, name: 'Jane Doe', email: 'jane@example.com' },
      { id: 2, name: 'John Doe', email: 'john@example.com' }
    ]
  }).as('getUsers');

  cy.visit('/users');
  cy.wait('@getUsers').its('response.statusCode').should('eq', 200);

  cy.findByRole('row', { name: /jane doe/i }).should('be.visible');
  cy.findByRole('row', { name: /john doe/i }).should('be.visible');
});
```

## Conditional Mocking

### Branch by Method

```typescript
cy.intercept('**/api/users', (req) => {
  if (req.method === 'GET') {
    req.reply({ statusCode: 200, body: [{ id: 1, name: 'Alice' }] });
    return;
  }

  if (req.method === 'POST') {
    req.reply({ statusCode: 201, body: { id: 2, name: req.body.name } });
    return;
  }

  req.continue();
});
```

### Branch by Query Params

```typescript
cy.intercept('GET', '**/api/search*', (req) => {
  const q = String(req.query.q || '').toLowerCase();

  if (q.includes('cypress')) {
    req.reply({ statusCode: 200, body: [{ id: 'p1', title: 'Cypress Guide' }] });
    return;
  }

  req.reply({ statusCode: 200, body: [] });
}).as('search');
```

## GraphQL Mocking

### TypeScript

```typescript
cy.intercept('POST', '**/graphql', (req) => {
  const operationName = req.body?.operationName;

  if (operationName === 'GetUsers') {
    req.reply({
      statusCode: 200,
      body: { data: { users: [{ id: '1', name: 'Alice' }] } }
    });
    return;
  }

  if (operationName === 'CreateUser') {
    req.reply({
      statusCode: 200,
      body: { data: { createUser: { id: '2', name: req.body.variables.name } } }
    });
    return;
  }

  req.continue();
}).as('graphql');
```

### JavaScript

```javascript
cy.intercept('POST', '**/graphql', (req) => {
  const operationName = req.body && req.body.operationName;

  if (operationName === 'GetUsers') {
    req.reply({
      statusCode: 200,
      body: { data: { users: [{ id: '1', name: 'Alice' }] } }
    });
    return;
  }

  if (operationName === 'CreateUser') {
    req.reply({
      statusCode: 200,
      body: { data: { createUser: { id: '2', name: req.body.variables.name } } }
    });
    return;
  }

  req.continue();
}).as('graphql');
```

## Error and Edge Simulation

```typescript
// 500 server error
cy.intercept('GET', '**/api/users', {
  statusCode: 500,
  body: { error: 'Internal Server Error' }
}).as('users500');

// Unauthorized
cy.intercept('GET', '**/api/admin/**', {
  statusCode: 403,
  body: { error: 'Forbidden' }
}).as('admin403');

// Network error
cy.intercept('GET', '**/api/health', { forceNetworkError: true }).as('healthDown');

// Delayed response for loading UI tests
cy.intercept('GET', '**/api/reports', {
  statusCode: 200,
  delayMs: 3000,
  body: []
}).as('slowReports');
```

## Spy on Real Requests

Use this when you want backend realism plus request assertions.

```typescript
it('sends expected payload on create user', () => {
  cy.intercept('POST', '**/api/users').as('createUser');

  cy.visit('/users/new');
  cy.findByLabelText('Name').clear().type('Alice');
  cy.findByLabelText('Email').clear().type('alice@example.com');
  cy.findByRole('button', { name: 'Create' }).click();

  cy.wait('@createUser').then(({ request, response }) => {
    expect(request.body).to.include({ name: 'Alice', email: 'alice@example.com' });
    expect(response && response.statusCode).to.be.oneOf([200, 201]);
  });
});
```

## Block Third-Party Noise

```typescript
cy.intercept('**/*', (req) => {
  const blockedDomains = ['google-analytics.com', 'googletagmanager.com', 'hotjar.com', 'segment.io'];

  if (blockedDomains.some((d) => req.url.includes(d))) {
    req.reply({ statusCode: 204, body: '' });
    return;
  }

  req.continue();
});
```

## Fixture-Driven Mocking

```typescript
cy.fixture('users.json').then((users) => {
  cy.intercept('GET', '**/api/users', { statusCode: 200, body: users }).as('getUsers');
});
```

## Anti-Patterns

- Registering intercepts after the request already fired.
- Using `cy.wait(2000)` instead of request aliases.
- Returning impossible API shapes that do not match production contracts.
- Mocking every endpoint in tests meant for integration confidence.

## Related

- [core/assertions-and-waiting.md](assertions-and-waiting.md)
- [core/flaky-tests.md](flaky-tests.md)
- [core/test-architecture.md](test-architecture.md)
- [core/when-to-mock.md](when-to-mock.md)
