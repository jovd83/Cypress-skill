# Security Testing

> **When to use**: Validate common web security controls in normal CI pipelines.
> **Prerequisites**: [api-testing.md](api-testing.md), [authentication.md](authentication.md)

## Scope

Cypress is effective for application-level security regression checks:

- XSS output encoding checks
- CSRF enforcement checks
- cookie flag checks
- security header checks
- auth route protection checks

Use dedicated security scanners (OWASP ZAP, Burp, SAST/DAST) for deep coverage.

## Pattern 1: Basic XSS Defense Check

```typescript
it('renders user input safely (no script execution)', () => {
  cy.visit('/profile');

  const payload = `<img src=x onerror="window.__xss_hit__=true">`;
  cy.findByLabelText(/display name/i).clear().type(payload);
  cy.findByRole('button', { name: /save/i }).click();

  cy.window().then((win) => {
    expect((win as any).__xss_hit__).to.be.undefined;
  });
  cy.findByTestId('display-name').should('contain.text', payload);
});
```

## Pattern 2: CSRF Enforcement

```typescript
it('rejects state-changing request without csrf token', () => {
  cy.request({
    method: 'POST',
    url: '/api/settings',
    failOnStatusCode: false,
    body: { theme: 'dark' },
  }).then((res) => {
    expect([401, 403, 419]).to.include(res.status);
  });
});
```

If your app requires login first, authenticate with `cy.request` then repeat the POST without CSRF header/token.

## Pattern 3: Security Headers

```typescript
it('returns expected security headers', () => {
  cy.request('/').then((res) => {
    expect(res.headers['x-content-type-options']).to.eq('nosniff');
    expect(res.headers['x-frame-options']).to.match(/DENY|SAMEORIGIN/);
    expect(res.headers['referrer-policy']).to.exist;
    expect(res.headers['strict-transport-security']).to.exist;
  });
});
```

## Pattern 4: Cookie Security Flags

```typescript
it('session cookie has secure attributes', () => {
  cy.loginByApi(Cypress.env('USER_EMAIL'), Cypress.env('USER_PASSWORD'));

  cy.getCookie('session').then((cookie) => {
    expect(cookie).to.exist;
    expect(cookie?.httpOnly).to.eq(true);
    expect(cookie?.secure).to.eq(true);
    expect(cookie?.sameSite).to.match(/strict|lax/i);
  });
});
```

## Pattern 5: Route Protection

```typescript
it('redirects unauthenticated user to login', () => {
  cy.clearCookies();
  cy.clearLocalStorage();
  cy.visit('/admin', { failOnStatusCode: false });
  cy.url().should('include', '/login');
});
```

## Pattern 6: Sensitive Data Exposure

```typescript
it('does not leak secrets in URL', () => {
  cy.visit('/dashboard');
  cy.url().should('not.include', 'password');
  cy.url().should('not.include', 'token=');
  cy.url().should('not.include', 'secret=');
});
```

## Pattern 7: HTTP to HTTPS Redirect (Non-local envs)

```typescript
it('redirects http traffic to https', () => {
  cy.request({
    url: 'http://your-app.com',
    followRedirect: false,
    failOnStatusCode: false,
  }).then((res) => {
    expect([301, 302, 307, 308]).to.include(res.status);
    expect(res.redirectedToUrl || res.headers.location).to.match(/^https:\/\//);
  });
});
```

## Anti-Patterns

| Anti-pattern | Why it fails | Better approach |
|---|---|---|
| Testing only happy auth path | Misses bypass regressions | Add unauthorized and expired-session checks |
| Asserting headers via `cy.visit` return value | `cy.visit` does not return response headers | Use `cy.request` |
| Ignoring cookie flags in lower envs | Drift reaches production | Enforce baseline in CI |
| Using only UI checks for CSRF | Hard to isolate backend control | Add direct `cy.request` negative checks |

## Troubleshooting

### Header assertion fails only in local env

- Local proxy may not inject production headers.
- Keep separate local vs CI expectation profile.

### Cookie flag not present in dev

- `secure` cookies require HTTPS.
- Validate this in HTTPS-enabled test env, not plain `http://localhost`.

### XSS test flaky

- Ensure payload is actually rendered in a user-visible field.
- Clear prior state before injection.

## Related Guides

- [api-testing.md](api-testing.md)
- [authentication.md](authentication.md)
- [network-mocking.md](network-mocking.md)
