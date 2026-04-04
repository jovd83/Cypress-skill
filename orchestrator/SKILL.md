---
name: cypress-orchestrator
description: Central entrypoint for broad or ambiguous Cypress requests. Use when Codex needs to classify the user's testing goal, choose the right Cypress subskill, and move from intent to implementation, planning, documentation, execution, or reporting without unnecessary menu-driven back-and-forth.
metadata:
  author: jovd83
  version: "1.1"
---

# Cypress Orchestrator

Use this skill when the user asks for Cypress help but the exact workflow is not yet obvious. Its job is to classify the task, route to the right subskill, and keep the work moving.

## Deterministic First Question

If the user already gave enough context, do not ask this question. Route immediately.

If intent is still ambiguous and the answer would materially change the artifact or next step, ask exactly one routing question:

> "What do you want to do right now with Cypress: write or fix tests, debug a failing run, plan coverage from requirements, document tests, work with a test-management tool, summarize results, or handle setup and migration?"

Do not ask a menu question after the user already requested a concrete deliverable.

## Intent Routing Table

| User intent | Route | Follow-up only if needed |
|---|---|---|
| Write, fix, or review Cypress tests | `core` | Clarify scope only if it changes what gets built |
| Decide between POMs, fixtures, helpers, or commands | `pom` | Ask only if the current architecture is unclear |
| Run or debug a failing suite | `core` and `documentation/root_cause` | Request failure output if it is missing |
| Set up or debug CI execution | `ci` | Ask which CI provider only when examples differ materially |
| Derive requirements from tickets or specs | `analysis` | Ask for the strongest available source if none was provided |
| Produce or refine a coverage plan | `coverage_plan/generation` and `coverage_plan/review` | Clarify approval needs only for large or costly plans |
| Write test documentation or convert case formats | `C:\projects\skills\test-artifact-export-skill\SKILL.md` or `documentation/tests` | Ask for the desired format only if it is not inferable |
| Create handoff or session-state artifacts | `documentation/cypress-handover` or `documentation/session-state` | Confirm task scope only when multiple scopes exist |
| Export test cases to TestLink, TestRail, Xray, or Zephyr | `C:\projects\skills\test-artifact-export-skill\SKILL.md` | Ask for the target system if not stated |
| Report execution to TestLink, TestRail, Xray, or Zephyr | relevant `mappers/*` or `reporters/*` | Ask for the target system if not stated |
| Summarize Cypress results for stakeholders | `reporting/stakeholder` | Ask for release context if the report would otherwise be misleading |
| Migrate from another framework or Selenium/WebDriver | `migration` | Ask for source stack if missing |
| Drive a browser from the terminal | `cypress-cli` | Ask whether the need is interaction, scraping, mocking, or diagnostics only if it changes the workflow |
| Install or align IDE workflows | `installers/*` | Ask for IDE only if it is not already clear |

## Orchestration Rules

1. Prefer the smallest capable subskill instead of loading the whole pack.
2. After routing, do the work. Do not just announce the destination skill.
3. State high-impact assumptions when you make them.
4. Keep planning, documentation, and implementation handoffs explicit when multiple subskills are used in sequence.
5. Escalate only when the missing decision materially changes scope, cost, risk, or long-lived structure.
