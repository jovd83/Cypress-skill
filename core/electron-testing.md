# Electron Testing

> **When to use**: Validate desktop-app flows running in Electron with Cypress, focusing on renderer behavior and app-visible integration outcomes.

## Scope Guidance

Cypress can run your app in Electron browser mode. For deep main-process orchestration, complement with dedicated Electron integration tests.

## Quick Reference

```bash
# Run Cypress in Electron
npx cypress run --browser electron
```

```typescript
it('opens settings and saves preference', () => {
  cy.visit('/');
  cy.findByRole('button', { name: /settings/i }).click();
  cy.findByLabelText('Enable notifications').check();
  cy.findByRole('button', { name: /save/i }).click();
  cy.findByRole('status').should('contain.text', 'Saved');
});
```

## Renderer Process Testing

```typescript
it('handles file import flow in electron renderer', () => {
  cy.visit('/import');

  cy.get('input[type=file]').selectFile('cypress/fixtures/sample.csv', { force: true });
  cy.findByRole('button', { name: /import/i }).click();

  cy.findByText(/import complete/i).should('be.visible');
});
```

## IPC Outcome Validation (App-Level)

Instead of testing IPC internals directly, assert outcome in UI/state.

```typescript
it('reflects main-process save result in UI', () => {
  cy.visit('/preferences');
  cy.findByRole('button', { name: /save preferences/i }).click();

  cy.findByRole('status').should('contain.text', 'Preferences saved');
});
```

## Error Recovery

```typescript
it('shows error when export fails', () => {
  cy.intercept('POST', '**/api/export', { statusCode: 500, body: { error: 'Export failed' } }).as('export');

  cy.visit('/reports');
  cy.findByRole('button', { name: /export/i }).click();

  cy.wait('@export');
  cy.findByRole('alert').should('contain.text', 'Export failed');
});
```

## Multi-Window Note

Cypress does not provide direct window event control in this style for Electron tests. Recommended alternatives:

1. Open target route directly in test for validation.
2. Assert window-open triggers via app-visible state/message hooks.
3. Cover deep multi-window lifecycle with dedicated Electron integration tooling.

## Anti-Patterns

- Using non-Cypress `window-event` APIs in Cypress docs.
- Mixing renderer UI tests with low-level process management in one spec.
- Assuming Chromium + Electron behavior is identical to Chrome-only web runs.

## Related

- [core/file-operations.md](file-operations.md)
- [core/error-and-edge-cases.md](error-and-edge-cases.md)
- [core/debugging.md](debugging.md)

