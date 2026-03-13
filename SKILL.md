---
name: cypress-skill
description: Battle-tested Cypress v13+ patterns for E2E, API, component, and visual testing, extended with an intelligent Orchestrator. Includes requirements analysis, functional coverage plans, formal TDD/BDD documentation, and test management integrations for TestLink, Zephyr, Xray, and TestRail. Covers CI/CD, migration guides, and specialized IDE installers.
---

# Cypress Skill

> Opinionated, production-tested Cypress guidance - every pattern includes when (and when *not*) to use it.

**50+ reference guides** covering the full Cypress surface: selectors, assertions, commands, page objects, network interception, auth, visual regression, accessibility, API testing, CI/CD, debugging, and more - with TypeScript and JavaScript examples throughout.

## Golden Rules

1. **Prefer `findByRole()` or robust `cy.get()` selectors over brittle CSS chains** - target user-facing semantics first
2. **Never `cy.wait(2000)` for timing** - wait on aliases, URL changes, or deterministic DOM assertions
3. **Use retryable assertions** - `cy.get(...).should(...)` retries; raw synchronous checks do not
4. **Isolate every test** - no shared state, no order dependencies
5. **Use `baseUrl` in config** - avoid hardcoded absolute URLs in tests
6. **Retries in CI, not local by default** - expose flakiness early while stabilizing pipelines
7. **Capture videos/screenshots on failure** - keep debugging artifacts without bloating local runs
8. **Use `cy.session()` for auth reuse** - speed up suites while preserving deterministic login state
9. **Avoid `{ force: true }` unless you first prove actionability is intentionally blocked**
10. **Prefer `cy.intercept()` for external dependencies** - never mock your own app internals
11. **Verify explicit user feedback** - always assert success/error toasts for state-changing flows
12. **POM for Repetition** - Use Page Object Models (POMs) primarily to avoid repetition across tests or for complex features. For simple, one-off test cases with no repetition, inline locators are acceptable. Repeated UI interactions MUST always be encapsulated in POMs.
13. **Strict Triad Architecture** - Enforce the separation of concerns: use **Fixtures** (`cy.fixture()`) or setup hooks (`beforeEach`) for setup/teardown and state, use **POMs** for UI interactions, and use **Custom Commands / `cy.task()`** exclusively for overarching app integrations or Node-based routines. NEVER mix Page Object concerns into custom commands.
14. **No Placeholder Assertions** - Every test must contain at least one meaningful assertion that validates the actual user requirement (e.g., `cy.get(locator).should('be.visible')`). NEVER use weak placeholders like `expect(true).to.be.true` or `cy.wrap({}).should('exist')` as a substitute for actual implementation.
15. **Standard Internal Core** - Keep all Page Objects (`cypress/support/pages/`), fixtures (`cypress/fixtures/`), and custom commands (`cypress/support/commands.ts`) together inside the `cypress/` directory. Avoid placing them in the project root to keep the testing context isolated and portable. (Note: If migrating from Playwright and preserving a `tests/` folder, mirror this structure inside `tests/`).

## Official References

- Cypress best practices: https://docs.cypress.io/guides/references/best-practices

## Compatibility Matrix

| Component | Supported range | Notes |
|---|---|---|
| Cypress | `>=13.0.0` | This skill pack is authored for Cypress v13+ patterns. |
| Node.js (by Cypress major) | Cypress 13-14: `>=18`; Cypress 15+: `20.x`, `22.x`, `>=24.x` | Keep Node aligned with your installed Cypress major. |
| TypeScript (`cypress.config.ts`) | Cypress <=14: `>=4`; Cypress 15+: `>=5` | Cypress 15 raised the TypeScript floor to 5. |
| `@testing-library/cypress` | `10.x` | Required for `findByRole`/`findByLabelText` examples in this pack. |
| Package managers | npm `>=10.1`, pnpm `>=8`, Yarn modern `>=4`, Yarn classic `>=1.22.22` | Match Cypress install prerequisites before running examples. |

## Guide Index

### Writing Tests

