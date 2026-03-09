# Authentication Testing

> **When to use**: Any suite that hits protected routes, role-based behavior, or login/session state.
> **Prerequisites**: [core/configuration.md](configuration.md), [core/fixtures-and-hooks.md](fixtures-and-hooks.md), [core/network-mocking.md](network-mocking.md)

## Quick Reference

```typescript
// Cache UI login with cy.session()
Cypress.Commands.add('loginUi', (email: string, password: string) => {
  cy.session(['ui', email], () => {
    cy.visit('/login');
    cy.findByLabelText(/email/i).type(email);
    cy.findByLabelText(/password/i).type(password, { log: false });
    cy.findByRole('button', { name: /sign in/i }).click();
    cy.location('pathname').should('match', /dashboard|home/);
  });
});

// Programmatic login (faster)
Cypress.Commands.add('loginApi', (email: string, password: string) => {
  cy.session(['api', email], () => {
    cy.request('POST', '/api/auth/login', { email, password })
      .its('status')
      .should('eq', 200);
  });
});
```

## Patterns

### Pattern 1: Default to `cy.session()`

**Use when**: Most authenticated E2E tests.
**Avoid when**: You explicitly test the login page UX in that spec.

`cy.session()` caches cookies/localStorage/sessionStorage for a key. Repeated tests skip the expensive login path.

**TypeScript**
```typescript
// cypress/support/commands.ts
Cypress.Commands.add('loginUi', (email: string, password: string) => {
  cy.session(['ui', email], () => {
    cy.visit('/login');
    cy.findByLabelText('Email').type(email);
    cy.findByLabelText('Password').type(password, { log: false });
    cy.findByRole('button', { name: 'Sign in' }).click();
    cy.findByRole('heading', { name: /dashboard/i }).should('be.visible');
  }, {
    validate: () => {
      cy.request({ url: '/api/auth/me', failOnStatusCode: false })
        .its('status')
        .should('eq', 200);
    },
    cacheAcrossSpecs: true,
  });
});
```

```typescript
// cypress/e2e/dashboard.cy.ts
describe('dashboard', () => {
  beforeEach(() => {
    cy.loginUi(Cypress.env('USER_EMAIL'), Cypress.env('USER_PASSWORD'));
  });

  it('loads widgets for authenticated user', () => {
    cy.visit('/dashboard');
    cy.findByRole('heading', { name: /dashboard/i }).should('be.visible');
  });
});
```

**JavaScript**
```javascript
Cypress.Commands.add('loginUi', (email, password) => {
  cy.session(['ui', email], () => {
    cy.visit('/login');
    cy.findByLabelText('Email').type(email);
    cy.findByLabelText('Password').type(password, { log: false });
    cy.findByRole('button', { name: 'Sign in' }).click();
    cy.findByRole('heading', { name: /dashboard/i }).should('be.visible');
  });
});
```

### Pattern 2: Prefer API Login for Non-Auth Features

**Use when**: Most tests do not care about login form behavior.
**Avoid when**: You need to assert field-level login errors, MFA UI, or captcha UX.

Programmatic login is usually the fastest and least flaky path.

**TypeScript**
```typescript
Cypress.Commands.add('loginApi', (email: string, password: string) => {
  cy.session(['api', email], () => {
    cy.request('POST', '/api/auth/login', { email, password }).then((resp) => {
      expect(resp.status).to.eq(200);
      // If token is returned and app expects localStorage:
      if (resp.body?.token) {
        cy.window().then((win) => {
          win.localStorage.setItem('auth_token', resp.body.token);
        });
      }
    });
  }, {
    validate: () => {
      cy.request('/api/auth/me').its('status').should('eq', 200);
    },
  });
});
```

```typescript
describe('orders', () => {
  beforeEach(() => {
    cy.loginApi(Cypress.env('USER_EMAIL'), Cypress.env('USER_PASSWORD'));
  });

  it('creates an order', () => {
    cy.visit('/orders/new');
    cy.findByRole('button', { name: /submit order/i }).click();
    cy.findByText(/order created/i).should('be.visible');
  });
});
```

### Pattern 3: Multi-Role Authentication

**Use when**: Admin/user/viewer flows differ.
**Avoid when**: Single-role app behavior.

Use a role map and one command that selects credentials.

**TypeScript**
```typescript
type Role = 'admin' | 'editor' | 'viewer';

const creds: Record<Role, { email: string; password: string }> = {
  admin: { email: Cypress.env('ADMIN_EMAIL'), password: Cypress.env('ADMIN_PASSWORD') },
  editor: { email: Cypress.env('EDITOR_EMAIL'), password: Cypress.env('EDITOR_PASSWORD') },
  viewer: { email: Cypress.env('VIEWER_EMAIL'), password: Cypress.env('VIEWER_PASSWORD') },
};

Cypress.Commands.add('loginAs', (role: Role) => {
  const { email, password } = creds[role];
  cy.loginApi(email, password);
});
```

