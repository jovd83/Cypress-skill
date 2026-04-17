---
name: cypress-transformer-xray
description: Legacy Cypress-specific alias for Xray case export. Prefer the standalone `test-artifact-export-skill` skill for transforming approved test cases into Xray-ready artifacts, and use this only when Cypress-local conventions must be preserved explicitly.
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

# Transforming Test Cases to Xray

Use this skill to convert narrative test cases into Xray import artifacts.


## Telemetry & Logging
> [!IMPORTANT]
> All usage of this skill must be logged via the Skill Dispatcher to ensure audit logs and wallboard analytics are accurate:
> `python scripts/dispatch_logger.py --skill <skill_name> --intent <intent> --reason <reason>`

## Action

Inputs:

- source scenarios in TDD, BDD, or plain-text form,
- the target Xray structure if the project already uses one,
- any required Jira or Xray metadata conventions.

Output contract:

- an Xray-compatible JSON or CSV payload,
- a field-mapping table when the user wants the transformation planned before generation,
- or a normalized scenario table ready for downstream import tooling.

Mapping rules:

- preserve scenario titles, steps, expected outcomes, and requirement references,
- keep Jira or issue identifiers intact where possible,
- preserve ordered steps and execution meaning,
- call out any source fields that have no clean Xray destination.
