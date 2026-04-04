# Request Mocking

> **When to use**: Stub or observe network traffic with `cy.intercept()` to make tests deterministic, isolate third-party dependencies, and validate request/response contracts.
> **Prerequisites**: [core-commands.md](core-commands.md), [running-custom-code.md](running-custom-code.md)

## Quick Reference

```bash
# CLI route helpers
cypress-cli route "**/*.jpg" --status=404
cypress-cli route "**/api/users" --body='[{"id":1,"name":"Alice"}]' --content-type=application/json
cypress-cli route-list
cypress-cli unroute "**/*.jpg"
cypress-cli unroute
```

## URL Pattern Notes

Use glob-style URL patterns consistently:

| Pattern | Example |
|---|---|
| `**/api/users` | Match users endpoint on any host |
| `**/api/*/details` | Match one dynamic path segment |
| `**/*.{png,jpg,webp}` | Match static asset extensions |
| `**/search?q=*` | Match query-parameterized endpoint |

## Cypress `cy.intercept()` Patterns

### Static Stub

```bash
cypress-cli run-code "() => {
  cy.intercept('GET', '**/api/users', {
    statusCode: 200,
    body: [{ id: 1, name: 'Alice' }, { id: 2, name: 'Bob' }]
  }).as('users');

  cy.visit('https://app.example.com/users');
  cy.wait('@users');
}"
```

### Conditional Stub by Request Body

```bash
cypress-cli run-code "() => {
  cy.intercept('POST', '**/api/login', (req) => {
    if (req.body?.username === 'admin' && req.body?.password === 'secret') {
      req.reply({ statusCode: 200, body: { token: 'mock-jwt', role: 'admin' } });
    } else {
      req.reply({ statusCode: 401, body: { error: 'Invalid credentials' } });
    }
  }).as('login');
}"
```

### Pass Through and Assert Response

```bash
cypress-cli run-code "() => {
  cy.intercept('GET', '**/api/profile', (req) => {
    req.continue((res) => {
      expect(res.statusCode).to.eq(200);
      expect(res.body).to.have.property('id');
    });
  }).as('profile');
}"
```

### Simulate Server Errors and Timeouts

```bash
# 500 error
cypress-cli run-code "() => {
  cy.intercept('GET', '**/api/reports', { statusCode: 500, body: { error: 'boom' } }).as('reports');
}"

# Network error
cypress-cli run-code "() => {
  cy.intercept('GET', '**/api/health', { forceNetworkError: true }).as('health');
}"

# Delayed response
cypress-cli run-code "() => {
  cy.intercept('GET', '**/api/slow', {
    statusCode: 200,
    delayMs: 3000,
    body: { ok: true }
  }).as('slow');
}"
```

## GraphQL Example

```bash
cypress-cli run-code "() => {
  cy.intercept('POST', '**/graphql', (req) => {
    const query = req.body?.query || '';

    if (query.includes('GetUser')) {
      req.reply({
        statusCode: 200,
        body: { data: { user: { id: '1', name: 'Alice' } } }
      });
      return;
    }

    if (query.includes('ListProducts')) {
      req.reply({
        statusCode: 200,
        body: { data: { products: [{ id: 'p1', name: 'Widget', price: 9.99 }] } }
      });
      return;
    }

    req.continue();
  }).as('graphql');
}"
```

## Block Third-Party Noise

```bash
cypress-cli run-code "() => {
  const blocked = [
    'google-analytics.com',
    'googletagmanager.com',
    'segment.io',
    'hotjar.com'
  ];

  cy.intercept('**/*', (req) => {
    if (blocked.some((d) => req.url.includes(d))) {
      req.reply({ statusCode: 204, body: '' });
    } else {
      req.continue();
    }
  });
}"
```

## Request Counting

```bash
cypress-cli run-code "() => {
  let count = 0;

  cy.intercept('POST', '**/api/analytics', (req) => {
    count += 1;
    req.reply({ statusCode: 204, body: '' });
  }).as('analytics');

  cy.then(() => console.log('analytics calls:', count));
}"
```

## WebSocket Note

Cypress does not natively stub WebSocket frames the same way it stubs HTTP. Prefer:

1. Testing server behavior via API contracts where possible.
2. Exposing app-level hooks/events for deterministic assertions.
3. Using backend test doubles for socket-heavy flows.

## Anti-Patterns

| Anti-pattern | Problem | Better pattern |
|---|---|---|
| Registering `cy.intercept` after trigger action | Alias never sees request | Register intercept before click/navigation |
| Wildcard stubs without HTTP method | Unintended routes get stubbed | Include method + targeted path pattern |
| Mocking every internal backend response | Hides integration regressions | Mock external dependencies selectively |
| Stubbing without alias/assertions | False confidence on flow correctness | Use `.as(...)` and assert request/response |

## Best Practices

1. Register intercepts before triggering UI actions.
2. Alias important calls and wait/assert on them.
3. Mock external dependencies aggressively; mock your own backend selectively.
4. Keep fixtures realistic and versioned.
5. Remove temporary mocks that hide regressions.

## Troubleshooting

### Route helper does not appear to match the request

- Narrow or broaden the glob pattern until it matches the real request URL.
- Include the HTTP method when the same path is used for multiple operations.
- Use `cypress-cli network` or `run-code` with logging to inspect the actual request shape.

### `cy.intercept()` logic becomes hard to read

- Move repeated mock setup into reusable `run-code` snippets or fixtures.
- Split very large conditional mocks by endpoint or operation name.
- Prefer static fixtures when branching logic is not part of the test intent.

### Mocked flow passes but real integration still fails

- Keep a separate suite or run path with reduced mocking.
- Use pass-through assertions for contract validation when realism matters.
- Confirm the mocked payload still reflects the real API shape.

## Related

- [core-commands.md](core-commands.md)
- [running-custom-code.md](running-custom-code.md)
- [debugging-and-artifacts.md](debugging-and-artifacts.md)
