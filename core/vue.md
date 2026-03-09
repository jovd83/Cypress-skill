# Vue + Cypress

> **When to use**: Test Vue applications (Vue 3/2) with Cypress for E2E flows, component behavior, reactivity updates, and API-driven UI states.

## Coverage Strategy

1. E2E for user journeys and router flows.
2. Component tests for props/events/slots/state rendering.
3. Intercept API calls to keep behavior deterministic.

## Quick Reference

```typescript
cy.intercept('GET', '**/api/todos', { fixture: 'todos.json' }).as('todos');
cy.visit('/todos');
cy.wait('@todos');
cy.findAllByRole('listitem').should('have.length.greaterThan', 0);
```

## Vue E2E Example

### TypeScript

```typescript
it('creates a todo item', () => {
  cy.intercept('GET', '**/api/todos', { fixture: 'todos-empty.json' }).as('todos');
  cy.intercept('POST', '**/api/todos').as('createTodo');

  cy.visit('/todos');
  cy.wait('@todos');

  cy.findByPlaceholderText('What needs to be done?').clear().type('Write Cypress docs{enter}');
  cy.wait('@createTodo').its('response.statusCode').should('be.oneOf', [200, 201]);

  cy.findByRole('listitem', { name: /write cypress docs/i }).should('be.visible');
});
```

### JavaScript

```javascript
it('creates a todo item', () => {
  cy.intercept('GET', '**/api/todos', { fixture: 'todos-empty.json' }).as('todos');
  cy.intercept('POST', '**/api/todos').as('createTodo');

  cy.visit('/todos');
  cy.wait('@todos');

  cy.findByPlaceholderText('What needs to be done?').clear().type('Write Cypress docs{enter}');
  cy.wait('@createTodo').its('response.statusCode').should('be.oneOf', [200, 201]);

  cy.findByRole('listitem', { name: /write cypress docs/i }).should('be.visible');
});
```

## Vue Router Navigation

```typescript
it('navigates to details page', () => {
  cy.visit('/projects');
  cy.findByRole('link', { name: /project alpha/i }).click();
  cy.location('pathname').should('match', /\/projects\/[a-z0-9-]+$/);
  cy.findByRole('heading', { name: /project alpha/i }).should('be.visible');
});
```

## Reactivity and Conditional Rendering

```typescript
it('toggles advanced filters section', () => {
  cy.visit('/search');

  cy.findByRole('button', { name: /advanced filters/i }).click();
  cy.findByLabelText('Minimum score').should('be.visible');

  cy.findByRole('button', { name: /advanced filters/i }).click();
  cy.findByLabelText('Minimum score').should('not.exist');
});
```

## Async Validation and Server Errors

```typescript
it('shows email-taken validation from API', () => {
  cy.intercept('POST', '**/api/register', {
    statusCode: 409,
    body: { error: 'Email already in use' }
  }).as('register');

  cy.visit('/register');
  cy.findByLabelText('Email').clear().type('taken@example.com');
  cy.findByLabelText('Password').clear().type('ValidP@ss1');
  cy.findByRole('button', { name: /register/i }).click();

  cy.wait('@register');
  cy.findByRole('alert').should('contain.text', 'Email already in use');
});
```

## Component Testing (Vue)

Assuming Cypress Vue component testing is configured.

```typescript
import { mount } from 'cypress/vue';
import CounterButton from '../../src/components/CounterButton.vue';

it('increments on click', () => {
  mount(CounterButton, { props: { initial: 0 } });

  cy.findByRole('button', { name: /count: 0/i }).click();
  cy.findByRole('button', { name: /count: 1/i }).should('be.visible');
});
```

## Slots and Emitted Events

```typescript
import { mount } from 'cypress/vue';
import ConfirmDialog from '../../src/components/ConfirmDialog.vue';

it('emits confirm event', () => {
  const onConfirm = cy.stub().as('onConfirm');

  mount(ConfirmDialog, {
    props: { open: true, onConfirm },
    slots: { default: 'Delete item?' }
  });

  cy.findByText('Delete item?').should('be.visible');
  cy.findByRole('button', { name: /confirm/i }).click();
  cy.get('@onConfirm').should('have.been.calledOnce');
});
```

## Anti-Patterns

- Selecting elements by generated Vue class names.
- Asserting internal component instance values in E2E tests.
- Sleeping for reactivity updates instead of asserting final UI state.
- Combining unrelated feature flows in one giant spec.

## Related

- [core/component-testing.md](component-testing.md)
- [core/forms-and-validation.md](forms-and-validation.md)
- [core/network-mocking.md](network-mocking.md)
- [core/test-organization.md](test-organization.md)
