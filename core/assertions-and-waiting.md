# Assertions and Waiting

> **When to use**: Every time you assert UI state, synchronize asynchronous work, or debug flaky timing.
> **Prerequisites**: [core/locators.md](locators.md)

## Quick Reference

```typescript
// Retryable DOM assertions (default)
cy.findByRole('button', { name: 'Submit' }).should('be.visible');
cy.findByRole('heading').should('have.text', 'Dashboard');
cy.findAllByRole('listitem').should('have.length', 5);

// Negative assertions (also retry)
cy.findByRole('dialog').should('not.exist');
cy.findByRole('alert').should('not.be.visible');

// Network synchronization
cy.intercept('GET', '**/api/users').as('getUsers');
cy.wait('@getUsers').its('response.statusCode').should('eq', 200);

// URL / navigation
cy.location('pathname').should('eq', '/dashboard');
```

## Patterns

### Retryable DOM Assertions (Default)

**Use when**: Asserting visibility, text, attributes, classes, counts, and values in the UI.
**Avoid when**: The value is already resolved in plain JavaScript.

Cypress automatically retries `cy.get(...).should(...)` chains until timeout. This is the core reliability model.

**TypeScript**
```typescript
describe('retryable assertions', () => {
  it('asserts dynamic UI state safely', () => {
    cy.visit('/products');

    cy.findByRole('heading', { name: 'Products' }).should('be.visible');

    cy.get('[data-testid="total"]')
      .should('be.visible')
      .and('contain.text', '$99');

    cy.findAllByRole('listitem').should('have.length', 5);
    cy.findByRole('link', { name: 'Docs' }).should('have.attr', 'href', '/docs');
    cy.get('[data-testid="alert"]').should('have.css', 'background-color', 'rgb(255, 0, 0)');
    cy.findByLabelText('Email').should('have.value', 'user@example.com');
    cy.get('[data-testid="card"]').should('have.class', 'active');
    cy.findByRole('button', { name: 'Submit' }).should('be.enabled');
    cy.findByRole('checkbox').should('be.checked');
  });
});
```

**JavaScript**
```javascript
describe('retryable assertions', () => {
  it('asserts dynamic UI state safely', () => {
    cy.visit('/products');

    cy.findByRole('heading', { name: 'Products' }).should('be.visible');
    cy.get('[data-testid="total"]').should('contain.text', '$99');
    cy.findAllByRole('listitem').should('have.length', 5);
    cy.findByRole('link', { name: 'Docs' }).should('have.attr', 'href', '/docs');
    cy.findByLabelText('Email').should('have.value', 'user@example.com');
  });
});
```

### Non-Retrying Assertions

**Use when**: Working with resolved data (plain objects, response payloads, computed values).
**Avoid when**: Validating DOM that can still change asynchronously.

Use `.then(...)` and regular `expect(...)` for already-resolved values.

**TypeScript**
```typescript
describe('non-retrying assertions', () => {
  it('asserts resolved values', () => {
    cy.request('/api/users').then((response) => {
      expect(response.status).to.eq(200);
      expect(response.body.users).to.have.length(3);
      expect(response.body).to.deep.include({ status: 'healthy' });
    });

    cy.location('pathname').then((path) => {
      expect(path).to.match(/\/api\/health/);
    });
  });
});
```

**JavaScript**
```javascript
describe('non-retrying assertions', () => {
  it('asserts resolved values', () => {
    cy.request('/api/users').then((response) => {
      expect(response.status).to.eq(200);
      expect(response.body.users).to.have.length(3);
    });
  });
});
```

### Negative Assertions

**Use when**: Verifying an element disappears, is removed, or stays hidden.
**Avoid when**: Never.

`.should('not.exist')` confirms removal from DOM. `.should('not.be.visible')` confirms hidden state.

**TypeScript**
```typescript
describe('negative assertions', () => {
  it('verifies dismiss behavior', () => {
    cy.visit('/notifications');

    cy.findByRole('button', { name: 'Dismiss' }).click();

    cy.findByRole('alert').should('not.exist');
    cy.findByText(/error occurred/i).should('not.exist');
    cy.get('[data-testid="modal"]').should('not.exist');
  });
});
```

**JavaScript**
```javascript
describe('negative assertions', () => {
  it('verifies dismiss behavior', () => {
    cy.visit('/notifications');

    cy.findByRole('button', { name: 'Dismiss' }).click();
    cy.findByRole('alert').should('not.exist');
  });
});
```

### Grouped Assertions Without Soft-Assert Leakage

**Use when**: You need multiple checks on one page state.
**Avoid when**: Later checks depend on earlier checks succeeding.

Cypress has no first-party soft assertion mode. Keep checks grouped with clear `should` chains or use a dedicated plugin only when needed.

**TypeScript**
```typescript
describe('grouped assertions', () => {
  it('checks dashboard widgets', () => {
    cy.visit('/dashboard');

    cy.get('[data-testid="revenue-widget"]')
      .should('be.visible')
      .and('contain.text', '$');

    cy.get('[data-testid="users-widget"]')
      .should('be.visible')
      .and('contain.text', 'active');

    cy.get('[data-testid="orders-widget"]').should('be.visible');
  });
});
```

