# Cypress Agent Skills

[![Validate Skills](https://github.com/jovd83/Cypress-skill/actions/workflows/validate.yml/badge.svg)](https://github.com/jovd83/Cypress-skill/actions/workflows/validate.yml)
[![version](https://img.shields.io/badge/version-1.1-blue)](CHANGELOG.md)
[![license](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-ffdd00?style=flat&logo=buy-me-a-coffee&logoColor=black)](https://buymeacoffee.com/jovd83)

Enterprise-grade Cypress skills for AI coding assistants. This repository packages focused `SKILL.md` entrypoints, reusable reference guides, and deterministic workflow tooling so Cypress help feels consistent, installable, and maintainable instead of prompt-fragile.

## What This Repository Is

This is a skill pack, not a single monolithic skill. The repository is organized so an agent can:

- route a broad Cypress request to the right subskill,
- load only the guidance needed for the current task,
- follow shared testing standards across implementation, planning, documentation, and CI,
- optionally use enterprise workflow extensions for handover, session-state, and test-management integration.

## What This Repository Is Not

- It is not a Cypress project template.
- It is not a shared-memory system.
- It does not require every optional pack to be installed together.
- It does not assume every team needs planning, documentation, or test-management workflows.

## Repository Design

The root [SKILL.md](SKILL.md) is a navigation layer. It owns routing, package boundaries, and shared standards.

Focused work should move quickly into a specialized subskill:

| Area | Primary path | Use it when |
|---|---|---|
| Core Cypress authoring | [core/](core/) | Writing, fixing, or reviewing Cypress tests |
| CI/CD | [ci/](ci/) | Configuring pipelines, sharding, artifacts, or container runs |
| Page-object architecture | [pom/](pom/) | Deciding between page objects, helpers, fixtures, and commands |
| Migration | [migration/](migration/) | Moving from Playwright or Selenium/WebDriver |
| CLI browser automation | [cypress-cli/](cypress-cli/) | Driving a browser from the terminal without writing a spec first |
| Test orchestration | [orchestrator/](orchestrator/) | Handling broad or ambiguous testing requests |
| Requirements analysis | [analysis/](analysis/) | Turning tickets or specs into testable behaviors |
| Coverage planning | [coverage_plan/](coverage_plan/) | Generating, reviewing, or synchronizing coverage plans |
| Documentation | [documentation/](documentation/) | Producing TDD, BDD, plain-text, code-doc, root-cause, handover, or session-state artifacts |
| Stakeholder reporting | [reporting/](reporting/) | Summarizing outcomes for non-technical audiences |
| Test-management integrations | [transformers/](transformers/), [mappers/](mappers/), [reporters/](reporters/) | Working with TestRail, Xray, Zephyr, or TestLink |
| IDE setup | [installers/](installers/) | Installing or aligning editor-specific workflows |

## Architecture Boundaries

This repository keeps three concerns separate:

| Concern | Responsibility | In scope here |
|---|---|---|
| Runtime execution | Solve the current Cypress task | Yes |
| Project-local persistence | Store repo-local plans, handovers, and resume state | Yes, in `coverage_plan/` and `documentation/` workflows |
| Shared cross-agent memory | Reuse durable knowledge across repos or teams | No, integrate an external shared-memory skill if needed |

That separation is intentional. Runtime notes should not silently become persistent artifacts, and project-local documentation should not silently become shared organizational memory.

## Installation

Install the full pack:

```bash
npx skills add jovd83/cypress-skill
```

Install focused packs when you only need part of the repository:

```bash
npx skills add jovd83/cypress-skill/core
npx skills add jovd83/cypress-skill/ci
npx skills add jovd83/cypress-skill/pom
npx skills add jovd83/cypress-skill/cypress-cli
npx skills add jovd83/cypress-skill/orchestrator
npx skills add jovd83/cypress-skill/analysis
npx skills add jovd83/cypress-skill/coverage_plan
npx skills add jovd83/cypress-skill/documentation
npx skills add jovd83/cypress-skill/reporters
npx skills add jovd83/cypress-skill/mappers
npx skills add jovd83/cypress-skill/transformers
```

Manual installation also works: clone the repository and place the desired skill folders in the directory your agent platform uses for local skills.

## Core Standards

Across the pack, the default stance is:

- prefer resilient, user-facing locators and meaningful assertions,
- avoid hard waits, placeholder tests, and fake completion claims,
- keep setup and state explicit,
- use page objects when repetition or complexity justifies the abstraction,
- use `cy.intercept()` intentionally and avoid mocking away the system under test,
- keep requirements, plans, documentation, and executable tests traceable when those artifacts exist.

These standards are deliberately opinionated. The goal is not theoretical purity; it is reliable outcomes under real delivery pressure.

## Optional Enterprise Workflows

Most Cypress users will care primarily about `core/`, `ci/`, `pom/`, `migration/`, and `cypress-cli/`.

The following areas are optional extensions:

- `analysis/` and `coverage_plan/` for requirements-driven planning
- `documentation/` for test-case artifacts, code documentation, root-cause reports, handovers, and live session-state
- `transformers/`, `mappers/`, and `reporters/` for enterprise test-management systems
- `installers/` and `reporting/` for environment-specific setup and stakeholder communication

See [reports/skill-inventory.md](reports/skill-inventory.md) for a generated inventory of every skill, its area, and metadata coverage.

README sections and skill descriptions call these optional where relevant so adopters can separate the core pack from the broader ecosystem.

## Validation

Run the repository quality gate before publishing or opening a pull request:

```powershell
powershell -NoProfile -File .\scripts\quality-gate.ps1
```

Regenerate the inventory report after adding, renaming, or reorganizing skills:

```powershell
powershell -NoProfile -File .\scripts\generate-skill-inventory.ps1
```

Verify the committed inventory report is fresh:

```powershell
powershell -NoProfile -File .\scripts\check-skill-inventory-freshness.ps1
```

For local preflight automation that syncs metadata and runs the full gate:

```powershell
powershell -NoProfile -File .\scripts\preflight.ps1
```

The repository includes GitHub Actions validation for repo-wide skill health and the Cypress handover workflow tooling.
It also includes a dedicated release workflow that runs preflight, validates generated artifacts, and packages a publishable release asset on version tags.

## Release Policy

This repository uses tag-driven GitHub releases.

- Release tags should use the format `vMAJOR.MINOR.PATCH`, for example `v1.1.0`.
- Create a release only after the quality gate passes locally and the changelog is updated.
- Treat `CHANGELOG.md` as the human-facing summary of notable changes.
- Treat `reports/skill-inventory.md` as a generated artifact that must stay fresh before tagging.

### What The Release Workflow Does

On a matching version tag, [.github/workflows/release.yml](.github/workflows/release.yml):

1. checks out the tagged revision,
2. installs Pester,
3. runs `scripts/preflight.ps1`,
4. packages the repository as a zip artifact,
5. uploads the build artifact,
6. publishes a GitHub release with generated release notes.

### What Gets Packaged

The release artifact currently includes the published skill surface and maintainer assets:

- root docs and metadata such as `README.md`, `SKILL.md`, `CHANGELOG.md`, `CONTRIBUTING.md`, and `LICENSE`
- all skill directories and their `agents/` metadata
- generated reports such as `reports/skill-inventory.md`
- scripts and tests used to validate and maintain the repository

### Maintainer Checklist

Before creating a release tag:

1. Update the relevant docs and `CHANGELOG.md`.
2. Run `powershell -NoProfile -File .\scripts\preflight.ps1`.
3. Confirm `reports/skill-inventory.md` is fresh.
4. Verify the intended version tag matches the release scope.
5. Push the tag and confirm the release workflow succeeds.

## Contributing

See CONTRIBUTING.md (missing) for repository conventions, validation expectations, and guidance for editing or adding skills without bloating the package.

## Upstream Credit

This repository builds on the upstream Cypress skill foundation originally published by [testdino-hq](https://github.com/testdino-hq/cypress-skill) under the MIT license. This version expands that base into a more structured, multi-skill package with stronger routing, validation, packaging, and enterprise workflow support.

## License

[MIT](LICENSE)
