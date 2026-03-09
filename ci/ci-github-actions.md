# CI: GitHub Actions

> **When to use**: Run Cypress E2E or component tests on pull requests and main branch pushes.
> **Prerequisites**: [parallel-and-sharding.md](parallel-and-sharding.md), [reporting-and-artifacts.md](reporting-and-artifacts.md), [docker-and-containers.md](docker-and-containers.md)

## Quick Reference

```bash
npm ci
npx cypress verify
npx cypress run --browser chrome --headless
npx cypress run --record --parallel --group "linux-chrome"
```

## Pattern 1: Baseline Workflow (No Cypress Cloud)

Use this when you want one reliable CI job with screenshots/videos as artifacts.

```yaml
# .github/workflows/cypress.yml
name: cypress

on:
  pull_request:
  push:
    branches: [main]

concurrency:
  group: cypress-${{ github.ref }}
  cancel-in-progress: true

jobs:
  e2e:
    runs-on: ubuntu-latest
    timeout-minutes: 25

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: npm

      - name: Cache Cypress binary
        uses: actions/cache@v4
        with:
          path: ~/.cache/Cypress
          key: cypress-${{ runner.os }}-${{ hashFiles('package-lock.json') }}

      - name: Install dependencies
        run: npm ci

      - name: Verify Cypress
        run: npx cypress verify

      - name: Run E2E
        run: npx cypress run --browser chrome --headless
        env:
          CYPRESS_BASE_URL: ${{ secrets.CYPRESS_BASE_URL }}
          CYPRESS_USER_EMAIL: ${{ secrets.CYPRESS_USER_EMAIL }}
          CYPRESS_USER_PASSWORD: ${{ secrets.CYPRESS_USER_PASSWORD }}

      - name: Upload screenshots
        if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: cypress-screenshots
          path: cypress/screenshots
          if-no-files-found: ignore

      - name: Upload videos
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: cypress-videos
          path: cypress/videos
          if-no-files-found: ignore
```

## Pattern 2: Parallel Runs with Cypress Cloud

Use this when suite duration is high and you have `CYPRESS_RECORD_KEY`.

```yaml
name: cypress-parallel

on:
  pull_request:
  push:
    branches: [main]

jobs:
  cypress:
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        container: [1, 2, 3, 4]

    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: npm
      - run: npm ci
      - run: npx cypress verify

      - name: Cypress run (parallel)
        run: |
          npx cypress run \
            --record \
            --parallel \
            --group "gh-linux-chrome" \
            --browser chrome
        env:
          CYPRESS_RECORD_KEY: ${{ secrets.CYPRESS_RECORD_KEY }}
          CYPRESS_PROJECT_ID: ${{ secrets.CYPRESS_PROJECT_ID }}
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          CYPRESS_BASE_URL: ${{ secrets.CYPRESS_BASE_URL }}
```

## Pattern 3: Split Test Types by Job

Use this when E2E and component tests should fail independently.

```yaml
jobs:
  component:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: npm
      - run: npm ci
      - run: npx cypress run --component --browser chrome --headless

  e2e:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: npm
      - run: npm ci
      - run: npx cypress run --e2e --browser chrome --headless
```

## Pattern 4: Documentation Quality Gate Job

Use this to fail PRs when markdown links break, unsupported CLI commands appear in snippets, or non-allowed residue patterns are introduced.

Use `quality-gate.ps1` in CI (check-only behavior). Keep `preflight.ps1` for local runs where auto-sync is desired.

Reference implementation in this repository:
- `.github/workflows/quality-gate.yml`

```yaml
jobs:
  docs-quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run documentation quality gate
        shell: pwsh
        run: ./scripts/quality-gate.ps1
```

## Recommended NPM Scripts

```json
{
  "scripts": {
    "cy:verify": "cypress verify",
    "cy:e2e": "cypress run --e2e --browser chrome --headless",
    "cy:component": "cypress run --component --browser chrome --headless",
    "cy:open": "cypress open"
  }
}
```

## Anti-Patterns

| Anti-pattern | Problem | Fix |
|---|---|---|
| `npm install` in CI | Non-deterministic dependency tree | Use `npm ci` |
| No artifact uploads | Hard to debug failures | Upload screenshots/videos/junit |
| Blind retries everywhere | Masks instability | Keep retries modest and fix root causes |
| Hardcoded secrets in workflow YAML | Security risk | Use GitHub Secrets |

## Troubleshooting

### Cypress binary missing

- Ensure cache path is `~/.cache/Cypress`.
- Run `npx cypress verify` before `cypress run`.

### Tests pass locally but fail in Actions

- Set explicit browser (`--browser chrome`).
- Check env var names (`CYPRESS_*`).
- Confirm backend/services are available in CI network.

## Related

- [parallel-and-sharding.md](parallel-and-sharding.md)
- [reporting-and-artifacts.md](reporting-and-artifacts.md)
- [docker-and-containers.md](docker-and-containers.md)
