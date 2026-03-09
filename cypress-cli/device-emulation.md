# Device and Environment Emulation

> **When to use**: Validate responsive layouts, locale-sensitive formatting, geolocation-dependent UX, reduced motion behavior, and degraded network conditions.
> **Prerequisites**: [core-commands.md](core-commands.md), [running-custom-code.md](running-custom-code.md)

## Quick Reference

```bash
# Viewport / responsive checks
cypress-cli resize 375 812
cypress-cli screenshot --filename=mobile.png

# Locale-driven run
cypress-cli open https://example.com --config=locale-de.json

# Geolocation stubbing
cypress-cli run-code "() => {
  cy.window().then((win) => {
    cy.stub(win.navigator.geolocation, 'getCurrentPosition').callsFake((cb) => {
      cb({ coords: { latitude: 40.7128, longitude: -74.0060 } });
    });
  });
}"
```

## Viewport Emulation

```bash
# Desktop
cypress-cli resize 1920 1080
cypress-cli resize 1366 768

# Tablet
cypress-cli resize 1024 768
cypress-cli resize 768 1024

# Mobile
cypress-cli resize 430 932
cypress-cli resize 390 844
cypress-cli resize 375 812
cypress-cli resize 360 800
cypress-cli resize 320 568
```

### Breakpoint Sweep

```bash
cypress-cli resize 320 568
cypress-cli screenshot --filename=bp-xs.png

cypress-cli resize 576 768
cypress-cli screenshot --filename=bp-sm.png

cypress-cli resize 768 1024
cypress-cli screenshot --filename=bp-md.png

cypress-cli resize 992 768
cypress-cli screenshot --filename=bp-lg.png

cypress-cli resize 1200 900
cypress-cli screenshot --filename=bp-xl.png
```

## Locale and Timezone

Use config-per-run for deterministic localization checks.

**`locale-de.json`**
```json
{
  "locale": "de-DE",
  "timezone": "Europe/Berlin"
}
```

**`locale-ja.json`**
```json
{
  "locale": "ja-JP",
  "timezone": "Asia/Tokyo"
}
```

```bash
cypress-cli open https://example.com --config=locale-de.json
```

```bash
# Verify current locale/timezone in browser runtime
cypress-cli run-code "() => {
  cy.window().then((win) => {
    console.log({
      language: win.navigator.language,
      timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
      date: new Date('2024-01-15').toLocaleDateString(),
      number: (1234567.89).toLocaleString()
    });
  });
}"
```

## Geolocation

Cypress does not have a native `setGeolocation` API in this form. Stub browser geolocation methods.

```bash
# New York
cypress-cli run-code "() => {
  cy.window().then((win) => {
    cy.stub(win.navigator.geolocation, 'getCurrentPosition').callsFake((cb) => {
      cb({ coords: { latitude: 40.7128, longitude: -74.0060 } });
    });
  });
}"

# London
cypress-cli run-code "() => {
  cy.window().then((win) => {
    cy.stub(win.navigator.geolocation, 'getCurrentPosition').callsFake((cb) => {
      cb({ coords: { latitude: 51.5074, longitude: -0.1278 } });
    });
  });
}"
```

## Color Scheme and Reduced Motion

You can emulate these in tests by stubbing `matchMedia`.

```bash
# Dark mode stub
cypress-cli run-code "() => {
  cy.window().then((win) => {
    cy.stub(win, 'matchMedia').callsFake((query) => ({
      matches: query.includes('prefers-color-scheme: dark'),
      media: query,
      onchange: null,
      addListener: () => {},
      removeListener: () => {},
      addEventListener: () => {},
      removeEventListener: () => {},
      dispatchEvent: () => false
    }));
  });
}"

# Reduced motion stub
cypress-cli run-code "() => {
  cy.window().then((win) => {
    cy.stub(win, 'matchMedia').callsFake((query) => ({
      matches: query.includes('prefers-reduced-motion: reduce'),
      media: query,
      onchange: null,
      addListener: () => {},
      removeListener: () => {},
      addEventListener: () => {},
      removeEventListener: () => {},
      dispatchEvent: () => false
    }));
  });
}"
```

## Network Condition Emulation (Cypress Style)

Use intercept delays/errors to model poor networks.

```bash
# Slow response simulation
cypress-cli run-code "() => {
  cy.intercept('GET', '**/api/feed', {
    statusCode: 200,
    delayMs: 2500,
    body: { items: [] }
  }).as('feed');
}"

# Offline simulation for one endpoint
cypress-cli run-code "() => {
  cy.intercept('GET', '**/api/feed', { forceNetworkError: true }).as('feed');
}"
```

## Common Patterns

### Multi-Viewport Capture

```bash
#!/bin/bash
URL="https://example.com"

cypress-cli open "$URL"
for vp in "1920:1080:desktop" "768:1024:tablet" "375:812:mobile"; do
  IFS=':' read -r w h name <<< "$vp"
  cypress-cli resize "$w" "$h"
  cypress-cli screenshot --filename="device-${name}.png"
done
cypress-cli close
```

```powershell
$url = "https://example.com"
$viewports = @(
  @{ W = 1920; H = 1080; Name = "desktop" },
  @{ W = 768; H = 1024; Name = "tablet" },
  @{ W = 375; H = 812; Name = "mobile" }
)

cypress-cli open $url
foreach ($vp in $viewports) {
  cypress-cli resize $vp.W $vp.H
  cypress-cli screenshot --filename="device-$($vp.Name).png"
}
cypress-cli close
```

### Geo-Based Content Check

```bash
cypress-cli open https://example.com/stores
cypress-cli run-code "() => {
  cy.window().then((win) => {
    cy.stub(win.navigator.geolocation, 'getCurrentPosition').callsFake((cb) => {
      cb({ coords: { latitude: 37.7749, longitude: -122.4194 } });
    });
  });
}"
cypress-cli reload
cypress-cli screenshot --filename=stores-sf.png
```

## Anti-Patterns

| Anti-pattern | Problem | Better pattern |
|---|---|---|
| Assuming viewport resize equals full device emulation | Missed device-specific behavior | Combine viewport with network/locale/motion scenarios |
| Relying on host locale/timezone defaults | CI/local inconsistencies | Set explicit per-run locale and timezone fixtures |
| Injecting geolocation stubs after app already queried location | Test becomes timing-dependent | Stub before action/page state that triggers geolocation |
| Testing every permutation blindly | Slow low-signal suites | Prioritize user-relevant scenario combinations |

## Tips

- Viewport resize alone is not full device emulation.
- Keep locale/timezone fixtures explicit per test run.
- Prefer stubs over UI permission popups.
- Test combinations that users actually run (mobile + slow network + reduced motion).
