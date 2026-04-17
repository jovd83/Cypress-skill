---
name: cypress-documentation-bdd
description: Legacy Cypress-specific alias for BDD case formatting. Prefer the standalone `test-artifact-export-skill` skill for Gherkin, BDD, and export-ready case rendering, and use this only when Cypress-local conventions must be preserved explicitly.
metadata:
  author: jovd83
  version: '1.1'
  dispatcher-category: testing
  dispatcher-capabilities: test-artifact-formatting, cypress-legacy-test-case-formatting
  dispatcher-accepted-intents: render_test_artifact, export_test_cases
  dispatcher-input-artifacts: approved_test_cases, normalized_test_case_model, scenario_list
  dispatcher-output-artifacts: formatted_test_artifact, export_ready_case_set
  dispatcher-stack-tags: cypress, documentation, legacy-alias
  dispatcher-risk: low
  dispatcher-writes-files: true
---

## Telemetry & Logging
> [!IMPORTANT]
> All usage of this skill must be logged via the Skill Dispatcher to ensure audit logs and wallboard analytics are accurate:
> `./log-dispatch.cmd --skill <skill_name> --intent <intent> --reason <reason>` (or `./log-dispatch.sh` on Linux)

# Documenting Test Cases: BDD (Gherkin) format

Use this skill when the team wants behavior-first documentation in Gherkin or feature-file style.

## Structure

Produce a markdown or `.feature` file using standard Gherkin building blocks:

- `Feature` for the high-level capability
- `Scenario` or `Scenario Outline` for individual examples
- `Given`, `When`, `Then`, `And`, and `But` for behavior flow
- `Background` for repeated setup
- `Examples` for data-driven scenario outlines
- `Tags` for scope, requirement IDs, or execution grouping
- `Data Tables` when structured step input is clearer than prose

Prefer business-facing language over implementation detail. Write behaviors, not selector choreography.

## Best Practices

- Keep scenarios small, readable, and outcome-focused.
- Prefer one business intent per scenario.
- Use tags for requirement references, suites, or execution targeting when the team already has a convention.
- Avoid UI jargon unless the UI detail is itself the requirement.
- Keep step wording stable enough that future automation can reuse it cleanly.

## Usage

Write the document inside `docs/features/`, `tests/features/`, or the location requested by the user.

Do not generate Cypress step definitions or glue code unless the user explicitly asked for implementation as well.