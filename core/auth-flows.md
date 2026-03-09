# Authentication Flow Recipes

> **When to use**: Implementing or validating real authentication behavior in Cypress tests.
> **Prerequisites**: [authentication.md](authentication.md), [network-mocking.md](network-mocking.md), [assertions-and-waiting.md](assertions-and-waiting.md)

## Recipe 1: Basic Login

### Complete Example

**TypeScript**
```typescript
describe('auth: basic login', () => {
  it('logs in through UI and reaches dashboard', () => {
    cy.intercept('POST', '/api/auth/login').as('login');

    cy.visit('/login');
    cy.findByLabelText(/email/i).type('user@example.com');
    cy.findByLabelText(/password/i).type('password123', { log: false });
    cy.findByRole('button', { name: /sign in/i }).click();

    cy.wait('@login').its('response.statusCode').should('eq', 200);
    cy.location('pathname').should('eq', '/dashboard');
    cy.findByRole('heading', { name: /dashboard/i }).should('be.visible');
  });
});
```

**JavaScript**
```javascript
describe('auth: basic login', () => {
  it('logs in through UI and reaches dashboard', () => {
    cy.intercept('POST', '/api/auth/login').as('login');

    cy.visit('/login');
    cy.findByLabelText(/email/i).type('user@example.com');
    cy.findByLabelText(/password/i).type('password123', { log: false });
    cy.findByRole('button', { name: /sign in/i }).click();

    cy.wait('@login').its('response.statusCode').should('eq', 200);
    cy.location('pathname').should('eq', '/dashboard');
  });
});
```

## Recipe 2: Login with Remember Me

### Complete Example

**TypeScript**
```typescript
describe('auth: remember me', () => {
  it('persists session cookie when remember me is checked', () => {
    cy.visit('/login');

    cy.findByLabelText(/email/i).type('user@example.com');
    cy.findByLabelText(/password/i).type('password123', { log: false });
    cy.findByRole('checkbox', { name: /remember me/i }).check();
    cy.findByRole('button', { name: /sign in/i }).click();

    cy.getCookie('session').should('exist');
    cy.location('pathname').should('eq', '/dashboard');

    cy.reload();
    cy.location('pathname').should('eq', '/dashboard');
  });
});
```

## Recipe 3: Signup with Email Verification (Mocked)

### Complete Example

Use intercepts to keep the flow deterministic. Keep at least one environment-level test with real email infrastructure.

**TypeScript**
```typescript
describe('auth: signup + verification', () => {
  it('creates account and verifies email token', () => {
    const token = 'test-verify-token';

    cy.intercept('POST', '/api/auth/signup', {
      statusCode: 201,
      body: { userId: 'u-1' },
    }).as('signup');

    cy.intercept('POST', '/api/auth/send-verification-email', {
      statusCode: 202,
      body: { sent: true, token },
    }).as('sendVerification');

    cy.intercept('GET', `/api/auth/verify-email?token=${token}`, {
      statusCode: 200,
      body: { verified: true },
    }).as('verifyEmail');

    cy.visit('/signup');
    cy.findByLabelText(/name/i).type('Jane Doe');
    cy.findByLabelText(/email/i).type('jane@example.com');
    cy.findByLabelText(/^password$/i).type('password123!', { log: false });
    cy.findByLabelText(/confirm password/i).type('password123!', { log: false });
    cy.findByRole('button', { name: /create account/i }).click();

    cy.wait('@signup').its('response.statusCode').should('eq', 201);
    cy.wait('@sendVerification').its('response.statusCode').should('eq', 202);

    cy.visit(`/verify-email?token=${token}`);
    cy.wait('@verifyEmail').its('response.statusCode').should('eq', 200);
    cy.findByText(/email verified/i).should('be.visible');
  });
});
```

## Recipe 4: Password Reset Flow

### Complete Example

**TypeScript**
```typescript
describe('auth: password reset', () => {
  it('requests reset link and sets a new password', () => {
    const resetToken = 'reset-abc123';

    cy.intercept('POST', '/api/auth/forgot-password', {
      statusCode: 202,
      body: { sent: true, token: resetToken },
    }).as('forgot');

    cy.intercept('POST', '/api/auth/reset-password', {
      statusCode: 200,
      body: { reset: true },
    }).as('reset');

    cy.visit('/forgot-password');
    cy.findByLabelText(/email/i).type('user@example.com');
    cy.findByRole('button', { name: /send reset link/i }).click();

    cy.wait('@forgot').its('response.statusCode').should('eq', 202);

    cy.visit(`/reset-password?token=${resetToken}`);
    cy.findByLabelText(/^new password$/i).type('newPassword123!', { log: false });
    cy.findByLabelText(/confirm new password/i).type('newPassword123!', { log: false });
    cy.findByRole('button', { name: /update password/i }).click();

    cy.wait('@reset').its('response.statusCode').should('eq', 200);
    cy.findByText(/password updated/i).should('be.visible');
  });
});
```

