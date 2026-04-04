---
name: cypress-reporting-stakeholder
description: Stakeholder-reporting skill for Cypress execution results. Use when Codex needs to turn raw Cypress runs into a concise, non-technical summary of tested scope, release health, business impact, and recommended next actions.
metadata:
  author: jovd83
  version: "1.1"
---

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
