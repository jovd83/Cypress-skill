# Advanced Workflows

> **When to use**: Multi-step browser automation, multi-session test flows, bulk data extraction, resilient form wizards, and recovery-driven CLI runs.
> **Prerequisites**: [core-commands.md](core-commands.md), [running-custom-code.md](running-custom-code.md), [session-management.md](session-management.md), [request-mocking.md](request-mocking.md)

## Quick Reference

```bash
# Prepare output folders
mkdir -p ./states ./artifacts

# 1) Start a session and log in
cypress-cli -s=admin open https://app.example.com/login
cypress-cli -s=admin snapshot
cypress-cli -s=admin fill e1 "admin@example.com"
cypress-cli -s=admin fill e2 "password123"
cypress-cli -s=admin click e3

# 2) Save auth for reuse
cypress-cli -s=admin state-save ./states/admin.json

# 3) Open another isolated user session
cypress-cli -s=user open https://app.example.com
cypress-cli -s=user state-load ./states/user.json

# 4) Capture evidence
cypress-cli -s=admin screenshot --filename=admin-dashboard.png
cypress-cli -s=user screenshot --filename=user-dashboard.png
```

## Capability and Limits

| Workflow capability | Primary commands | Status | Notes |
|---|---|---|---|
| Multi-role isolated sessions | `-s=<name>`, `state-save`, `state-load` | Supported | Best for admin/user verification without shared state bleed. |
| New tab checks | `tab-new`, `tab-select`, `tab-list` | Partial | Browser/runtime dependent; verify post-action app state, not tab internals only. |
| Inline custom logic | `run-code`, `eval` | Supported | Keep queue-safe Cypress patterns and avoid `await cy...`. |
| Long-flow evidence | `screenshot`, `video-start`, `video-stop`, `console`, `network` | Supported | Use targeted artifact capture to avoid oversized outputs. |
| PDF and print-style artifacts | `pdf` | Partial | Depends on CLI/browser implementation details. |

## Multi-Session Workflows

### Two-Role Verification (Admin vs User)

Use this when one role performs an action and another role validates visibility.

```bash
# Admin session
cypress-cli -s=admin open https://app.example.com/login
cypress-cli -s=admin snapshot
cypress-cli -s=admin fill e1 "admin@example.com"
cypress-cli -s=admin fill e2 "password123"
cypress-cli -s=admin click e3

# User session
cypress-cli -s=user open https://app.example.com/login
cypress-cli -s=user snapshot
cypress-cli -s=user fill e1 "user@example.com"
cypress-cli -s=user fill e2 "password123"
cypress-cli -s=user click e3

# Admin creates announcement
cypress-cli -s=admin goto https://app.example.com/admin/announcements/new
cypress-cli -s=admin snapshot
cypress-cli -s=admin fill e1 "Scheduled Maintenance"
cypress-cli -s=admin fill e2 "Maintenance starts at 22:00 UTC"
cypress-cli -s=admin click e3

# User verifies announcement
cypress-cli -s=user goto https://app.example.com/dashboard
cypress-cli -s=user snapshot
cypress-cli -s=user eval "Array.from(document.querySelectorAll('body *')).some(n => n.textContent && n.textContent.includes('Scheduled Maintenance'))"
```

### Session Reuse Across Runs

```bash
# Save once after successful login
cypress-cli -s=qa state-save ./states/qa-auth.json

# Restore in future runs
cypress-cli -s=qa open https://app.example.com
cypress-cli -s=qa state-load ./states/qa-auth.json
cypress-cli -s=qa goto https://app.example.com/protected
```

## Tabs and Popup-Like Navigation

### New Tab Validation

```bash
cypress-cli open https://app.example.com/reports
cypress-cli snapshot

# Open a second tab and validate destination content
cypress-cli tab-new https://app.example.com/help
cypress-cli tab-list
cypress-cli tab-select 1
cypress-cli snapshot
cypress-cli eval "document.title"

# Return to original tab
cypress-cli tab-select 0
```

### External Auth Redirect Validation (Without Controlling Provider UI)

Use this when SSO provider pages are external and should not be scripted directly in CI.

```bash
# Intercept app callback endpoint to keep flow deterministic
cypress-cli route "**/api/auth/callback/**" '{"status":200,"body":{"ok":true}}'

cypress-cli open https://app.example.com/login
cypress-cli snapshot
cypress-cli click e4

# Validate app post-auth state
cypress-cli snapshot
cypress-cli eval "window.location.pathname"
```

