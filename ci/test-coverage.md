# CI: Test Coverage with Cypress

> **When to use**: You want frontend/backend coverage metrics from Cypress runs and CI trend tracking.
> **Prerequisites**: [reporting-and-artifacts.md](reporting-and-artifacts.md), [ci-github-actions.md](ci-github-actions.md), [projects-and-dependencies.md](projects-and-dependencies.md)

## Preferred Stack

- `@cypress/code-coverage`
- `nyc` (Istanbul)
- Build/tooling instrumentation (Babel/Vite/Webpack plugin)

## Install

```bash
npm i -D @cypress/code-coverage nyc
```

## Cypress Setup

**TypeScript**
```typescript
// cypress/support/e2e.ts
import '@cypress/code-coverage/support';
```

```typescript
// cypress.config.ts
import { defineConfig } from 'cypress';
import codeCoverageTask from '@cypress/code-coverage/task';

export default defineConfig({
  e2e: {
    setupNodeEvents(on, config) {
      codeCoverageTask(on, config);
      return config;
    },
  },
});
```

**JavaScript**
```javascript
// cypress/support/e2e.js
import '@cypress/code-coverage/support';
```

```javascript
// cypress.config.js
const { defineConfig } = require('cypress');
const codeCoverageTask = require('@cypress/code-coverage/task');

module.exports = defineConfig({
  e2e: {
    setupNodeEvents(on, config) {
      codeCoverageTask(on, config);
      return config;
    },
  },
});
```

## NYC Config

```json
{
  "nyc": {
    "all": true,
    "include": ["src/**/*.ts", "src/**/*.tsx", "src/**/*.js"],
    "exclude": ["**/*.cy.*", "cypress/**", "**/*.d.ts"],
    "reporter": ["text-summary", "lcov", "cobertura"],
    "report-dir": "coverage"
  }
}
```

## CI Commands

```bash
npx cypress run --browser chrome --headless
npx nyc report --reporter=text-summary --reporter=lcov --reporter=cobertura
```

## Merge Coverage Across Parallel Jobs

If running parallel jobs:
1. Upload `.nyc_output` artifacts per job.
2. Merge in a dedicated report job.

```bash
npx nyc merge .nyc_output coverage/.nyc_output.json
npx nyc report --temp-dir coverage --report-dir coverage --reporter=lcov --reporter=text-summary
```

## Threshold Enforcement

```json
{
  "scripts": {
    "coverage:check": "nyc check-coverage --lines 80 --functions 80 --branches 70 --statements 80"
  }
}
```

Run in CI after report generation.

## Anti-Patterns

| Anti-pattern | Problem | Better approach |
|---|---|---|
| Treating E2E coverage as full quality signal | Misses unit-level edge cases | Combine with unit/integration coverage |
| Ignoring branch coverage | Gives false confidence | Enforce branch thresholds |
| No merge strategy for parallel jobs | Coverage appears incomplete | Merge `.nyc_output` before reporting |

## Troubleshooting

### Coverage is always zero

- App likely not instrumented.
- Confirm instrumentation plugin is enabled in test build.
- Ensure `@cypress/code-coverage/support` is loaded.

### Coverage exists locally but not in CI

- Verify artifacts include `.nyc_output`.
- Ensure report generation runs after test job completion.

## Related

- [reporting-and-artifacts.md](reporting-and-artifacts.md)
- [parallel-and-sharding.md](parallel-and-sharding.md)
- [../core/test-architecture.md](../core/test-architecture.md)
