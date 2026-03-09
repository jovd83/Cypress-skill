# Locators

> **When to use**: Every time you need to find an element in Cypress.
> **Prerequisites**: [core/configuration.md](configuration.md)

## Quick Reference

```typescript
// Priority order - use the first stable option that exists in your app:
cy.findByRole('button', { name: /submit/i })            // 1. Role + accessible name
cy.findByLabelText(/email/i)                            // 2. Label (form fields)
cy.findByText('Welcome back')                           // 3. Text (non-interactive)
cy.findByPlaceholderText('Search...')                   // 4. Placeholder
cy.findByAltText('Company logo')                        // 5. Alt text
cy.findByTitle('Close dialog')                          // 6. Title
cy.get('[data-testid="checkout-summary"]')             // 7. Test ID
cy.get('.legacy-widget .btn-submit')                    // 8. CSS (last resort)
```

## Patterns

### Role-Based Locators (Default Choice)

**Use when**: Always. This should be your default.
**Avoid when**: The element has no semantic role and cannot be improved.

Role-based locators reflect what users and assistive tech perceive. In Cypress, use `@testing-library/cypress` commands such as `findByRole`.

**TypeScript**
```typescript
// cypress/support/e2e.ts
import '@testing-library/cypress/add-commands';
```

```typescript
// cypress/e2e/locators.cy.ts
describe('role-based locators', () => {
  it('covers common UI interactions', () => {
    cy.visit('/dashboard');

    cy.findByRole('button', { name: 'Save changes' }).click();
    cy.findByRole('link', { name: 'View profile' }).click();

    cy.findByRole('heading', { name: 'Dashboard', level: 1 }).should('be.visible');

    cy.findByRole('textbox', { name: 'Email' }).type('user@example.com');
    cy.findByRole('checkbox', { name: 'Remember me' }).check();
    cy.findByRole('radio', { name: 'Monthly billing' }).check();

    cy.findByRole('combobox', { name: 'Country' }).select('US');

    cy.findByRole('navigation', { name: 'Main' }).within(() => {
      cy.findByRole('link', { name: 'Settings' }).should('be.visible');
    });

    cy.findByRole('dialog', { name: 'Confirm deletion' }).within(() => {
      cy.findByRole('button', { name: 'Delete' }).click();
    });
  });
});
```

**JavaScript**
```javascript
// cypress/support/e2e.js
import '@testing-library/cypress/add-commands';
```

```javascript
describe('role-based locators', () => {
  it('covers common UI interactions', () => {
    cy.visit('/dashboard');

    cy.findByRole('button', { name: 'Save changes' }).click();
    cy.findByRole('link', { name: 'View profile' }).click();
    cy.findByRole('heading', { name: 'Dashboard', level: 1 }).should('be.visible');
    cy.findByRole('textbox', { name: 'Email' }).type('user@example.com');
    cy.findByRole('checkbox', { name: 'Remember me' }).check();
    cy.findByRole('radio', { name: 'Monthly billing' }).check();
    cy.findByRole('combobox', { name: 'Country' }).select('US');
  });
});
```

### Label-Based Locators

**Use when**: Targeting form controls with associated labels.
**Avoid when**: The control is interactive but role-based targeting is clearer.

**TypeScript**
```typescript
describe('label-based locators', () => {
  it('fills a registration form', () => {
    cy.visit('/register');

    cy.findByLabelText('First name').type('Jane');
    cy.findByLabelText('Last name').type('Doe');
    cy.findByLabelText('Email address').type('jane@example.com');
    cy.findByLabelText('Password').type('s3cure!Pass');
    cy.findByLabelText('Confirm password').type('s3cure!Pass');
    cy.findByLabelText('I agree to the terms').check();

    cy.findByRole('button', { name: 'Create account' }).click();
    cy.findByRole('heading', { name: 'Welcome' }).should('be.visible');
  });
});
```

