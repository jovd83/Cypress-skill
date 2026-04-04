---
name: cypress-ci
description: CI and delivery skill for Cypress automation. Use when Codex needs to design, debug, or optimize Cypress execution in GitHub Actions, GitLab CI, CircleCI, Azure DevOps, Jenkins, Docker, sharded pipelines, artifact workflows, or shared setup and teardown.
metadata:
  author: jovd83
  version: "1.1"
---

# Cypress CI/CD

Use this skill when the main problem is pipeline execution rather than test authoring.

## Golden Rules

1. Prefer deterministic setup over clever pipeline shortcuts.
2. Capture screenshots, videos, reports, and other artifacts where they materially reduce triage time.
3. Scale horizontally with sharding only after test data and isolation are under control.
4. Cache stable dependencies deliberately, including the Cypress binary and package-manager state where appropriate.
5. Keep retries informative, not silent flake camouflage.
6. Prefer explicit browser and environment selection in CI.

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

| Need | Guide |
|---|---|
| GitHub Actions | [ci-github-actions.md](ci-github-actions.md) |
| GitLab CI | [ci-gitlab.md](ci-gitlab.md) |
| Other providers | [ci-other.md](ci-other.md) |
| Sharding and scaling | [parallel-and-sharding.md](parallel-and-sharding.md), [projects-and-dependencies.md](projects-and-dependencies.md) |
| Containers | [docker-and-containers.md](docker-and-containers.md) |
| Reports and artifacts | [reporting-and-artifacts.md](reporting-and-artifacts.md) |
| Coverage and setup orchestration | [test-coverage.md](test-coverage.md), [global-setup-teardown.md](global-setup-teardown.md) |

## Output Bias

When solving CI tasks, prefer:

- concrete workflow or pipeline changes,
- exact commands, cache locations, and artifact paths,
- explicit diagnostics and validation steps,
- clear tradeoffs when the pipeline needs faster feedback versus deeper debugging.
