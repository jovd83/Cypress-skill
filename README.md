# Cypress Skill Pack

Cypress skills for E2E, API, component, visual, accessibility, and security testing, plus CLI automation. **85+ skills** with TypeScript and JavaScript examples.

## What are Agent Skills?
[Agent Skills](https://github.com/agentskills/agentskills) are a simple, open format for giving AI agents capabilities and expertise. They are essentially folders of instructions, scripts, and resources that agents can discover and use to perform better at specific tasks. Write once, use everywhere!

## Installation Manual

This repository provides Cypress skills designed for AI coding assistants (like OpenAI Codex or Junie). To take full advantage of these skills, you need to import them into your project so your agent can read them.

### Step 1: Base Installation
You can add all the core skills and the orchestrator at once using the `npx skills` command:

```bash
npx skills add <your-github-username>/cypress-skill
```

### Step 2: Customizing Your Setup
If you only need specific functionalities (e.g., just the reporters or just the mappers), you can add individual skill packs:

**Core & CI/CD**
```bash
npx skills add <your-github-username>/cypress-skill/core
npx skills add <your-github-username>/cypress-skill/ci
npx skills add <your-github-username>/cypress-skill/pom
npx skills add <your-github-username>/cypress-skill/migration
npx skills add <your-github-username>/cypress-skill/cypress-cli
```

**Test Management Extensions**
```bash
npx skills add <your-github-username>/cypress-skill/orchestrator
npx skills add <your-github-username>/cypress-skill/analysis
npx skills add <your-github-username>/cypress-skill/coverage_plan
npx skills add <your-github-username>/cypress-skill/documentation
npx skills add <your-github-username>/cypress-skill/transformers
npx skills add <your-github-username>/cypress-skill/mappers
npx skills add <your-github-username>/cypress-skill/reporters
npx skills add <your-github-username>/cypress-skill/reporting
```

Once installed, your AI agent will automatically reference the `SKILL.md` files imported into your workspace when you ask it testing-related questions!

### Manual Installation (Alternative)
If you prefer not to use `npx skills`, you can manually download this repository and place the guides in either a system-wide or IDE-specific skills directory.

**1. Download the Files**
Download or clone this repository to your local machine:
```bash
git clone https://github.com/jovd83/cypress-skill.git
```

**2. Place the Skills Folder**
Move the `cypress-skill` folder to the appropriate location where your AI assistant looks for custom skills:

- **System-wide (Generic Agents):** Typically placed in a shared directory like `~/.agents/skills/`.
- **For a specific IDE:** Copy the folder into `~/.cursor/skills/`.
  *Note: Check the documentation of your specific AI assistant for the exact directory paths it supports for injecting local skill files. i.e.:*
  - *Google antigravity: https://antigravity.google/docs/skills*
  - *Cursor: https://cursor.dev/docs/skills*
  - *Visual Studio Code: https://code.visualstudio.com/docs/copilot/customization/agent-skills*
  - *JetBrains: https://plugins.jetbrains.com/plugin/29975-agent-skills-manage*
  - *OpenClaw: https://docs.openclaw.ai/tools/skills*

## Skills Overview

| Skill Pack | Guides | What's Covered |
|---|:---:|---|
| **core** | 54 | Locators, assertions, fixtures, auth, API testing, network mocking, visual regression, accessibility, debugging, framework recipes |
| **ci** | 9 | GitHub Actions, GitLab CI, CircleCI, Azure DevOps, Jenkins, Docker, sharding, reporting, coverage |
| **pom** | 2 | Page Object Model patterns, POM vs fixtures vs helpers |
| **migration** | 2 | Migrating from Playwright, migrating from Selenium |
| **cypress-cli** | 11 | CLI browser automation, screenshots, recording, session management, device emulation |

## Core Skills

The foundation of Cypress testing. These guides cover everything you need to write, debug, and maintain reliable end-to-end tests.

- **Start here** if you're new to Cypress - begin with locators, assertions, and fixtures
- Covers common patterns like authentication, API testing, network mocking, and visual regression
- Includes framework-specific recipes for React, Vue, Angular, and Next.js
- Debugging guides to help you fix flaky tests and common pitfalls

### Writing Tests

| Guide | Description |
|---|---|
| [locators.md](core/locators.md) | Selector strategies |
| [assertions-and-waiting.md](core/assertions-and-waiting.md) | Retry-ability, assertions, explicit waiting |
| [fixtures-and-hooks.md](core/fixtures-and-hooks.md) | `cy.fixture()`, `beforeEach`, setup/teardown |
| [configuration.md](core/configuration.md) | `cypress.config.ts`, timeouts, reporters |
| [test-organization.md](core/test-organization.md) | File structure, grouping |
| [test-data-management.md](core/test-data-management.md) | Factories, seeding, cleanup strategies |
| [authentication.md](core/authentication.md) | `cy.session()`, multi-role auth |
| [api-testing.md](core/api-testing.md) | REST and GraphQL testing with `cy.request` |
| [network-mocking.md](core/network-mocking.md) | Route interception (`cy.intercept`) |
| [forms-and-validation.md](core/forms-and-validation.md) | Form fills, validation, error states |
| [visual-regression.md](core/visual-regression.md) | Screenshot comparison, thresholds |
| [accessibility.md](core/accessibility.md) | cypress-axe integration |
| [component-testing.md](core/component-testing.md) | Mount React/Vue/Angular components |
| [mobile-and-responsive.md](core/mobile-and-responsive.md) | Viewport testing (`cy.viewport`) |
| [search-and-filter.md](core/search-and-filter.md) | Testing search bars and filter combinations |
| [route-behavior.md](core/route-behavior.md) | URL routing, query parameters, navigation |
| [locator-resilience.md](core/locator-resilience.md) | Making locators robust against layout shifts |
| [testability-hooks.md](core/testability-hooks.md) | Exposing internal state specifically for testing |
| [api-handler-hardening.md](core/api-handler-hardening.md) | Unit testing API endpoints directly |
| [contract-first-mocking.md](core/contract-first-mocking.md) | Contract-driven network mocking |

### Debugging & Fixing

| Guide | Description |
|---|---|
| [debugging.md](core/debugging.md) | Cypress UI, DevTools, `cy.pause()`, `.debug()` |
| [error-index.md](core/error-index.md) | Common error messages and how to fix them |
| [flaky-tests.md](core/flaky-tests.md) | Root causes, stabilization patterns |
| [common-pitfalls.md](core/common-pitfalls.md) | Top beginner mistakes and how to avoid them |
| [stability-diagnostics.md](core/stability-diagnostics.md) | Diagnostics for element pointer interception |
| [preflight.md](core/preflight.md) | Environment readiness preflight checks |

### Framework Recipes

| Guide | Description |
|---|---|
| [nextjs.md](core/nextjs.md) | App Router + Pages Router testing |
| [react.md](core/react.md) | CRA, Vite, component testing |
| [vue.md](core/vue.md) | Vue 3 / Nuxt testing |
| [angular.md](core/angular.md) | Angular testing patterns |

### Specialized Topics

| Guide | Description |
|---|---|
| [browser-apis.md](core/browser-apis.md) | Geolocation, clipboard, permissions |
| [iframes-and-shadow-dom.md](core/iframes-and-shadow-dom.md) | Cross-frame testing, Shadow DOM |
| [multi-context-and-popups.md](core/multi-context-and-popups.md) | Handling multiple tabs and popups |
| [websockets-and-realtime.md](core/websockets-and-realtime.md) | WebSocket testing, real-time UI |
| [canvas-and-webgl.md](core/canvas-and-webgl.md) | Canvas testing |
| [electron-testing.md](core/electron-testing.md) | Electron testing |
| [security-testing.md](core/security-testing.md) | XSS, CSRF, header validation |
| [performance-testing.md](core/performance-testing.md) | Lighthouse integration |
| [clock-and-time-mocking.md](core/clock-and-time-mocking.md) | Using `cy.clock` and `cy.tick` |
| [service-workers-and-pwa.md](core/service-workers-and-pwa.md) | PWA testing |
| [browser-extensions.md](core/browser-extensions.md) | Extension testing |
| [i18n-and-localization.md](core/i18n-and-localization.md) | Language and locale testing |
| [third-party-integrations.md](core/third-party-integrations.md) | Stripe, Firebase, external services |

## CI/CD Skills

| Guide | Description |
|---|---|
| [ci-github-actions.md](ci/ci-github-actions.md) | Workflows, caching |
| [ci-gitlab.md](ci/ci-gitlab.md) | GitLab CI pipelines |
| [ci-other.md](ci/ci-other.md) | CircleCI, Azure DevOps, Jenkins |
| [parallel-and-sharding.md](ci/parallel-and-sharding.md) | Cypress Cloud sharding/parallelization |
| [docker-and-containers.md](ci/docker-and-containers.md) | Cypress Docker images |
| [reporting-and-artifacts.md](ci/reporting-and-artifacts.md) | JUnit, Mochawesome |
| [test-coverage.md](ci/test-coverage.md) | Code coverage collection via Istanbul |
| [global-setup-teardown.md](ci/global-setup-teardown.md) | One-time global setup |
| [projects-and-dependencies.md](ci/projects-and-dependencies.md) | Multi-project setup |

## Cypress CLI Skills

| Guide | Description |
|---|---|
| [core-commands.md](cypress-cli/core-commands.md) | Open, navigate, click, fill |
| [request-mocking.md](cypress-cli/request-mocking.md) | Network interception and mocking |
| [running-custom-code.md](cypress-cli/running-custom-code.md) | Cypress plugins and tasks |
| [session-management.md](cypress-cli/session-management.md) | Session preservation and caching |
| [storage-and-auth.md](cypress-cli/storage-and-auth.md) | Cookies and localStorage manipulation |
| [test-generation.md](cypress-cli/test-generation.md) | Using Cypress Studio to generate tests |
| [debugging-and-artifacts.md](cypress-cli/debugging-and-artifacts.md) | Cypress debug capabilities |
| [screenshots-and-media.md](cypress-cli/screenshots-and-media.md) | Screenshots, video recording |
| [device-emulation.md](cypress-cli/device-emulation.md) | Viewport and device mocking |
| [advanced-workflows.md](cypress-cli/advanced-workflows.md) | Complex multi-step scenarios |

## Migration Skills

| Guide | Description |
|---|---|
| [from-playwright.md](migration/from-playwright.md) | Playwright to Cypress migration |
| [from-selenium.md](migration/from-selenium.md) | Selenium/WebDriver to Cypress migration |

## Page Object Model Skills

| Guide | Description |
|---|---|
| [page-object-model.md](pom/page-object-model.md) | POM patterns for Cypress |
| [pom-vs-fixtures-vs-helpers.md](pom/pom-vs-fixtures-vs-helpers.md) | When to use POM vs custom commands |

## Skills Documentation

This section provides a detailed index of all AI skills and deep-dive guides. These files are designed to be consumed by AI agents to provide expert-level assistance throughout the testing lifecycle.

### 1. Automation Core (The Foundation)

- **[SKILL.md](core/SKILL.md)**: The primary entry point for the core pack, guiding the agent in setting up a robust, web-first automation foundation.
- **[locators.md](core/locators.md)**: Detailed strategies for the locator hierarchy, prioritizing user-facing roles and test-IDs.
- **[locator-strategy.md](core/locator-strategy.md)**: Theoretical and practical comparison of different locator methods.
- **[assertions-and-waiting.md](core/assertions-and-waiting.md)**: Patterns for assertion retries, aliasing, and avoiding implicit waits.
- **[fixtures-and-hooks.md](core/fixtures-and-hooks.md)**: Using `cy.fixture()`, before/after hooks correctly.
- **[configuration.md](core/configuration.md)**: Deep dive into `cypress.config.ts`.
- **[test-organization.md](core/test-organization.md)**: Guidelines for folder structures and `describe`/`it` blocks.
- **[test-data-management.md](core/test-data-management.md)**: Strategies for factories, seeding, and cleanup.
- **[test-architecture.md](core/test-architecture.md)**: High-level patterns for choosing between E2E, API, and component tests.
- **[authentication.md](core/authentication.md)**: Usage of `cy.session()` to speed up suite executions.
- **[auth-flows.md](core/auth-flows.md)**: Step-by-step recipes for different authentication scenarios.
- **[api-testing.md](core/api-testing.md)**: Best practices for combining UI and API testing with `cy.request()`.
- **[network-mocking.md](core/network-mocking.md)**: Recipes for route interception via `cy.intercept()`.
- **[when-to-mock.md](core/when-to-mock.md)**: Decision framework for choosing between real APIs and local stubs.
- **[forms-and-validation.md](core/forms-and-validation.md)**: Comprehensive guide for testing complex forms.
- **[crud-testing.md](core/crud-testing.md)**: Patterns for Create, Read, Update, and Delete workflows.
- **[drag-and-drop.md](core/drag-and-drop.md)**: Reliable patterns for testing mouse-driven drag and drop `trigger()` events.
- **[file-operations.md](core/file-operations.md)**: Using `cy.readFile()` and `cy.writeFile()`.
- **[file-upload-download.md](core/file-upload-download.md)**: Recipes for `selectFile` and verifying downloads.
- **[visual-regression.md](core/visual-regression.md)**: Using Cypress image snapshot plugins.
- **[accessibility.md](core/accessibility.md)**: Integrating `cypress-axe`.
- **[mobile-and-responsive.md](core/mobile-and-responsive.md)**: Testing across viewports with `cy.viewport()`.
- **[iframes-and-shadow-dom.md](core/iframes-and-shadow-dom.md)**: Strategies for accessing cross-origin iframes and piercing the Shadow DOM.
- **[multi-context-and-popups.md](core/multi-context-and-popups.md)**: Workarounds for multi-tab testing within Cypress constraints.
- **[multi-user-and-collaboration.md](core/multi-user-and-collaboration.md)**: Patterns for testing real-time collaborative features.
- **[websockets-and-realtime.md](core/websockets-and-realtime.md)**: Asserting on real-time UI updates via sockets.
- **[browser-apis.md](core/browser-apis.md)**: Stubbing Geolocation and permissions natively.
- **[browser-extensions.md](core/browser-extensions.md)**: Loading plugins inside the Cypress runner.
- **[service-workers-and-pwa.md](core/service-workers-and-pwa.md)**: Testing Service Worker registration.
- **[canvas-and-webgl.md](core/canvas-and-webgl.md)**: Testing Canvas elements.
- **[electron-testing.md](core/electron-testing.md)**: Electron application testing methodologies.
- **[security-testing.md](core/security-testing.md)**: Basic security audits.
- **[performance-testing.md](core/performance-testing.md)**: Cypress Lighthouse audits.
- **[clock-and-time-mocking.md](core/clock-and-time-mocking.md)**: Leveraging `cy.clock()` and `cy.tick()`.
- **[i18n-and-localization.md](core/i18n-and-localization.md)**: Changing browser locales.
- **[third-party-integrations.md](core/third-party-integrations.md)**: Mocking external Stripe/Firebase calls.
- **[component-testing.md](core/component-testing.md)**: React/Vue component testing configurations.
- **[react.md](core/react.md)**, **[vue.md](core/vue.md)**, **[angular.md](core/angular.md)**, **[nextjs.md](core/nextjs.md)**: Framework-specific references.
- **[debugging.md](core/debugging.md)**: Using the Cypress runner UI and `cy.pause()`.
- **[error-index.md](core/error-index.md)**: A searchable catalog of Cypress errors.
- **[error-and-edge-cases.md](core/error-and-edge-cases.md)**: Designing tests for "unhappy paths".
- **[flaky-tests.md](core/flaky-tests.md)**: Retrying flaky interactions.
- **[common-pitfalls.md](core/common-pitfalls.md)**: Returning promises inside of `.then()` or anti-patterns avoiding closures.
- **[search-and-filter.md](core/search-and-filter.md)**: Testing debounce UI limits.
- **[route-behavior.md](core/route-behavior.md)**: Handling URL routing via `cy.location()`.
- **[locator-resilience.md](core/locator-resilience.md)**: Scoping elements robustly to avoid hidden overlaps.
- **[testability-hooks.md](core/testability-hooks.md)**: Semantic automation contracts.
- **[api-handler-hardening.md](core/api-handler-hardening.md)**: API endpoint business logic verification.
- **[stability-diagnostics.md](core/stability-diagnostics.md)**: Avoiding { force: true } and letting tests properly check element states.
- **[preflight.md](core/preflight.md)**: Scripted health validations ahead of Cypress execution.
- **[contract-first-mocking.md](core/contract-first-mocking.md)**: Network stubbing while backend environments deploy.

### 2. CI/CD & Infrastructure

- **[SKILL.md](ci/SKILL.md)**: The orchestrator for pipeline setup.
- **[ci-github-actions.md](ci/ci-github-actions.md)**: Optimized YAML examples for GitHub Actions.
- **[ci-gitlab.md](ci/ci-gitlab.md)**: Implementation guide for GitLab CI/CD.
- **[ci-other.md](ci/ci-other.md)**: CircleCI/Jenkins templates.
- **[parallel-and-sharding.md](ci/parallel-and-sharding.md)**: Leveraging Cypress Cloud parallelization.
- **[docker-and-containers.md](ci/docker-and-containers.md)**: Cypress base Docker images.
- **[reporting-and-artifacts.md](ci/reporting-and-artifacts.md)**: XML and Mochawesome JSON publishing.
- **[test-coverage.md](ci/test-coverage.md)**: Native Cypress Code Coverage.
- **[global-setup-teardown.md](ci/global-setup-teardown.md)**: Setting up state ahead of test suites.
- **[projects-and-dependencies.md](ci/projects-and-dependencies.md)**: Working with workspaces and mono-repos.

### 3. Requirements & Planning

- **[analysis/SKILL.md](analysis/SKILL.md)**: High-level skill for extracting testable requirements.
- **[coverage_plan/generation/SKILL.md](coverage_plan/generation/SKILL.md)**: Logic for deriving a functional coverage plan.
- **[coverage_plan/review/SKILL.md](coverage_plan/review/SKILL.md)**: Human-in-the-loop review session for the testing plan.
- **[coverage_plan/auto-sync/SKILL.md](coverage_plan/auto-sync/SKILL.md)**: Keeping plans and traceability in sync with actual runs.

### 4. Test Documentation & Failure Analysis

- **[documentation/test_cases/tdd/SKILL.md](documentation/test_cases/tdd/SKILL.md)**: Formal Traceability-focused test case template.
- **[documentation/test_cases/bdd/SKILL.md](documentation/test_cases/bdd/SKILL.md)**: BDD step definitions and Feature drafts.
- **[documentation/test_cases/plain_text/SKILL.md](documentation/test_cases/plain_text/SKILL.md)**: Informal test planning.
- **[documentation/tests/SKILL.md](documentation/tests/SKILL.md)**: Automatic documentation updates using JSDoc styles for Cypress.
- **[documentation/root_cause/SKILL.md](documentation/root_cause/SKILL.md)**: Documenting bug investigations explicitly.
- **[documentation/cypress-handover/SKILL.md](documentation/cypress-handover/SKILL.md)**: Resume-ready handovers capturing completed work, current state, session state, blockers, and restart steps.
- **[documentation/session-state/SKILL.md](documentation/session-state/SKILL.md)**: Compatibility alias for record session state in the canonical handover workflow.

### 5. Cypress CLI

- **[SKILL.md](cypress-cli/SKILL.md)**: CLI usage entry bounds.
- **[core-commands.md](cypress-cli/core-commands.md)**: Cypress executable flags and behaviors.
- **[session-management.md](cypress-cli/session-management.md)**: Profile executions.
- **[storage-and-auth.md](cypress-cli/storage-and-auth.md)**: Pre-flight state logic.
- **[test-generation.md](cypress-cli/test-generation.md)**: Studio tools for step interception drafting.
- **[request-mocking.md](cypress-cli/request-mocking.md)**: Intercept generation via GUI.
- **[running-custom-code.md](cypress-cli/running-custom-code.md)**: Module hook behaviors.
- **[screenshots-and-media.md](cypress-cli/screenshots-and-media.md)**: CI image dumping defaults.
- **[device-emulation.md](cypress-cli/device-emulation.md)**: Using chrome config variations cleanly.
- **[debugging-and-artifacts.md](cypress-cli/debugging-and-artifacts.md)**: Handling traces and reports.
- **[advanced-workflows.md](cypress-cli/advanced-workflows.md)**: CI test triggers.

### 6. Migration & Architecture

- **[migration/SKILL.md](migration/SKILL.md)**: Migration strategies.
- **[migration/from-playwright.md](migration/from-playwright.md)**: Command-by-command mapping for Playwright converts.
- **[migration/from-selenium.md](migration/from-selenium.md)**: Transitioning past Selenium drivers.
- **[pom/SKILL.md](pom/SKILL.md)**: Overview of POM practices.
- **[pom/page-object-model.md](pom/page-object-model.md)**: Object structuring patterns safely avoiding static properties.
- **[pom/pom-vs-fixtures-vs-helpers.md](pom/pom-vs-fixtures-vs-helpers.md)**: Utilizing `cy.task()` appropriately over POM implementations.

### 7. Enterprise Integration & Orchestration

- **[orchestrator/SKILL.md](orchestrator/SKILL.md)**: Core request processing router.
- **[reporting/stakeholder/SKILL.md](reporting/stakeholder/SKILL.md)**: Executive summaries.
- **[transformers/](transformers/)**: Converters for formatting test scenarios for **Zephyr**, **Xray**, **TestRail**, and **TestLink**.
- **[mappers/](mappers/)**: Syncing unique management tool IDs.
- **[reporters/](reporters/)**: Publishing test execution results explicitly to remote hubs.
- **[installers/](installers/)**: Platform-specific installation guides for **VS Code (Codex)** and **IntelliJ (Junie)**.

## Documentation Quality Gate

Run the repository-level documentation checks:

- markdown link integrity
- quality-gate check coverage (all `scripts/check-*.ps1` are wired into `quality-gate.ps1`)
- quality-gate integrity (unique `Invoke-Check` names and exactly-once check-script invocation)
- check-script conventions (`check-*.ps1` requires canonical `Root` param and fail-fast error mode)
- text integrity scan (mojibake/encoding artifacts)
- spelling sanity for `playwright` (blocks common misspellings in markdown)
- markdown structural integrity (balanced code fences + consistent table rows)
- fenced code language tags (opening code fences require an explicit language)
- code-fence language policy by directory (enforced allowed languages per skill area/root docs)
- `cypress-cli` command snippet validity
- `cypress-handover` package integrity (required files, sections, and template placeholders)
- `cypress-handover` Pester suite pass (logic, overrides, and link repair)
- `cypress-handover` smoke test pass (end-to-end task lifecycle)
- Bash workflow block parity with nearby PowerShell examples in `cypress-cli/*.md`
- Cypress command queue safety patterns (no `await cy...`, no `Promise.all([cy...])`)
- hard-wait guard in runnable code fences (blocks numeric `cy.wait(...)` except documented polling/comment cases)
- force-true context guard in runnable code fences (allow only explicit `selectFile(...)`/`trigger(...)` contexts)
- `agents/openai.yaml` coverage and required metadata fields per skill
- `agents/openai.yaml` drift check against each `SKILL.md` frontmatter
- skill index coverage check (each pack `SKILL.md` links its local guides)
- core guide section contract (`When to use` + `Anti-Patterns`)
- cypress-cli guide section contract (`When to use` + `Prerequisites` + `Anti-Patterns`)
- ci/pom guide section contract (`When to use` + `Prerequisites` + `Anti-Patterns`)
- migration guide section contract (`When to use` + `Prerequisites` + `Anti-Patterns` + `Checklist`)
- migration example language parity (each `## Example:` includes Cypress TS + JS fenced blocks)
- migration alias/wait pairing (`.as('alias')` in Cypress example blocks requires `cy.wait('@alias')`)
- Playwright->Cypress command mapping sanity (`migration/from-playwright.md` table guard)
- migration source-column purity (source framework table column must not contain `cy.*` commands)
- migration source-example purity (Playwright/Selenium source blocks must stay source-native and non-Cypress)
- documentation skill section contract (required structure per `documentation/*/SKILL.md`)
- planning/reporting skill section contract (`orchestrator`, `analysis`, `coverage_plan/*`, `reporting/stakeholder`)
- test-management integration skill section contract (`mappers/*`, `transformers/*`, `reporters/*`)
- installer skill section contract (`installers/*/SKILL.md` headings + prerequisites + steps)
- installer command canonical check (`npm init cypress@latest` in installer guides)
- official Cypress best-practices reference presence in entry `SKILL.md` files
- `SKILL.md` frontmatter integrity (delimiter, required fields, unique names)
- skill-name prefix convention (`name:` in every `SKILL.md` must start with `cypress-`)
- skill-description convention (`description:` in every `SKILL.md` must include `Cypress`)
- CI workflow wiring check (`.github/workflows/quality-gate.yml`)
- structural parity with the sibling skill tree
- residue policy (including Playwright API signatures) and structural parity checks

```powershell
powershell -NoProfile -File .\scripts\quality-gate.ps1
```

Run local preflight (auto-sync metadata, then run full gate):

```powershell
powershell -NoProfile -File .\scripts\preflight.ps1
```

Strict residue mode (requires zero Playwright references in all markdown files):

```powershell
powershell -NoProfile -File .\scripts\quality-gate.ps1 -StrictResidue
```

Force parity comparison with sibling `..\Playwright-skill`:

```powershell
powershell -NoProfile -File .\scripts\quality-gate.ps1 -RequireParitySource
```

Preflight with strict residue and required source parity:

```powershell
powershell -NoProfile -File .\scripts\preflight.ps1 -StrictResidue -RequireParitySource
```

Regenerate all metadata files from `SKILL.md` frontmatter:

```powershell
powershell -NoProfile -File .\scripts\sync-agents-metadata.ps1
```

## Cypress Defaults Used Across This Repo

- Prefer semantic selectors (`cy.findByRole`) and stable `data-testid` selectors.
- Prefer `cy.intercept` over internal method mocking.
- Avoid `force: true` unless there is a documented UI constraint.
- Use `cy.session()` for login reuse.
- Keep tests deterministic by asserting on visible user outcomes.
