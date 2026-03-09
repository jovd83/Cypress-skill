# Component Testing

> **When to use**: Validate component behavior in isolation (props, events, conditional rendering, state transitions) with fast feedback.

## Why Cypress Component Testing

- Runs components in a real browser.
- Uses the same assertion and selector style as E2E tests.
- Faster and more focused than full-route tests.

## Setup Notes

Use framework-specific mount utilities:

- React: `cypress/react`
- Vue: `cypress/vue`
- Angular: `cypress/angular`

## Testing Rules

1. Assert visible behavior, not internal implementation.
2. Keep one behavior per test.
3. Stub network calls when the component fetches data.
4. Prefer accessible selectors (`findByRole`, `findByLabelText`, `findByText`).

## React Example (TypeScript)

```typescript
import { mount } from 'cypress/react';
import { CounterButton } from '../../src/components/CounterButton';

it('increments count on click', () => {
  mount(<CounterButton initialCount={0} />);

  cy.findByRole('button', { name: /count: 0/i }).click();
  cy.findByRole('button', { name: /count: 1/i }).should('be.visible');
});
```

## Vue Example (TypeScript)

```typescript
import { mount } from 'cypress/vue';
import CounterButton from '../../src/components/CounterButton.vue';

it('increments count on click', () => {
  mount(CounterButton, { props: { initialCount: 0 } });

  cy.findByRole('button', { name: /count: 0/i }).click();
  cy.findByRole('button', { name: /count: 1/i }).should('be.visible');
});
```

## Angular Example (TypeScript)

```typescript
import { mount } from 'cypress/angular';
import { CounterComponent } from '../../src/app/counter/counter.component';

it('increments count on click', () => {
  mount(CounterComponent, { componentProperties: { count: 0 } });

  cy.findByRole('button', { name: /increment/i }).click();
  cy.findByText('1').should('be.visible');
});
```

## Form Component Example

```typescript
it('shows validation error and then clears it', () => {
  mount(<ProfileForm onSave={cy.stub().as('onSave')} />);

  cy.findByRole('button', { name: /save/i }).click();
  cy.findByText('Display name is required').should('be.visible');

  cy.findByLabelText('Display name').clear().type('Jane Doe');
  cy.findByRole('button', { name: /save/i }).click();

  cy.get('@onSave').should('have.been.calledOnce');
});
```

## API-Driven Component Example

```typescript
it('renders API data in list component', () => {
  cy.intercept('GET', '**/api/items', {
    statusCode: 200,
    body: [{ id: '1', name: 'Item A' }]
  }).as('items');

  mount(<ItemsList />);
  cy.wait('@items');
  cy.findByRole('listitem', { name: /item a/i }).should('be.visible');
});
```

## Snapshot / Visual Component Checks

Use component screenshots for stable, focused visual checks.

```typescript
it('captures card visual state', () => {
  mount(<PricingCard plan="Pro" price="$29" />);
  cy.findByTestId('pricing-card').screenshot('pricing-card-pro');
});
```

## Anti-Patterns

- Mounting entire app shell when only one component behavior is under test.
- Asserting CSS class internals instead of user-visible outcomes.
- Reusing mutable global state across component tests.
- Mixing component-level and full E2E concerns in one spec.

## Related

- [core/react.md](react.md)
- [core/vue.md](vue.md)
- [core/angular.md](angular.md)
- [core/test-organization.md](test-organization.md)
