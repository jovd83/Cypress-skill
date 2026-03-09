# Storage and Authentication

> **When to use**: Manage cookies, localStorage, sessionStorage, persisted auth state, and repeatable login patterns for Cypress v13+.
> **Prerequisites**: [core-commands.md](core-commands.md), [running-custom-code.md](running-custom-code.md)

## Quick Reference

```bash
# Save or restore browser state with CLI helpers
cypress-cli state-save auth.json
cypress-cli state-load auth.json

# Cookies
cypress-cli cookie-list
cypress-cli cookie-set session_id abc123 --domain=example.com --httpOnly --secure
cypress-cli cookie-get session_id
cypress-cli cookie-delete session_id
cypress-cli cookie-clear

# localStorage/sessionStorage
cypress-cli localstorage-set theme dark
cypress-cli localstorage-get theme
cypress-cli localstorage-clear
cypress-cli sessionstorage-set step 2
cypress-cli sessionstorage-get step
cypress-cli sessionstorage-clear
```

## Auth Pattern (CLI State Files)

### 1) Login Once and Save

```bash
cypress-cli open https://app.example.com/login
cypress-cli snapshot
cypress-cli fill e1 "admin@example.com"
cypress-cli fill e2 "secure-password"
cypress-cli click e3
cypress-cli run-code "() => { cy.url().should('include', '/dashboard'); }"
cypress-cli state-save ./states/admin-auth.json
cypress-cli close
```

### 2) Reuse in New Session

```bash
cypress-cli open https://app.example.com
cypress-cli state-load ./states/admin-auth.json
cypress-cli goto https://app.example.com/dashboard
cypress-cli snapshot
```

## Multi-Role State Files

```bash
# Admin
cypress-cli -s=admin open https://app.example.com/login
cypress-cli -s=admin fill e1 "admin@example.com"
cypress-cli -s=admin fill e2 "admin-pass"
cypress-cli -s=admin click e3
cypress-cli -s=admin state-save ./states/admin.json

# User
cypress-cli -s=user open https://app.example.com/login
cypress-cli -s=user fill e1 "user@example.com"
cypress-cli -s=user fill e2 "user-pass"
cypress-cli -s=user click e3
cypress-cli -s=user state-save ./states/user.json
```

## `cy.session()` in Test Suites

Use `cy.session()` in spec code to cache authenticated state between tests.

```typescript
// cypress/e2e/auth.cy.ts
beforeEach(() => {
  cy.session('admin', () => {
    cy.request('POST', '/api/login', {
      email: 'admin@example.com',
      password: 'secure-password'
    }).its('status').should('eq', 200);
  });

  cy.visit('/dashboard');
});
```

```javascript
// cypress/e2e/auth.cy.js
beforeEach(() => {
  cy.session('admin', () => {
    cy.request('POST', '/api/login', {
      email: 'admin@example.com',
      password: 'secure-password'
    }).its('status').should('eq', 200);
  });

  cy.visit('/dashboard');
});
```

## OAuth / SSO Guidance (Cypress-Compatible)

Cypress should not automate a third-party provider popup/tab directly. Preferred patterns:

1. Use a programmatic login endpoint in test environments.
2. Stub the app callback exchange with `cy.intercept()`.
3. Reuse saved state (`cy.session` or CLI `state-save/state-load`).

```bash
# Example callback stubbing pattern
cypress-cli run-code "() => {
  cy.intercept('POST', '**/api/auth/callback', {
    statusCode: 200,
    body: { token: 'test-token', user: { role: 'admin' } }
  }).as('authCallback');

  cy.visit('https://app.example.com/login');
  cy.findByRole('button', { name: /continue with sso/i }).click();
  cy.wait('@authCallback');
  cy.url().should('include', '/dashboard');
}"
```

## Cookies

### Basic Cookie Operations

```bash
cypress-cli cookie-list
cypress-cli cookie-get session_id
cypress-cli cookie-set session abc123 --domain=example.com --path=/ --httpOnly --secure --sameSite=Lax
cypress-cli cookie-delete session
cypress-cli cookie-clear
```

### Programmatic Cookie Operations

```bash
cypress-cli run-code "() => {
  cy.setCookie('session_id', 'sess_abc123', {
    domain: 'example.com',
    secure: true,
    httpOnly: true,
    sameSite: 'strict'
  });

  cy.getCookies().then((cookies) => {
    console.log(cookies.map((c) => ({ name: c.name, domain: c.domain })));
  });
}"
```

## Local Storage and Session Storage

### Bulk Write / Read

```bash
cypress-cli run-code "() => {
  cy.window().then((win) => {
    win.localStorage.setItem('theme', 'dark');
    win.localStorage.setItem('feature_flags', JSON.stringify({ newCheckout: true }));
    win.sessionStorage.setItem('wizard_step', '2');
  });
}"

cypress-cli run-code "() => {
  cy.window().then((win) => {
    const local = Object.fromEntries(Object.entries(win.localStorage));
    const session = Object.fromEntries(Object.entries(win.sessionStorage));
    console.log({ local, session });
  });
}"
```

## IndexedDB (Advanced)

```bash
# List DB names
cypress-cli run-code "() => {
  cy.window().then(async (win) => {
    const dbs = await win.indexedDB.databases();
    console.log(dbs);
  });
}"

# Delete a DB
cypress-cli run-code "() => {
  cy.window().then((win) => {
    win.indexedDB.deleteDatabase('myDatabase');
  });
}"
```

## Common Test Patterns

### Token Refresh Validation

```bash
cypress-cli localstorage-set auth_token expired-token
cypress-cli goto https://app.example.com/dashboard
cypress-cli run-code "() => {
  cy.window().then((win) => {
    const token = win.localStorage.getItem('auth_token');
    expect(token).to.not.equal('expired-token');
  });
}"
```

### Clean Start

```bash
cypress-cli cookie-clear
cypress-cli localstorage-clear
cypress-cli sessionstorage-clear
cypress-cli reload
```

## Anti-Patterns

| Anti-pattern | Problem | Better pattern |
|---|---|---|
| Committing `state-save` JSON files | Credential/token leakage | Ignore state files and rotate test credentials |
| Reusing one auth state across roles/jobs | Cross-test contamination | Generate role-specific state per run |
| Hardcoding secrets in scripts/docs | Security and portability risk | Load secrets from `CYPRESS_*` environment variables |
| Skipping cleanup on shared runners | Stale auth artifacts affect later runs | Clear storage/cookies and remove state directories |

## Security Notes

State files and artifact captures often contain sensitive data (cookies, JWTs, CSRF tokens, user identifiers).

### Treat State Artifacts as Secrets

- Never commit auth state files to source control.
- Prefer short-lived test accounts and rotate credentials.
- Prefer environment variables for secrets.
- Keep auth snapshots in dedicated temp directories (for example `./states/`), not mixed with source files.
- Delete stale state artifacts in CI and on shared machines.

### Recommended Ignore Patterns

```gitignore
# Auth/session snapshots
states/
**/*auth*.json
**/*state*.json

# Local evidence artifacts
artifacts/
recordings/
```

### CI Cleanup Examples

```bash
rm -rf ./states ./artifacts ./recordings
```

```powershell
Remove-Item -Recurse -Force ./states, ./artifacts, ./recordings -ErrorAction SilentlyContinue
```
