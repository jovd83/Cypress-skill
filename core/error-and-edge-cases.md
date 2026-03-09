# Error States and Edge Cases

> **When to use**: Validate resilience when APIs fail, data is missing, input is invalid, or user behavior is unexpected.

## Golden Rules

1. Cover happy path first, then one edge case per test.
2. Use `cy.intercept()` to model failures deterministically.
3. Assert visible recovery behavior (retry, error text, fallback UI).
4. Verify state recovery after errors.

## Quick Reference

```typescript
// 500 error
cy.intercept('GET', '**/api/dashboard', { statusCode: 500, body: { error: 'Internal server error' } }).as('dashboard500');

// network failure
cy.intercept('POST', '**/api/save', { forceNetworkError: true }).as('saveFail');

// empty state
cy.intercept('GET', '**/api/items', { statusCode: 200, body: [] }).as('emptyItems');
```

## HTTP Errors

### TypeScript

```typescript
it('shows fallback UI on 500', () => {
  cy.intercept('GET', '**/api/dashboard', {
    statusCode: 500,
    body: { error: 'Internal server error' }
  }).as('dashboard500');

  cy.visit('/dashboard');
  cy.wait('@dashboard500');

  cy.findByRole('alert').should('contain.text', 'Something went wrong');
  cy.findByRole('button', { name: /try again/i }).should('be.visible');
});
```

### JavaScript

```javascript
it('shows fallback UI on 500', () => {
  cy.intercept('GET', '**/api/dashboard', {
    statusCode: 500,
    body: { error: 'Internal server error' }
  }).as('dashboard500');

  cy.visit('/dashboard');
  cy.wait('@dashboard500');

  cy.findByRole('alert').should('contain.text', 'Something went wrong');
  cy.findByRole('button', { name: /try again/i }).should('be.visible');
});
```

## Authorization and Session Edge Cases

```typescript
it('handles 401 by redirecting to login', () => {
  cy.intercept('GET', '**/api/profile', { statusCode: 401, body: { error: 'Unauthorized' } }).as('profile401');

  cy.visit('/profile');
  cy.wait('@profile401');
  cy.location('pathname').should('match', /\/login$/);
});

it('handles 403 with access denied view', () => {
  cy.intercept('GET', '**/api/admin/**', { statusCode: 403, body: { error: 'Forbidden' } }).as('admin403');

  cy.visit('/admin/settings');
  cy.wait('@admin403');
  cy.findByText(/access denied|not authorized/i).should('be.visible');
});
```

## Network Failure and Retry

```typescript
it('shows retry CTA on network drop', () => {
  cy.intercept('POST', '**/api/contact', { forceNetworkError: true }).as('contactFail');

  cy.visit('/contact');
  cy.findByLabelText('Name').clear().type('Jane Doe');
  cy.findByLabelText('Email').clear().type('jane@example.com');
  cy.findByLabelText('Message').clear().type('Need support');
  cy.findByRole('button', { name: /send message/i }).click();

  cy.wait('@contactFail');
  cy.findByRole('alert').should('contain.text', 'Network error');
  cy.findByRole('button', { name: /retry/i }).should('be.visible');
});

it('recovers after transient 503', () => {
  let attempts = 0;
  cy.intercept('GET', '**/api/users', (req) => {
    attempts += 1;
    if (attempts <= 2) {
      req.reply({ statusCode: 503, body: { error: 'Service unavailable' } });
      return;
    }
    req.reply({ statusCode: 200, body: [{ id: 1, name: 'Alice' }] });
  }).as('users');

  cy.visit('/users');
  cy.wait('@users');
  cy.wait('@users');
  cy.wait('@users');
  cy.findByRole('row', { name: /alice/i }).should('be.visible');
});
```

## Empty, Partial, and Corrupt Data

```typescript
it('shows empty state when API returns empty array', () => {
  cy.intercept('GET', '**/api/orders', { statusCode: 200, body: [] }).as('orders');
  cy.visit('/orders');
  cy.wait('@orders');
  cy.findByText(/no orders yet/i).should('be.visible');
});

it('handles partial payload without crashing', () => {
  cy.intercept('GET', '**/api/profile', {
    statusCode: 200,
    body: { id: 'u1', name: null, email: 'user@example.com' }
  }).as('profile');

  cy.visit('/profile');
  cy.wait('@profile');
  cy.findByText(/unknown user/i).should('be.visible');
});
```

## Input Boundaries and Invalid Data

```typescript
it('validates boundary lengths', () => {
  cy.visit('/settings');

  cy.findByLabelText('Display name').clear().type('A'.repeat(256));
  cy.findByRole('button', { name: /save/i }).click();
  cy.findByText(/must be 255 characters or less/i).should('be.visible');

  cy.findByLabelText('Display name').clear().type('Valid Name');
  cy.findByRole('button', { name: /save/i }).click();
  cy.findByRole('status').should('contain.text', 'Saved');
});

it('rejects invalid email format before submit', () => {
  cy.visit('/contact');
  cy.findByLabelText('Email').clear().type('invalid').blur();
  cy.findByText(/please enter a valid email/i).should('be.visible');
});
```

## Multi-Step Form Failures

```typescript
it('keeps user on payment step when card is declined', () => {
  cy.intercept('POST', '**/api/payments', {
    statusCode: 402,
    body: { error: 'Card declined' }
  }).as('payment');

  cy.visit('/checkout/payment');
  cy.findByLabelText('Card number').clear().type('4000000000000002');
  cy.findByLabelText('Expiration').clear().type('12/28');
  cy.findByLabelText('CVC').clear().type('123');
  cy.findByRole('button', { name: /pay now/i }).click();

  cy.wait('@payment');
  cy.location('pathname').should('include', '/checkout/payment');
  cy.findByRole('alert').should('contain.text', 'Card declined');
});
```

## Navigation and Recovery Edge Cases

```typescript
it('preserves unsaved changes warning on back navigation', () => {
  cy.visit('/editor');
  cy.findByLabelText('Title').clear().type('Draft post');

  cy.on('window:confirm', (text) => {
    expect(text).to.match(/unsaved changes/i);
    return false; // cancel navigation
  });

  cy.go('back');
  cy.location('pathname').should('include', '/editor');
});
```

## Anti-Patterns

- Only checking status codes and not user-visible behavior.
- Packing multiple unrelated edge cases into one test.
- Using static waits to "stabilize" failures.
- Simulating impossible server responses that your app never receives.

## Related

- [core/network-mocking.md](network-mocking.md)
- [core/forms-and-validation.md](forms-and-validation.md)
- [core/flaky-tests.md](flaky-tests.md)
- [core/assertions-and-waiting.md](assertions-and-waiting.md)
