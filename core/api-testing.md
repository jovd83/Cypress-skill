# API Testing

> **When to use**: Validate REST or GraphQL behavior directly, seed test data, and verify backend contracts without UI overhead.
> **Prerequisites**: [configuration.md](configuration.md), [network-mocking.md](network-mocking.md), [test-data-management.md](test-data-management.md)

## Quick Reference

```typescript
it('GET /api/users returns active users', () => {
  cy.request('/api/users?status=active').then((response) => {
    expect(response.status).to.eq(200);
    expect(response.headers['content-type']).to.include('application/json');
    expect(response.body.users).to.be.an('array');
  });
});
```

## Cypress API Testing Rules

1. Use `cy.request()` for direct API checks.
2. Use `cy.intercept()` for UI + API synchronization.
3. Keep API tests deterministic and idempotent.
4. Assert both status codes and response body shape.
5. Use `cy.session()` to avoid repeated auth setup.

## Pattern 1: REST CRUD with `cy.request`

**TypeScript**
```typescript
it('creates, updates, and deletes a user via API', () => {
  const email = `api-user-${Date.now()}@example.com`;

  cy.request('POST', '/api/users', {
    name: 'API User',
    email,
    role: 'viewer',
  }).then((createRes) => {
    expect(createRes.status).to.eq(201);
    expect(createRes.body.id).to.be.a('number');

    const userId: number = createRes.body.id;

    cy.request('PATCH', `/api/users/${userId}`, { role: 'admin' }).then((patchRes) => {
      expect(patchRes.status).to.eq(200);
      expect(patchRes.body.role).to.eq('admin');
    });

    cy.request('DELETE', `/api/users/${userId}`).its('status').should('eq', 204);
    cy.request({
      method: 'GET',
      url: `/api/users/${userId}`,
      failOnStatusCode: false,
    }).its('status').should('eq', 404);
  });
});
```

**JavaScript**
```javascript
it('creates, updates, and deletes a user via API', () => {
  const email = `api-user-${Date.now()}@example.com`;

  cy.request('POST', '/api/users', {
    name: 'API User',
    email,
    role: 'viewer',
  }).then((createRes) => {
    expect(createRes.status).to.eq(201);
    const userId = createRes.body.id;

    cy.request('PATCH', `/api/users/${userId}`, { role: 'admin' })
      .its('body.role')
      .should('eq', 'admin');

    cy.request('DELETE', `/api/users/${userId}`).its('status').should('eq', 204);
    cy.request({
      method: 'GET',
      url: `/api/users/${userId}`,
      failOnStatusCode: false,
    }).its('status').should('eq', 404);
  });
});
```

## Pattern 2: Authenticated Requests with `cy.session()`

**TypeScript**
```typescript
beforeEach(() => {
  cy.session('admin-session', () => {
    cy.request('POST', '/api/auth/login', {
      email: Cypress.env('ADMIN_EMAIL'),
      password: Cypress.env('ADMIN_PASSWORD'),
    }).then((res) => {
      expect(res.status).to.eq(200);
      window.localStorage.setItem('access_token', res.body.accessToken);
    });
  });
});

it('reads protected admin stats', () => {
  cy.window().then((win) => {
    const token = win.localStorage.getItem('access_token');
    cy.request({
      method: 'GET',
      url: '/api/admin/stats',
      headers: { Authorization: `Bearer ${token}` },
    }).its('status').should('eq', 200);
  });
});
```

**JavaScript**
```javascript
beforeEach(() => {
  cy.session('admin-session', () => {
    cy.request('POST', '/api/auth/login', {
      email: Cypress.env('ADMIN_EMAIL'),
      password: Cypress.env('ADMIN_PASSWORD'),
    }).then((res) => {
      window.localStorage.setItem('access_token', res.body.accessToken);
    });
  });
});
```

## Pattern 3: GraphQL Requests

```typescript
it('queries GraphQL endpoint', () => {
  const query = `
    query GetUsers($limit: Int!) {
      users(limit: $limit) {
        id
        email
      }
    }
  `;

  cy.request('POST', '/graphql', {
    query,
    variables: { limit: 5 },
  }).then((res) => {
    expect(res.status).to.eq(200);
    expect(res.body.errors).to.be.undefined;
    expect(res.body.data.users).to.have.length.at.most(5);
  });
});
```

