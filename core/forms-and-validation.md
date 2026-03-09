# Forms and Validation

> **When to use**: Test user input flows, client/server validation, multi-step forms, and submission behavior using Cypress v13+.

## Golden Rules

1. Prefer semantic selectors (`findByLabelText`, `findByRole`) over CSS chains.
2. Use `.clear().type(...)` for text fields.
3. Use `.select(...)` for native `<select>` and `.check()` for checkboxes/radios.
4. Assert both error state and recovery state.
5. Use `cy.intercept()` to stabilize async/server validation paths.

## Quick Reference

```typescript
// Text
cy.findByLabelText('Email').clear().type('jane@example.com');

// Select
cy.findByLabelText('Country').select('US');

// Checkbox and radio
cy.findByLabelText('Accept terms').check();
cy.findByLabelText('Express shipping').check();

// Date/time inputs
cy.findByLabelText('Start date').clear().type('2026-03-15');
cy.findByLabelText('Start time').clear().type('14:30');

// Submit + assert
cy.findByRole('button', { name: 'Submit' }).click();
cy.findByRole('status').should('contain.text', 'Saved');
```

## Basic Form Fill Patterns

### TypeScript

```typescript
it('submits registration form', () => {
  cy.visit('/register');

  cy.findByLabelText('First name').clear().type('Jane');
  cy.findByLabelText('Last name').clear().type('Doe');
  cy.findByLabelText('Email').clear().type('jane@example.com');
  cy.findByLabelText('Password', { exact: true }).clear().type('Str0ngP@ss!');
  cy.findByLabelText('Confirm password').clear().type('Str0ngP@ss!');

  cy.findByLabelText('Country').select('US');
  cy.findByLabelText('Accept terms').check();

  cy.findByRole('button', { name: 'Create account' }).click();
  cy.url().should('include', '/welcome');
});
```

### JavaScript

```javascript
it('submits registration form', () => {
  cy.visit('/register');

  cy.findByLabelText('First name').clear().type('Jane');
  cy.findByLabelText('Last name').clear().type('Doe');
  cy.findByLabelText('Email').clear().type('jane@example.com');
  cy.findByLabelText('Password', { exact: true }).clear().type('Str0ngP@ss!');
  cy.findByLabelText('Confirm password').clear().type('Str0ngP@ss!');

  cy.findByLabelText('Country').select('US');
  cy.findByLabelText('Accept terms').check();

  cy.findByRole('button', { name: 'Create account' }).click();
  cy.url().should('include', '/welcome');
});
```

## Client-Side Validation

### Required Fields

```typescript
it('shows required errors and clears them after input', () => {
  cy.visit('/contact');

  cy.findByRole('button', { name: 'Send message' }).click();
  cy.findByText('Name is required').should('be.visible');
  cy.findByText('Email is required').should('be.visible');

  cy.findByLabelText('Name').clear().type('Jane Doe').blur();
  cy.findByText('Name is required').should('not.exist');
});
```

### Format Validation (Email)

```typescript
it('validates email format', () => {
  cy.visit('/register');

  cy.findByLabelText('Email').clear().type('invalid-email').blur();
  cy.findByText('Please enter a valid email').should('be.visible');

  cy.findByLabelText('Email').clear().type('valid@example.com').blur();
  cy.findByText('Please enter a valid email').should('not.exist');
});
```

### Password Rules

```typescript
it('validates password policy', () => {
  cy.visit('/register');

  cy.findByLabelText('Password', { exact: true }).clear().type('abc').blur();
  cy.findByText('At least 8 characters').should('be.visible');

  cy.findByLabelText('Password', { exact: true }).clear().type('abcdefg1!').blur();
  cy.findByText('At least one uppercase letter').should('be.visible');

  cy.findByLabelText('Password', { exact: true }).clear().type('Str0ngP@ss!').blur();
  cy.findByText(/At least/).should('not.exist');
});
```

## Async and Server Validation

### Form Submit API Validation

```typescript
it('shows server-side email already taken error', () => {
  cy.intercept('POST', '**/api/register', {
    statusCode: 409,
    body: { error: 'Email already in use' }
  }).as('register');

  cy.visit('/register');
  cy.findByLabelText('Email').clear().type('taken@example.com');
  cy.findByLabelText('Password', { exact: true }).clear().type('ValidP@ss1');
  cy.findByRole('button', { name: 'Register' }).click();

  cy.wait('@register');
  cy.findByRole('alert').should('contain.text', 'Email already in use');
});
```

### Live Field Validation (Debounced)

```typescript
it('validates username availability while typing', () => {
  cy.intercept('GET', '**/api/username/check*', {
    statusCode: 200,
    body: { available: false }
  }).as('checkUsername');

  cy.visit('/register');
  cy.findByLabelText('Username').clear().type('jane');
  cy.wait('@checkUsername');
  cy.findByText('Username is already taken').should('be.visible');
});
```

## Multi-Step Forms

```typescript
it('completes checkout wizard', () => {
  cy.intercept('POST', '**/api/orders').as('createOrder');
  cy.visit('/checkout');

  // Step 1: Shipping
  cy.findByLabelText('Address').clear().type('123 Main St');
  cy.findByLabelText('City').clear().type('Portland');
  cy.findByLabelText('State').select('OR');
  cy.findByLabelText('ZIP code').clear().type('97201');
  cy.findByRole('button', { name: 'Continue' }).click();

  // Step 2: Payment
  cy.findByLabelText('Card number').clear().type('4242424242424242');
  cy.findByLabelText('Expiration').clear().type('12/28');
  cy.findByLabelText('CVC').clear().type('123');
  cy.findByRole('button', { name: 'Continue' }).click();

  // Step 3: Review + submit
  cy.findByRole('button', { name: 'Place order' }).click();
  cy.wait('@createOrder').its('response.statusCode').should('be.oneOf', [200, 201]);
  cy.findByText('Order confirmed').should('be.visible');
});
```

## Reset and Cancel Behavior

```typescript
it('resets form to defaults', () => {
  cy.visit('/settings');

  cy.findByLabelText('Display name').clear().type('New Name');
  cy.findByLabelText('Theme').select('dark');
  cy.findByLabelText('Notifications').uncheck();

  cy.findByRole('button', { name: 'Reset' }).click();

  cy.findByLabelText('Display name').should('have.value', 'Jane Doe');
  cy.findByLabelText('Theme').should('have.value', 'light');
  cy.findByLabelText('Notifications').should('be.checked');
});
```

## Accessibility Checks for Forms

```typescript
it('links validation errors to fields', () => {
  cy.visit('/contact');
  cy.findByRole('button', { name: 'Send message' }).click();

  cy.findByLabelText('Email')
    .should('have.attr', 'aria-invalid', 'true')
    .and('have.attr', 'aria-describedby');

  cy.findByRole('alert').should('contain.text', 'Email is required');
});
```

## Anti-Patterns

- `cy.findByLabelText('Email').type('x')` without `.clear()` when editing existing values.
- Using CSS index selectors for fields that have labels.
- Large monolithic "all validation in one test" specs that are hard to debug.
- `cy.wait(2000)` for validation timing instead of waiting on observable UI/network signals.
- Mixing non-Cypress APIs with Cypress command queue patterns.

## Related

- [core/locators.md](locators.md)
- [core/assertions-and-waiting.md](assertions-and-waiting.md)
- [core/network-mocking.md](network-mocking.md)
- [core/error-and-edge-cases.md](error-and-edge-cases.md)