**JavaScript**
```javascript
describe('grouped assertions', () => {
  it('checks dashboard widgets', () => {
    cy.visit('/dashboard');

    cy.get('[data-testid="revenue-widget"]').should('be.visible').and('contain.text', '$');
    cy.get('[data-testid="users-widget"]').should('be.visible').and('contain.text', 'active');
    cy.get('[data-testid="orders-widget"]').should('be.visible');
  });
});
```

### Polling Non-DOM Conditions

**Use when**: Waiting for backend job completion, queue status, or async side effects not directly represented in DOM.
**Avoid when**: A UI assertion or network alias already covers the condition.

Cypress retries command chains, not arbitrary loops. Use deterministic polling via recursion or `cypress-recurse`.

**TypeScript**
```typescript
function waitForJobCompletion(jobId: string, attempts = 10): Cypress.Chainable<void> {
  return cy.request(`/api/jobs/${jobId}`).then((response) => {
    if (response.body.status === 'completed') return;
    expect(attempts, 'remaining polling attempts').to.be.greaterThan(0);
    return cy.wait(1000).then(() => waitForJobCompletion(jobId, attempts - 1));
  });
}

describe('polling backend status', () => {
  it('waits for export job completion', () => {
    cy.visit('/jobs');
    cy.findByRole('button', { name: 'Start Export' }).click();

    cy.get('[data-testid="job-id"]').invoke('text').then((jobId) => {
      waitForJobCompletion(jobId.trim());
    });
  });
});
```

**JavaScript**
```javascript
function waitForJobCompletion(jobId, attempts = 10) {
  return cy.request(`/api/jobs/${jobId}`).then((response) => {
    if (response.body.status === 'completed') return;
    expect(attempts, 'remaining polling attempts').to.be.greaterThan(0);
    return cy.wait(1000).then(() => waitForJobCompletion(jobId, attempts - 1));
  });
}
```

### Custom Assertions and Commands

**Use when**: Repeating domain-specific checks across many tests.
**Avoid when**: The check is only used once.

**TypeScript**
```typescript
// cypress/support/commands.ts
declare global {
  namespace Cypress {
    interface Chainable {
      shouldHaveValidPrice(): Chainable<JQuery<HTMLElement>>;
    }
  }
}

Cypress.Commands.add('shouldHaveValidPrice', { prevSubject: true }, (subject) => {
  cy.wrap(subject).invoke('text').then((text) => {
    expect(text.trim()).to.match(/^\$\d{1,3}(,\d{3})*\.\d{2}$/);
  });
});
```

```typescript
// cypress/e2e/products.cy.ts
describe('custom assertion command', () => {
  it('validates price format', () => {
    cy.visit('/products');
    cy.get('[data-testid="price-tag"]').first().shouldHaveValidPrice();
  });
});
```

**JavaScript**
```javascript
Cypress.Commands.add('shouldHaveValidPrice', { prevSubject: true }, (subject) => {
  cy.wrap(subject).invoke('text').then((text) => {
    expect(text.trim()).to.match(/^\$\d{1,3}(,\d{3})*\.\d{2}$/);
  });
});
```

### Auto-Waiting and Actionability

**Use when**: You do not need a separate wait before common actions.

Cypress waits for elements to exist, become actionable, and pass assertions before failing.

| Action | Built-in waiting behavior |
|---|---|
| `.click()` | Waits for existence, visibility, non-disabled state, non-covered position |
| `.type()` | Waits for actionable input |
| `.check()` / `.uncheck()` | Waits for actionable checkbox/radio |
| `.select()` | Waits for actionable select |

Avoid redundant assertions like `cy.get('button').should('be.visible').click()` unless visibility itself is the behavior under test.

### Explicit Waits

**Use when**: Waiting on network calls, navigation changes, or app-level async boundaries.
**Avoid when**: A direct UI assertion already expresses readiness.

**TypeScript**
```typescript
describe('explicit synchronization', () => {
  it('waits for API and URL transitions', () => {
    cy.intercept('POST', '**/api/login').as('login');
    cy.intercept('GET', '**/api/user').as('user');

    cy.visit('/login');
    cy.findByLabelText('Email').type('user@test.com');
    cy.findByLabelText('Password').type('password123');
    cy.findByRole('button', { name: 'Sign In' }).click();

    cy.wait('@login').its('response.statusCode').should('eq', 200);
    cy.wait('@user').its('response.statusCode').should('eq', 200);

    cy.location('pathname').should('eq', '/dashboard');
  });
});
```

**JavaScript**
```javascript
describe('explicit synchronization', () => {
  it('waits for API and URL transitions', () => {
    cy.intercept('POST', '**/api/login').as('login');

    cy.visit('/login');
    cy.findByRole('button', { name: 'Sign In' }).click();
    cy.wait('@login').its('response.statusCode').should('eq', 200);
    cy.location('pathname').should('eq', '/dashboard');
  });
});
```

**Critical pattern**: Register `cy.intercept()` before the action that triggers the request.

### Assertion Timeouts

**Use when**: A specific assertion legitimately needs longer than default timeout.

