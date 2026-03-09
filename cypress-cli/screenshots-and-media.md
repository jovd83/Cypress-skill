# Screenshots and Media

> **When to use**: Capture visual evidence, compare responsive layouts, create demo/debug artifacts, and export printable views.
> **Prerequisites**: [core-commands.md](core-commands.md), [device-emulation.md](device-emulation.md)

## Quick Reference

```bash
# Screenshots
cypress-cli screenshot
cypress-cli screenshot e5
cypress-cli screenshot --filename=checkout.png

# PDF (if enabled by your CLI/browser integration)
cypress-cli pdf --filename=report.pdf

# Video
cypress-cli video-start
cypress-cli video-stop demo.webm

# Viewport
cypress-cli resize 1920 1080
cypress-cli resize 375 812
```

## Screenshots

### Page Screenshots

```bash
cypress-cli screenshot
cypress-cli screenshot --filename=homepage.png
cypress-cli screenshot --filename=screenshots/checkout-step3.png
```

### Element Screenshots

```bash
cypress-cli snapshot
cypress-cli screenshot e5
cypress-cli screenshot e5 --filename=product-card.png
```

### Full Page Screenshot (via run-code)

```bash
cypress-cli run-code "() => {
  cy.screenshot('full-page', { capture: 'fullPage' });
}"
```

### Advanced Screenshot Options

```bash
# Disable animations for deterministic captures
cypress-cli run-code "() => {
  cy.document().then((doc) => {
    const style = doc.createElement('style');
    style.innerHTML = '* { animation: none !important; transition: none !important; }';
    doc.head.appendChild(style);
  });

  cy.screenshot('stable-ui');
}"

# Clip-like behavior by targeting a container element
cypress-cli run-code "() => {
  cy.get('[data-cy=header-region]').screenshot('header-region');
}"

# Hide dynamic elements before capture
cypress-cli run-code "() => {
  cy.get('[data-cy=timestamp], [data-cy=user-avatar], [data-cy=ad-slot]').invoke('css', 'visibility', 'hidden');
  cy.screenshot('masked-ui');
}"
```

## Responsive Screenshot Suite

```bash
# Desktop
cypress-cli resize 1920 1080
cypress-cli screenshot --filename=desktop.png

# Laptop
cypress-cli resize 1366 768
cypress-cli screenshot --filename=laptop.png

# Tablet portrait
cypress-cli resize 768 1024
cypress-cli screenshot --filename=tablet.png

# Mobile
cypress-cli resize 375 812
cypress-cli screenshot --filename=mobile.png
```

```bash
# Bash automation loop
#!/bin/bash
set -euo pipefail

for vp in "1920:1080:desktop" "1366:768:laptop" "768:1024:tablet" "375:812:mobile"; do
  IFS=':' read -r w h name <<< "$vp"
  cypress-cli resize "$w" "$h"
  cypress-cli screenshot --filename="responsive-${name}.png"
done
```

```powershell
$viewports = @(
  @{ W = 1920; H = 1080; Name = "desktop" },
  @{ W = 1366; H = 768; Name = "laptop" },
  @{ W = 768; H = 1024; Name = "tablet" },
  @{ W = 375; H = 812; Name = "mobile" }
)

foreach ($vp in $viewports) {
  cypress-cli resize $vp.W $vp.H
  cypress-cli screenshot --filename="responsive-$($vp.Name).png"
}
```

## PDF Export

```bash
# Basic PDF
cypress-cli pdf --filename=report.pdf
```

```bash
# Print layout preview before export
cypress-cli run-code "() => {
  cy.window().then((win) => {
    win.dispatchEvent(new Event('beforeprint'));
  });
}"
cypress-cli screenshot --filename=print-preview.png
cypress-cli pdf --filename=print-output.pdf
```

Notes:
- PDF generation is browser/CLI implementation dependent.
- For strict Cypress-only projects, PDF is usually generated outside test runtime.

## Video Recording

```bash
cypress-cli video-start
cypress-cli open https://example.com
cypress-cli snapshot
cypress-cli click e1
cypress-cli fill e2 "test input"
cypress-cli click e5
cypress-cli video-stop recordings/login-flow.webm
```

Use video for:
- end-to-end failure reproduction
- stakeholder demos
- onboarding walkthroughs

## Common Patterns

### Before/After Visual Diff Inputs

```bash
cypress-cli screenshot --filename=before.png
cypress-cli click e5
cypress-cli screenshot --filename=after.png
```

### Light vs Dark Theme Capture

```bash
cypress-cli open https://example.com

# Light
cypress-cli run-code "() => {
  cy.document().then((doc) => {
    doc.documentElement.setAttribute('data-theme', 'light');
  });
}"
cypress-cli screenshot --filename=theme-light.png

# Dark
cypress-cli run-code "() => {
  cy.document().then((doc) => {
    doc.documentElement.setAttribute('data-theme', 'dark');
  });
}"
cypress-cli screenshot --filename=theme-dark.png
```

### Cross-Browser Capture (Cypress-Compatible Targets)

```bash
#!/bin/bash
set -euo pipefail

URL="https://example.com"
for browser in chrome firefox msedge electron; do
  cypress-cli -s=$browser open "$URL" --browser=$browser
  cypress-cli -s=$browser screenshot --filename="compare-${browser}.png"
done

cypress-cli close-all
```

```powershell
$url = "https://example.com"
foreach ($browser in @("chrome", "firefox", "msedge", "electron")) {
  cypress-cli -s=$browser open $url --browser=$browser
  cypress-cli -s=$browser screenshot --filename="compare-${browser}.png"
}

cypress-cli close-all
```

## Anti-Patterns

| Anti-pattern | Problem | Better pattern |
|---|---|---|
| Comparing screenshots from different viewport sizes | False visual diffs | Set explicit viewport before each capture |
| Leaving dynamic timestamps/ads visible in baselines | Noisy unstable diffs | Mask dynamic regions before capture |
| Recording long videos for every local run | Large artifacts and slower feedback | Keep video targeted to failing/critical flows |
| Generic artifact filenames (`image.png`) | Hard triage in CI artifacts | Use route/step-specific naming conventions |

## Tips

1. Set viewport before every screenshot when comparing layouts.
2. Use descriptive file names with route or step context.
3. Mask or hide dynamic content for deterministic diffs.
4. Capture screenshots at key checkpoints, not only at test end.
5. Keep video recording targeted; it increases runtime and artifact size.
