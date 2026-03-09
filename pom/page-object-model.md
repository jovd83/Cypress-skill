# Page Object Model (POM)

> **When to use**: Encapsulate repeated UI interactions while keeping assertions in tests. Useful for large suites with stable page contracts.
> **Prerequisites**: [pom-vs-fixtures-vs-helpers.md](pom-vs-fixtures-vs-helpers.md), [../core/locators.md](../core/locators.md), [../core/assertions-and-waiting.md](../core/assertions-and-waiting.md)

## Cypress-Oriented POM Rules

1. Keep selectors and actions in page objects.
2. Keep assertions in test specs.
3. Return Cypress chains from methods when composition helps.
4. Do not hide critical waits; expose explicit action methods and use intercepts in tests.
5. Prefer custom commands/helpers for tiny shared flows; use POM for full page workflows.

## Suggested Structure

```text
cypress/
  e2e/
    auth/
      login.cy.ts
  support/
    pages/
      login.page.ts
      dashboard.page.ts
```

## TypeScript Example

### `cypress/support/pages/login.page.ts`

```typescript
export class LoginPage {
  visit() {
    cy.visit('/login');
  }

  emailInput() {
    return cy.findByLabelText('Email');
  }

  passwordInput() {
    return cy.findByLabelText('Password');
  }

  signInButton() {
    return cy.findByRole('button', { name: 'Sign In' });
  }

  login(email: string, password: string) {
    this.emailInput().clear().type(email);
    this.passwordInput().clear().type(password);
    this.signInButton().click();
  }
}
```

### `cypress/support/pages/dashboard.page.ts`

```typescript
export class DashboardPage {
  heading() {
    return cy.findByRole('heading', { name: 'Dashboard' });
  }

  openSettings() {
    cy.findByRole('link', { name: 'Settings' }).click();
  }

  createProject(name: string) {
    cy.findByRole('button', { name: 'New Project' }).click();
    cy.findByLabelText('Project name').clear().type(name);
    cy.findByRole('button', { name: 'Create' }).click();
  }
}
```

### `cypress/e2e/auth/login.cy.ts`

```typescript
import { LoginPage } from '../../support/pages/login.page';
import { DashboardPage } from '../../support/pages/dashboard.page';

describe('login', () => {
  const loginPage = new LoginPage();
  const dashboardPage = new DashboardPage();

  it('logs in successfully', () => {
    cy.intercept('POST', '**/api/login').as('login');

    loginPage.visit();
    loginPage.login('admin@example.com', 'secure-password');

    cy.wait('@login').its('response.statusCode').should('eq', 200);
    dashboardPage.heading().should('be.visible');
  });
});
```

## JavaScript Example

### `cypress/support/pages/login.page.js`

```javascript
class LoginPage {
  visit() {
    cy.visit('/login');
  }

  emailInput() {
    return cy.findByLabelText('Email');
  }

  passwordInput() {
    return cy.findByLabelText('Password');
  }

  signInButton() {
    return cy.findByRole('button', { name: 'Sign In' });
  }

  login(email, password) {
    this.emailInput().clear().type(email);
    this.passwordInput().clear().type(password);
    this.signInButton().click();
  }
}

module.exports = { LoginPage };
```

### `cypress/e2e/auth/login.cy.js`

```javascript
const { LoginPage } = require('../../support/pages/login.page');

describe('login', () => {
  const loginPage = new LoginPage();

  it('logs in successfully', () => {
    cy.intercept('POST', '**/api/login').as('login');

    loginPage.visit();
    loginPage.login('admin@example.com', 'secure-password');

    cy.wait('@login').its('response.statusCode').should('eq', 200);
    cy.findByRole('heading', { name: 'Dashboard' }).should('be.visible');
  });
});
```

## POM vs Custom Commands vs Helpers

| Pattern | Best for | Avoid when |
|---|---|---|
| POM classes | Large, stable page workflows | Very small flows with 1-2 repeated actions |
| Custom commands | Common cross-page actions (`loginUI`, `seedCart`) | Page-specific logic that belongs near feature tests |
| Helper functions | Pure data/setup logic | UI interaction-heavy behavior |

## Anti-Patterns

- Putting assertions deep inside page object methods.
- Returning raw selectors from tests and bypassing the object contract.
- Creating one mega-page object for unrelated routes.
- Hiding network synchronization inside opaque methods.

## Related

- [pom/pom-vs-fixtures-vs-helpers.md](pom-vs-fixtures-vs-helpers.md)
- [core/fixtures-and-hooks.md](../core/fixtures-and-hooks.md)
- [core/locators.md](../core/locators.md)
