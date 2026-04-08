---
name: cypress-skill
description: Flagship Cypress skill pack for planning, authoring, debugging, documenting, and operationalizing Cypress work. Use when Codex needs Cypress guidance or routing across E2E, API, component, visual, accessibility, CI/CD, coverage planning, documentation, CLI browser automation, or optional handoff workflows.
metadata:
  author: jovd83
  version: "1.1"
  dispatcher-category: testing
  dispatcher-capabilities: ui-automation, cypress, coverage-planning, automation-routing
  dispatcher-accepted-intents: implement_ui_confirmation_test, plan_cypress_coverage, diagnose_cypress_failure, document_cypress_tests
  dispatcher-input-artifacts: repo_context, requirements, test_case_set, existing_cypress_suite, failing_ui_scenario
  dispatcher-output-artifacts: cypress_test, coverage_plan, root_cause_report, automation_docs, routing_request
  dispatcher-stack-tags: cypress, ui-testing, browser-automation
  dispatcher-risk: high
  dispatcher-writes-files: true
---

# Cypress Skill Pack

Use this root skill as the package entrypoint for general Cypress requests. It is responsible for routing work to the smallest useful subskill, applying the shared standards of this repository, and keeping the package boundaries clear.

Do not load every guide by default. Read only the subskill and reference files that materially help with the current task.

## Responsibilities

- Route broad or ambiguous Cypress requests to the right subskill.
- Apply the shared testing standards used across this repository.
- Keep core testing guidance separate from optional planning, documentation, reporting, and handoff workflows.

## Boundaries

- Do not duplicate deep implementation guidance that already lives in a focused subskill.
- Do not treat this repository as shared-memory infrastructure. If durable cross-agent knowledge is needed beyond one repo or skill, integrate an external shared-memory skill instead of storing it here implicitly.
- Do not silently promote runtime notes into persistent artifacts. Persistent outputs should be deliberate, named, and stored in a documented workflow such as `coverage_plan/` or `documentation/`.

## Dispatcher Integration

Use `skill-dispatcher` as the primary integration layer whenever this package needs help from another skill or when a broader orchestrator is deciding whether Cypress is the right execution layer.

- Prefer dispatcher-led routing by intent, especially for tasks such as `implement_ui_confirmation_test`, `render_test_artifact`, and `review_automation_quality`.
- Prefer the repository's native browser automation stack over Cypress when repo evidence points elsewhere.
- Treat direct paths to sibling skills as a compatibility fallback, not as the primary routing contract.
- Keep shared-memory usage limited to stable cross-project policy supplied externally, never task-local routing state.

## Routing Map

| Need | Use |
|---|---|
| Generic Cypress request or unclear starting point | [orchestrator/SKILL.md](orchestrator/SKILL.md) |
| Writing or fixing Cypress tests | [core/SKILL.md](core/SKILL.md) |
| CI, sharding, artifacts, containerized execution | [ci/SKILL.md](ci/SKILL.md) |
| Page-object structure or fixture-vs-helper decisions | [pom/SKILL.md](pom/SKILL.md) |
| Playwright or Selenium/WebDriver migration | [migration/SKILL.md](migration/SKILL.md) |
| CLI browser automation | [cypress-cli/SKILL.md](cypress-cli/SKILL.md) |
| Requirements extraction | [analysis/SKILL.md](analysis/SKILL.md) |
| Coverage planning | [coverage_plan/generation/SKILL.md](coverage_plan/generation/SKILL.md) and [coverage_plan/review/SKILL.md](coverage_plan/review/SKILL.md) |
| Coverage-plan maintenance | [coverage_plan/auto-sync/SKILL.md](coverage_plan/auto-sync/SKILL.md) |
| Narrative test documentation or format conversion | Dispatch `render_test_artifact` through `skill-dispatcher`; fall back to `C:\projects\skills\test-artifact-export-skill\SKILL.md` when needed |
| Automation-code documentation or failure diagnosis | [documentation/tests/SKILL.md](documentation/tests/SKILL.md) or [documentation/root_cause/SKILL.md](documentation/root_cause/SKILL.md) |
| Human or agent handoff workflows | [documentation/cypress-handover/SKILL.md](documentation/cypress-handover/SKILL.md) and [documentation/session-state/SKILL.md](documentation/session-state/SKILL.md) |
| Test-case export to Xray, Zephyr, TestLink, or TestRail | Dispatch `render_test_artifact` through `skill-dispatcher`; fall back to `C:\projects\skills\test-artifact-export-skill\SKILL.md` when needed |
| Test-management integrations after export exists | [mappers/](mappers/), and [reporters/](reporters/) subskills |
| IDE-specific setup help | [installers/](installers/) subskills |
| Non-technical summary reporting | [reporting/stakeholder/SKILL.md](reporting/stakeholder/SKILL.md) |

