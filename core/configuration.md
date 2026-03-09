# Configuration

> **When to use**: Defining Cypress runtime behavior for local development and CI.
> **Prerequisites**: [assertions-and-waiting.md](assertions-and-waiting.md), [test-organization.md](test-organization.md)

## Quick Reference

```bash
npx cypress open
npx cypress run --browser chrome --headless
npx cypress run --config-file cypress.e2e.config.ts
npx cypress run --spec "cypress/e2e/smoke/**/*.cy.ts"
```

## Production-Ready Config (Copy-Paste Starter)

### TypeScript

```typescript
// cypress.config.ts
import { defineConfig } from 'cypress';

export default defineConfig({
  video: true,
  screenshotOnRunFailure: true,
  retries: {
    runMode: 2,
    openMode: 0,
  },
  e2e: {
    baseUrl: 'http://localhost:3000',
    specPattern: 'cypress/e2e/**/*.cy.ts',
    supportFile: 'cypress/support/e2e.ts',
    defaultCommandTimeout: 10000,
    requestTimeout: 15000,
    responseTimeout: 30000,
    pageLoadTimeout: 60000,
    testIsolation: true,
    setupNodeEvents(on, config) {
      on('task', {
        log(message: string) {
          console.log(message);
          return null;
        },
      });

      on('before:run', () => {
        console.log('[cypress] before:run');
      });

      on('after:run', (results) => {
        console.log('[cypress] after:run totalFailed=', results.totalFailed);
      });

      return config;
    },
  },
});
```

### JavaScript

```javascript
// cypress.config.js
const { defineConfig } = require('cypress');

module.exports = defineConfig({
  video: true,
  screenshotOnRunFailure: true,
  retries: {
    runMode: 2,
    openMode: 0,
  },
  e2e: {
    baseUrl: 'http://localhost:3000',
    specPattern: 'cypress/e2e/**/*.cy.ts',
    supportFile: 'cypress/support/e2e.js',
    defaultCommandTimeout: 10000,
    requestTimeout: 15000,
    responseTimeout: 30000,
    pageLoadTimeout: 60000,
    testIsolation: true,
    setupNodeEvents(on, config) {
      on('task', {
        log(message) {
          console.log(message);
          return null;
        },
      });

      return config;
    },
  },
});
```

## Patterns

### Pattern 1: Environment-Specific Configuration

Use `CYPRESS_*` vars and env overrides.

**TypeScript**
```typescript
import { defineConfig } from 'cypress';

const baseUrl = process.env.CYPRESS_BASE_URL ?? 'http://localhost:3000';

export default defineConfig({
  e2e: {
    baseUrl,
    env: {
      apiUrl: process.env.CYPRESS_API_URL ?? `${baseUrl}/api`,
    },
  },
});
```

Run examples:

```bash
CYPRESS_BASE_URL=https://staging.example.com npx cypress run
CYPRESS_BASE_URL=https://preprod.example.com npx cypress run --spec "cypress/e2e/smoke/**/*.cy.ts"
```

### Pattern 2: Separate E2E and Component Configs

```typescript
// cypress.e2e.config.ts
import { defineConfig } from 'cypress';

export default defineConfig({
  e2e: {
    baseUrl: 'http://localhost:3000',
    specPattern: 'cypress/e2e/**/*.cy.ts',
  },
});
```

```typescript
// cypress.component.config.ts
import { defineConfig } from 'cypress';

export default defineConfig({
  component: {
    specPattern: 'cypress/component/**/*.cy.ts',
    devServer: {
      framework: 'react',
      bundler: 'vite',
    },
  },
});
```

### Pattern 3: Web Server Management in CI

Prefer explicit startup checks in CI scripts.

```json
{
  "scripts": {
    "start:test": "node server.js",
    "wait:test": "wait-on http://localhost:3000/health",
    "cy:e2e": "cypress run --e2e --browser chrome --headless",
    "test:e2e:ci": "start-server-and-test start:test http://localhost:3000 cy:e2e"
  }
}
```

### Pattern 4: Setup and Teardown via Scripts/Events

Cypress does not expose `global setup/teardown` config keys in this style.

Use:
1. CI pre/post scripts (`npm run test:prep`, `npm run test:cleanup`)
2. `setupNodeEvents` hooks (`before:run`, `after:run`)
3. CI job dependencies

### Pattern 5: `.env` Strategy

```text
# .env.example
CYPRESS_BASE_URL=http://localhost:3000
CYPRESS_USER_EMAIL=test@example.com
CYPRESS_USER_PASSWORD=replace-me
```

```text
# .gitignore
.env
.env.*
```

Load env in CI via secrets, not committed files.

### Pattern 6: Artifact and Retry Settings

```typescript
import { defineConfig } from 'cypress';

export default defineConfig({
  video: true,
  screenshotOnRunFailure: true,
  retries: {
    runMode: 2,
    openMode: 0,
  },
});
```

## Decision Guide

### Which Timeout to Adjust

| Symptom | Setting |
|---|---|
| Elements appear slowly | `defaultCommandTimeout` |
| API requests timeout | `requestTimeout` / `responseTimeout` |
| Initial page navigation timeout | `pageLoadTimeout` |

### Single Config vs Multiple Config Files

| Need | Recommendation |
|---|---|
| Only E2E tests | single `cypress.config.*` |
| E2E + component + distinct runtime settings | multiple config files + scripts |
| Multiple environments | env vars + CI matrix |

### Where to Put Setup Logic

| Task | Best place |
|---|---|
| DB reset/seed before suite | CI prep script/job |
| Lightweight per-run logging/telemetry | `setupNodeEvents` |
| Per-test app state setup | custom commands/hooks in support files |

## Anti-Patterns

| Anti-pattern | Problem | Better approach |
|---|---|---|
| Hardcoded secrets in config | Security leak | Use `CYPRESS_*` env vars |
| Massive global timeouts | Slow failures, hidden flakiness | Targeted waits + deterministic aliases |
| Blind `chromeWebSecurity: false` | Overbroad security relaxation | Set only when required and documented |
| Mixing app startup inside spec files | Non-deterministic state | Use scripts or CI setup jobs |

## Troubleshooting

### `baseUrl` ignored

- Confirm you run the intended config file.
- Ensure paths/specs are in the same testing type (`e2e` vs `component`).
- Log active config inside `setupNodeEvents` for validation.

### Tests pass locally, fail in CI

- Check browser selection consistency (`--browser chrome`).
- Verify required `CYPRESS_*` vars exist in CI.
- Ensure app readiness check runs before Cypress.

### Cypress exits early with server errors

- App likely not ready when tests start.
- Use `start-server-and-test` or health-check wait script.

## Related

- [authentication.md](authentication.md)
- [auth-flows.md](auth-flows.md)
- [test-organization.md](test-organization.md)
- [../ci/global-setup-teardown.md](../ci/global-setup-teardown.md)
- [../ci/projects-and-dependencies.md](../ci/projects-and-dependencies.md)

