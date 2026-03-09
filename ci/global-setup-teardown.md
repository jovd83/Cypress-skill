# CI: Global Setup and Teardown

> **When to use**: Run one-time preparation and cleanup around Cypress runs in CI.
> **Prerequisites**: [projects-and-dependencies.md](projects-and-dependencies.md), [parallel-and-sharding.md](parallel-and-sharding.md), [ci-github-actions.md](ci-github-actions.md)

## Important Cypress Constraint

Cypress does not expose `global setup/teardown` config entries in the same way; use Node tasks and CI orchestration instead.

Use one of these approaches:
1. CI pre/post scripts (`npm run test:prep` and `npm run test:cleanup`)
2. Node event hooks in `setupNodeEvents` (`before:run`, `after:run`)
3. Separate CI jobs for seed/reset dependencies

## Pattern 1: Pre/Post NPM Scripts (Recommended)

```json
{
  "scripts": {
    "test:prep": "node scripts/test-prep.js",
    "test:e2e": "cypress run --e2e --browser chrome --headless",
    "test:cleanup": "node scripts/test-cleanup.js",
    "ci:e2e": "npm run test:prep && npm run test:e2e && npm run test:cleanup"
  }
}
```

```js
// scripts/test-prep.js
const { execSync } = require('child_process');

execSync('npm run db:reset', { stdio: 'inherit' });
execSync('npm run db:seed:test', { stdio: 'inherit' });
console.log('Test environment prepared');
```

```js
// scripts/test-cleanup.js
const { execSync } = require('child_process');

execSync('npm run db:cleanup:test', { stdio: 'inherit' });
console.log('Test environment cleaned');
```

## Pattern 2: `setupNodeEvents` Lifecycle Hooks

Use for lightweight orchestration, not heavy infra provisioning.

**TypeScript**
```typescript
// cypress.config.ts
import { defineConfig } from 'cypress';

export default defineConfig({
  e2e: {
    setupNodeEvents(on, config) {
      on('before:run', async () => {
        // Keep this fast and deterministic
        console.log('[before:run] starting test run');
      });

      on('after:run', async (results) => {
        console.log('[after:run] total failed:', results.totalFailed);
      });

      on('task', {
        seedDb() {
          // call out to seed logic
          return null;
        },
      });

      return config;
    },
  },
});
```

**JavaScript**
```javascript
// cypress.config.js
const { defineConfig } = require('cypress');

module.exports = defineConfig({
  e2e: {
    setupNodeEvents(on, config) {
      on('before:run', async () => {
        console.log('[before:run] start');
      });

      on('after:run', async () => {
        console.log('[after:run] done');
      });

      return config;
    },
  },
});
```

## Pattern 3: CI Job Dependencies for Environment Prep

### GitHub Actions example

```yaml
jobs:
  prep:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: npm run db:reset && npm run db:seed:test

  e2e:
    needs: prep
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: npx cypress run --browser chrome --headless
```

## Auth Setup Guidance

- Use `cy.session()` inside custom login commands for test-time reuse.
- For CI-wide auth seed, create users/tokens in prep scripts through backend APIs.
- Avoid treating browser state snapshots as a built-in primitive; prefer `cy.session()` and explicit auth setup.

## Anti-Patterns

| Anti-pattern | Problem | Better approach |
|---|---|---|
| Heavy DB migrations inside `before:run` for every CI shard | Slow and duplicate work | Move heavy work to a prep job |
| Using arbitrary waits to "let environment start" | Flaky startup synchronization | Add explicit health checks |
| Mixing environment provisioning inside test specs | Non-isolated and hard to maintain | Keep provisioning in scripts/tasks |

## Troubleshooting

### Setup passes locally but fails in CI

- Ensure required env vars are defined in CI secrets.
- Use deterministic seed data and idempotent scripts.
- Fail fast on prep script errors (non-zero exit codes).

### Cleanup not running after failure

- Use CI `always()`/`post` sections.
- Keep cleanup in a dedicated step/job that always executes.

## Related

- [projects-and-dependencies.md](projects-and-dependencies.md)
- [parallel-and-sharding.md](parallel-and-sharding.md)
- [../core/authentication.md](../core/authentication.md)

