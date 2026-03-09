# Test Generation

> **When to use**: Convert interactive `cypress-cli` sessions into maintainable Cypress tests (TypeScript or JavaScript).
> **Prerequisites**: [core-commands.md](core-commands.md), [running-custom-code.md](running-custom-code.md)

## Quick Reference

```bash
# CLI actions emit equivalent Cypress commands
cypress-cli open https://example.com/login
cypress-cli snapshot
cypress-cli fill e1 "user@example.com"
# Generated idea: cy.findByLabelText('Email').clear().type('user@example.com');

cypress-cli fill e2 "password123"
# Generated idea: cy.findByLabelText('Password').clear().type('password123');

cypress-cli click e3
# Generated idea: cy.findByRole('button', { name: 'Sign In' }).click();
```

## How Generation Should Be Used

1. Record interactions quickly with CLI.
2. Paste generated lines into a spec file.
3. Refactor selectors and test data.
4. Add assertions (generation captures actions, not intent).

## Example: Login Flow to Test File

### Recorded CLI Flow

```bash
cypress-cli open https://example.com/login
cypress-cli snapshot
cypress-cli fill e1 "user@example.com"
cypress-cli fill e2 "password123"
cypress-cli click e3
```

### TypeScript Version

```typescript
// cypress/e2e/login.cy.ts
it('user can log in', () => {
  cy.visit('https://example.com/login');
  cy.findByLabelText('Email').clear().type('user@example.com');
  cy.findByLabelText('Password').clear().type('password123');
  cy.findByRole('button', { name: 'Sign In' }).click();

  cy.url().should('match', /\/dashboard$/);
  cy.findByRole('heading', { name: 'Dashboard' }).should('be.visible');
});
```

### JavaScript Version

```javascript
// cypress/e2e/login.cy.js
it('user can log in', () => {
  cy.visit('https://example.com/login');
  cy.findByLabelText('Email').clear().type('user@example.com');
  cy.findByLabelText('Password').clear().type('password123');
  cy.findByRole('button', { name: 'Sign In' }).click();

  cy.url().should('match', /\/dashboard$/);
  cy.findByRole('heading', { name: 'Dashboard' }).should('be.visible');
});
```

## Locator Strategy for Generated Code

| Priority | Preferred selector | Example |
|---|---|---|
| 1 | Role + name | `cy.findByRole('button', { name: 'Submit' })` |
| 2 | Label | `cy.findByLabelText('Email')` |
| 3 | Placeholder | `cy.findByPlaceholderText('Search')` |
| 4 | Text content | `cy.findByText('Order confirmed')` |
| 5 | Stable test id | `cy.get('[data-cy="submit"]')` |

Avoid brittle CSS chains and index-based selectors.

## Add Assertions Explicitly

```typescript
// URL assertion
cy.url().should('include', '/checkout');

// Visibility and content
cy.findByRole('alert').should('contain.text', 'Saved');
cy.get('[data-cy=total]').should('have.text', '$99.99');

// Count
cy.findAllByRole('listitem').should('have.length', 5);

// State
cy.findByRole('button', { name: 'Submit' }).should('be.disabled');
```

## Example: Checkout Flow

```typescript
it('completes checkout', () => {
  cy.visit('/products');

  cy.findByRole('button', { name: 'Add to cart' }).click();
  cy.get('[data-cy=cart-count]').should('have.text', '1');

  cy.findByRole('link', { name: 'Cart' }).click();
  cy.url().should('include', '/cart');

  cy.findByRole('button', { name: 'Checkout' }).click();
  cy.findByLabelText('Full Name').clear().type('Jane Doe');
  cy.findByLabelText('Address').clear().type('123 Main St');
  cy.findByRole('button', { name: 'Place Order' }).click();

  cy.findByText('Order confirmed').should('be.visible');
  cy.get('[data-cy=order-number]').should('be.visible');
});
```

## Command Queue vs Async/Await

### Anti-pattern

```typescript
// Do not do this in Cypress
it('bad async pattern', async () => {
  const chain = cy.get('[data-cy=email]').type('user@example.com');
  await chain; // Misleading: Cypress chainables are not standard promises
});
```

### Correct pattern

```typescript
it('good queue pattern', () => {
  cy.visit('/login');
  cy.get('[data-cy=email]').type('user@example.com');
  cy.get('[data-cy=password]').type('secret');
  cy.get('[data-cy=submit]').click();
});
```

## Anti-Patterns

| Anti-pattern | Problem | Better pattern |
|---|---|---|
| Treating generated code as final production tests | Carries brittle selectors and weak assertions | Refactor output and add intent-focused checks |
| Keeping hardcoded credentials/test data | Fragile and unsafe in CI | Replace with fixtures/factories/env variables |
| Converting generated flows to `async/await` style | Breaks Cypress queue mental model | Keep Cypress chain-based command flow |
| Building one giant generated scenario | Hard to debug and maintain | Split into behavior-focused tests |

## Best Practices

1. Keep generated tests small and behavior-focused.
2. Replace hardcoded data with fixtures/factories.
3. Use `cy.intercept()` to make network-dependent tests deterministic.
4. Avoid `cy.wait(milliseconds)` unless there is no better signal.
5. Reuse auth with `cy.session()` for faster suites.

## Tips

- Use generation as scaffolding, not final production code.
- Refactor into helpers or custom commands when flows repeat.
- Keep assertions close to the action they verify.
