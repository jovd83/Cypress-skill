# React + Cypress

> **When to use**: Test React applications with Cypress for E2E flows, component behavior, routing, form interactions, and API-driven states.

## Recommended Coverage

1. E2E for user-critical journeys (auth, checkout, account management).
2. Component tests for isolated UI behavior and state transitions.
3. Network contract assertions via `cy.intercept()`.

## Quick Reference

```typescript
cy.intercept('GET', '**/api/me', { fixture: 'me-admin.json' }).as('me');
cy.visit('/dashboard');
cy.wait('@me');
cy.findByRole('heading', { name: 'Dashboard' }).should('be.visible');
```

## React E2E Example

### TypeScript

```typescript
it('logs in and opens dashboard', () => {
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
it('logs in and opens dashboard', () => {
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

## React Router Patterns

```typescript
it('navigates between routes', () => {
  cy.visit('/settings');
  cy.findByRole('link', { name: 'Billing' }).click();
  cy.location('pathname').should('include', '/billing');
  cy.findByRole('heading', { name: /billing/i }).should('be.visible');
});
```

## State and Data Loading

```typescript
it('shows empty state for projects list', () => {
  cy.intercept('GET', '**/api/projects', { statusCode: 200, body: [] }).as('projects');

  cy.visit('/projects');
  cy.wait('@projects');
  cy.findByText(/no projects yet/i).should('be.visible');
});

it('shows error fallback for failed request', () => {
  cy.intercept('GET', '**/api/projects', { statusCode: 500, body: { error: 'boom' } }).as('projects500');

  cy.visit('/projects');
  cy.wait('@projects500');
  cy.findByRole('alert').should('contain.text', 'Something went wrong');
});
```

## Form Handling (React Hook Form / Controlled Inputs)

```typescript
it('validates profile form', () => {
  cy.visit('/profile/edit');

  cy.findByRole('button', { name: /save/i }).click();
  cy.findByText('Display name is required').should('be.visible');

  cy.findByLabelText('Display name').clear().type('Jane Doe');
  cy.findByLabelText('Email').clear().type('jane@example.com');
  cy.findByRole('button', { name: /save/i }).click();

  cy.findByRole('status').should('contain.text', 'Saved');
});
```

## Component Testing (React)

Assuming Cypress Component Testing is configured.

```typescript
import { mount } from 'cypress/react';
import { UserBadge } from '../../src/components/UserBadge';

it('renders premium badge', () => {
  mount(<UserBadge user={{ name: 'Jane', isPremium: true }} />);
  cy.findByText('Jane').should('be.visible');
  cy.findByText('Premium').should('be.visible');
});
```

## React + Suspense / Loading UI

```typescript
it('shows loader then data', () => {
  cy.intercept('GET', '**/api/report', {
    statusCode: 200,
    delayMs: 1200,
    body: { title: 'Q1 Report' }
  }).as('report');

  cy.visit('/reports/q1');
  cy.findByTestId('loading-spinner').should('be.visible');
  cy.wait('@report');
  cy.findByTestId('loading-spinner').should('not.exist');
  cy.findByText('Q1 Report').should('be.visible');
});
```

## Anti-Patterns

- Using implementation selectors (`.MuiBox-root:nth-child(2)`).
- Asserting internal React state instead of visible behavior.
- Relying on `cy.wait(milliseconds)` for async React updates.
- Mixing non-Cypress APIs in Cypress specs.

## Related

- [core/component-testing.md](component-testing.md)
- [core/forms-and-validation.md](forms-and-validation.md)
- [core/network-mocking.md](network-mocking.md)
- [core/flaky-tests.md](flaky-tests.md)
