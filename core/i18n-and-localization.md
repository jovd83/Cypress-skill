# i18n and Localization

> **When to use**: Validate language switching, locale formatting, timezone behavior, RTL layouts, translation fallback, and text expansion in Cypress.

## Golden Rules

1. Test at least one LTR locale and one RTL locale.
2. Validate user-visible formatting (dates, numbers, currency), not internal locale config only.
3. Keep visual checks deterministic by fixing data and viewport.
4. Separate locale routing tests from formatting tests.

## Quick Reference

```typescript
cy.visit('/?lang=de');
cy.findByRole('button', { name: /konto/i }).should('be.visible');

cy.window().then((win) => {
  const amount = new Intl.NumberFormat('de-DE', { style: 'currency', currency: 'EUR' }).format(1234.56);
  expect(amount).to.eq('1.234,56 €');
});
```

## Language Switcher Flow

```typescript
it('switches app language from EN to DE', () => {
  cy.visit('/');
  cy.findByRole('button', { name: /language/i }).click();
  cy.findByRole('option', { name: /deutsch/i }).click();

  cy.location('search').should('include', 'lang=de');
  cy.findByRole('heading', { name: /willkommen/i }).should('be.visible');
});
```

## Locale Formatting Validation

```typescript
it('formats currency/date for french locale', () => {
  cy.visit('/billing?lang=fr');

  cy.findByTestId('invoice-total').should('contain.text', '1 234,56');
  cy.findByTestId('invoice-date').should('match', /\d{2}\/\d{2}\/\d{4}/);
});
```

## Timezone-Sensitive Rendering

Use a test config/environment that sets timezone for the browser process where supported.

```typescript
it('shows local time in configured timezone', () => {
  cy.visit('/events/launch');
  cy.findByTestId('event-time').should('contain.text', '09:00');
});
```

## RTL Layout Checks

```typescript
it('renders rtl document direction for arabic', () => {
  cy.visit('/?lang=ar');

  cy.get('html').should('have.attr', 'dir', 'rtl');
  cy.findByRole('navigation').should('be.visible');
  cy.findByRole('button', { name: /تسجيل الدخول/i }).should('be.visible');
});
```

## Missing Translation Fallback

```typescript
it('does not expose raw translation keys', () => {
  cy.visit('/?lang=it');
  cy.get('body').invoke('text').should('not.match', /\b[a-z]+\.[a-z]+\.[a-z]+\b/i);
  cy.get('body').invoke('text').should('not.contain', '{{');
});
```

## Text Expansion and Overflow

```typescript
it('handles long german labels without overflow', () => {
  cy.visit('/settings?lang=de');

  cy.findByRole('button').each(($btn) => {
    const el = $btn[0];
    expect(el.scrollWidth <= el.clientWidth || getComputedStyle(el).textOverflow === 'ellipsis').to.eq(true);
  });
});
```

## Per-Locale Visual Capture

```typescript
const locales = ['en', 'de', 'ar'];

locales.forEach((lang) => {
  it(`captures homepage visual for ${lang}`, () => {
    cy.viewport(1280, 720);
    cy.visit(`/?lang=${lang}`);
    cy.screenshot(`homepage-${lang}`);
  });
});
```

## Routing and Canonical Locale URLs

```typescript
it('routes to localized product page', () => {
  cy.visit('/de/products/123');
  cy.location('pathname').should('eq', '/de/products/123');
  cy.findByRole('heading', { name: /produktdetails/i }).should('be.visible');
});
```

## Anti-Patterns

- Testing only English locale.
- Hardcoding translated strings for every assertion.
- Ignoring RTL and text expansion impacts.
- Updating visual baselines without verifying intended translation/layout changes.

## Related

- [core/visual-regression.md](visual-regression.md)
- [core/mobile-and-responsive.md](mobile-and-responsive.md)
- [core/error-and-edge-cases.md](error-and-edge-cases.md)
