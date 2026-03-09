# Mobile and Responsive Testing

> **When to use**: Validate layouts, interactions, and behavior across mobile/tablet/desktop breakpoints in Cypress.

## Golden Rules

1. Set viewport explicitly at test start.
2. Assert behavior, not only pixel layout.
3. Keep responsive tests deterministic (stable data + hidden dynamic widgets).
4. Run critical responsive checks across at least one mobile and one desktop profile.

## Quick Reference

```typescript
cy.viewport(390, 844); // iPhone-like
cy.visit('/');
cy.findByRole('button', { name: /menu/i }).should('be.visible');

cy.viewport(1440, 900); // desktop
cy.visit('/');
cy.findByRole('navigation').should('be.visible');
```

## Common Viewports

| Target | Width x Height |
|---|---|
| Small mobile | `320 x 568` |
| Standard mobile | `390 x 844` |
| Tablet portrait | `768 x 1024` |
| Tablet landscape | `1024 x 768` |
| Desktop | `1366 x 768` |
| Large desktop | `1440 x 900` |

## Responsive Navigation Example

### TypeScript

```typescript
it('shows hamburger menu on mobile and full nav on desktop', () => {
  cy.visit('/');

  cy.viewport(390, 844);
  cy.findByRole('button', { name: /menu/i }).should('be.visible');
  cy.findByRole('navigation').should('not.be.visible');

  cy.viewport(1440, 900);
  cy.findByRole('button', { name: /menu/i }).should('not.exist');
  cy.findByRole('navigation').should('be.visible');
});
```

### JavaScript

```javascript
it('shows hamburger menu on mobile and full nav on desktop', () => {
  cy.visit('/');

  cy.viewport(390, 844);
  cy.findByRole('button', { name: /menu/i }).should('be.visible');
  cy.findByRole('navigation').should('not.be.visible');

  cy.viewport(1440, 900);
  cy.findByRole('button', { name: /menu/i }).should('not.exist');
  cy.findByRole('navigation').should('be.visible');
});
```

## Mobile Form Usability

```typescript
it('submits checkout form on mobile', () => {
  cy.viewport(390, 844);
  cy.intercept('POST', '**/api/orders').as('createOrder');

  cy.visit('/checkout');
  cy.findByLabelText('Address').clear().type('123 Main St');
  cy.findByLabelText('City').clear().type('Brussels');
  cy.findByLabelText('ZIP code').clear().type('1000');
  cy.findByRole('button', { name: /place order/i }).click();

  cy.wait('@createOrder').its('response.statusCode').should('be.oneOf', [200, 201]);
});
```

## Responsive Table/Card Switch

```typescript
it('renders cards on mobile and table on desktop', () => {
  cy.visit('/orders');

  cy.viewport(390, 844);
  cy.findByTestId('orders-card-list').should('be.visible');
  cy.findByRole('table').should('not.exist');

  cy.viewport(1366, 768);
  cy.findByRole('table').should('be.visible');
  cy.findByTestId('orders-card-list').should('not.exist');
});
```

## Visual Capture Matrix

```typescript
const viewports = [
  { name: 'mobile', width: 390, height: 844 },
  { name: 'tablet', width: 768, height: 1024 },
  { name: 'desktop', width: 1366, height: 768 }
];

viewports.forEach((vp) => {
  it(`captures homepage (${vp.name})`, () => {
    cy.viewport(vp.width, vp.height);
    cy.visit('/');
    cy.screenshot(`home-${vp.name}`);
  });
});
```

## Touch and Gesture Notes

Cypress does not emulate every native touch behavior exactly. Test critical gesture logic with:

1. Browser-based event simulations (`trigger('touchstart')`, `trigger('touchmove')`, `trigger('touchend')`).
2. Real-device checks for a small smoke subset when gesture-heavy.

## Performance-Aware Mobile Checks

```typescript
it('shows loading skeleton before mobile feed render', () => {
  cy.viewport(390, 844);
  cy.intercept('GET', '**/api/feed', { delayMs: 1500, fixture: 'feed.json' }).as('feed');

  cy.visit('/feed');
  cy.findByTestId('feed-skeleton').should('be.visible');
  cy.wait('@feed');
  cy.findByTestId('feed-skeleton').should('not.exist');
});
```

## Anti-Patterns

- Asserting only viewport size without checking UI behavior.
- Using one viewport for all responsive claims.
- Sleeping to wait for CSS transitions.
- Ignoring keyboard accessibility while testing responsive nav.

## Related

- [core/visual-regression.md](visual-regression.md)
- [core/forms-and-validation.md](forms-and-validation.md)
- [core/flaky-tests.md](flaky-tests.md)
