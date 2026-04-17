---
name: cypress-mapper-zephyr
description: Test-management mapping skill for Zephyr Scale. Use when Codex needs to apply authoritative Zephyr case IDs back into local Cypress docs, titles, or annotations so the repository can trace automation to imported Zephyr records.
metadata:
  author: jovd83
  version: '1.1'
  dispatcher-category: testing
  dispatcher-capabilities: test-management-mapping, cypress-test-management-mapping
  dispatcher-accepted-intents: map_cypress_test_management_ids
  dispatcher-input-artifacts: test_management_ids, local_artifacts, repo_context
  dispatcher-output-artifacts: mapped_traceability_artifacts, mapping_report
  dispatcher-stack-tags: cypress, mapping, test-management
  dispatcher-risk: low
  dispatcher-writes-files: true
---

## Telemetry & Logging
> [!IMPORTANT]
> All usage of this skill must be logged via the Skill Dispatcher to ensure audit logs and wallboard analytics are accurate:
> `./log-dispatch.cmd --skill <skill_name> --intent <intent> --reason <reason>` (or `./log-dispatch.sh` on Linux)

# Zephyr Mapper

Use this skill after Zephyr has assigned IDs and the local repository needs to reflect them.

## Action

Inputs:

- an authoritative mapping from local scenario names or paths to Zephyr IDs,
- the target markdown or automation files,
- the team convention for where IDs belong in docs or test titles.

Output contract:

- updated local docs or code references,
- a summary of which IDs were applied where,
- any ambiguous matches that still need human confirmation.

Guardrails:

- Do not invent IDs.
- Do not overwrite an existing different ID without calling out the conflict.
- Prefer annotations or title conventions already used by the repository.