# Accessibility Testing

> **When to use**: Every project. Accessibility is a quality baseline, not an optional add-on.
> **Prerequisites**: [locators.md](locators.md), [assertions-and-waiting.md](assertions-and-waiting.md)

## Tooling Baseline

Use `cypress-axe` for automated checks, then add keyboard and focus behavior tests for critical flows.

```bash
npm i -D cypress-axe axe-core
```

```typescript
// cypress/support/e2e.ts
import 'cypress-axe';
```

## Quick Reference

```typescript
it('homepage has no serious accessibility violations', () => {
  cy.visit('/');
  cy.injectAxe();
  cy.checkA11y(null, { includedImpacts: ['serious', 'critical'] });
});
```

## Pattern 1: Global Page Scan

**TypeScript**
```typescript
it('dashboard passes axe checks', () => {
  cy.visit('/dashboard');
  cy.injectAxe();
  cy.checkA11y();
});
```

**JavaScript**
```javascript
it('dashboard passes axe checks', () => {
  cy.visit('/dashboard');
  cy.injectAxe();
  cy.checkA11y();
});
```

## Pattern 2: Scoped Scan

```typescript
it('checkout form is accessible', () => {
  cy.visit('/checkout');
  cy.injectAxe();

  cy.findByRole('form', { name: /checkout/i }).then(($form) => {
    cy.checkA11y($form, {
      includedImpacts: ['serious', 'critical'],
    });
  });
});
```

Use scoped scans to isolate noisy areas and speed up checks.

## Pattern 3: Keyboard Navigation

Automated scanners cannot validate full keyboard behavior.

```typescript
it('supports tab navigation through login form', () => {
  cy.visit('/login');

  cy.findByLabelText(/email/i).focus().should('be.focused');
  cy.focused().tab();
  cy.findByLabelText(/password/i).should('be.focused');
  cy.focused().tab();
  cy.findByRole('button', { name: /sign in/i }).should('be.focused');
});
```

If using `.tab()`, install `cypress-plugin-tab` or drive keyboard events with your preferred plugin strategy.

## Pattern 4: Focus Management in Dialogs

```typescript
it('returns focus to trigger after modal close', () => {
  cy.visit('/settings');

  cy.findByRole('button', { name: /delete account/i })
    .as('trigger')
    .click();

  cy.findByRole('dialog', { name: /confirm delete/i }).should('be.visible');
  cy.findByRole('button', { name: /cancel/i }).click();
  cy.get('@trigger').should('be.focused');
});
```

## Pattern 5: Accessible Form Errors

```typescript
it('announces validation errors', () => {
  cy.visit('/register');
  cy.findByRole('button', { name: /create account/i }).click();

  cy.findByRole('alert').should('contain.text', 'Email is required');
  cy.findByLabelText(/email/i).should('have.attr', 'aria-invalid', 'true');
});
```

## Pattern 6: CI Accessibility Gate

Use `includedImpacts` to enforce strict blocking only for severe issues.

```typescript
cy.checkA11y(null, {
  includedImpacts: ['critical'],
});
```

Recommended policy:

- PR gate: `critical`
- nightly full suite: `serious` + `critical`

## Anti-Patterns

| Anti-pattern | Why it fails | Better approach |
|---|---|---|
| Accessibility checks only before release | Late defects, expensive fixes | Run in CI from first sprint |
| Relying only on axe scans | Misses keyboard and focus behavior | Add targeted keyboard/focus tests |
| Using text selectors that ignore semantics | Brittle tests and weak a11y signal | Prefer `findByRole`, `findByLabelText` |
| Suppressing all violations globally | Hides regressions | Track explicit exceptions with owner and expiry |

## Troubleshooting

### `cy.checkA11y is not a function`

- Ensure `import 'cypress-axe'` is in `cypress/support/e2e.ts`.
- Confirm test uses `e2e` support file path from config.

### Too many noisy violations

- Start with scoped scans and `includedImpacts`.
- Fix repeated root causes (missing labels, color contrast, landmark roles).

### Keyboard tests flaky in CI

- Avoid arbitrary waits.
- Assert on visible and focused elements after each action.
- Keep viewport stable for keyboard/focus tests.

## Related Guides

- [locators.md](locators.md)
- [forms-and-validation.md](forms-and-validation.md)
- [component-testing.md](component-testing.md)
- [ci/ci-github-actions.md](../ci/ci-github-actions.md)
