# Performance Testing

> **When to use**: Track frontend performance budgets and regressions (navigation timing, resource timing, API latency, render readiness) in Cypress.

## Scope Guidance

Cypress is best for lightweight performance guardrails, not full synthetic load testing.

Use Cypress for:
- Navigation timing checks.
- API latency thresholds from intercepted requests.
- Render-readiness budgets for key UI sections.

Use dedicated tooling for:
- Backend load testing.
- Large-scale concurrency benchmarks.

## Quick Reference

```typescript
cy.visit('/dashboard');
cy.window().then((win) => {
  const nav = win.performance.getEntriesByType('navigation')[0] as PerformanceNavigationTiming;
  expect(nav.loadEventEnd - nav.startTime).to.be.lessThan(4000);
});
```

## Navigation Timing Budget

```typescript
it('keeps homepage load under budget', () => {
  cy.visit('/');

  cy.window().then((win) => {
    const nav = win.performance.getEntriesByType('navigation')[0] as PerformanceNavigationTiming;
    expect(nav).to.not.equal(undefined);

    const total = nav.loadEventEnd - nav.startTime;
    const domContentLoaded = nav.domContentLoadedEventEnd - nav.startTime;

    expect(total).to.be.lessThan(3500);
    expect(domContentLoaded).to.be.lessThan(2000);
  });
});
```

## API Latency Budget with Intercepts

```typescript
it('search API responds within 800ms', () => {
  cy.intercept('GET', '**/api/search*').as('search');

  cy.visit('/search');
  cy.findByRole('searchbox', { name: /search/i }).clear().type('cypress{enter}');

  cy.wait('@search').then(({ response, duration }) => {
    expect(response && response.statusCode).to.eq(200);
    expect(duration).to.be.lessThan(800);
  });
});
```

## Resource Timing Audit

```typescript
it('keeps heavy resources in check', () => {
  cy.visit('/');

  cy.window().then((win) => {
    const resources = win.performance.getEntriesByType('resource') as PerformanceResourceTiming[];

    const slow = resources
      .filter((r) => r.initiatorType !== 'xmlhttprequest' && r.initiatorType !== 'fetch')
      .sort((a, b) => b.duration - a.duration)
      .slice(0, 5);

    expect(slow[0]?.duration || 0).to.be.lessThan(2000);
  });
});
```

## Render Readiness Budget

```typescript
it('renders dashboard content quickly', () => {
  cy.intercept('GET', '**/api/dashboard').as('dashboard');
  cy.visit('/dashboard');

  cy.wait('@dashboard');
  cy.findByTestId('dashboard-content', { timeout: 3000 }).should('be.visible');
});
```

## Lighthouse Integration Hook (Optional)

If your project uses `cypress-audit` or a Lighthouse integration, enforce score floors in CI.

```typescript
// Example shape only; plugin setup required
it('meets lighthouse performance threshold', () => {
  cy.visit('/');
  // cy.lighthouse({ performance: 80 });
});
```

## Budget File Pattern

```json
{
  "navigation": {
    "loadEventEndMs": 3500,
    "domContentLoadedMs": 2000
  },
  "api": {
    "searchMs": 800,
    "dashboardMs": 1200
  }
}
```

Use one source of truth for thresholds and apply it in specs.

## Anti-Patterns

- Treating Cypress timings as exact lab benchmarks.
- Failing tests on tiny jitter without tolerance.
- Mixing perf checks with long functional workflows.
- Running perf checks against unstable seeded data.

## Related

- [core/network-mocking.md](network-mocking.md)
- [core/flaky-tests.md](flaky-tests.md)
- [ci/parallel-and-sharding.md](../ci/parallel-and-sharding.md)