```typescript
describe('admin access', () => {
  beforeEach(() => cy.loginAs('admin'));

  it('can access user management', () => {
    cy.visit('/admin/users');
    cy.findByRole('heading', { name: /user management/i }).should('be.visible');
  });
});

describe('viewer access', () => {
  beforeEach(() => cy.loginAs('viewer'));

  it('cannot access user management', () => {
    cy.visit('/admin/users');
    cy.findByText(/forbidden|not authorized/i).should('be.visible');
  });
});
```

### Pattern 4: Keep One Dedicated Login Spec

**Use when**: Validating login UX and error messaging.
**Avoid when**: Feature tests where login is only setup.

Do not remove UI login coverage entirely.

```typescript
describe('login page', () => {
  it('shows validation and server errors', () => {
    cy.visit('/login');

    cy.findByRole('button', { name: /sign in/i }).click();
    cy.findByText(/email is required/i).should('be.visible');

    cy.findByLabelText(/email/i).type('bad@example.com');
    cy.findByLabelText(/password/i).type('wrong-password', { log: false });
    cy.findByRole('button', { name: /sign in/i }).click();

    cy.findByText(/invalid credentials/i).should('be.visible');
  });
});
```

### Pattern 5: Logged-Out Test Segments

**Use when**: Testing redirects, public pages, and access control.

```typescript
describe('auth guard', () => {
  it('redirects anonymous users', () => {
    cy.clearCookies();
    cy.clearLocalStorage();

    cy.visit('/account');
    cy.location('pathname').should('eq', '/login');
  });
});
```

### Pattern 6: Token Expiry and Refresh

**Use when**: JWT expiry/refresh is critical.

```typescript
describe('session refresh', () => {
  it('refreshes token on 401', () => {
    cy.loginApi(Cypress.env('USER_EMAIL'), Cypress.env('USER_PASSWORD'));

    cy.intercept('GET', '/api/auth/me', { statusCode: 401 }).as('me401');
    cy.intercept('POST', '/api/auth/refresh').as('refresh');

    cy.visit('/dashboard');

    cy.wait('@me401');
    cy.wait('@refresh').its('response.statusCode').should('eq', 200);
    cy.findByRole('heading', { name: /dashboard/i }).should('be.visible');
  });
});
```

## Decision Guide

| Scenario | Recommended Pattern | Why |
|---|---|---|
| Standard authenticated feature tests | `cy.session()` + API login | Fast and stable |
| Login UX validation | Dedicated UI login specs | Preserves real user-path coverage |
| Multiple roles | `loginAs(role)` wrapper | Keeps role logic centralized |
| Access control / anonymous user | Clear cookies/storage per test | Deterministic logged-out state |
| Short-lived tokens | Session validate callback + refresh checks | Catches expiry regressions |

## Anti-Patterns

| Anti-pattern | Problem | Better approach |
|---|---|---|
| Logging in through UI in every test | Slow and flaky | Cache with `cy.session()` |
| Reusing one mutable admin account across all parallel jobs | Race conditions and test coupling | Use role/account isolation per job |
| Using `cy.wait(2000)` after sign-in | Non-deterministic synchronization | Assert URL + visible post-login element |
| Blindly forcing clicks in auth flows | Hides real UI blockers | Fix actionability root cause |
| Skipping login UI tests entirely | Misses real regression in auth UX | Keep a focused login spec suite |

## Troubleshooting

### `cy.session` seems ignored

- Confirm session key is stable (`['api', email]`).
- Ensure `validate` passes quickly and deterministically.
- Keep `testIsolation` enabled unless you have a proven reason otherwise.

### Tests pass locally, fail in CI with auth errors

- Verify env vars are set in CI (`CYPRESS_USER_EMAIL`, etc.).
- Check domain/origin consistency (`baseUrl` must match cookie domain assumptions).
- Confirm backend seed/user provisioning runs before Cypress.

### `401` after restore

- Token likely expired before reuse.
- Add refresh behavior checks or reduce session reuse scope.
- Generate fresh sessions per role/job when TTL is short.

## Security and Secret Hygiene

1. Keep all credentials in environment variables (`CYPRESS_*`), never hardcoded literals.
2. Mask sensitive inputs in logs (`type(password, { log: false })`) and avoid `cy.log()` with tokens.
3. Treat `cy.session()` caches and CLI `state-save` files as secrets; never commit them.
4. Use short-lived test credentials and isolate accounts per role and CI shard.
5. Clean state artifacts after runs, especially on shared agents.

```bash
rm -rf ./states ./artifacts ./recordings
```

```powershell
Remove-Item -Recurse -Force ./states, ./artifacts, ./recordings -ErrorAction SilentlyContinue
```

## Related

- [core/auth-flows.md](auth-flows.md) - OAuth, SSO, MFA, and advanced auth scenarios
- [core/network-mocking.md](network-mocking.md) - auth endpoint interception patterns
- [core/flaky-tests.md](flaky-tests.md) - removing timing flakiness from login setup
- [ci/global-setup-teardown.md](../ci/global-setup-teardown.md) - CI lifecycle hooks and pre-run scripts