**JavaScript**
```javascript
describe('label-based locators', () => {
  it('fills a registration form', () => {
    cy.visit('/register');

    cy.findByLabelText('First name').type('Jane');
    cy.findByLabelText('Last name').type('Doe');
    cy.findByLabelText('Email address').type('jane@example.com');
    cy.findByLabelText('Password').type('s3cure!Pass');
    cy.findByLabelText('Confirm password').type('s3cure!Pass');
    cy.findByLabelText('I agree to the terms').check();

    cy.findByRole('button', { name: 'Create account' }).click();
  });
});
```

### Text-Based Locators

**Use when**: Asserting non-interactive copy, banners, helper text, and status messages.
**Avoid when**: The target is a button, link, input, or other actionable control.

**TypeScript**
```typescript
describe('text-based locators', () => {
  it('verifies confirmation text', () => {
    cy.visit('/order/confirmation');

    cy.findByText('Order confirmed').should('be.visible');
    cy.findByText(/Order #\d+/).should('be.visible');

    // Prefer role for interactive elements:
    cy.findByRole('button', { name: 'Submit' }).should('be.visible');
  });
});
```

**JavaScript**
```javascript
describe('text-based locators', () => {
  it('verifies confirmation text', () => {
    cy.visit('/order/confirmation');

    cy.findByText('Order confirmed').should('be.visible');
    cy.findByText(/Order #\d+/).should('be.visible');
  });
});
```

### Test ID Locators

**Use when**: Semantic locators are not possible or not stable enough.
**Avoid when**: A role/label/text locator already identifies the element.

Prefer `data-cy` or `data-testid` consistently across the codebase.

**TypeScript**
```typescript
describe('test id locators', () => {
  it('interacts with a custom widget', () => {
    cy.visit('/analytics');

    cy.get('[data-testid="revenue-chart"]').should('be.visible').click(150, 75);
    cy.get('[data-testid="chart-tooltip"]').should('contain.text', '$12,400');
  });
});
```

**JavaScript**
```javascript
describe('test id locators', () => {
  it('interacts with a custom widget', () => {
    cy.visit('/analytics');

    cy.get('[data-testid="revenue-chart"]').should('be.visible').click(150, 75);
    cy.get('[data-testid="chart-tooltip"]').should('contain.text', '$12,400');
  });
});
```

### CSS/XPath - Last Resort

**Use when**: Legacy markup gives no reliable semantic path.
**Avoid when**: Any semantic locator or test id can be used.

**TypeScript**
```typescript
describe('legacy locator fallbacks', () => {
  it('uses constrained CSS selectors', () => {
    cy.visit('/legacy-admin');

    cy.get('table.report-grid td').contains('Overdue').first().click();
    cy.get('.sidebar').find('button').contains('Expand').click();
  });
});
```

**JavaScript**
```javascript
describe('legacy locator fallbacks', () => {
  it('uses constrained CSS selectors', () => {
    cy.visit('/legacy-admin');

    cy.get('table.report-grid td').contains('Overdue').first().click();
    cy.get('.sidebar').find('button').contains('Expand').click();
  });
});
```

### Chaining and Scoping

**Use when**: The same label or control appears in multiple regions.
**Avoid when**: One direct locator is already unique.

**TypeScript**
```typescript
describe('scoped locator patterns', () => {
  it('scopes interactions to container context', () => {
    cy.visit('/products');

    cy.findByRole('list', { name: 'Products' }).within(() => {
      cy.findByRole('listitem', { name: /Running Shoes/i }).within(() => {
        cy.findByRole('button', { name: 'Add to cart' }).click();
      });
    });

    cy.findAllByRole('row').filter(':contains("Premium Plan")').within(() => {
      cy.findByRole('button', { name: 'Upgrade' }).click();
    });

    cy.get('[data-testid="result-item"]').eq(2).should('be.visible');
  });
});
```

