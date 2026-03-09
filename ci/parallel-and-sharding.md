# CI: Parallelization and Sharding

> **When to use**: Your Cypress run time is too long for single-job CI.
> **Prerequisites**: [ci-github-actions.md](ci-github-actions.md), [ci-gitlab.md](ci-gitlab.md), [projects-and-dependencies.md](projects-and-dependencies.md)

## Quick Reference

```bash
# Cypress Cloud parallelization
npx cypress run --record --parallel --group "linux-chrome"

# Non-Cloud split by spec pattern (example)
npx cypress run --spec "cypress/e2e/smoke/**/*.cy.ts"
npx cypress run --spec "cypress/e2e/regression/**/*.cy.ts"
```

## Strategy Options

1. Cypress Cloud native parallelization (`--record --parallel`)
2. CI matrix split by spec groups
3. Multiple config files by scope (smoke/regression/component)

## Pattern 1: Cypress Cloud (Best for Dynamic Load Balancing)

```bash
npx cypress run \
  --record \
  --parallel \
  --group "gh-linux-chrome" \
  --browser chrome
```

Requirements:
- `CYPRESS_RECORD_KEY`
- stable `projectId` in Cypress config

Benefits:
- dynamic spec balancing
- historical timing optimization
- built-in run dashboards

## Pattern 2: CI Matrix Splitting (No Cloud)

Use explicit spec buckets.

```yaml
strategy:
  fail-fast: false
  matrix:
    shard:
      - "cypress/e2e/smoke/**/*.cy.ts"
      - "cypress/e2e/account/**/*.cy.ts"
      - "cypress/e2e/orders/**/*.cy.ts"
      - "cypress/e2e/admin/**/*.cy.ts"

steps:
  - run: npm ci
  - run: npx cypress run --spec "${{ matrix.shard }}" --browser chrome --headless
```

## Pattern 3: Separate Fast and Slow Suites

```json
{
  "scripts": {
    "cy:smoke": "cypress run --spec 'cypress/e2e/smoke/**/*.cy.ts'",
    "cy:regression": "cypress run --spec 'cypress/e2e/regression/**/*.cy.ts'"
  }
}
```

Run smoke on every PR, regression on merge/nightly.

## Balancing Rules

- Keep shard duration within ~20% of each other.
- Avoid one huge spec file that dominates one runner.
- Split high-duration specs into smaller files where possible.
- Isolate test data to avoid cross-shard interference.

## Retries with Parallel Runs

Use moderate CI retries:

```typescript
// cypress.config.ts
import { defineConfig } from 'cypress';

export default defineConfig({
  retries: {
    runMode: 2,
    openMode: 0,
  },
});
```

## Anti-Patterns

| Anti-pattern | Problem | Better approach |
|---|---|---|
| Arbitrary shard count | Overhead can exceed gains | Size shards by measured spec durations |
| Shared mutable accounts across shards | Race conditions | Unique accounts or isolated fixtures per shard |
| One monolithic `regression.cy.ts` | Cannot balance effectively | Split into domain-focused specs |

## Troubleshooting

### Parallel jobs are slower than single job

- Dependency install/cache overhead may dominate.
- Shards are imbalanced.
- Specs depend on serialized external systems.

### Flaky failures only when parallel

- Shared data collisions are likely.
- Add per-shard namespaces (tenant IDs, resource prefixes).
- Ensure seed scripts are idempotent and isolated.

## Related

- [ci-github-actions.md](ci-github-actions.md)
- [ci-gitlab.md](ci-gitlab.md)
- [../core/test-data-management.md](../core/test-data-management.md)
