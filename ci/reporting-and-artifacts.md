# CI: Reporting and Artifacts

> **When to use**: You need actionable outputs for failed and passed Cypress runs in CI.
> **Prerequisites**: [ci-github-actions.md](ci-github-actions.md), [ci-gitlab.md](ci-gitlab.md), [test-coverage.md](test-coverage.md)

## Core Outputs to Preserve

- `cypress/screenshots` (failures)
- `cypress/videos` (run recordings)
- JUnit XML (`cypress/results/*.xml`) for CI test dashboards
- Optional HTML/Allure artifacts

## Pattern 1: JUnit Reporter for CI Integration

Install:

```bash
npm i -D mocha-junit-reporter
```

Configure:

```typescript
// cypress.config.ts
import { defineConfig } from 'cypress';

export default defineConfig({
  reporter: 'junit',
  reporterOptions: {
    mochaFile: 'cypress/results/junit-[hash].xml',
    toConsole: false,
  },
});
```

## Pattern 2: Mochawesome HTML Report

Install:

```bash
npm i -D mochawesome mochawesome-merge mochawesome-report-generator
```

Config example:

```typescript
import { defineConfig } from 'cypress';

export default defineConfig({
  reporter: 'mochawesome',
  reporterOptions: {
    reportDir: 'cypress/results/mochawesome',
    overwrite: false,
    html: false,
    json: true,
  },
});
```

Merge and generate:

```bash
npx mochawesome-merge cypress/results/mochawesome/*.json > cypress/results/merged.json
npx marge cypress/results/merged.json -o cypress/results/html
```

## Pattern 3: Allure (Optional)

Install (plugin choice depends on your stack):

```bash
npm i -D @shelex/cypress-allure-plugin allure-commandline
```

Then publish `allure-results/` and generated `allure-report/` as artifacts.

## CI Artifact Upload Examples

### GitHub Actions

```yaml
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

- name: Upload junit
  if: always()
  uses: actions/upload-artifact@v4
  with:
    name: cypress-junit
    path: cypress/results/*.xml
    if-no-files-found: ignore
```

### GitLab

```yaml
artifacts:
  when: always
  paths:
    - cypress/screenshots/
    - cypress/videos/
    - cypress/results/
  reports:
    junit: cypress/results/*.xml
```

## Retention Recommendations

- PR runs: keep 7-14 days
- main/nightly regression: keep 14-30 days
- release-candidate validation: keep longer if compliance requires it

## Anti-Patterns

| Anti-pattern | Problem | Better approach |
|---|---|---|
| Uploading only on success | Failing runs lose debug data | Upload failure artifacts always |
| Huge raw artifacts without structure | Hard to find useful files | Separate screenshots/videos/results paths |
| No junit output | CI UI lacks test-level visibility | Emit JUnit XML consistently |

## Troubleshooting

### No screenshots/videos in CI

- Verify `video` and `screenshotOnRunFailure` settings.
- Confirm artifact upload steps use `if: always()` or `when: always`.

### JUnit report not recognized

- Confirm XML path matches CI pattern.
- Avoid overwriting same filename from parallel jobs unless merged intentionally.

## Related

- [ci-github-actions.md](ci-github-actions.md)
- [ci-gitlab.md](ci-gitlab.md)
- [parallel-and-sharding.md](parallel-and-sharding.md)
