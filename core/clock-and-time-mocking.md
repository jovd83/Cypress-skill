# Clock and Time Mocking

> **When to use**: Any feature depending on timers, countdowns, expirations, schedules, or date-sensitive UI.
> **Prerequisites**: [assertions-and-waiting.md](assertions-and-waiting.md), [test-data-management.md](test-data-management.md)

## Core Cypress APIs

- `cy.clock(now?)` freezes timers and `Date`.
- `cy.tick(ms)` advances mocked time.
- `cy.clock(Date.UTC(...))` is useful for deterministic UTC baselines.

## Quick Reference

```typescript
it('expires session after 15 minutes', () => {
  cy.clock(new Date('2026-03-01T10:00:00Z').getTime());
  cy.visit('/dashboard');

  cy.findByText(/session active/i).should('be.visible');
  cy.tick(15 * 60 * 1000);
  cy.findByText(/session expired/i).should('be.visible');
});
```

## Pattern 1: Timeout and Countdown

```typescript
it('counts down from 30 seconds', () => {
  cy.clock();
  cy.visit('/otp');

  cy.findByTestId('countdown').should('have.text', '30');
  cy.tick(5000);
  cy.findByTestId('countdown').should('have.text', '25');

  cy.tick(25000);
  cy.findByRole('button', { name: /resend code/i }).should('be.enabled');
});
```

## Pattern 2: Expiration Banner

```typescript
it('trial banner changes after expiration date', () => {
  cy.clock(new Date('2026-03-01T12:00:00Z').getTime());
  cy.visit('/dashboard');
  cy.findByTestId('trial-banner').should('contain.text', '13 days remaining');

  cy.tick(14 * 24 * 60 * 60 * 1000);
  cy.reload();
  cy.findByText(/trial expired/i).should('be.visible');
});
```

## Pattern 3: Delayed UI Feedback

```typescript
it('hides toast after 4 seconds', () => {
  cy.clock();
  cy.visit('/settings');
  cy.findByRole('button', { name: /save/i }).click();
  cy.findByRole('status').should('contain.text', 'Saved');

  cy.tick(4000);
  cy.findByRole('status').should('not.exist');
});
```

## Pattern 4: Debounce Validation

```typescript
it('runs search after debounce delay', () => {
  cy.clock();
  cy.intercept('GET', '/api/search*').as('search');

  cy.visit('/products');
  cy.findByRole('searchbox', { name: /search/i }).type('keyboard');

  // Debounce not elapsed yet
  cy.tick(299);
  cy.get('@search.all').should('have.length', 0);

  // Debounce elapsed
  cy.tick(1);
  cy.wait('@search');
});
```

## Pattern 5: Scheduled Daily Behavior

```typescript
it('shows maintenance warning at configured time', () => {
  cy.clock(new Date('2026-06-01T01:55:00Z').getTime());
  cy.visit('/status');
  cy.findByText(/maintenance starts at 02:00/i).should('be.visible');

  cy.tick(5 * 60 * 1000);
  cy.findByText(/maintenance in progress/i).should('be.visible');
});
```

## Pattern 6: Date Picker Defaults

```typescript
it('opens date picker on mocked current month', () => {
  cy.clock(new Date('2026-07-04T10:00:00Z').getTime());
  cy.visit('/booking');
  cy.findByLabelText(/date/i).click();
  cy.findByText(/july 2026/i).should('be.visible');
});
```

## Timezone Guidance

Cypress does not provide per-test browser-context timezone control in this style. Prefer:

1. Storing timestamps in UTC.
2. Formatting dates in app code with explicit locale/timezone options.
3. Testing timezone-dependent formatting via deterministic input and expected output strings.

If you must run in a specific timezone, set environment/process timezone for the test run and keep assertions explicit.

## Anti-Patterns

| Anti-pattern | Why it fails | Better approach |
|---|---|---|
| Using real waits for timer flows (`cy.wait(30000)`) | Slow and flaky | Freeze clock and `cy.tick` |
| Calling `cy.clock` after app timers are already created | Timers may have fired with real time | Call `cy.clock` before `cy.visit` |
| Mocking only `Date.now` in ad-hoc code | Leaves `setTimeout` behavior uncontrolled | Use Cypress clock APIs |
| Testing timezone behavior with implicit local machine timezone | CI/local mismatch | Use explicit UTC fixtures and deterministic expected text |

## Troubleshooting

### Timers do not move when calling `cy.tick`

- Ensure `cy.clock` was called first.
- Ensure timer code runs after clock is installed.

### Date values still look real-time

- App may compute date on server side.
- Mock API response timestamps instead of only browser clock.

### Flaky countdown assertions

- Assert exact checkpoints after controlled ticks.
- Avoid mixed real-time and mocked-time expectations in one test.

## Related Guides

- [assertions-and-waiting.md](assertions-and-waiting.md)
- [search-and-filter.md](search-and-filter.md)
- [test-data-management.md](test-data-management.md)
