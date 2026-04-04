---
name: cypress-transformer-zephyr
description: Legacy Cypress-specific alias for Zephyr case export. Prefer the standalone `test-artifact-export-skill` skill for transforming approved test cases into Zephyr-ready artifacts, and use this only when Cypress-local conventions must be preserved explicitly.
metadata:
  author: jovd83
  version: "1.1"
---

# Transforming Test Cases to Zephyr

Use this skill to convert narrative test cases into Zephyr import artifacts.

## Action

Inputs:

- source scenarios in TDD, BDD, or plain-text form,
- the target Zephyr structure if the project already uses one,
- any required suite, folder, or metadata conventions.

Output contract:

- a Zephyr-compatible JSON or CSV payload,
- a field-mapping table when the user wants the transformation planned before generation,
- or a normalized scenario table ready for downstream import tooling.

Mapping rules:

- preserve scenario titles, preconditions, steps, and expected results,
- keep requirement identifiers where Zephyr fields allow them,
- preserve ordering and execution meaning,
- call out any source fields that have no clean Zephyr destination.
