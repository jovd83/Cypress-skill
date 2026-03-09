# Next.js Testing with Cypress

> **When to use**: Next.js apps (App Router or Pages Router) requiring E2E, component, and API route coverage.
> **Prerequisites**: [configuration.md](configuration.md), [api-testing.md](api-testing.md), [component-testing.md](component-testing.md)

## Quick Reference

```typescript
it('renders home page and navigates to docs', () => {
  cy.visit('/');
  cy.findByRole('heading', { level: 1 }).should('be.visible');
  cy.findByRole('link', { name: /docs/i }).click();
  cy.url().should('include', '/docs');
});
```

## Recommended Setup

Use a dedicated test env:

```bash
NODE_ENV=test
NEXT_PUBLIC_API_BASE_URL=http://localhost:3000
```

In CI, start Next.js before Cypress:

```bash
npm run build
npm run start &
npx cypress run
```

## Pattern 1: App Router and Pages Router Navigation

```typescript
describe('routing', () => {
  it('navigates to dynamic blog route', () => {
    cy.visit('/blog/nextjs-testing-guide');
    cy.findByRole('heading', { level: 1 }).should('contain.text', 'Next.js Testing Guide');
  });

  it('shows not-found page for unknown slug', () => {
    cy.visit('/blog/this-post-does-not-exist', { failOnStatusCode: false });
    cy.findByRole('heading').should('contain.text', '404');
  });
});
```

## Pattern 2: API Routes with `cy.request`

**TypeScript**
```typescript
describe('api routes', () => {
  it('GET /api/products returns products', () => {
    cy.request('/api/products').then((res) => {
      expect(res.status).to.eq(200);
      expect(res.body.products).to.be.an('array');
    });
  });

  it('POST /api/products validates required fields', () => {
    cy.request({
      method: 'POST',
      url: '/api/products',
      failOnStatusCode: false,
      body: { name: '' },
    }).then((res) => {
      expect(res.status).to.eq(400);
      expect(res.body.error).to.exist;
    });
  });
});
```

**JavaScript**
```javascript
describe('api routes', () => {
  it('GET /api/products returns products', () => {
    cy.request('/api/products').then((res) => {
      expect(res.status).to.eq(200);
      expect(res.body.products).to.be.an('array');
    });
  });
});
```

## Pattern 3: Server Actions and Form Workflows

```typescript
it('creates product through UI and confirms success', () => {
  cy.visit('/products/new');
  cy.findByLabelText(/product name/i).type('Widget');
  cy.findByLabelText(/price/i).type('19.99');
  cy.findByRole('button', { name: /create product/i }).click();

  cy.findByText(/product created successfully/i).should('be.visible');
  cy.url().should('match', /\/products\/\d+$/);
});
```

## Pattern 4: Middleware Guards

```typescript
describe('middleware auth guard', () => {
  it('redirects anonymous user from /dashboard', () => {
    cy.clearCookies();
    cy.visit('/dashboard', { failOnStatusCode: false });
    cy.url().should('include', '/login');
  });

  it('blocks unauthorized API access', () => {
    cy.request({
      method: 'GET',
      url: '/api/admin/users',
      failOnStatusCode: false,
    }).its('status').should('be.oneOf', [401, 403]);
  });
});
```

## Pattern 5: SSR/CSR Consistency

```typescript
it('hydrates without user-visible regression', () => {
  cy.visit('/');
  cy.findByRole('button', { name: /get started/i }).click();
  cy.findByRole('heading', { name: /welcome/i }).should('be.visible');
});
```

For deeper hydration diagnostics, capture browser console errors and fail on hydration mismatch messages.

## Pattern 6: i18n and Locale Routing

```typescript
it('serves french locale route', () => {
  cy.visit('/fr');
  cy.findByText('Bienvenue').should('be.visible');
});
```

## Pattern 7: Component Testing Next.js UI

```typescript
import { mount } from 'cypress/react';
import ProductCard from '../../src/components/ProductCard';

it('renders product card and click handler', () => {
  const onAdd = cy.stub().as('onAdd');
  mount(<ProductCard name="Keyboard" price={79.99} onAdd={onAdd} />);

  cy.findByText('Keyboard').should('be.visible');
  cy.findByRole('button', { name: /add to cart/i }).click();
  cy.get('@onAdd').should('have.been.calledOnce');
});
```

## Anti-Patterns

| Anti-pattern | Why it fails | Better pattern |
|---|---|---|
| Using non-Cypress `request` fixture examples in Cypress docs | Invalid API | Use `cy.request` |
| Asserting response status from `cy.visit` return value | `cy.visit` is for navigation, not response introspection | Use `cy.request` for status/header checks |
| Heavy UI setup for API route tests | Slow and flaky | Test API routes directly with `cy.request` |
| Testing only one router mode | Misses App/Pages parity regressions | Cover both route types used by your app |

## Troubleshooting

### Next page loads but data is empty in tests

- Verify test env variables (`NEXT_PUBLIC_*`) are set for Cypress runs.
- Confirm API mocks/intercepts match actual route URLs.

### Middleware redirect assertions flaky

- Use `failOnStatusCode: false` on protected routes.
- Assert final URL and login UI marker.

### Dynamic route 404 behavior differs in CI

- Ensure build artifacts are produced (`next build`) before `next start`.
- Avoid relying on `next dev` behavior for production-like tests.

## Related Guides

- [react.md](react.md)
- [api-testing.md](api-testing.md)
- [network-mocking.md](network-mocking.md)
- [authentication.md](authentication.md)
