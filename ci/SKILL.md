---
name: cypress-ci
description: Production-ready CI/CD patterns for Cypress including GitHub Actions, GitLab, CircleCI, Azure DevOps, Jenkins, Docker, parallelization, reporting artifacts, and coverage integration.
---

# Cypress CI/CD

Use this skill when setting up or improving Cypress pipelines.

## Golden Rules

1. Run headless in CI with explicit browser selection.
2. Cache dependencies and Cypress binary for stable speed.
3. Upload screenshots/videos/results on every run (or always on failure).
4. Parallelize only after measuring and isolating test data.
5. Use `cy.session()` and deterministic test seed/setup.
6. Keep retries moderate and fix root causes instead of masking flakiness.

## Official References

- Cypress best practices: https://docs.cypress.io/guides/references/best-practices

## CI Compatibility Matrix

| Layer | Supported range | CI guidance |
|---|---|---|
| Cypress | `>=13.0.0` | Keep runner images aligned with your Cypress major. |
| Node.js (by Cypress major) | Cypress 13-14: `>=18`; Cypress 15+: `20.x`, `22.x`, `>=24.x` | Pin Node explicitly in pipeline config to avoid drift. |
| OS runners | Linux (Ubuntu 22+), Windows 10+/Server 2019+, macOS 13+ | Match Cypress system requirements for browser dependencies. |
| Package managers | npm `>=10.1`, pnpm `>=8`, Yarn modern `>=4`, Yarn classic `>=1.22.22` | Install failures are often package-manager floor issues. |
| Browsers | Chrome, Firefox, Edge, Electron | Use explicit browser flags in CI for deterministic behavior. |

## Guides

- [ci-github-actions.md](ci-github-actions.md)
- [ci-gitlab.md](ci-gitlab.md)
- [ci-other.md](ci-other.md)
- [docker-and-containers.md](docker-and-containers.md)
- [parallel-and-sharding.md](parallel-and-sharding.md)
- [reporting-and-artifacts.md](reporting-and-artifacts.md)
- [test-coverage.md](test-coverage.md)
- [global-setup-teardown.md](global-setup-teardown.md)
- [projects-and-dependencies.md](projects-and-dependencies.md)
