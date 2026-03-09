# CI: Projects and Dependencies

> **When to use**: You need multiple Cypress scopes (E2E, component, mobile, smoke) and explicit CI job dependencies.
> **Prerequisites**: [global-setup-teardown.md](global-setup-teardown.md), [parallel-and-sharding.md](parallel-and-sharding.md), [ci-github-actions.md](ci-github-actions.md)

## Cypress Reality

Cypress does not use dependency-graph style multi-project configuration.

Equivalent Cypress patterns:
1. Separate config files (`cypress.e2e.config.ts`, `cypress.component.config.ts`)
2. Distinct npm scripts per scope
3. CI job dependencies (`needs`, `dependsOn`) between setup and test jobs

## Pattern 1: Multi-Config Setup

**TypeScript**
```typescript
// cypress.e2e.config.ts
import { defineConfig } from 'cypress';

export default defineConfig({
  e2e: {
    baseUrl: 'http://localhost:3000',
    specPattern: 'cypress/e2e/**/*.cy.ts',
  },
  retries: { runMode: 2, openMode: 0 },
});
```

```typescript
// cypress.component.config.ts
import { defineConfig } from 'cypress';

export default defineConfig({
  component: {
    devServer: {
      framework: 'react',
      bundler: 'vite',
    },
    specPattern: 'cypress/component/**/*.cy.ts',
  },
});
```

```json
{
  "scripts": {
    "cy:e2e": "cypress run --config-file cypress.e2e.config.ts",
    "cy:ct": "cypress run --component --config-file cypress.component.config.ts",
    "cy:smoke": "cypress run --config-file cypress.e2e.config.ts --spec 'cypress/e2e/smoke/**/*.cy.ts'"
  }
}
```

## Pattern 2: Job Dependencies in CI

### GitHub Actions

```yaml
jobs:
  setup:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: npm run db:seed:test

  e2e:
    needs: setup
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: npm run cy:e2e

  component:
    needs: setup
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: npm run cy:ct
```

### GitLab

```yaml
stages:
  - setup
  - test

setup:
  stage: setup
  script:
    - npm ci
    - npm run db:seed:test

e2e:
  stage: test
  needs: [setup]
  script:
    - npm run cy:e2e

component:
  stage: test
  needs: [setup]
  script:
    - npm run cy:ct
```

## Pattern 3: Browser Matrix

```yaml
strategy:
  matrix:
    browser: [chrome, firefox]

steps:
  - run: npm ci
  - run: npx cypress run --browser ${{ matrix.browser }} --headless
```

## Pattern 4: Environment Matrix

```yaml
strategy:
  matrix:
    env_name: [staging, preprod]

steps:
  - run: npm ci
  - run: npx cypress run
    env:
      CYPRESS_BASE_URL: ${{ matrix.env_name == 'staging' && secrets.STAGING_BASE_URL || secrets.PREPROD_BASE_URL }}
```

## Decision Guide

| Need | Pattern |
|---|---|
| Fast smoke checks on PR | `cy:smoke` script + dedicated CI job |
| Full regression nightly | separate scheduled workflow/job |
| CT and E2E in same repo | separate config files + scripts |
| Shared seed before tests | setup job with dependencies |

## Anti-Patterns

| Anti-pattern | Problem | Better approach |
|---|---|---|
| One mega command for all test types | Slow and hard to triage | Split jobs by test scope |
| Hidden setup inside first spec | Non-deterministic ordering | Explicit setup job/script |
| Mixing CT and E2E artifacts | Confusing reports | Store artifacts per job type |

## Troubleshooting

### Setup job succeeds but tests fail with missing data

- Confirm the setup targets the same DB/tenant as test jobs.
- Ensure environment variables are identical across jobs.

### Different browsers show inconsistent failures

- Check browser-specific assumptions in selectors/events.
- Keep assertions user-centric and avoid timing hacks.

## Related

- [global-setup-teardown.md](global-setup-teardown.md)
- [parallel-and-sharding.md](parallel-and-sharding.md)
- [../core/test-architecture.md](../core/test-architecture.md)