**TypeScript**
```typescript
describe('timeouts', () => {
  it('overrides timeout for one assertion', () => {
    cy.visit('/slow-dashboard');

    cy.get('[data-testid="heavy-chart"]', { timeout: 30_000 }).should('be.visible');
  });

  it('sets test-level timeout when needed', () => {
    cy.visit('/import');
    cy.findByRole('button', { name: 'Import CSV' }).click();
    cy.findByText('Import complete', { timeout: 60_000 }).should('be.visible');
  });
});
```

**JavaScript**
```javascript
describe('timeouts', () => {
  it('overrides timeout for one assertion', () => {
    cy.visit('/slow-dashboard');
    cy.get('[data-testid="heavy-chart"]', { timeout: 30000 }).should('be.visible');
  });
});
```

**Global timeout** in `cypress.config.ts`:
```typescript
import { defineConfig } from 'cypress';

export default defineConfig({
  e2e: {
    defaultCommandTimeout: 10_000,
    requestTimeout: 15_000,
    responseTimeout: 30_000,
  },
});
```

## Decision Guide

| Scenario | Recommended Approach | Why |
|---|---|---|
| Element visible / hidden | `.should('be.visible')` / `.should('not.be.visible')` | Retryable DOM check |
| Element removed from DOM | `.should('not.exist')` | Distinguishes hidden vs removed |
| Text content | `.should('have.text', x)` or `.should('contain.text', x)` | Deterministic and retryable |
| Element count | `.should('have.length', n)` | Retries until count matches |
| Input value | `.should('have.value', x)` | Retryable value check |
| Attribute | `.should('have.attr', 'href', '/x')` | Simple and readable |
| URL changed | `cy.location('pathname').should(...)` | Retryable navigation signal |
| API response status | `cy.wait('@alias').its('response.statusCode')` | Deterministic synchronization |
| Background polling | Controlled recursion or helper | Handles non-DOM async work |
| State-changing action success | Assert toast/message + side effect | Protects UX and behavior |

## Patterns

### Action Confirmation (Toasts and Success Messages)

**Use when**: Verifying destructive or state-changing operations.
**Avoid when**: Read-only navigation where no mutation occurs.

**TypeScript**
```typescript
describe('action confirmation', () => {
  it('asserts explicit user feedback after delete', () => {
    cy.visit('/items');

    cy.findByRole('button', { name: 'Delete' }).first().click();
    cy.findByRole('button', { name: 'Confirm' }).click();

    cy.findByText(/item deleted|successfully removed/i).should('be.visible');
    cy.get('[data-testid="item-row"]').should('have.length.lessThan', 5);
  });
});
```

**JavaScript**
```javascript
describe('action confirmation', () => {
  it('asserts explicit user feedback after delete', () => {
    cy.visit('/items');

    cy.findByRole('button', { name: 'Delete' }).first().click();
    cy.findByRole('button', { name: 'Confirm' }).click();

    cy.findByText(/item deleted|successfully removed/i).should('be.visible');
  });
});
```

## Anti-Patterns

| Don't Do This | Problem | Do This Instead |
|---|---|---|
| `cy.wait(2000)` | Arbitrary delay and flakiness | Alias waits or retryable assertions |
| `const visible = Cypress.$('#x').is(':visible')` | No retries, detached from command queue | `cy.get('#x').should('be.visible')` |
| `cy.get(btn).click({ force: true })` by default | Masks UI/actionability defects | Fix overlap/disabled root cause first |
| Assert text via immediate DOM snapshot logic | Races against async rendering | Use retryable `.should(...)` |
| Huge global timeouts to hide flakiness | Slow failures and hidden defects | Use focused waits and root-cause fixes |
| Mixing Cypress commands with uncontrolled async/await | Breaks command queue guarantees | Keep Cypress chain model intact |

## Troubleshooting

### "Timed out retrying after 4000ms"

**Cause**: Wrong locator, stale assumptions about app state, or async event not synchronized.

**Fix**:
- Confirm selector uniqueness in the rendered DOM.
- Add deterministic waits on network aliases.
- Scope queries with `.within(...)` to reduce ambiguity.

### Assertion passes locally but fails in CI

**Cause**: Slower environment exposes hidden race conditions.

**Fix**:
- Replace arbitrary waits with `cy.intercept` aliases.
- Ensure app state is isolated per test.
- Enable retries in CI only and inspect screenshots/videos.

### Command queue confusion with async/await

**Cause**: Treating Cypress commands like immediate Promises.

**Fix**:
- Keep Cypress chain flow (`cy.get(...).should(...)`).
- Use `.then(...)` when extracting resolved values.
- Do not wrap Cypress chains in unmanaged async loops.

## Related

- [core/locators.md](locators.md) - selector strategy for stable assertions
- [core/fixtures-and-hooks.md](fixtures-and-hooks.md) - reusable setup for assertion-heavy suites
- [core/debugging.md](debugging.md) - debug failing assertions using Cypress runner artifacts
- [core/flaky-tests.md](flaky-tests.md) - timing and retry stabilization
- [core/error-index.md](error-index.md) - common failure signatures and fixes