## Operating Workflow

1. Inspect the existing repository, tests, and requirements before prescribing structure.
2. Infer the user's intent when it is clear; ask for clarification only when the decision would materially change the artifact or scope.
3. Choose the smallest subskill that can complete the task well.
4. Load only the relevant reference guides or scripts for that path.
5. Produce concrete outputs such as code, plans, documentation, validation results, or stakeholder summaries instead of generic advice.

## Shared Standards

- Prefer resilient, user-facing locators and meaningful assertions.
- Avoid hard waits, placeholder tests, placeholder assertions, and fake completion claims.
- Keep setup and state explicit. Use `cy.session()` and seeded backend state intentionally, not implicitly.
- Keep UI behavior in page objects only when repetition or complexity justifies them; keep helpers stateless where possible.
- Mock external dependencies selectively; do not hide the behavior of the system under test behind unnecessary mocks.
- Keep requirements, plans, documentation, and executable tests traceable to one another when the workflow includes planning or documentation.

## Gotchas

- **Asynchronous Execution:** Cypress commands are added to a queue and run asynchronously. Do not use standard `async/await` with Cypress commands; use `.then()` for yielding values.
- **Conditional Testing Avoidance:** Avoid writing tests that conditionally behave differently depending on the DOM state (e.g., "if this button exists, click it"). Cypress expects deterministic state.
- **Cross-Origin Limits:** Navigating to a different superdomain within a single test requires `cy.origin()`.
- **Anti-Pattern Hard Waits:** Avoid using `cy.wait(Number)`. Always prefer waiting for aliases on network intercepts or relying on Cypress's built-in retry-ability on assertions.

## Official References

- Cypress best practices: https://docs.cypress.io/guides/references/best-practices

## Memory Model

- Runtime memory: ephemeral reasoning and task state for the current thread.
- Project-local persistent memory: artifacts such as coverage plans, handovers, session-state references, and generated documentation stored inside the target repository.
- Shared memory: optional and external. Promote information into shared memory only when it is stable, reusable across tasks, and belongs outside this skill pack.

## Package Shape

- `core/`, `ci/`, `pom/`, `migration/`, and `cypress-cli/` are the reusable testing foundation.
- `analysis/`, `coverage_plan/`, and `documentation/` add planning and traceability workflows.
- `documentation/cypress-handover/` and `documentation/session-state/` are optional operational workflows for multi-session or multi-operator work.
- `mappers/`, `reporters/`, `reporting/`, and `installers/` are optional extensions, not prerequisites for ordinary Cypress authoring.
- The standalone `test-artifact-export-skill` skill is the canonical formatter/exporter for narrative test cases and tool-ready artifacts, but reach it through `skill-dispatcher` first when cross-skill routing is available.

## Use the Root Skill Well

- Stay at the root only for routing, package discovery, or repo-wide standards.
- Move into a focused subskill as soon as the task is specific enough.
- Keep the package coherent: update the README, changelog, metadata, and validation artifacts when repo-level behavior changes.
