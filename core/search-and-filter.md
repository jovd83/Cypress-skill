# Search and Filter Recipes

> **When to use**: Validate search boxes, filter panels, autocomplete, date ranges, pagination, URL query sync, and empty-state behavior.

## Golden Rules

1. Intercept and alias the search/filter API request.
2. Assert URL/query params if search state is URL-driven.
3. Validate both result content and result count.
4. Cover empty states and clear/reset actions.
5. Avoid sleep-based waits; use observable network/UI signals.

## Quick Reference

```typescript
cy.intercept('GET', '**/api/products*').as('getProducts');

cy.findByRole('searchbox', { name: /search/i }).clear().type('wireless keyboard{enter}');
cy.wait('@getProducts').its('response.statusCode').should('eq', 200);

cy.findAllByRole('row').should('have.length.greaterThan', 1);
cy.url().should('include', 'q=wireless+keyboard');
```

## Recipe 1: Search Input with Results

### TypeScript

```typescript
it('searches and shows matching products', () => {
  cy.intercept('GET', '**/api/products*').as('getProducts');

  cy.visit('/products');
  cy.findByRole('searchbox', { name: /search/i }).clear().type('wireless keyboard{enter}');

  cy.wait('@getProducts').then(({ request, response }) => {
    expect(request.query.q).to.eq('wireless keyboard');
    expect(response && response.statusCode).to.eq(200);
  });

  cy.findByText(/results?/i).should('be.visible');
  cy.findAllByRole('row').should('have.length.greaterThan', 1);
  cy.url().should('include', 'q=wireless+keyboard');
});
```

### JavaScript

```javascript
it('searches and shows matching products', () => {
  cy.intercept('GET', '**/api/products*').as('getProducts');

  cy.visit('/products');
  cy.findByRole('searchbox', { name: /search/i }).clear().type('wireless keyboard{enter}');

  cy.wait('@getProducts').then(({ request, response }) => {
    expect(request.query.q).to.eq('wireless keyboard');
    expect(response && response.statusCode).to.eq(200);
  });

  cy.findByText(/results?/i).should('be.visible');
  cy.findAllByRole('row').should('have.length.greaterThan', 1);
  cy.url().should('include', 'q=wireless+keyboard');
});
```

## Recipe 2: Debounced Autocomplete

```typescript
it('shows autocomplete suggestions after typing', () => {
  cy.intercept('GET', '**/api/suggestions*', { fixture: 'suggestions-keyboard.json' }).as('suggestions');

  cy.visit('/products');
  cy.findByRole('searchbox', { name: /search/i }).clear().type('keybo');

  cy.wait('@suggestions');
  cy.findByRole('listbox', { name: /suggestions/i }).should('be.visible');
  cy.findByRole('option', { name: /keyboard stand/i }).should('be.visible').click();

  cy.findByRole('searchbox', { name: /search/i }).should('have.value', 'keyboard stand');
});
```

## Recipe 3: Multi-Filter Panel

```typescript
it('applies category and price filters together', () => {
  cy.intercept('GET', '**/api/products*').as('getProducts');

  cy.visit('/products');

  cy.findByRole('button', { name: /filters/i }).click();
  cy.findByLabelText('Category: Accessories').check();
  cy.findByLabelText('Price: Under $50').check();
  cy.findByRole('button', { name: /apply filters/i }).click();

  cy.wait('@getProducts').then(({ request }) => {
    expect(request.query.category).to.include('accessories');
    expect(request.query.priceRange).to.eq('under-50');
  });

  cy.findByRole('button', { name: /clear filters/i }).should('be.visible');
  cy.findByText(/accessories/i).should('be.visible');
  cy.findByText(/under \$50/i).should('be.visible');
});
```

## Recipe 4: Date Range Filtering

```typescript
it('filters report by date range', () => {
  cy.intercept('GET', '**/api/reports*').as('reports');

  cy.visit('/reports');
  cy.findByLabelText('From').clear().type('2026-01-01');
  cy.findByLabelText('To').clear().type('2026-01-31');
  cy.findByRole('button', { name: /apply/i }).click();

  cy.wait('@reports').then(({ request }) => {
    expect(request.query.from).to.eq('2026-01-01');
    expect(request.query.to).to.eq('2026-01-31');
  });

  cy.findByText(/jan 1, 2026/i).should('be.visible');
});
```

## Recipe 5: Pagination + Filters Persistence

```typescript
it('keeps active filters when moving to next page', () => {
  cy.intercept('GET', '**/api/products*').as('products');

  cy.visit('/products?category=accessories');
  cy.wait('@products');

  cy.findByRole('button', { name: /next page/i }).click();
  cy.wait('@products').then(({ request }) => {
    expect(request.query.category).to.eq('accessories');
    expect(request.query.page).to.eq('2');
  });

  cy.url().should('include', 'category=accessories');
  cy.url().should('include', 'page=2');
});
```

## Recipe 6: Empty Results State

```typescript
it('shows empty state and recover action', () => {
  cy.intercept('GET', '**/api/products*', { statusCode: 200, body: [] }).as('emptySearch');

  cy.visit('/products');
  cy.findByRole('searchbox', { name: /search/i }).clear().type('no-such-product{enter}');

  cy.wait('@emptySearch');
  cy.findByText(/no results found/i).should('be.visible');
  cy.findByRole('button', { name: /clear search/i }).click();

  cy.findByRole('searchbox', { name: /search/i }).should('have.value', '');
});
```

## Recipe 7: URL-Driven Deep Linking

```typescript
it('loads search state from URL', () => {
  cy.intercept('GET', '**/api/products*').as('products');

  cy.visit('/products?q=monitor&category=electronics&sort=price-asc');
  cy.wait('@products');

  cy.findByRole('searchbox', { name: /search/i }).should('have.value', 'monitor');
  cy.findByDisplayValue(/electronics/i).should('exist');
  cy.findByDisplayValue(/price low to high/i).should('exist');
});
```

## Anti-Patterns

- `cy.wait(2000)` after typing in search fields.
- Verifying only row count, not request query or URL state.
- Writing one huge test that mixes search, filters, sort, and pagination without clear assertions.
- Using fragile selectors like `.filters > div:nth-child(2)` instead of role/label/data-cy.

## Related

- [core/network-mocking.md](network-mocking.md)
- [core/assertions-and-waiting.md](assertions-and-waiting.md)
- [core/error-and-edge-cases.md](error-and-edge-cases.md)
