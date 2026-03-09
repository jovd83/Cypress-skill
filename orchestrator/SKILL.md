---
name: cypress-orchestrator
description: An orchestrator skill that acts as the primary contact point for Cypress testing. It prompts the user for their goals (new tests, existing tests, planning, documenting, etc.) and routes them to the appropriate skills.
---

# Cypress Orchestrator

Use this as the primary entry point for generic Cypress requests.

## Deterministic First Question

If intent is not explicit, ask exactly one question:

> "What do you want to do right now: create tests, run/debug tests, plan coverage from requirements, document tests, transform for test management tools, report results, or migration/setup?"

Wait for the user response before routing.

If intent is already clear in the first user message, skip this question and route immediately.

## Intent Routing Table

| User intent | Route | Follow-up (only if needed) |
|---|---|---|
| Create new tests from feature scope | `core`, `pom`, `ci` | "Scope: smoke, happy path, or regression?" |
| Create tests from requirements docs | `analysis` -> `coverage_plan/generation` -> `coverage_plan/review` -> `core/pom` | "Should scenarios be AI-defined or mapped from existing test cases?" |
| Run/debug failing tests | `core/debugging`, `core/error-index`, `documentation/root_cause` | "Share failure output/logs first, then we triage." |
| Document test cases | `documentation/test_cases/tdd` or `documentation/test_cases/bdd` or `documentation/test_cases/plain_text` | "Which format do you need?" |
| Document existing code tests | `documentation/tests` | "Document all specs or a specific folder?" |
| Transform to test-management import | `transformers/*` | "Target tool: TestLink, Zephyr, Xray, or TestRail?" |
| Map external IDs to docs | `mappers/*` | "Which system's IDs are you mapping?" |
| Publish execution results to tools | `reporters/*` | "Which tool and what run metadata should be sent?" |
| Stakeholder summary report | `reporting/stakeholder` | "Audience: technical lead, product, or management?" |
| Migration from other framework | `migration` | "Source stack: current framework or Selenium/WebDriver?" |
| IDE setup/install | `installers/*` | "Environment: VSCode/Codex or IntelliJ/Junie?" |
| CLI browser automation workflows | `cypress-cli` | "Do you need interaction, scraping, mocking, or diagnostics?" |

## Orchestration Rules

1. Use the minimum skill set needed for the requested outcome.
2. Ask at most one blocking clarification at a time.
3. Prefer direct execution over planning-only responses when context is sufficient.
4. Keep test recommendations Cypress-native and deterministic.
5. End with clear next actions or outputs delivered.







