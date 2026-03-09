# CRUD Testing

> **When to use**: Validate create, read, update, and delete flows for application entities.
> **Prerequisites**: [forms-and-validation.md](forms-and-validation.md), [api-testing.md](api-testing.md), [test-data-management.md](test-data-management.md)

## Quick Reference

```typescript
it('creates a product and shows it in list', () => {
  cy.visit('/products');
  cy.findByRole('button', { name: /add product/i }).click();
  cy.findByLabelText(/product name/i).type('Keyboard');
  cy.findByLabelText(/price/i).type('79.99');
  cy.findByRole('button', { name: /save/i }).click();
  cy.findByText('Keyboard').should('be.visible');
});
```

## Pattern 1: Create

```typescript
it('create product', () => {
  const name = `Keyboard-${Date.now()}`;

  cy.visit('/products');
  cy.findByRole('button', { name: /add product/i }).click();
  cy.findByLabelText(/product name/i).type(name);
  cy.findByLabelText(/price/i).type('79.99');
  cy.findByRole('button', { name: /save product/i }).click();

  cy.findByRole('alert').should('contain.text', 'Product created');
  cy.findByText(name).should('be.visible');
});
```

## Pattern 2: Read and Search

```typescript
it('searches product list', () => {
  cy.visit('/products');
  cy.findByRole('textbox', { name: /search/i }).type('Keyboard');
  cy.findByRole('row', { name: /Keyboard/i }).should('be.visible');
});
```

## Pattern 3: Update

```typescript
it('updates product price', () => {
  const newPrice = '89.99';

  cy.visit('/products');
  cy.findByRole('row', { name: /Keyboard/i }).within(() => {
    cy.findByRole('button', { name: /edit/i }).click();
  });

  cy.findByLabelText(/price/i).clear().type(newPrice);
  cy.findByRole('button', { name: /save changes/i }).click();

  cy.findByRole('alert').should('contain.text', 'Product updated');
  cy.findByRole('row', { name: /Keyboard/i }).should('contain.text', '$89.99');
});
```

## Pattern 4: Delete

```typescript
it('deletes product from list', () => {
  cy.visit('/products');

  cy.findByRole('row', { name: /Keyboard/i }).within(() => {
    cy.findByRole('button', { name: /delete/i }).click();
  });

  cy.findByRole('dialog', { name: /confirm delete/i }).within(() => {
    cy.findByRole('button', { name: /confirm/i }).click();
  });

  cy.findByRole('alert').should('contain.text', 'Product deleted');
  cy.findByRole('row', { name: /Keyboard/i }).should('not.exist');
});
```

## Pattern 5: API Verification after UI Mutation

```typescript
it('creates product in UI and verifies persistence through API', () => {
  const name = `API-Verified-${Date.now()}`;

  cy.visit('/products');
  cy.findByRole('button', { name: /add product/i }).click();
  cy.findByLabelText(/product name/i).type(name);
  cy.findByLabelText(/price/i).type('49.99');
  cy.findByRole('button', { name: /save product/i }).click();

  cy.request(`/api/products?search=${encodeURIComponent(name)}`).then((res) => {
    expect(res.status).to.eq(200);
    expect(res.body.products).to.have.length.greaterThan(0);
    expect(res.body.products[0].name).to.eq(name);
  });
});
```

## Pattern 6: Optimistic UI Update

```typescript
it('shows optimistic status update while request is pending', () => {
  cy.intercept('PATCH', '/api/products/*', (req) => {
    req.reply((res) => {
      res.delay = 1500;
      res.send();
    });
  }).as('updateProduct');

  cy.visit('/products');
  cy.findByRole('row', { name: /Keyboard/i }).within(() => {
    cy.findByRole('button', { name: /toggle status/i }).click();
    cy.findByText(/active/i).should('be.visible');
    cy.findByRole('progressbar').should('be.visible');
  });

  cy.wait('@updateProduct');
  cy.findByRole('row', { name: /Keyboard/i })
    .findByRole('progressbar')
    .should('not.exist');
});
```

## Pattern 7: End-to-End CRUD Lifecycle

```typescript
it('create -> read -> update -> delete lifecycle', () => {
  const name = `Lifecycle-${Date.now()}`;

  // Create
  cy.visit('/products');
  cy.findByRole('button', { name: /add product/i }).click();
  cy.findByLabelText(/product name/i).type(name);
  cy.findByLabelText(/price/i).type('10.00');
  cy.findByRole('button', { name: /save/i }).click();

  // Read
  cy.findByRole('textbox', { name: /search/i }).clear().type(name);
  cy.findByRole('row', { name }).should('be.visible');

  // Update
  cy.findByRole('row', { name }).within(() => {
    cy.findByRole('button', { name: /edit/i }).click();
  });
  cy.findByLabelText(/price/i).clear().type('12.00');
  cy.findByRole('button', { name: /save changes/i }).click();
  cy.findByRole('row', { name }).should('contain.text', '$12.00');

  // Delete
  cy.findByRole('row', { name }).within(() => {
    cy.findByRole('button', { name: /delete/i }).click();
  });
  cy.findByRole('button', { name: /confirm/i }).click();
  cy.findByRole('row', { name }).should('not.exist');
});
```

## Anti-Patterns

| Anti-pattern | Why it fails | Better pattern |
|---|---|---|
| Assert only toast after mutation | Can hide persistence bugs | Also assert table/card state and API result |
| Reuse fixed names/IDs | Conflicts across CI runs | Use unique test data values |
| Use index-based row selectors | Breaks with sorting/filtering | Use role + row text |
| Skip delete cleanup | Pollutes test env | Delete entities or reset via API |
| Fixed wait after save | Flaky | Wait on alias or assert eventual state |

## Troubleshooting

### Row not found after create

- Search/filter may still be applied.
- Clear filters before assertion.
- Confirm backend response with `cy.request`.

### Update appears in UI then disappears

- Optimistic update rolled back due API error.
- Assert network status (`cy.intercept` alias) and fallback message.

### Delete button click does nothing in CI

- Element may be hidden behind overlay.
- Assert dialog is visible before clicking confirm.

## Related Guides

- [forms-and-validation.md](forms-and-validation.md)
- [search-and-filter.md](search-and-filter.md)
- [api-testing.md](api-testing.md)
- [test-data-management.md](test-data-management.md)
