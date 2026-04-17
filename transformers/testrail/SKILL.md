---
name: cypress-transformer-testrail
description: Legacy Cypress-specific alias for TestRail case export. Prefer the standalone `test-artifact-export-skill` skill for transforming approved test cases into TestRail-ready artifacts, and use this only when Cypress-local conventions must be preserved explicitly.
metadata:
  author: jovd83
  version: '1.1'
  dispatcher-category: testing
  dispatcher-capabilities: test-artifact-formatting, cypress-legacy-export-transform
  dispatcher-accepted-intents: render_test_artifact, export_test_cases
  dispatcher-input-artifacts: approved_test_cases, normalized_test_case_model, destination_constraints
  dispatcher-output-artifacts: transformed_test_artifact, export_bundle
  dispatcher-stack-tags: cypress, transform, legacy-alias
  dispatcher-risk: low
  dispatcher-writes-files: true
---

# Transforming Test Cases to TestRail

Use this skill to convert narrative test cases into TestRail import artifacts.


## Telemetry & Logging
> [!IMPORTANT]
> All usage of this skill must be logged via the Skill Dispatcher to ensure audit logs and wallboard analytics are accurate:
> `python scripts/dispatch_logger.py --skill <skill_name> --intent <intent> --reason <reason>`

## Action

Inputs:

- source scenarios in TDD, BDD, or plain-text form,
- the target TestRail structure if the project already uses one,
- any required suite, section, or metadata conventions.

Output contract:

- a TestRail-compatible XML or CSV payload,
- a structured mapping table when import planning should happen before generation,
- or a normalized scenario table ready for import tooling.

Mapping rules:

- map titles, preconditions, steps, and expected results consistently,
- keep requirement identifiers where TestRail fields allow them,
- preserve ordering and execution intent,
- call out any source fields that have no clean TestRail destination.