## Bulk Data Extraction

### Paginated Extraction Script

```bash
#!/bin/bash
set -euo pipefail

BASE_URL="https://example.com/products?page="
OUT="./artifacts/products.jsonl"
mkdir -p ./artifacts
: > "$OUT"

cypress-cli -s=scraper open "${BASE_URL}1"

for page in 1 2 3 4 5; do
  cypress-cli -s=scraper goto "${BASE_URL}${page}"
  cypress-cli -s=scraper eval "JSON.stringify(Array.from(document.querySelectorAll('.product-card')).map(card => ({ name: card.querySelector('.name')?.textContent?.trim(), price: card.querySelector('.price')?.textContent?.trim() })))" >> "$OUT"
done

echo "Wrote data to $OUT"
```

```powershell
$BaseUrl = "https://example.com/products?page="
$Out = "./artifacts/products.jsonl"
New-Item -ItemType Directory -Path ./artifacts -Force | Out-Null
Set-Content -LiteralPath $Out -Value ""

cypress-cli -s=scraper open "${BaseUrl}1"

foreach ($page in 1..5) {
  cypress-cli -s=scraper goto "${BaseUrl}${page}"
  cypress-cli -s=scraper eval "JSON.stringify(Array.from(document.querySelectorAll('.product-card')).map(card => ({ name: card.querySelector('.name')?.textContent?.trim(), price: card.querySelector('.price')?.textContent?.trim() })))" |
    Add-Content -LiteralPath $Out
}

Write-Host "Wrote data to $Out"
```

### Structured Metadata Extraction (JSON-LD)

```bash
cypress-cli open https://example.com/article/42
cypress-cli eval "Array.from(document.querySelectorAll('script[type=\"application/ld+json\"]')).map(s => s.textContent)"
```

## File and Media Workflows

### Upload Sequence in Multi-Step Wizard

```bash
cypress-cli open https://app.example.com/apply
cypress-cli snapshot

# Step 1
cypress-cli fill e1 "Jane"
cypress-cli fill e2 "Doe"
cypress-cli fill e3 "jane@example.com"
cypress-cli click e4

# Step 2
cypress-cli snapshot
cypress-cli upload e2 ./artifacts/resume.pdf
cypress-cli upload e3 ./artifacts/cover-letter.pdf
cypress-cli click e5

# Step 3 + evidence
cypress-cli snapshot
cypress-cli screenshot --filename=application-review.png
```

### Visual Baseline Loop

```bash
for route in / /pricing /docs; do
  safe=$(echo "$route" | sed 's#[/ ]#_#g')
  cypress-cli open "https://app.example.com$route"
  cypress-cli screenshot --filename="baseline${safe}.png"
done
```

```powershell
$routes = @("/", "/pricing", "/docs")
foreach ($route in $routes) {
  $safe = $route -replace "[/ ]", "_"
  cypress-cli open "https://app.example.com$route"
  cypress-cli screenshot --filename="baseline${safe}.png"
}
```

## Accessibility-Focused Checks

### Missing Accessible Names on Inputs

```bash
cypress-cli open https://app.example.com/signup
cypress-cli eval "Array.from(document.querySelectorAll('input,textarea,select')).filter(el => { const hasLabel = !!el.labels?.length; const aria = el.getAttribute('aria-label') || el.getAttribute('aria-labelledby'); return !hasLabel && !aria; }).map(el => ({ tag: el.tagName, id: el.id, name: el.getAttribute('name') }))"
```

### Landmark and Heading Sanity

```bash
cypress-cli eval "({ landmarks: Array.from(document.querySelectorAll('main,nav,aside,header,footer')).length, h1Count: document.querySelectorAll('h1').length })"
```

## Form Wizard Automation

### Deterministic Step-By-Step Pattern

```bash
cypress-cli open https://app.example.com/registration

# Step 1
cypress-cli snapshot
cypress-cli fill e1 "Acme Corp"
cypress-cli fill e2 "12-3456789"
cypress-cli select e3 "business"
cypress-cli click e4

# Step 2
cypress-cli snapshot
cypress-cli fill e1 "Jane Doe"
cypress-cli fill e2 "jane@acme.com"
cypress-cli check e3
cypress-cli click e4

# Final review
cypress-cli snapshot
cypress-cli screenshot --filename=registration-review.png
```

## Recovery and Stability Patterns

### Banner/Modal Dismissal Guard

