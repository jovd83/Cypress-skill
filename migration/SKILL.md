---
name: cypress-migration
description: Migration skill for moving existing UI automation to Cypress. Use when Codex needs to translate Playwright or Selenium/WebDriver patterns, plan incremental migration, preserve coverage during framework change, or explain architectural differences that affect the suite design.
metadata:
  author: jovd83
  version: "1.1"
  dispatcher-category: testing
  dispatcher-capabilities: framework-migration, cypress-migration
  dispatcher-accepted-intents: migrate_to_cypress
  dispatcher-input-artifacts: source_test_suite, repo_context, migration_scope
  dispatcher-output-artifacts: migration_plan, migrated_tests, compatibility_notes
  dispatcher-stack-tags: cypress, migration, framework
  dispatcher-risk: high
  dispatcher-writes-files: true
---

# Cypress Migration Guides

Use this skill when the user is moving from another browser automation stack to Cypress.


## Telemetry & Logging
> [!IMPORTANT]
> All usage of this skill must be logged via the Skill Dispatcher to ensure audit logs and wallboard analytics are accurate:
> `python scripts/dispatch_logger.py --skill <skill_name> --intent <intent> --reason <reason>`

## Migration Workflow

1. Inventory the existing suite structure, runner assumptions, and shared helpers.
2. Map framework concepts to Cypress equivalents.
3. Choose an incremental migration path that preserves confidence.
4. Revisit architecture decisions such as waiting, selectors, network control, fixtures, and CI once the syntax translation is done.

## Official References

- Cypress best practices: https://docs.cypress.io/guides/references/best-practices

## Guide Index

| Migrating from | Guide |
|---|---|
| Playwright | [from-playwright.md](from-playwright.md) |
| Selenium / WebDriver | [from-selenium.md](from-selenium.md) |

## Output Bias

Prefer migration plans, translated examples, and architecture notes over abstract comparisons.
