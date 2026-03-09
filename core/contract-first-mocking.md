# Contract-First Mocking (Temporary Bridge for Frontend Development)

> [!IMPORTANT]
> **Mocking is a last resort.** Always prefer real End-to-End (E2E) verification against a real backend whenever possible. This guide is specifically for the period *before* the backend is available or when hitting the real backend is physically impossible.

> **When to use**: **Only** when frontend development must start before the backend implementation is ready, or to test specialized error states (4xx/5xx) that are impossible to trigger reliably on a real environment.

## The E2E-First Workflow

1. **Agree on the Contract**: Collaborate with backend developers to define the API shape.
2. **Implement Temporary Skeleton Mocks**: Create Cypress intercepts to unblock frontend development.
3. **Develop Frontend Logic**: Use the mocks to build UI components and initial test logic.
4. **Final Verification (The Goal)**: Transition **100%** to real E2E tests once the backend is ready. Verification is incomplete until it has passed against real services.

---

## 1. Defining the Contract

Use a shared source of truth.

- **OpenAPI / Swagger**: Generate types or mock data from a `.yaml` file.
- **TypeScript Interfaces**: Share a common `types` package between frontend and backend.
- **JSON Schemas**: Ensure the mock data matches the expected production output.

---

## 2. Environment-Driven Toggling

Configure your project to easily switch between **Real** and **Mocked** modes using environment variables in `cypress.config.ts`.

### Config Setup (`cypress.config.ts`)

```typescript
import { defineConfig } from 'cypress';

export default defineConfig({
  e2e: {
    baseUrl: process.env.BASE_URL || 'http://localhost:3000',
    env: {
      useMocks: process.env.USE_MOCKS === 'true',
    },
    setupNodeEvents(on, config) {
      // Setup node events
    }
  }
});
```

### Global Hook for Toggling

Create a global `beforeEach` hook in your support file that applies mocks only if `useMocks` is enabled in Cypress.env().

```typescript
// cypress/support/e2e.ts

beforeEach(() => {
  if (Cypress.env('useMocks')) {
    cy.log('--- RUNNING WITH MOCKS ---');
    cy.intercept('GET', '**/api/v1/users', {
      statusCode: 200,
      body: [{ id: '1', name: 'Contract User', role: 'Developer' }]
    }).as('mockUsers');
    
    // Add other contract-based routes here
  }
});
```

---

## 3. Refactoring from Mock to Real

When the backend implementation is ready, you don't need to rewrite your tests. Instead:

### Phase A: Parallel Runs
Run your tests twice in CI: 
- Once with `CYPRESS_USE_MOCKS=true` (fast feedback on UI logic).
- Once with `CYPRESS_USE_MOCKS=false` against a staging backend (integration confidence).

### Phase B: Hybrid Mocking (The "Shim" Pattern)
Use `req.continue()` in Cypress's `cy.intercept` to let real calls through, but fall back to mocks for endpoints that aren't ready or for specific error states.

```typescript
// cypress/support/e2e.ts
beforeEach(() => {
  cy.intercept('**/api/v1/**', (req) => {
    // Attempt the real request first
    req.continue((res) => {
      // Fallback if backend is down or endpoint not implemented (404/501)
      if (res.statusCode === 404 || res.statusCode === 501) {
        res.send({ statusCode: 200, body: getMockData(req.url) });
      }
    });
  });
});
```

### Phase C: Mock Decay Audit
Periodically disable mocks to see which tests fail. This identifies where the backend implementation has diverged from the original contract.

---

## Checklist

- [ ] **E2E verification**: Ensure every mocked scenario has a corresponding run configured against the real backend as part of integration verification.
- [ ] **Contract Versioning**: Mocks are updated if and when the API version changes.
- [ ] **Data Parity**: Mock data uses realistic values (e.g., valid UUIDs, real-looking emails).
- [ ] **Switchable Config**: The `useMocks` environment flag is documented and works in both local and CI environments.
- [ ] **Mock Decay Audit**: Regularly disable mocks to catch drift between the contract and the implementation.
