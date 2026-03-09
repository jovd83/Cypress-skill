# Canvas and WebGL Testing

> **When to use**: Validate charts, drawings, canvases, and WebGL scenes where DOM assertions alone are insufficient.

## Golden Rules

1. Assert render completion before pixel checks.
2. Prefer deterministic test data and fixed viewport.
3. Use visual capture for output validation; use event assertions for interactions.
4. Allow small rendering tolerance across environments.

## Quick Reference

```typescript
cy.viewport(1280, 720);
cy.intercept('GET', '**/api/chart-data', { fixture: 'chart-data.json' }).as('chart');
cy.visit('/dashboard');
cy.wait('@chart');
cy.get('canvas#revenue-chart').should('be.visible').screenshot('revenue-chart');
```

## Render Readiness

```typescript
it('waits for chart render before assertions', () => {
  cy.intercept('GET', '**/api/chart-data').as('chart');
  cy.visit('/dashboard');

  cy.wait('@chart');
  cy.get('[data-testid=\"chart-loading\"]').should('not.exist');
  cy.get('canvas#revenue-chart').should('be.visible');
});
```

## Pixel Sampling (Canvas 2D)

```typescript
it('reads a pixel color from canvas', () => {
  cy.visit('/chart');

  cy.get('canvas#chart').then(($canvas) => {
    const canvas = $canvas[0] as HTMLCanvasElement;
    const ctx = canvas.getContext('2d');
    expect(ctx).to.not.equal(null);

    const pixel = ctx!.getImageData(50, 50, 1, 1).data;
    expect(pixel[3]).to.be.greaterThan(0); // alpha > 0
  });
});
```

## Interaction Testing by Coordinates

```typescript
it('shows tooltip on chart point hover', () => {
  cy.visit('/chart');

  cy.get('canvas#chart')
    .trigger('mousemove', { clientX: 320, clientY: 180 })
    .trigger('mouseover');

  cy.findByRole('tooltip').should('contain.text', 'Revenue');
});
```

## Drawing Tool Scenario

```typescript
it('draws a stroke on whiteboard canvas', () => {
  cy.visit('/whiteboard');

  cy.get('canvas#board')
    .trigger('mousedown', { clientX: 100, clientY: 100 })
    .trigger('mousemove', { clientX: 220, clientY: 220 })
    .trigger('mouseup', { force: true });

  cy.get('canvas#board').screenshot('whiteboard-stroke');
});
```

## WebGL Smoke Validation

```typescript
it('renders WebGL scene shell', () => {
  cy.visit('/viewer');
  cy.get('canvas#scene').should('be.visible');
  cy.findByText(/loading/i).should('not.exist');
  cy.get('canvas#scene').screenshot('webgl-scene');
});
```

## Stabilization Tips

1. Freeze time when overlays include timestamps.
2. Stub APIs that drive chart data.
3. Disable CSS animations around canvases when possible.
4. Keep consistent browser + viewport for baseline updates.

## Anti-Patterns

- Asserting exact floating-point coordinates from chart libraries.
- Using fixed sleeps to guess render completion.
- Comparing screenshots without controlling data/time.
- Treating canvas elements like standard DOM text containers.

## Related

- [core/visual-regression.md](visual-regression.md)
- [core/network-mocking.md](network-mocking.md)
- [core/flaky-tests.md](flaky-tests.md)
