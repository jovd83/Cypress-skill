# Stability Diagnostics and Flake Hardening

> **When to use**: Handling post-failure triage, hydration races, pointer interception, and optimistic UI timing issues.

## Error Context Triage Flow

When a test fails intermittently, follow this triage flow:

1. **Hydration Check**: Does the button exist but isn't "clickable" yet because the UI framework (e.g., React, Vue, Angular) hasn't hydrated?
   - *Fix*: Wait for a state change or an attribute that indicates readiness.
2. **Pointer Interception**: Is a loading spinner or another invisible overlay blocking the click?
   - *Fix*: `cy.get('[data-testid="spinner"]').should('not.exist')`
3. **Optimistic UI**: Did the UI update *before* the API call finished, causing the next action to fail when the API eventually errors?
   - *Fix*: Intercept the network request and wait for the response before proceeding.

## Hydration-Safe Interactions

### Preflight Script (Example Implementation)
In hydration-heavy apps, `cy.visit()` might finish its pageload while the JS is still executing.

```typescript
// BAD: Click might happen before event listeners are attached
cy.visit('/');
cy.findByRole('button', { name: 'Menu' }).click(); // Could fail if not hydrated

// GOOD: Ensure the menu is actually interactive
cy.visit('/');
cy.findByRole('button', { name: 'Menu' })
  .should('be.visible')
  .and('be.enabled')
  .click();
```

## Flake-Hardening Recipes

### 1. Pointer Interception Recovery

Cypress natively handles actionability checks (pointer-events, covered elements) before interacting. If Cypress fails to click due to interception, it usually means an animation or spinner is present.

```typescript
// Cypress automatically retries assertions and actions like click()
// until the element is actionable. Do not bypass actionability checks as a workaround.
// Wait for the overlay to disappear explicitly:
cy.get('.overlay--loading').should('not.exist');
cy.findByRole('button', { name: 'Save' }).should('be.visible').click();
```

### 2. Optimistic UI Validation

```typescript
// Ensure the background request actually finished
cy.intercept('POST', '**/api/save').as('saveRequest');
cy.findByRole('button', { name: 'Save' }).click();

// Wait for the interception and verify the network response was OK
cy.wait('@saveRequest').its('response.statusCode').should('eq', 200);

// Now proceed to assert on the next page/state
cy.findByText('Success').should('be.visible');
```

## Run-Health Classification

Don't just look at Pass/Fail. Monitor these "health metrics":

- **Console Errors**: Are there `404` or `500` errors in the console during a "Passing" test? Cypress can be configured to fail on `uncaught:exception`.
- **Warning Count**: Is the app spamming "depreciated" warnings that slow down the run?
- **Rerun Policy**: If a test fails once but passes on retry, it's a **Flake**, not a **Pass**. Treat it as a bug.

## Checklist

- [ ] **Triage Context**: Captured screenshots and video for the failing run.
- [ ] **Timing Analysis**: Compared "Success" vs "Failure" network timelines via Cypress UI.
- [ ] **Spinners & Overlays**: Explicitly waited for "Loading" states to resolve using `.should('not.exist')`.
- [ ] **Optimistic Sync**: Verified that UI state reflects the backend truth via `cy.intercept` and `cy.wait`.

## Anti-Patterns

| Anti-pattern | Why it hurts | Better approach |
|---|---|---|
| Bypassing actionability checks instead of diagnosing overlays or hydration races | Hides the real flake source and weakens the test | Wait for readiness signals and remove blocking UI states explicitly |
| Treating retry-pass runs as success | Flaky behavior remains in the suite | Classify retry-only passes as defects and investigate root cause |