| What you're doing | Guide | Deep dive |
|---|---|---|
| Choosing selectors | [locators.md](core/locators.md) | [locator-strategy.md](core/locator-strategy.md) |
| Assertions & waiting | [assertions-and-waiting.md](core/assertions-and-waiting.md) | |
| Organizing test suites | [test-organization.md](core/test-organization.md) | [test-architecture.md](core/test-architecture.md) |
| Cypress config | [configuration.md](core/configuration.md) | |
| Page objects | [page-object-model.md](pom/page-object-model.md) | [pom-vs-fixtures-vs-helpers.md](pom/pom-vs-fixtures-vs-helpers.md) |
| Fixtures & hooks | [fixtures-and-hooks.md](core/fixtures-and-hooks.md) | |
| Test data | [test-data-management.md](core/test-data-management.md) | |
| Auth & login | [authentication.md](core/authentication.md) | [auth-flows.md](core/auth-flows.md) |
| API testing (REST/GraphQL) | [api-testing.md](core/api-testing.md) | |
| Visual regression | [visual-regression.md](core/visual-regression.md) | |
| Accessibility | [accessibility.md](core/accessibility.md) | |
| Mobile & responsive | [mobile-and-responsive.md](core/mobile-and-responsive.md) | |
| Component testing | [component-testing.md](core/component-testing.md) | |
| Network mocking | [network-mocking.md](core/network-mocking.md) | [when-to-mock.md](core/when-to-mock.md) |
| Forms & validation | [forms-and-validation.md](core/forms-and-validation.md) | |
| File uploads/downloads | [file-operations.md](core/file-operations.md) | [file-upload-download.md](core/file-upload-download.md) |
| Error & edge cases | [error-and-edge-cases.md](core/error-and-edge-cases.md) | |
| CRUD flows | [crud-testing.md](core/crud-testing.md) | |
| Drag and drop | [drag-and-drop.md](core/drag-and-drop.md) | |
| Search & filter UI | [search-and-filter.md](core/search-and-filter.md) | |
| Route behavior | [route-behavior.md](core/route-behavior.md) | |
| Locator resilience | [locator-resilience.md](core/locator-resilience.md) | |
| Testability hooks | [testability-hooks.md](core/testability-hooks.md) | |
| API hardening | [api-handler-hardening.md](core/api-handler-hardening.md) | |

### Debugging & Fixing

| Problem | Guide |
|---|---|
| General debugging workflow | [debugging.md](core/debugging.md) |
| Specific error message | [error-index.md](core/error-index.md) |
| Flaky / intermittent tests | [flaky-tests.md](core/flaky-tests.md) |
| Common beginner mistakes | [common-pitfalls.md](core/common-pitfalls.md) |
| Stability diagnostics | [stability-diagnostics.md](core/stability-diagnostics.md) |
| Preflight readiness | [preflight.md](core/preflight.md) |

### Framework Recipes

| Framework | Guide |
|---|---|
| Next.js (App Router + Pages Router) | [nextjs.md](core/nextjs.md) |
| React (CRA, Vite) | [react.md](core/react.md) |
| Vue 3 / Nuxt | [vue.md](core/vue.md) |
| Angular | [angular.md](core/angular.md) |

### Migration Guides

| From | Guide |
|---|---|
| Playwright | [from-playwright.md](migration/from-playwright.md) |
| Selenium / WebDriver | [from-selenium.md](migration/from-selenium.md) |

### Architecture Decisions

| Question | Guide |
|---|---|
| Which locator strategy? | [locator-strategy.md](core/locator-strategy.md) |
| E2E vs component vs API? | [test-architecture.md](core/test-architecture.md) |
| Mock vs real services? | [when-to-mock.md](core/when-to-mock.md) |
| Contract-first mocking | [contract-first-mocking.md](core/contract-first-mocking.md) |
| POM vs fixtures vs helpers? | [pom-vs-fixtures-vs-helpers.md](pom/pom-vs-fixtures-vs-helpers.md) |

### CI/CD & Infrastructure

| Topic | Guide |
|---|---|
| GitHub Actions | [ci-github-actions.md](ci/ci-github-actions.md) |
| GitLab CI | [ci-gitlab.md](ci/ci-gitlab.md) |
| CircleCI / Azure DevOps / Jenkins | [ci-other.md](ci/ci-other.md) |
| Parallel execution & sharding | [parallel-and-sharding.md](ci/parallel-and-sharding.md) |
| Docker & containers | [docker-and-containers.md](ci/docker-and-containers.md) |
| Reports & artifacts | [reporting-and-artifacts.md](ci/reporting-and-artifacts.md) |
| Code coverage | [test-coverage.md](ci/test-coverage.md) |
| Global setup/teardown | [global-setup-teardown.md](ci/global-setup-teardown.md) |
| Multi-project config | [projects-and-dependencies.md](ci/projects-and-dependencies.md) |

### Specialized Topics

| Topic | Guide |
|---|---|
| Multi-user & collaboration | [multi-user-and-collaboration.md](core/multi-user-and-collaboration.md) |
| WebSockets & real-time | [websockets-and-realtime.md](core/websockets-and-realtime.md) |
| Browser APIs (geo, clipboard, permissions) | [browser-apis.md](core/browser-apis.md) |
| iframes & Shadow DOM | [iframes-and-shadow-dom.md](core/iframes-and-shadow-dom.md) |
| Canvas & WebGL | [canvas-and-webgl.md](core/canvas-and-webgl.md) |
| Service workers & PWA | [service-workers-and-pwa.md](core/service-workers-and-pwa.md) |
| Electron apps | [electron-testing.md](core/electron-testing.md) |
| Browser extensions | [browser-extensions.md](core/browser-extensions.md) |
| Security testing | [security-testing.md](core/security-testing.md) |
| Performance & benchmarks | [performance-testing.md](core/performance-testing.md) |
| i18n & localization | [i18n-and-localization.md](core/i18n-and-localization.md) |
| Multi-tab & popups | [multi-context-and-popups.md](core/multi-context-and-popups.md) |
| Clock & time mocking | [clock-and-time-mocking.md](core/clock-and-time-mocking.md) |
| Third-party integrations | [third-party-integrations.md](core/third-party-integrations.md) |