GraphQL note:

- HTTP status can still be `200` when logical errors exist.
- Always assert `body.errors` and required `body.data` fields.

## Pattern 4: Seed Data by API, Verify in UI

**TypeScript**
```typescript
it('seeds product by API and verifies checkout flow in UI', () => {
  const sku = `sku-${Date.now()}`;

  cy.request('POST', '/api/products', {
    name: 'Seeded Product',
    sku,
    price: 49.99,
  }).then((res) => {
    expect(res.status).to.eq(201);
  });

  cy.visit('/shop');
  cy.findByText('Seeded Product').should('be.visible');
  cy.findByRole('button', { name: /add to cart/i }).click();
  cy.findByRole('link', { name: /cart/i }).click();
  cy.findByText('$49.99').should('be.visible');
});
```

## Pattern 5: Negative and Edge Cases

```typescript
describe('users API error handling', () => {
  it('returns 400 for invalid payload', () => {
    cy.request({
      method: 'POST',
      url: '/api/users',
      failOnStatusCode: false,
      body: { email: 'not-an-email' },
    }).then((res) => {
      expect(res.status).to.eq(400);
      expect(res.body.error).to.match(/invalid/i);
    });
  });

  it('returns 401 without auth token', () => {
    cy.request({
      method: 'GET',
      url: '/api/admin/stats',
      failOnStatusCode: false,
    }).its('status').should('eq', 401);
  });

  it('returns 404 for unknown resource', () => {
    cy.request({
      method: 'GET',
      url: '/api/users/999999999',
      failOnStatusCode: false,
    }).its('status').should('eq', 404);
  });
});
```

## Pattern 6: Contract Assertions

```typescript
it('validates response contract for user profile', () => {
  cy.request('/api/profile').then((res) => {
    expect(res.status).to.eq(200);
    expect(res.body).to.include.keys('id', 'email', 'role', 'createdAt');
    expect(res.body.id).to.be.a('number');
    expect(res.body.email).to.match(/@/);
    expect(['viewer', 'editor', 'admin']).to.include(res.body.role);
  });
});
```

For larger APIs, use schema validation libraries in Cypress tasks (Ajv, Zod, or custom validators) to keep response assertions consistent.

## Pattern 7: API + `cy.intercept()` Coordination

```typescript
it('asserts UI calls expected endpoint and handles response', () => {
  cy.intercept('GET', '/api/orders*').as('getOrders');

  cy.visit('/orders');
  cy.wait('@getOrders').then(({ response }) => {
    expect(response?.statusCode).to.eq(200);
  });

  cy.findByRole('heading', { name: /orders/i }).should('be.visible');
});
```

## Anti-Patterns

| Anti-pattern | Why it fails | Cypress alternative |
|---|---|---|
| Using non-Cypress request fixture syntax | Not valid Cypress API | Use `cy.request()` |
| Skipping status assertions | False positives on partial failures | Assert status first, then body |
| Using `cy.wait(2000)` for API readiness | Flaky and slow | Wait on `cy.intercept()` aliases |
| Hardcoding seeded entity IDs | Fails across environments | Create entities in-test and capture IDs |
| Repeating login before every test | Slow suite | Cache auth with `cy.session()` |

## Troubleshooting

### `cy.request()` returns HTML instead of JSON

- Verify `baseUrl` and route path.
- Check auth and redirect behavior.
- Log payload quickly:

```typescript
cy.request({ url: '/api/users', failOnStatusCode: false }).then((res) => {
  cy.log(`status=${res.status}`);
  cy.log(`content-type=${res.headers['content-type']}`);
});
```

### Need to test multipart upload endpoints

- For UI uploads, prefer input file flows in [file-upload-download.md](file-upload-download.md).
- For pure API multipart, use a plugin or task if backend requires raw multipart boundaries.

## Related Guides

- [test-data-management.md](test-data-management.md)
- [network-mocking.md](network-mocking.md)
- [authentication.md](authentication.md)
- [test-architecture.md](test-architecture.md)
