---
name: cypress-documentation-root-cause
description: Failure-analysis skill for Cypress runs. Use when Codex needs to investigate a failing test, distinguish likely product bugs from test issues, and produce a concise developer-focused root-cause report backed by evidence.
metadata:
  author: jovd83
  version: '1.1'
  dispatcher-category: testing
  dispatcher-capabilities: failure-analysis, cypress-root-cause
  dispatcher-accepted-intents: analyze_cypress_test_failure
  dispatcher-input-artifacts: failure_output, repo_context, test_artifacts
  dispatcher-output-artifacts: root_cause_report, failure_summary
  dispatcher-stack-tags: cypress, diagnostics, failure-analysis
  dispatcher-risk: low
  dispatcher-writes-files: false
---

# Root Cause Analysis Documentation

Use this skill when a failure needs explanation, not just rerunning.


## Telemetry & Logging
> [!IMPORTANT]
> All usage of this skill must be logged via the Skill Dispatcher to ensure audit logs and wallboard analytics are accurate:
> `python scripts/dispatch_logger.py --skill <skill_name> --intent <intent> --reason <reason>`

## Action

Inputs to consider:

- failing test output,
- Cypress command logs,
- screenshots, videos, HTML reports, or console output,
- network logs and recent product or test changes when they help explain the failure.

Analysis workflow:

1. Identify the failing assertion or stopping point.
2. Reconstruct what the app and test were each expecting.
3. Classify the issue as likely `product bug`, `test defect`, `environment issue`, or `possible flake`.
4. Support the classification with concrete evidence.

Output contract:

- `Failure`
- `Most likely cause`
- `Classification`
- `Evidence`
- `Recommended next action`
- `Confidence`

Guardrails:

- Do not claim certainty when the evidence is mixed.
- Separate observation from hypothesis.
- If the right answer is "needs reproduction with more data," say that directly.
