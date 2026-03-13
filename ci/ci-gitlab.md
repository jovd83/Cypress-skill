# CI: GitLab CI/CD

> **When to use**: Run Cypress pipelines for merge requests, default branch, and scheduled jobs in GitLab.
> **Prerequisites**: [parallel-and-sharding.md](parallel-and-sharding.md), [reporting-and-artifacts.md](reporting-and-artifacts.md), [docker-and-containers.md](docker-and-containers.md)

## Quick Reference

```bash
npm ci
npx cypress verify
npx cypress run --browser chrome --headless
npx cypress run --record --parallel --group "gitlab-linux"
```

## Pattern 1: Baseline `.gitlab-ci.yml`

```yaml
image: cypress/browsers:node-20.11.1-chrome-121-ff-122

stages:
  - test

variables:
  CI: "true"
  npm_config_cache: "$CI_PROJECT_DIR/.npm"

cache:
  key:
    files:
      - package-lock.json
  paths:
    - .npm/
    - node_modules/

cypress-e2e:
  stage: test
  script:
    - npm ci
    - npx cypress verify
    - npx cypress run --browser chrome --headless
  artifacts:
    when: always
    paths:
      - cypress/screenshots/
      - cypress/videos/
      - cypress/results/
    expire_in: 14 days
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

## Pattern 2: Parallel with Cypress Cloud

```yaml
image: cypress/browsers:node-20.11.1-chrome-121-ff-122

stages:
  - test

cypress-parallel:
  stage: test
  parallel: 4
  script:
    - npm ci
    - npx cypress verify
    - |
      npx cypress run \
        --record \
        --parallel \
        --group "gitlab-linux-chrome"
  variables:
    CYPRESS_RECORD_KEY: $CYPRESS_RECORD_KEY
    CYPRESS_PROJECT_ID: $CYPRESS_PROJECT_ID
    CYPRESS_BASE_URL: $CYPRESS_BASE_URL
  artifacts:
    when: always
    paths:
      - cypress/screenshots/
      - cypress/videos/
    expire_in: 7 days
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

## Pattern 3: Job Separation (Lint, CT, E2E)

```yaml
stages:
  - lint
  - component
  - e2e

lint:
  stage: lint
  script:
    - npm ci
    - npm run lint

component:
  stage: component
  script:
    - npm ci
    - npx cypress run --component --browser chrome --headless

e2e:
  stage: e2e
  script:
    - npm ci
    - npx cypress run --e2e --browser chrome --headless
```

## Pattern 4: Publish Cypress Handover Pester Results

When the repo contains the Cypress handover package checks, publish the dedicated Pester results as an artifact:

```yaml
handover-docs:
  stage: test
  script:
    - pwsh -NoProfile -File ./scripts/check-cypress-handover-pester.ps1 -ResultsPath ./artifacts/pester/cypress-handover.xml
  artifacts:
    when: always
    paths:
      - artifacts/pester/
    expire_in: 14 days
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

Use this alongside the main docs quality gate when you want a dedicated machine-readable result file for the handover package tests.

## Secrets and Environment

Use GitLab CI variables for credentials:
- `CYPRESS_BASE_URL`
- `CYPRESS_USER_EMAIL`
- `CYPRESS_USER_PASSWORD`
- `CYPRESS_RECORD_KEY` (if using Cloud)

Avoid committing `.env` secrets into the repository.

## Anti-Patterns

| Anti-pattern | Problem | Better approach |
|---|---|---|
| Single long job for all checks | Slow feedback and noisy logs | Split CT/E2E/lint |
| No artifacts on failure | Root cause is hard to diagnose | Always keep screenshots/videos/results |
| Running tests only on main | Late failure discovery | Run on merge requests |

## Troubleshooting

### Browser launch errors in GitLab runners

- Use an image with browsers preinstalled (`cypress/browsers` or `cypress/included`).
- Confirm Docker executor supports required shared memory settings.

### Flaky parallel runs

- Isolate test data per pipeline.
- Avoid shared mutable test accounts.
- Keep retries low and investigate failing specs.

### Handover Pester results are missing

- Confirm the job runs `check-cypress-handover-pester.ps1` with `-ResultsPath`.
- Confirm `artifacts/pester/` is included in GitLab artifacts.
- If the repo image lacks PowerShell or Pester, use a job image that can run `pwsh` and install Pester first.

## Related

- [ci-github-actions.md](ci-github-actions.md)
- [parallel-and-sharding.md](parallel-and-sharding.md)
- [reporting-and-artifacts.md](reporting-and-artifacts.md)
