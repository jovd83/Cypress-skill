# CI: Docker and Containers

> **When to use**: You need reproducible Cypress execution across local and CI environments.
> **Prerequisites**: [ci-github-actions.md](ci-github-actions.md), [ci-gitlab.md](ci-gitlab.md), [reporting-and-artifacts.md](reporting-and-artifacts.md)

## Quick Reference

```bash
docker pull cypress/included:13.17.0
docker run --rm -v ${PWD}:/e2e -w /e2e cypress/included:13.17.0 npm ci
docker run --rm -v ${PWD}:/e2e -w /e2e cypress/included:13.17.0 npx cypress run --browser chrome --headless
```

## Recommended Images

- `cypress/included:<version>`: Cypress + Node + browsers included.
- `cypress/browsers:<tag>`: Node + browsers, install Cypress via npm.

Use pinned tags for reproducibility.

## Pattern 1: Minimal Dockerfile for CI

```dockerfile
FROM cypress/browsers:node-20.11.1-chrome-121-ff-122

WORKDIR /app
COPY package*.json ./
RUN npm ci

COPY . .
CMD ["npx", "cypress", "run", "--browser", "chrome", "--headless"]
```

## Pattern 2: Docker Compose with App + Cypress

```yaml
version: '3.9'
services:
  app:
    build: .
    command: npm run start:test
    ports:
      - "3000:3000"

  cypress:
    image: cypress/included:13.17.0
    depends_on:
      - app
    working_dir: /e2e
    volumes:
      - ./:/e2e
    environment:
      - CYPRESS_BASE_URL=http://app:3000
    command: ["npx", "cypress", "run", "--browser", "chrome", "--headless"]
```

## Pattern 3: CI-Friendly Runtime Flags

```bash
npx cypress run \
  --browser chrome \
  --headless \
  --config video=true,screenshotOnRunFailure=true
```

## Volumes and Caching

Cache these paths where possible:
- `~/.cache/Cypress`
- `node_modules`

Persist these artifacts:
- `cypress/screenshots`
- `cypress/videos`
- test result outputs (`cypress/results`, `allure-results`, etc.)

## Anti-Patterns

| Anti-pattern | Problem | Better approach |
|---|---|---|
| Floating image tags like `latest` | Non-deterministic browser/runtime changes | Pin exact image tags |
| Installing dependencies every job without cache | Slow pipelines | Cache npm + Cypress binary |
| Running app and tests in same process with weak health checks | Race conditions at startup | Add explicit readiness checks |

## Troubleshooting

### Browser missing inside container

- Use `cypress/included` or a browser-enabled `cypress/browsers` image.
- Confirm requested `--browser` exists in image.

### App not reachable from Cypress container

- Use service name (`http://app:3000`) not `localhost`.
- Ensure both services are on same Docker network.

## Related

- [ci-github-actions.md](ci-github-actions.md)
- [ci-gitlab.md](ci-gitlab.md)
- [parallel-and-sharding.md](parallel-and-sharding.md)