```bash
cypress-cli run-code "() => {
  const selectors = [
    '[data-testid=\"cookie-accept\"]',
    '.cookie-banner button.accept',
    '[aria-label=\"Close\"]'
  ];

  cy.get('body').then(($body) => {
    let dismissed = null;
    selectors.some((sel) => {
      const el = $body.find(sel).first();
      if (el.length) {
        cy.wrap(el).click();
        dismissed = sel;
        return true;
      }
      return false;
    });
    console.log({ dismissed });
  });
}"
```

### Retry Wrapper for Unstable Page Sections

```bash
#!/bin/bash
set -euo pipefail

attempt=1
max=3

until [ "$attempt" -gt "$max" ]; do
  echo "Attempt $attempt/$max"
  if cypress-cli open https://app.example.com/flaky-dashboard \
    && cypress-cli snapshot \
    && cypress-cli eval "!!document.querySelector('[data-testid=\"dashboard-ready\"]')"; then
    echo "Ready"
    exit 0
  fi
  attempt=$((attempt + 1))
  sleep 2
done

echo "Dashboard never stabilized" >&2
exit 1
```

```powershell
$attempt = 1
$max = 3

while ($attempt -le $max) {
  Write-Host "Attempt $attempt/$max"
  cypress-cli open https://app.example.com/flaky-dashboard
  cypress-cli snapshot
  $ready = cypress-cli eval "!!document.querySelector('[data-testid=\"dashboard-ready\"]')"
  if ($ready -match "true") {
    Write-Host "Ready"
    exit 0
  }
  $attempt++
  Start-Sleep -Seconds 2
}

Write-Error "Dashboard never stabilized"
exit 1
```

## Full Workflow Example

```bash
#!/bin/bash
set -euo pipefail

mkdir -p ./artifacts

# 1) Launch and restore auth
cypress-cli -s=e2e open https://app.example.com
cypress-cli -s=e2e state-load ./states/e2e-auth.json

# 2) Start diagnostics
cypress-cli -s=e2e console error
cypress-cli -s=e2e network
cypress-cli -s=e2e video-start

# 3) Execute flow
cypress-cli -s=e2e goto https://app.example.com/orders/new
cypress-cli -s=e2e snapshot
cypress-cli -s=e2e fill e1 "Enterprise Plan"
cypress-cli -s=e2e click e2

# 4) Validate + capture
cypress-cli -s=e2e snapshot
cypress-cli -s=e2e screenshot --filename=order-created.png

# 5) Stop recording and cleanup
cypress-cli -s=e2e video-stop artifacts/e2e-flow.webm
cypress-cli close-all
```

```powershell
New-Item -ItemType Directory -Path ./artifacts -Force | Out-Null

# 1) Launch and restore auth
cypress-cli -s=e2e open https://app.example.com
cypress-cli -s=e2e state-load ./states/e2e-auth.json

# 2) Start diagnostics
cypress-cli -s=e2e console error
cypress-cli -s=e2e network
cypress-cli -s=e2e video-start

# 3) Execute flow
cypress-cli -s=e2e goto https://app.example.com/orders/new
cypress-cli -s=e2e snapshot
cypress-cli -s=e2e fill e1 "Enterprise Plan"
cypress-cli -s=e2e click e2

# 4) Validate + capture
cypress-cli -s=e2e snapshot
cypress-cli -s=e2e screenshot --filename=order-created.png

# 5) Stop recording and cleanup
cypress-cli -s=e2e video-stop artifacts/e2e-flow.webm
cypress-cli close-all
```

## Anti-Patterns

| Anti-pattern | Problem | Better pattern |
|---|---|---|
| One monolithic script without checkpoints | Hard to isolate failure step | Add snapshots/screenshots per stage |
| Reusing one auth state file across roles/environments | State bleed and false positives | Keep role- and environment-specific state files |
| Automating third-party SSO provider UIs directly in CI | Cross-origin instability | Validate app callback behavior with deterministic stubs |
| Ending scripts without cleanup | Session/process leaks | Always run `close`/`close-all` and artifact cleanup |

## Tips

1. Re-run `snapshot` after every navigation or modal transition.
2. Use named sessions for parallel role checks.
3. Save and reload state files to avoid repeated login overhead.
4. Keep scraping and extraction scripts idempotent and file-backed.
5. Capture screenshots at each critical checkpoint, not only at the end.
6. Create artifact/state directories up front so first-run scripts do not fail on missing paths.
