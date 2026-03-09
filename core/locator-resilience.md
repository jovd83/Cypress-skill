# Locator Resilience and Strict Mode

> **When to use**: Dealing with multiple similar elements, localization variations, or strict-mode collisions in complex UIs.

## Patterns

### 1. Same-Label Multi-Surface Disambiguation

When a label like "Save" appears in both a sidebar and a main modal, scope your searches using containers to avoid matching multiple elements unintentionally.

```typescript
// BAD: Might match the Save button in the background instead of the modal
cy.findByRole('button', { name: 'Save' }).click();

// GOOD: Scope to the active container using .within()
cy.findByRole('dialog', { name: 'Edit User' }).within(() => {
  cy.findByRole('button', { name: 'Save' }).click();
});

// ALTERNATIVE: Use chained finds if you don't want to change the subject scope heavily
cy.findByRole('dialog', { name: 'Edit User' })
  .findByRole('button', { name: 'Save' })
  .click();
```

### 2. Localization-Tolerant Locators

Avoid hardcoding strings when possible. Use `data-testid` or regex if the text varies slightly (e.g., "Save", "Speichern", "Enregistrer").

```typescript
// RESILIENT: Using regex for common variations
cy.findByRole('button', { name: /save|speichern|enregistrer/i }).click();

// BEST: Using a stable automation contract
cy.get('[data-testid="save-button"]').click();
```

### 3. Strict-Mode Collision Recovery

If Cypress complains about finding multiple elements when you only expected one, use this triage checklist:

1. **Check for hidden duplicates**: Is there a mobile version of the button also in the DOM?
2. **Check for stale elements**: Did the previous modal close but its markup remain?
3. **Use `.first()` / `.last()` only as a last resort**: It's usually better to be more specific.

```typescript
// TRIAGE EXAMPLE
// Violation: multiple <h1> found
cy.findByRole('heading', { level: 1 }).should('be.visible');

// Fix: specify which one by its parent's purpose
cy.findByRole('main').within(() => {
  cy.findByRole('heading', { level: 1 }).should('have.text', 'Dashboard');
});
```

## Heuristics for Locator Precision

1. **Role + Name**: `cy.findByRole('button', { name: 'Login' })`
2. **Role + Container**: `cy.get('form#login').findByRole('button')`
3. **Test ID**: `cy.get('[data-testid="login-submit"]')`
4. **ARIA Attributes**: `cy.get('button[aria-label="submit"]')`

## Checklist

- [ ] **Strict Mode Audit**: Avoid using `.first()` to bypass multiple matching elements. Find out WHY there are multiple.
- [ ] **Role Tightening**: Move from generic `cy.get('.btn')` to specific `cy.findByRole('button')`.
- [ ] **Container Scoping**: Ensure every action happens within the intended UI surface (`cy.within()`).