### Test Orchestration & Management

| Category | Skill / Guide | Description |
|---|---|---|
| **Orchestrator** | [SKILL.md](orchestrator/SKILL.md) | Central command for test creation, planning, and execution |
| **Requirements Analysis** | [SKILL.md](analysis/SKILL.md) | Deriving epics, stories, and AC from raw requirements |
| **Functional Coverage** | [SKILL.md](coverage_plan/generation/SKILL.md) | Generating and [reviewing](coverage_plan/review/SKILL.md) complete coverage plans |
| **Stakeholder Reporting** | [SKILL.md](reporting/stakeholder/SKILL.md) | Human-readable reports for non-technical audiences |
| **Failure Analysis** | [SKILL.md](documentation/root_cause/SKILL.md) | AI-driven root cause analysis for test failures |
| **Coverage Auto-Sync** | [SKILL.md](coverage_plan/auto-sync/SKILL.md) | Keeping plans and traceability in sync |

### Test Case Documentation

| Format | Skill / Guide | Description |
|---|---|---|
| **TDD / IEEE 829** | [SKILL.md](documentation/test_cases/tdd/SKILL.md) | Formal test case specifications (ID, Steps, Expected) |
| **BDD / Gherkin** | [SKILL.md](documentation/test_cases/bdd/SKILL.md) | Given/When/Then scenarios with Examples and Tags |
| **Plain Text** | [SKILL.md](documentation/test_cases/plain_text/SKILL.md) | Concise, human-readable test descriptions |
| **Code Documentation** | [SKILL.md](documentation/tests/SKILL.md) | Generating JSDoc/TSDoc for Cypress automation code |
| **Handover** | [SKILL.md](documentation/cypress-handover/SKILL.md) | Resume-ready handover doc with status, session state, blockers, and next steps |
| **Session State** | [SKILL.md](documentation/session-state/SKILL.md) | Compatibility alias for session state preservation during handover |

### External Tool Integrations (Test Management)

| Tool | Transformer | Mapper | Reporter |
|---|---|---|---|
| **TestLink** | [Transform](transformers/testlink/SKILL.md) | [Map IDs](mappers/testlink/SKILL.md) | [API Report](reporters/testlink/SKILL.md) |
| **Zephyr Scale** | [Transform](transformers/zephyr/SKILL.md) | [Map IDs](mappers/zephyr/SKILL.md) | [API Report](reporters/zephyr/SKILL.md) |
| **Xray / Jira** | [Transform](transformers/xray/SKILL.md) | [Map IDs](mappers/xray/SKILL.md) | [API Report](reporters/xray/SKILL.md) |
| **TestRail** | [Transform](transformers/testrail/SKILL.md) | [Map IDs](mappers/testrail/SKILL.md) | [API Report](reporters/testrail/SKILL.md) |

### Installation & IDE Setup

| Environment | Skill / Guide | Description |
|---|---|---|
| **VSCode & Codex** | [SKILL.md](installers/vscode-codex/SKILL.md) | Setting up VSCode with OpenAI Codex and Cypress |
| **IntelliJ & Junie** | [SKILL.md](installers/intellij-junie/SKILL.md) | Configuring JetBrains IDEs with Junie AI assistant |

### CLI Browser Automation

| What you're doing | Guide |
|---|---|
| CLI browser interaction | [cypress-cli/SKILL.md](cypress-cli/SKILL.md) |
| Core commands (open, click, fill, navigate) | [core-commands.md](cypress-cli/core-commands.md) |
| Network mocking & interception | [request-mocking.md](cypress-cli/request-mocking.md) |
| Running custom Cypress code | [running-custom-code.md](cypress-cli/running-custom-code.md) |
| Multi-session browser management | [session-management.md](cypress-cli/session-management.md) |
| Cookies, localStorage, auth state | [storage-and-auth.md](cypress-cli/storage-and-auth.md) |
| Test code generation from CLI | [test-generation.md](cypress-cli/test-generation.md) |
| Debugging and artifacts | [debugging-and-artifacts.md](cypress-cli/debugging-and-artifacts.md) |
| Screenshots and video | [screenshots-and-media.md](cypress-cli/screenshots-and-media.md) |
| Device & environment emulation | [device-emulation.md](cypress-cli/device-emulation.md) |
| Complex multi-step workflows | [advanced-workflows.md](cypress-cli/advanced-workflows.md) |

## Language Note

All guides include TypeScript and JavaScript examples. When the project uses `.js` files or has no `tsconfig.json`, examples are adapted to plain JavaScript.

## Maintenance Checks

Use the built-in repository checks before publishing changes:

```powershell
powershell -NoProfile -File .\scripts\quality-gate.ps1
```

For local pre-commit automation (metadata sync + full gate), run:

```powershell
powershell -NoProfile -File .\scripts\preflight.ps1
```

For hard-zero residue scans, run:

```powershell
powershell -NoProfile -File .\scripts\quality-gate.ps1 -StrictResidue
```







