---
name: cypress-core
description: Battle-tested Cypress patterns for E2E, API, component, visual, accessibility, and security testing. Covers selectors, assertions, hooks, intercepts, auth flows, debugging, and framework recipes for React, Next.js, Vue, and Angular.
metadata:
  author: jovd83
  version: '1.0'
  dispatcher-category: testing
  dispatcher-capabilities: ui-automation, cypress-core, cypress-implementation
  dispatcher-accepted-intents: implement_ui_confirmation_test, debug_cypress_test, review_cypress_test
  dispatcher-input-artifacts: repo_context, requirements, failing_ui_scenario, existing_cypress_suite
  dispatcher-output-artifacts: cypress_test, implementation_guidance, fix_plan
  dispatcher-stack-tags: cypress, ui-testing, implementation
  dispatcher-risk: high
  dispatcher-writes-files: true
---

# Cypress Core Testing

> Opinionated, production-tested Cypress guidance with explicit "when to use" and "when not to use" rules.

**46 reference guides** covering selectors, assertions, waiting, data setup, auth, network control, accessibility, component tests, visual checks, and debugging.


## Telemetry & Logging
> [!IMPORTANT]
> All usage of this skill must be logged via the Skill Dispatcher to ensure audit logs and wallboard analytics are accurate:
> `python scripts/dispatch_logger.py --skill <skill_name> --intent <intent> --reason <reason>`

## Golden Rules

1. **Use semantic locators first**: prefer `findByRole`/`findByLabelText` over brittle CSS chains.
2. **Do not use arbitrary sleeps**: avoid `cy.wait(2000)` for synchronization.
3. **Use retryable assertions**: `cy.get(...).should(...)` is the default stability model.
4. **Keep tests isolated**: no shared mutable state or order dependencies.
5. **Use `baseUrl` and environment config**: avoid hardcoded URLs.
6. **Use `cy.intercept()` for external dependencies**: avoid mocking your app internals.
7. **Use `cy.session()` for repeat auth flows**: cache login safely for speed.
8. **Avoid `{ force: true }` as a habit**: fix actionability or UI state first.
9. **Assert user-facing feedback for mutations**: validate toasts, banners, and state changes.
10. **Capture artifacts in CI**: screenshots/videos on failure are mandatory for triage.

## Official References

- Cypress best practices: https://docs.cypress.io/guides/references/best-practices

## Version Compatibility

| Dependency | Supported range | Why it matters |
|---|---|---|
| Cypress | `>=13.0.0` | Core guides rely on Cypress retryability and `cy.session()` patterns from v13+. |
| Node.js (by Cypress major) | Cypress 13-14: `>=18`; Cypress 15+: `20.x`, `22.x`, `>=24.x` | Running unsupported Node versions causes install/runtime failures. |
| TypeScript (optional) | Cypress <=14: `>=4`; Cypress 15+: `>=5` | Needed for typed config, commands, and examples in TS projects. |
| `@testing-library/cypress` | `10.x` | Enables semantic query examples such as `findByRole`. |

## Guide Index

### Writing Tests

| What you're doing | Guide | Deep dive |
|---|---|---|
| Choosing selectors | [locators.md](locators.md) | [locator-strategy.md](locator-strategy.md) |
| Assertions & waiting | [assertions-and-waiting.md](assertions-and-waiting.md) | |
| Organizing test suites | [test-organization.md](test-organization.md) | [test-architecture.md](test-architecture.md) |
| Cypress config | [configuration.md](configuration.md) | |
| Fixtures & hooks | [fixtures-and-hooks.md](fixtures-and-hooks.md) | |
| Test data | [test-data-management.md](test-data-management.md) | |
| Auth & login | [authentication.md](authentication.md) | [auth-flows.md](auth-flows.md) |
| API testing (REST/GraphQL) | [api-testing.md](api-testing.md) | |
| Visual regression | [visual-regression.md](visual-regression.md) | |
| Accessibility | [accessibility.md](accessibility.md) | |
| Mobile & responsive | [mobile-and-responsive.md](mobile-and-responsive.md) | |
| Component testing | [component-testing.md](component-testing.md) | |
| Network mocking | [network-mocking.md](network-mocking.md) | [when-to-mock.md](when-to-mock.md) |
| Forms & validation | [forms-and-validation.md](forms-and-validation.md) | |
| File uploads/downloads | [file-operations.md](file-operations.md) | [file-upload-download.md](file-upload-download.md) |
| Error & edge cases | [error-and-edge-cases.md](error-and-edge-cases.md) | |
| CRUD flows | [crud-testing.md](crud-testing.md) | |
| Drag and drop | [drag-and-drop.md](drag-and-drop.md) | |
| Search & filter UI | [search-and-filter.md](search-and-filter.md) | |
| Route behavior & navigation parity | [route-behavior.md](route-behavior.md) | |
| Locator strictness & resilience | [locator-resilience.md](locator-resilience.md) | |
| Testability hooks & automation contracts | [testability-hooks.md](testability-hooks.md) | |
| API handler hardening | [api-handler-hardening.md](api-handler-hardening.md) | |
| Contract-first mocking | [contract-first-mocking.md](contract-first-mocking.md) | |
| Environment preflight checks | [preflight.md](preflight.md) | |

### Debugging & Fixing

| Problem | Guide |
|---|---|
| General debugging workflow | [debugging.md](debugging.md) |
| Specific error message | [error-index.md](error-index.md) |
| Flaky / intermittent tests | [flaky-tests.md](flaky-tests.md) |
| Common beginner mistakes | [common-pitfalls.md](common-pitfalls.md) |
| Stability diagnostics | [stability-diagnostics.md](stability-diagnostics.md) |

### Framework Recipes

| Framework | Guide |
|---|---|
| Next.js (App Router + Pages Router) | [nextjs.md](nextjs.md) |
| React (CRA, Vite) | [react.md](react.md) |
| Vue 3 / Nuxt | [vue.md](vue.md) |
| Angular | [angular.md](angular.md) |

### Specialized Topics

| Topic | Guide |
|---|---|
| Multi-user & collaboration | [multi-user-and-collaboration.md](multi-user-and-collaboration.md) |
| WebSockets & real-time | [websockets-and-realtime.md](websockets-and-realtime.md) |
| Browser APIs (geo, clipboard, permissions) | [browser-apis.md](browser-apis.md) |
| iframes & Shadow DOM | [iframes-and-shadow-dom.md](iframes-and-shadow-dom.md) |
| Canvas & WebGL | [canvas-and-webgl.md](canvas-and-webgl.md) |
| Service workers & PWA | [service-workers-and-pwa.md](service-workers-and-pwa.md) |
| Electron apps | [electron-testing.md](electron-testing.md) |
| Browser extensions | [browser-extensions.md](browser-extensions.md) |
| Security testing | [security-testing.md](security-testing.md) |
| Performance & benchmarks | [performance-testing.md](performance-testing.md) |
| i18n & localization | [i18n-and-localization.md](i18n-and-localization.md) |
| Multi-tab & popups | [multi-context-and-popups.md](multi-context-and-popups.md) |
| Clock & time mocking | [clock-and-time-mocking.md](clock-and-time-mocking.md) |
| Third-party integrations | [third-party-integrations.md](third-party-integrations.md) |

### Architecture Decisions

| Question | Guide |
|---|---|
| Which locator strategy? | [locator-strategy.md](locator-strategy.md) |
| E2E vs component vs API? | [test-architecture.md](test-architecture.md) |
| Mock vs real services? | [when-to-mock.md](when-to-mock.md) |
