# Locator Strategy

> **When to use**: Decide which selector style gives the most stable Cypress tests.
> **Prerequisites**: [locators.md](locators.md), [accessibility.md](accessibility.md)

## Golden Priority

1. `cy.findByRole(...)`
2. `cy.findByLabelText(...)`
3. `cy.findByText(...)` for non-interactive content
4. `cy.findByPlaceholderText(...)` only when label is unavailable
5. `cy.get('[data-testid="..."]')` as explicit fallback

## Decision Matrix

| Element | Preferred | Fallback | Example |
|---|---|---|---|
| Button | `findByRole('button', { name })` | `findByText` | `cy.findByRole('button', { name: /save/i })` |
| Link | `findByRole('link', { name })` | `findByText` | `cy.findByRole('link', { name: 'Pricing' })` |
| Input | `findByLabelText('Email')` | `findByRole('textbox', { name: /email/i })` | `cy.findByLabelText('Email')` |
| Checkbox | `findByRole('checkbox', { name })` | `findByLabelText` | `cy.findByRole('checkbox', { name: /terms/i })` |
| Dialog | `findByRole('dialog', { name })` | `get('[role=\"dialog\"]')` | `cy.findByRole('dialog', { name: /confirm/i })` |
| Custom widget | `get('[data-testid=\"...\"]')` | add semantic role | `cy.get('[data-testid=\"color-picker\"]')` |

## Core Rules

1. Prefer user-facing selectors (role, label, visible name).
2. Scope with `within` instead of index-based targeting.
3. Avoid CSS-path and `nth-child` selectors.
4. Avoid brittle text-only locators for interactive controls.
5. Add `data-testid` when semantics are genuinely unavailable.

## Pattern 1: Scope by Region

```typescript
cy.findByRole('region', { name: /billing/i }).within(() => {
  cy.findByRole('button', { name: /update/i }).click();
});
```

## Pattern 2: Scope by Table Row

```typescript
cy.findByRole('row', { name: /jane smith/i }).within(() => {
  cy.findByRole('button', { name: /edit/i }).click();
});
```

## Pattern 3: Dynamic List Item Selection

```typescript
cy.findByRole('list', { name: /shopping list/i })
  .findByText('Milk')
  .closest('[role="listitem"]')
  .within(() => {
    cy.findByRole('button', { name: /remove/i }).click();
  });
```

## Pattern 4: Dialog Interactions

```typescript
cy.findByRole('dialog', { name: /confirm deletion/i }).within(() => {
  cy.findByRole('button', { name: /delete/i }).click();
});
```

## Pattern 5: Form Field Strategy

```typescript
cy.findByLabelText(/email/i).clear().type('user@example.com');
cy.findByLabelText(/password/i).clear().type('Password123!');
cy.findByRole('button', { name: /sign in/i }).click();
```

## Pattern 6: Content Assertions

```typescript
cy.findByRole('heading', { level: 1, name: /dashboard/i }).should('be.visible');
cy.findByText(/last updated/i).should('be.visible');
```

## Anti-Patterns

| Anti-pattern | Why it breaks | Better pattern |
|---|---|---|
| `cy.get('.btn-primary')` | Style classes change | `findByRole('button', { name })` |
| `cy.get('button').eq(2)` | Order-dependent and fragile | Scope parent + role/name |
| `cy.get('div > form > input:first-child')` | DOM-structure coupling | `findByLabelText` |
| Generic `findByText('Edit')` click | May hit wrong element | Scope row/region first |

## Legacy Mapping (Other Framework -> Cypress)

| Legacy pattern | Cypress |
|---|---|
| Role-based query | `cy.findByRole(...)` |
| Label-based query | `cy.findByLabelText(...)` |
| Text-based query | `cy.findByText(...)` |
| Test id query | `cy.get('[data-testid=\"...\"]')` |
| `locator.filter({ hasText })` | scope + `findByText` + `closest(...)` |

## Related

- [locators.md](locators.md)
- [accessibility.md](accessibility.md)
- [common-pitfalls.md](common-pitfalls.md)