## Recipe 5: OAuth Login (Mocked Callback)

### Complete Example

Cypress cannot control external provider tabs as a first-class multi-context flow. The robust approach is mocking your backend callback.

**TypeScript**
```typescript
describe('auth: oauth callback', () => {
  it('handles oauth callback and establishes app session', () => {
    cy.intercept('GET', '/api/auth/callback/google*', {
      statusCode: 302,
      headers: { location: '/dashboard' },
    }).as('oauthCallback');

    cy.visit('/login');
    cy.findByRole('button', { name: /continue with google/i }).click();

    // Simulate provider redirect back to app
    cy.visit('/api/auth/callback/google?code=fake-code&state=fake-state');

    cy.wait('@oauthCallback');
    cy.location('pathname').should('eq', '/dashboard');
  });
});
```

## Recipe 6: Role-Based Access Testing

### Complete Example

**TypeScript**
```typescript
type Role = 'admin' | 'editor' | 'viewer';

const creds: Record<Role, { email: string; password: string }> = {
  admin: { email: 'admin@example.com', password: 'password123' },
  editor: { email: 'editor@example.com', password: 'password123' },
  viewer: { email: 'viewer@example.com', password: 'password123' },
};

function loginAs(role: Role) {
  const user = creds[role];
  cy.session(['api', role], () => {
    cy.request('POST', '/api/auth/login', user).its('status').should('eq', 200);
  });
}

describe('auth: role-based access', () => {
  it('admin can access user management', () => {
    loginAs('admin');
    cy.visit('/admin/users');
    cy.findByRole('heading', { name: /user management/i }).should('be.visible');
  });

  it('viewer cannot access user management', () => {
    loginAs('viewer');
    cy.visit('/admin/users');
    cy.findByText(/forbidden|not authorized/i).should('be.visible');
  });
});
```

## Recipe 7: Session Timeout Handling

### Complete Example

**TypeScript**
```typescript
describe('auth: session timeout', () => {
  it('redirects to login when session expires', () => {
    cy.session(['api', 'user'], () => {
      cy.request('POST', '/api/auth/login', {
        email: 'user@example.com',
        password: 'password123',
      }).its('status').should('eq', 200);
    });

    cy.intercept('GET', '/api/auth/me', { statusCode: 401, body: { message: 'expired' } }).as('me401');

    cy.visit('/dashboard');
    cy.wait('@me401');

    cy.location('pathname').should('eq', '/login');
    cy.findByText(/session expired/i).should('be.visible');
  });
});
```

## Recipe 8: Logout

### Complete Example

**TypeScript**
```typescript
describe('auth: logout', () => {
  it('clears auth state and blocks protected routes', () => {
    cy.session(['api', 'user'], () => {
      cy.request('POST', '/api/auth/login', {
        email: 'user@example.com',
        password: 'password123',
      });
    });

    cy.visit('/dashboard');
    cy.findByRole('button', { name: /logout/i }).click();

    cy.location('pathname').should('eq', '/login');

    cy.visit('/dashboard');
    cy.location('pathname').should('eq', '/login');
  });
});
```

## Variations

### Login via API for Speed

Use this for non-auth features:

```typescript
cy.session(['api', 'user@example.com'], () => {
  cy.request('POST', '/api/auth/login', {
    email: 'user@example.com',
    password: 'password123',
  }).its('status').should('eq', 200);
});
```

### Multi-Factor Authentication

Use stubs for OTP verification in regular CI, and keep one environment-level real integration test.

```typescript
cy.intercept('POST', '/api/auth/verify-otp', {
  statusCode: 200,
  body: { verified: true },
}).as('verifyOtp');
```

### Cross-Role Data Isolation

In parallel CI jobs, avoid shared mutable accounts. Use per-role/per-job users:
- `admin+job1@example.com`
- `admin+job2@example.com`

## Anti-Patterns

| Anti-pattern | Problem | Better pattern |
|---|---|---|
| UI login in every spec by default | Slow and flaky suites | Cache auth with `cy.session()` and keep dedicated login UX specs |
| Registering auth intercepts after clicking sign-in | Alias never captures request | Register `cy.intercept` before action |
| Hardcoding secrets in test code | Security risk and poor portability | Use `CYPRESS_*` environment variables |
| Fixed waits during auth transitions | Race conditions across CI/local | Wait on aliases, URL/state assertions |

## Tips

1. Always assert both network response and user-visible state.
2. Register `cy.intercept` before the action that triggers the request.
3. Keep one dedicated login UX spec even if most tests use API/session shortcuts.
4. Never use `cy.wait(2000)` for auth transitions.
5. Keep secret values in `CYPRESS_*` env vars, not in test files.

## Related

- [authentication.md](authentication.md)
- [network-mocking.md](network-mocking.md)
- [flaky-tests.md](flaky-tests.md)
- [../ci/global-setup-teardown.md](../ci/global-setup-teardown.md)
