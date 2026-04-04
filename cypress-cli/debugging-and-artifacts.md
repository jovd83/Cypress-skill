# Debugging and Artifacts

> **When to use**: Diagnose flaky or failing flows using Cypress-native signals: command log, screenshots, videos, console errors, and network interception.
> **Prerequisites**: [core-commands.md](core-commands.md), [request-mocking.md](request-mocking.md)

## Quick Reference

```bash
# Reproduce + capture artifacts
cypress-cli open https://app.example.com
cypress-cli snapshot
cypress-cli screenshot --filename=before-submit.png
cypress-cli click e5
cypress-cli screenshot --filename=after-submit.png

# Runtime logs
cypress-cli console error
cypress-cli network

# Optional video artifact for full-flow playback
cypress-cli video-start
cypress-cli video-stop artifacts/debug-flow.webm
```

## Cypress Debugging Stack

1. **Command log**: First place to inspect what happened and in what order.
2. **Screenshots/videos**: Primary visual artifacts for CI failures.
3. **Console output**: Catch runtime JS errors quickly.
4. **Network interception**: Validate request/response contracts.
5. **`cy.pause()` / `cy.debug()`**: Interactive local debugging.

## Console Monitoring

```bash
# Read captured console output
cypress-cli console
cypress-cli console error
cypress-cli console warning
```

```bash
# Attach browser error listeners in run-code
cypress-cli run-code "() => {
  cy.on('window:alert', (text) => console.log('[alert]', text));
  cy.on('uncaught:exception', (err) => {
    console.log('[uncaught]', err.message);
    return false; // optional: keep test running while investigating
  });
}"
```

## Network Debugging

```bash
cypress-cli run-code "() => {
  cy.intercept('GET', '**/api/**', (req) => {
    req.continue((res) => {
      if (res.statusCode >= 400) {
        console.log('[http error]', req.url, res.statusCode);
      }
    });
  }).as('api');

  cy.visit('https://app.example.com/dashboard');
  cy.wait('@api');
}"
```

## Snapshot-First Triage

```bash
cypress-cli snapshot --filename=before.yaml
cypress-cli click e5
cypress-cli snapshot --filename=after.yaml
```

Use this before deep debugging. It often reveals overlay, visibility, or selector drift immediately.

## Performance Investigation

```bash
cypress-cli run-code "() => {
  cy.window().then((win) => {
    const nav = win.performance.getEntriesByType('navigation')[0];
    if (!nav) return;
    console.log({
      ttfb: Math.round(nav.responseStart - nav.requestStart),
      domContentLoaded: Math.round(nav.domContentLoadedEventEnd - nav.startTime),
      load: Math.round(nav.loadEventEnd - nav.startTime)
    });
  });
}"
```

```bash
cypress-cli run-code "() => {
  cy.window().then((win) => {
    const slow = win.performance
      .getEntriesByType('resource')
      .sort((a, b) => b.duration - a.duration)
      .slice(0, 10)
      .map((r) => ({ name: r.name, duration: Math.round(r.duration) }));
    console.log(slow);
  });
}"
```

## Retry and Stability Patterns

```bash
# Wait for deterministic conditions, not fixed time
cypress-cli run-code "() => {
  cy.intercept('GET', '**/api/checkout-summary').as('summary');
  cy.get('[data-cy=checkout]').click();
  cy.wait('@summary');
  cy.get('[data-cy=summary-total]').should('be.visible');
}"
```

```bash
# Dismiss optional modal safely
cypress-cli run-code "() => {
  cy.get('body').then(($body) => {
    const close = $body.find('[data-cy=welcome-close]');
    if (close.length) cy.wrap(close).click();
  });
}"
```

## Artifact Strategy (Cypress-Oriented)

| Artifact | Best for | Cost |
|---|---|---|
| Screenshot | Point-in-time UI verification | Low |
| Video | Full execution playback | Medium |
| Command log + console | Root-cause details | Low |
| Optional diagnostics bundle (`tracing-*`) | Extra low-level CLI diagnostics where supported | Medium |

## Anti-Patterns

| Anti-pattern | Problem | Better pattern |
|---|---|---|
| Capturing only a final screenshot | Misses where failure first appears | Capture checkpoints before and after risky actions |
| Relying on video only without alias assertions | Hard to prove backend cause | Combine artifacts with `cy.intercept` aliases |
| Keeping blanket retries as default fix | Masks deterministic issues | Stabilize selectors, waits, and data setup first |
| Debugging with live third-party traffic enabled | Noisy and nondeterministic failures | Block/mock non-essential external requests |

## Best Practices

1. Capture screenshots at each critical checkpoint in long flows.
2. Keep videos on in CI for failing specs.
3. Alias key requests (`.as('name')`) and assert status/body.
4. Avoid blanket retries that hide real defects.
5. Prefer app-observable signals over arbitrary waits.

## Troubleshooting

### Artifacts are not useful enough to explain the failure

- Add screenshots before and after the risky interaction instead of only at the end.
- Pair visual artifacts with aliased network assertions and console output.
- Save snapshots around UI transitions so selector drift is visible.

### Debug run is too noisy

- Block or stub non-essential third-party traffic.
- Focus console capture on error or warning levels first.
- Reduce the scenario to the smallest reproducible flow before collecting more artifacts.

### Video exists but still does not show the cause

- Add command-log evidence and request assertions to the same flow.
- Capture intermediate screenshots at major checkpoints.
- Use `run-code` to log browser performance or application state where that signal matters.

## Related

- [core-commands.md](core-commands.md)
- [request-mocking.md](request-mocking.md)
- [running-custom-code.md](running-custom-code.md)
- [screenshots-and-media.md](screenshots-and-media.md)
