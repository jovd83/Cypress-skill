# Visual Regression

> **When to use**: Detect unintended UI changes between builds by comparing screenshots under controlled conditions.

## Strategy

Use one of these approaches:

1. Built-in `cy.screenshot()` + external image diff in CI.
2. Cypress plugin-based snapshot assertions (for example `cypress-image-snapshot`).
3. SaaS visual tools (Percy, Applitools) for large-scale review workflows.

## Golden Rules

1. Stabilize data and time before taking screenshots.
2. Freeze or hide volatile UI (timestamps, avatars, rotating ads, live counters).
3. Keep viewport and browser consistent.
4. Prefer component-level snapshots for precision; use page-level snapshots sparingly.

## Quick Reference

```typescript
// Baseline capture
cy.viewport(1280, 720);
cy.visit('/dashboard');
cy.screenshot('dashboard-baseline');

// Stable run with mocked data
cy.intercept('GET', '**/api/dashboard', { fixture: 'dashboard-stable.json' }).as('dashboard');
cy.visit('/dashboard');
cy.wait('@dashboard');
cy.screenshot('dashboard-stable');
```

## Built-In Screenshot Workflow

### TypeScript

```typescript
it('captures dashboard visual baseline', () => {
  cy.viewport(1366, 768);
  cy.intercept('GET', '**/api/dashboard', { fixture: 'dashboard-stable.json' }).as('dashboard');

  cy.visit('/dashboard');
  cy.wait('@dashboard');

  cy.get('[data-cy=current-time], [data-cy=live-counter]').invoke('css', 'visibility', 'hidden');
  cy.screenshot('dashboard');
});
```

### JavaScript

```javascript
it('captures dashboard visual baseline', () => {
  cy.viewport(1366, 768);
  cy.intercept('GET', '**/api/dashboard', { fixture: 'dashboard-stable.json' }).as('dashboard');

  cy.visit('/dashboard');
  cy.wait('@dashboard');

  cy.get('[data-cy=current-time], [data-cy=live-counter]').invoke('css', 'visibility', 'hidden');
  cy.screenshot('dashboard');
});
```

## Plugin Snapshot Assertions (Optional)

If your project installs `cypress-image-snapshot`, add snapshot assertions.

### TypeScript

```typescript
it('matches homepage snapshot', () => {
  cy.viewport(1280, 720);
  cy.visit('/');

  cy.matchImageSnapshot('homepage', {
    failureThreshold: 0.01,
    failureThresholdType: 'percent'
  });
});
```

### JavaScript

```javascript
it('matches homepage snapshot', () => {
  cy.viewport(1280, 720);
  cy.visit('/');

  cy.matchImageSnapshot('homepage', {
    failureThreshold: 0.01,
    failureThresholdType: 'percent'
  });
});
```

## Control Flakiness Sources

### Freeze Time

```typescript
beforeEach(() => {
  cy.clock(new Date('2026-01-01T10:00:00Z').getTime(), ['Date']);
});
```

### Mock Dynamic APIs

```typescript
cy.intercept('GET', '**/api/notifications', { fixture: 'notifications-empty.json' }).as('notifications');
cy.intercept('GET', '**/api/recommendations', { fixture: 'recommendations-fixed.json' }).as('recs');
```

### Disable Motion

```typescript
cy.document().then((doc) => {
  const style = doc.createElement('style');
  style.innerHTML = '* { animation: none !important; transition: none !important; }';
  doc.head.appendChild(style);
});
```

## Component-Level Visuals

```typescript
it('renders pricing card correctly', () => {
  cy.visit('/pricing');
  cy.get('[data-cy=pricing-card-pro]').should('be.visible').screenshot('pricing-card-pro');
});
```

## Responsive Visual Matrix

```typescript
const viewports = [
  { name: 'desktop', width: 1440, height: 900 },
  { name: 'tablet', width: 768, height: 1024 },
  { name: 'mobile', width: 390, height: 844 }
];

viewports.forEach((vp) => {
  it(`homepage visual ${vp.name}`, () => {
    cy.viewport(vp.width, vp.height);
    cy.visit('/');
    cy.screenshot(`homepage-${vp.name}`);
  });
});
```

## CI Guidance

```bash
# Run Cypress suite with screenshots/videos on failure
npx cypress run --browser chrome

# Update visual baselines (your own script convention)
npm run visual:update
```

Example `package.json` scripts:

```json
{
  "scripts": {
    "test:visual": "cypress run --spec 'cypress/e2e/visual/**/*.cy.ts'",
    "visual:update": "cypress run --spec 'cypress/e2e/visual/**/*.cy.ts'"
  }
}
```

## Baseline Review Workflow

1. Run visual tests locally with stable fixtures.
2. Inspect changed images and diff output.
3. Accept baseline changes only when UI change is intentional.
4. Keep baseline updates in separate PR commits for clarity.

## Anti-Patterns

- Capturing full-page screenshots for highly dynamic screens without stubbing data.
- Comparing screenshots across different viewport/browser combos unintentionally.
- Updating baselines blindly after every test failure.
- Hiding too much UI and missing real visual regressions.

## Related

- [core/assertions-and-waiting.md](assertions-and-waiting.md)
- [core/mobile-and-responsive.md](mobile-and-responsive.md)
- [core/network-mocking.md](network-mocking.md)
- [ci/reporting-and-artifacts.md](../ci/reporting-and-artifacts.md)
