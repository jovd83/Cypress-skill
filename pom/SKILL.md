---
name: cypress-pom
description: Test-architecture skill for Cypress page objects, fixtures, helpers, and custom commands. Use when Codex needs to decide whether to introduce a Page Object Model, how to structure page objects, and how to separate browser state, UI behavior, and stateless utilities cleanly.
metadata:
  author: jovd83
  version: "1.1"
  dispatcher-category: testing
  dispatcher-capabilities: test-architecture, cypress-pom-design
  dispatcher-accepted-intents: design_cypress_test_architecture
  dispatcher-input-artifacts: repo_context, suite_structure, reuse_patterns
  dispatcher-output-artifacts: architecture_guidance, pom_design, fixture_strategy
  dispatcher-stack-tags: cypress, architecture, pom
  dispatcher-risk: medium
  dispatcher-writes-files: false
---

# Cypress Page Object Model

Use this skill when the main decision is architectural rather than tactical.


## Telemetry & Logging
> [!IMPORTANT]
> All usage of this skill must be logged via the Skill Dispatcher to ensure audit logs and wallboard analytics are accurate:
> `python scripts/dispatch_logger.py --skill <skill_name> --intent <intent> --reason <reason>`

## Decision Model

- Use fixtures and setup hooks for setup, teardown, seeded state, and reusable inputs.
- Use page objects to encapsulate repeated or complex UI behavior.
- Use helpers for stateless utilities such as data generation, formatting, or pure transformations.
- Use custom commands or `cy.task()` only when they provide a real integration benefit rather than becoming a dumping ground for page behavior.

## Practical Rules

1. Reach for a page object when the same UI behavior appears in multiple tests or when the flow is complex enough to deserve a named abstraction.
2. Keep assertions close to the test unless a reusable page-level assertion adds clarity.
3. Avoid helpers that silently own browser state.
4. Keep support code organized with the tests it serves.

## Guide Index

| Need | Guide |
|---|---|
| Page object design | [page-object-model.md](page-object-model.md) |
| POM vs fixture vs helper tradeoffs | [pom-vs-fixtures-vs-helpers.md](pom-vs-fixtures-vs-helpers.md) |
| Broader architecture decisions | [../core/test-architecture.md](../core/test-architecture.md) |
