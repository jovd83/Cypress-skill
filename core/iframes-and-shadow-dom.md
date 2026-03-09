# Iframes and Shadow DOM

> **When to use**: When your app renders UI inside iframes or Web Components.
> **Prerequisites**: [locators.md](locators.md), [assertions-and-waiting.md](assertions-and-waiting.md)

## Quick Reference

```typescript
// Same-origin iframe
cy.get('iframe[data-testid="payment-frame"]')
  .its('0.contentDocument.body')
  .should('not.be.empty')
  .then(cy.wrap)
  .within(() => {
    cy.findByLabelText('Card number').type('4242424242424242');
    cy.findByRole('button', { name: /pay/i }).click();
  });

// Shadow DOM
cy.get('my-checkout-widget')
  .shadow()
  .find('[data-testid="submit-order"]')
  .click();
```

## Cypress Rules

1. Cypress can work with **same-origin** iframes.
2. Cypress cannot directly control DOM inside most **cross-origin** third-party iframes.
3. For Shadow DOM, use `.shadow()` and then standard Cypress commands.

## Pattern 1: Same-Origin Iframe Interaction

**Use when**: Your application owns the iframe content (same origin).
**Avoid when**: The iframe is cross-origin (Stripe, OAuth provider, ad network).

**TypeScript**
```typescript
it('submits card details inside same-origin iframe', () => {
  cy.visit('/checkout');

  cy.get('iframe[title="Payment"]')
    .its('0.contentDocument.body')
    .should('not.be.empty')
    .then(cy.wrap)
    .within(() => {
      cy.findByLabelText('Card number').type('4242424242424242');
      cy.findByLabelText('Expiry').type('12/30');
      cy.findByLabelText('CVC').type('123');
      cy.findByRole('button', { name: /pay/i }).click();
    });

  cy.findByRole('heading', { name: /order confirmed/i }).should('be.visible');
});
```

**JavaScript**
```javascript
it('submits card details inside same-origin iframe', () => {
  cy.visit('/checkout');

  cy.get('iframe[title="Payment"]')
    .its('0.contentDocument.body')
    .should('not.be.empty')
    .then(cy.wrap)
    .within(() => {
      cy.findByLabelText('Card number').type('4242424242424242');
      cy.findByLabelText('Expiry').type('12/30');
      cy.findByLabelText('CVC').type('123');
      cy.findByRole('button', { name: /pay/i }).click();
    });

  cy.findByRole('heading', { name: /order confirmed/i }).should('be.visible');
});
```

## Pattern 2: Helper Command for Iframes

Create a reusable custom command when iframe access repeats.

```typescript
// cypress/support/commands.ts
Cypress.Commands.add('withinIframe', (selector: string, callback) => {
  cy.get(selector)
    .its('0.contentDocument.body')
    .should('not.be.empty')
    .then(cy.wrap)
    .within(callback);
});
```

```typescript
// usage
cy.withinIframe('iframe[data-testid="editor-frame"]', () => {
  cy.findByRole('textbox', { name: /title/i }).type('Draft');
  cy.findByRole('button', { name: /save/i }).click();
});
```

## Pattern 3: Cross-Origin Iframes

**Use when**: Third-party providers render secure inputs or hosted widgets.

Do not attempt to access cross-origin iframe DOM. Instead:

1. Assert iframe shell renders (`src`, `title`, visible frame).
2. Assert backend/network side-effects from host app (`cy.intercept`).
3. Validate post-submit host UI state.

**TypeScript**
```typescript
it('verifies hosted payment integration without cross-origin DOM access', () => {
  cy.intercept('POST', '/api/payments/confirm').as('confirmPayment');

  cy.visit('/checkout');
  cy.get('iframe[src*="payments.example.com"]').should('be.visible');

  cy.findByRole('button', { name: /complete order/i }).click();
  cy.wait('@confirmPayment').its('response.statusCode').should('eq', 200);
  cy.findByText(/payment successful/i).should('be.visible');
});
```

## Pattern 4: Shadow DOM (Open Roots)

**TypeScript**
```typescript
it('interacts with controls inside open shadow root', () => {
  cy.visit('/settings');

  cy.get('theme-picker')
    .shadow()
    .find('button[aria-label="Dark"]')
    .click();

  cy.get('theme-picker')
    .shadow()
    .find('[data-testid="theme-value"]')
    .should('have.text', 'dark');
});
```

**JavaScript**
```javascript
it('interacts with controls inside open shadow root', () => {
  cy.visit('/settings');

  cy.get('theme-picker')
    .shadow()
    .find('button[aria-label="Dark"]')
    .click();

  cy.get('theme-picker')
    .shadow()
    .find('[data-testid="theme-value"]')
    .should('have.text', 'dark');
});
```

## Anti-Patterns

| Anti-pattern | Why it fails | Cypress alternative |
|---|---|---|
| Using external frame-locator APIs | Not a Cypress API | Use `contentDocument` + `cy.wrap(...).within(...)` |
| Accessing third-party cross-origin iframe DOM | Browser security boundary | Assert host page behavior and network outcomes |
| Using brittle iframe index selectors only | Breaks when layout changes | Prefer stable iframe attributes (`title`, `name`, `data-testid`) |
| Using `force: true` to click hidden controls in shadow DOM | Masks real UX issues | Wait for visible actionable element and assert state |

## Troubleshooting

### "Cannot read properties of null (reading 'body')"

- The iframe has not loaded yet.
- Add `should('not.be.empty')` before `cy.wrap`.

### "Timed out retrying inside iframe"

- Selector is wrong for the iframe document.
- Add a scoped debug check:

```typescript
cy.get('iframe[title="Payment"]')
  .its('0.contentDocument.body')
  .then((body) => {
    expect(body.innerHTML).to.include('Card number');
  });
```

### Shadow element not found

- Host element may have a closed shadow root.
- Closed roots are not directly automatable. Test public host behavior only.

## Related Guides

- [locators.md](locators.md)
- [network-mocking.md](network-mocking.md)
- [authentication.md](authentication.md)
- [multi-context-and-popups.md](multi-context-and-popups.md)
