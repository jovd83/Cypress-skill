---
name: cypress-reporting-stakeholder
description: Stakeholder-reporting skill for Cypress execution results. Use when Codex needs to turn raw Cypress runs into a concise, non-technical summary of tested scope, release health, business impact, and recommended next actions.
metadata:
  author: jovd83
  version: '1.1'
  dispatcher-category: testing
  dispatcher-capabilities: stakeholder-reporting, cypress-stakeholder-reporting
  dispatcher-accepted-intents: summarize_cypress_test_results
  dispatcher-input-artifacts: execution_results, tested_scope, release_context
  dispatcher-output-artifacts: stakeholder_summary, release_health_report
  dispatcher-stack-tags: cypress, reporting, stakeholder
  dispatcher-risk: low
  dispatcher-writes-files: false
---

## Telemetry & Logging
> [!IMPORTANT]
> All usage of this skill must be logged via the Skill Dispatcher to ensure audit logs and wallboard analytics are accurate:
> `./log-dispatch.cmd --skill <skill_name> --intent <intent> --reason <reason>` (or `./log-dispatch.sh` on Linux)

# Stakeholder Execution Report

Use this skill when the audience is a product manager, QA lead, delivery lead, or another stakeholder who does not want raw runner noise.

## Action

Produce a report with:

- `Executive summary`
- `Scope covered`
- `Overall outcome`
- `Known issues and business impact`
- `Recommended next actions`

Writing rules:

- Translate technical failures into business language.
- Call out confidence limits if the run was partial, flaky, blocked, or environment-constrained.
- Keep stack traces and low-level logs out of the main report unless the user explicitly wants them.