**JavaScript**
```javascript
describe('scoped locator patterns', () => {
  it('scopes interactions to container context', () => {
    cy.visit('/products');

    cy.findByRole('list', { name: 'Products' }).within(() => {
      cy.findByRole('listitem', { name: /Running Shoes/i }).within(() => {
        cy.findByRole('button', { name: 'Add to cart' }).click();
      });
    });
  });
});
```

### iframes

**Use when**: Interacting with third-party widgets inside `<iframe>`.
**Avoid when**: Content is in the main DOM.

**TypeScript**
```typescript
describe('iframe interactions', () => {
  it('fills payment details in iframe', () => {
    cy.visit('/checkout');

    cy.get('iframe[title="Payment"]')
      .its('0.contentDocument.body')
      .should('not.be.empty')
      .then(cy.wrap)
      .within(() => {
        cy.findByLabelText('Card number').type('4242424242424242');
        cy.findByLabelText('Expiration').type('12/28');
        cy.findByLabelText('CVC').type('123');
        cy.findByRole('button', { name: 'Pay' }).click();
      });
  });
});
```

**JavaScript**
```javascript
describe('iframe interactions', () => {
  it('fills payment details in iframe', () => {
    cy.visit('/checkout');

    cy.get('iframe[title="Payment"]')
      .its('0.contentDocument.body')
      .should('not.be.empty')
      .then(cy.wrap)
      .within(() => {
        cy.findByLabelText('Card number').type('4242424242424242');
        cy.findByLabelText('Expiration').type('12/28');
        cy.findByLabelText('CVC').type('123');
        cy.findByRole('button', { name: 'Pay' }).click();
      });
  });
});
```

### Shadow DOM

**Use when**: Targeting elements rendered in open shadow roots.
**Avoid when**: The target is in normal DOM.

**TypeScript**
```typescript
describe('shadow dom locators', () => {
  it('interacts through shadow roots', () => {
    cy.visit('/design-system-demo');

    cy.get('my-menu').shadow().find('button[aria-label="Toggle menu"]').click();
    cy.get('my-dropdown').shadow().contains('[role="option"]', 'Settings').click();
  });
});
```

**JavaScript**
```javascript
describe('shadow dom locators', () => {
  it('interacts through shadow roots', () => {
    cy.visit('/design-system-demo');

    cy.get('my-menu').shadow().find('button[aria-label="Toggle menu"]').click();
    cy.get('my-dropdown').shadow().contains('[role="option"]', 'Settings').click();
  });
});
```

### Dynamic Content and Waiting

**Use when**: Content appears after API requests, route transitions, or background processing.
**Avoid when**: The target is immediately available.

Never use blind sleeps for synchronization. Prefer aliases and retryable assertions.

**TypeScript**
```typescript
describe('dynamic content waits', () => {
  it('waits on network aliases and deterministic UI state', () => {
    cy.intercept('GET', '**/api/search*').as('search');
    cy.intercept('GET', '**/api/search*page=2*').as('searchPage2');

    cy.visit('/search');
    cy.findByRole('textbox', { name: 'Search' }).type('cypress');
    cy.findByRole('button', { name: 'Search' }).click();

    cy.wait('@search');
    cy.findAllByRole('listitem').should('have.length', 10);

    cy.findByRole('button', { name: 'Load more' }).click();
    cy.wait('@searchPage2');
    cy.findAllByRole('listitem').should('have.length', 20);

    cy.findByRole('link', { name: 'First result' }).click();
    cy.location('pathname').should('match', /\/results\//);
    cy.findByRole('heading', { level: 1 }).should('be.visible');
  });
});
```

**JavaScript**
```javascript
describe('dynamic content waits', () => {
  it('waits on network aliases and deterministic UI state', () => {
    cy.intercept('GET', '**/api/search*').as('search');

    cy.visit('/search');
    cy.findByRole('textbox', { name: 'Search' }).type('cypress');
    cy.findByRole('button', { name: 'Search' }).click();

    cy.wait('@search');
    cy.findAllByRole('listitem').should('have.length', 10);
  });
});
```

