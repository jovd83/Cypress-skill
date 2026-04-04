---
name: cypress-reporter-xray
description: Test-management reporting skill for Xray. Use when Codex needs to publish Cypress execution results into Xray using the project's mappings, environment configuration, and chosen reporting flow.
metadata:
  author: jovd83
  version: "1.1"
---

# Xray API Reporter

Use this skill when the goal is to push execution outcomes into Xray.

## Action

Inputs:

- Xray connection details and credentials,
- the local result source,
- the mapping from automated tests to Xray issue or case IDs,
- any target run, build, or environment context required by the project.

Workflow:

1. Confirm the mapping and target run context.
2. Configure the reporting path or client the project uses.
3. Publish results securely.
4. Return a concise report of what was sent and what could not be reported.

Guardrails:

- Never echo secrets back in plain text.
- Do not report results for tests that cannot be mapped confidently.
- Call out partial publication explicitly.
