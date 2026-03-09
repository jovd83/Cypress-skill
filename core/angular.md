# Angular + Cypress

> **When to use**: Test Angular applications with Cypress for E2E workflows, reactive/template-driven forms, route guards, and component behavior.

## Coverage Strategy

1. E2E tests for primary user journeys and route transitions.
2. Component tests for isolated Angular component behavior.
3. API interception for deterministic asynchronous states.

## Quick Reference

```typescript
cy.intercept('GET', '**/api/profile').as('profile');
cy.visit('/profile');
cy.wait('@profile');
cy.findByRole('heading', { name: /profile/i }).should('be.visible');
```

## Angular E2E Example

### TypeScript

```typescript
it('logs in and reaches dashboard', () => {
  cy.intercept('POST', '**/api/login').as('login');
  cy.intercept('GET', '**/api/me').as('me');

  cy.visit('/login');
  cy.findByLabelText('Email').clear().type('admin@example.com');
  cy.findByLabelText('Password').clear().type('secure-password');
  cy.findByRole('button', { name: 'Sign In' }).click();

  cy.wait('@login').its('response.statusCode').should('eq', 200);
  cy.wait('@me').its('response.statusCode').should('eq', 200);
  cy.location('pathname').should('include', '/dashboard');
});
```

### JavaScript

```javascript
it('logs in and reaches dashboard', () => {
  cy.intercept('POST', '**/api/login').as('login');
  cy.intercept('GET', '**/api/me').as('me');

  cy.visit('/login');
  cy.findByLabelText('Email').clear().type('admin@example.com');
  cy.findByLabelText('Password').clear().type('secure-password');
  cy.findByRole('button', { name: 'Sign In' }).click();

  cy.wait('@login').its('response.statusCode').should('eq', 200);
  cy.wait('@me').its('response.statusCode').should('eq', 200);
  cy.location('pathname').should('include', '/dashboard');
});
```

## Route Guards and Authorization

```typescript
it('redirects unauthenticated users from guarded route', () => {
  cy.intercept('GET', '**/api/me', { statusCode: 401, body: { error: 'Unauthorized' } }).as('me401');

  cy.visit('/admin');
  cy.wait('@me401');
  cy.location('pathname').should('match', /\/login$/);
});
```

## Reactive Forms Validation

```typescript
it('validates registration reactive form', () => {
  cy.visit('/register');

  cy.findByRole('button', { name: /create account/i }).click();
  cy.findByText('Email is required').should('be.visible');

  cy.findByLabelText('Email').clear().type('invalid').blur();
  cy.findByText('Please enter a valid email').should('be.visible');

  cy.findByLabelText('Email').clear().type('valid@example.com').blur();
  cy.findByText('Please enter a valid email').should('not.exist');
});
```

## Async Validators

```typescript
it('shows username availability feedback', () => {
  cy.intercept('GET', '**/api/username/check*', {
    statusCode: 200,
    body: { available: false }
  }).as('usernameCheck');

  cy.visit('/register');
  cy.findByLabelText('Username').clear().type('admin').blur();

  cy.wait('@usernameCheck');
  cy.findByText('Username is already taken').should('be.visible');
});
```

## Component Testing (Angular)

Assuming Cypress Angular component testing is configured.

```typescript
import { mount } from 'cypress/angular';
import { CounterComponent } from '../../src/app/counter/counter.component';

it('increments counter', () => {
  mount(CounterComponent, {
    componentProperties: { count: 0 }
  });

  cy.findByRole('button', { name: /increment/i }).click();
  cy.findByText('1').should('be.visible');
});
```

## HTTP Error Handling in Angular UI

```typescript
it('shows retry UI when API fails', () => {
  cy.intercept('GET', '**/api/invoices', {
    statusCode: 500,
    body: { error: 'Internal server error' }
  }).as('invoices500');

  cy.visit('/billing/invoices');
  cy.wait('@invoices500');

  cy.findByRole('alert').should('contain.text', 'Something went wrong');
  cy.findByRole('button', { name: /retry/i }).should('be.visible');
});
```

## Anti-Patterns

- Using generated Angular classes in selectors.
- Asserting internal Angular form control state instead of visible validation messages.
- Time-based waits for HTTP/zone stabilization.
- Mixing component concerns and full journey concerns in one test.

## Related

- [core/forms-and-validation.md](forms-and-validation.md)
- [core/network-mocking.md](network-mocking.md)
- [core/component-testing.md](component-testing.md)
- [core/test-organization.md](test-organization.md)