## Decision Guide

| Element Type | Recommended Locator | Example | Why |
|---|---|---|---|
| Button | `findByRole('button', { name })` | `cy.findByRole('button', { name: 'Submit' })` | Semantic and resilient |
| Link | `findByRole('link', { name })` | `cy.findByRole('link', { name: 'Home' })` | Targets user-facing intent |
| Text input | `findByRole('textbox', { name })` | `cy.findByRole('textbox', { name: 'Email' })` | Tied to accessible name |
| Password input | `findByLabelText()` | `cy.findByLabelText('Password')` | Password role matching is limited |
| Checkbox | `findByRole('checkbox', { name })` | `cy.findByRole('checkbox', { name: 'Agree' })` | Clear intent |
| Select | `findByRole('combobox', { name })` | `cy.findByRole('combobox', { name: 'Country' })` | Works for native selects |
| Dialog | `findByRole('dialog', { name })` | `cy.findByRole('dialog', { name: 'Confirm' })` | Good scoping root |
| Static text | `findByText()` | `cy.findByText('No results found')` | For non-interactive content |
| No semantic support | `cy.get('[data-testid=...]')` | `cy.get('[data-testid="sparkline-chart"]')` | Stable fallback |
| iframe content | `its('0.contentDocument.body').then(cy.wrap)` | See iframe section above | Required to enter frame DOM |
| Shadow DOM | `.shadow()` with `find/contains` | `cy.get('x-el').shadow().find('button')` | Explicit shadow traversal |

## Anti-Patterns

| Don't Do This | Problem | Do This Instead |
|---|---|---|
| `cy.get('.btn-primary')` everywhere | Breaks when styling classes change | `cy.findByRole('button', { name: 'Save' })` |
| `cy.contains('Submit').click()` without scope | May hit wrong element | Scope with role/container first |
| `cy.get('.item').eq(0)` on dynamic lists | Index shifts under real data | Filter by semantic text or test id |
| `cy.wait(3000)` | Arbitrary delay and flakiness | `cy.wait('@alias')` or retryable `should(...)` |
| `cy.get('button').click({ force: true })` by default | Masks real UX/actionability issues | Fix visibility/overlap root cause first |
| XPath-first strategy | Hard to read and maintain | Semantic queries or stable data attributes |
| Multiple deep `.find()` chains with style selectors | Coupled to implementation details | Anchor on role/label/test id |
| Assertions on translated hardcoded copy only | Breaks in i18n | Use role + name regex or test ids where needed |

## Troubleshooting

### "Timed out retrying after Xms: Expected to find element"

**Cause**: Locator mismatch, wrong app state, or async content not synchronized.

**Fix**:
- Confirm the element exists in the expected state before assertion.
- Use `cy.intercept(...).as('name')` + `cy.wait('@name')` for network-driven UI.
- Reduce locator ambiguity by scoping with `.within(...)`.

### Multiple elements matched by `contains()`

**Cause**: Text appears in many places.

**Fix**:
- Use `findByRole(..., { name })` where possible.
- Scope to a container first, then `contains`.
- Use exact text or regex boundaries when needed.

### Element exists but click fails due to coverage/actionability

**Cause**: Overlay, animation, sticky header, or disabled state.

**Fix**:
- Assert state before interaction: `.should('be.visible').and('not.be.disabled')`.
- Wait for overlays/spinners to disappear.
- Only use `{ force: true }` with a documented reason.

## Related

- [core/locator-strategy.md](locator-strategy.md) - project-level locator strategy decisions
- [core/assertions-and-waiting.md](assertions-and-waiting.md) - pair selectors with retryable assertions
- [pom/page-object-model.md](../pom/page-object-model.md) - encapsulate locators in page objects
- [core/iframes-and-shadow-dom.md](iframes-and-shadow-dom.md) - advanced iframe and shadow patterns
- [core/i18n-and-localization.md](i18n-and-localization.md) - selector strategy in multi-locale apps









