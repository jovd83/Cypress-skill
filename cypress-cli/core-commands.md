# Core Commands

> **When to use**: Start sessions, navigate pages, interact with elements, and perform baseline browser automation from the CLI.
> **Prerequisites**: `cypress-cli install --skills` and `cypress-cli install-browser`

## Quick Reference

```bash
cypress-cli open https://example.com
cypress-cli snapshot
cypress-cli fill e1 "user@example.com"
cypress-cli click e3
cypress-cli screenshot --filename=home.png
cypress-cli close
```

## Snapshot Workflow

Always take a snapshot before interacting. Refs (`e1`, `e2`, ...) are bound to the current DOM state.

```bash
cypress-cli open https://example.com/login
cypress-cli snapshot
# e1 [textbox "Email"]
# e2 [textbox "Password"]
# e3 [button "Sign In"]

cypress-cli fill e1 "user@example.com"
cypress-cli fill e2 "secret"
cypress-cli click e3

# DOM changed after submit -> refresh refs
cypress-cli snapshot
```

## Open and Close

```bash
# Open blank or with URL
cypress-cli open
cypress-cli open https://example.com

# Browser choice (Cypress-supported targets)
cypress-cli open --browser=chrome
cypress-cli open --browser=firefox
cypress-cli open --browser=msedge
cypress-cli open --browser=electron

# Persistence
cypress-cli open https://example.com --persistent
cypress-cli open https://example.com --profile=/tmp/my-profile

# Cleanup
cypress-cli close
cypress-cli close-all
cypress-cli kill-all
cypress-cli delete-data
```

## Navigation

```bash
cypress-cli goto https://example.com/dashboard
cypress-cli go-back
cypress-cli go-forward
cypress-cli reload
```

### Wait for Navigation Safely

```bash
# URL assertion
cypress-cli run-code "() => {
  cy.location('pathname').should('include', '/dashboard');
}"

# API-driven settle check
cypress-cli run-code "() => {
  cy.intercept('GET', '**/api/dashboard').as('dashboard');
  cy.wait('@dashboard');
}"
```

## Element Interaction

```bash
# Clicks
cypress-cli click e3
cypress-cli dblclick e7
cypress-cli hover e4

# Form controls
cypress-cli fill e5 "user@example.com"
cypress-cli type "search query"
cypress-cli select e9 "option-value"
cypress-cli check e12
cypress-cli uncheck e12

# Files and drag/drop
cypress-cli upload e8 ./document.pdf
cypress-cli drag e2 e8
```

## Keyboard and Mouse

```bash
# Key presses
cypress-cli press Enter
cypress-cli press Escape
cypress-cli press ArrowDown

# Modifiers
cypress-cli keydown Shift
cypress-cli click e5
cypress-cli keyup Shift

# Mouse primitives
cypress-cli mousemove 150 300
cypress-cli mousedown
cypress-cli mouseup
cypress-cli mousewheel 0 100
```

## Dialog Handling

```bash
cypress-cli dialog-accept
cypress-cli dialog-accept "my response"
cypress-cli dialog-dismiss
```

```bash
# Optional pre-hook for window dialogs
cypress-cli run-code "() => {
  cy.on('window:confirm', () => true);
  cy.on('window:alert', (text) => console.log('[alert]', text));
}"
```

## JavaScript Evaluation

```bash
cypress-cli eval "document.title"
cypress-cli eval "window.location.href"
cypress-cli eval "document.querySelectorAll('li').length"

# Evaluate against a specific ref
cypress-cli eval "el => el.textContent" e5
cypress-cli eval "el => el.getAttribute('href')" e3
```

## Example Flows

### Login

```bash
cypress-cli open https://app.example.com/login
cypress-cli snapshot
cypress-cli fill e1 "admin@example.com"
cypress-cli fill e2 "password123"
cypress-cli click e3
cypress-cli snapshot
cypress-cli screenshot --filename=dashboard.png
```

### Search

```bash
cypress-cli open https://example.com
cypress-cli snapshot
cypress-cli fill e1 "cypress automation"
cypress-cli press Enter
cypress-cli snapshot
cypress-cli click e5
```

## Anti-Patterns

| Anti-pattern | Problem | Better pattern |
|---|---|---|
| Interacting without `snapshot` | Wrong or stale refs (`e1`, `e2`, ...) | Snapshot before each interaction block |
| Reusing old refs after navigation/rerender | Commands target outdated DOM nodes | Re-run `snapshot` after state-changing actions |
| Using `run-code` for basic click/fill/select | Harder to maintain and debug | Prefer first-class CLI commands |
| Forgetting session/process cleanup | Zombie sessions and inconsistent runs | Use `close`, `close-all`, `kill-all` explicitly |

## Best Practices

1. Re-snapshot after every navigation, modal open/close, or large DOM update.
2. Prefer semantic locators from snapshots over brittle CSS selectors.
3. Keep selectors test-friendly (`data-cy`, roles, labels).
4. Avoid forcing interactions when elements are hidden/disabled.
5. Use `run-code` only when command primitives are insufficient.

## Troubleshooting

### Refs point at the wrong element

- Run `cypress-cli snapshot` again after any navigation, rerender, modal change, or tab switch.
- Do not reuse refs captured before a major DOM change.
- Prefer smaller interaction batches with a fresh snapshot between them.

### Click or fill fails even though the element looks visible

- Re-snapshot and confirm the current ref still maps to the intended element.
- Check whether an overlay, disabled state, or scroll position is blocking actionability.
- Use `run-code` only if the workflow genuinely needs Cypress-level assertions or setup.

### Browser processes stay open after scripts

- Close the current session with `cypress-cli close`.
- Use `cypress-cli close-all` for multi-session cleanup.
- Use `cypress-cli kill-all` only when normal shutdown fails.

## Related

- [request-mocking.md](request-mocking.md)
- [session-management.md](session-management.md)
- [running-custom-code.md](running-custom-code.md)
- [debugging-and-artifacts.md](debugging-and-artifacts.md)
