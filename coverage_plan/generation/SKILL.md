---
name: cypress-coverage-plan-generation
description: Coverage-planning skill for Cypress work. Use when Codex needs to turn confirmed requirements into a structured, risk-aware Cypress coverage plan with scenarios, execution types, priorities, and traceability.
metadata:
  author: jovd83
  version: "1.1"
  dispatcher-category: testing
  dispatcher-capabilities: coverage-planning, cypress-coverage-planning
  dispatcher-accepted-intents: plan_cypress_coverage, generate_cypress_test_coverage_plan
  dispatcher-input-artifacts: analysis_baseline, confirmed_requirements, repo_context, scope_constraints
  dispatcher-output-artifacts: coverage_plan, scenario_matrix, approval_request
  dispatcher-stack-tags: cypress, coverage-planning, ui-testing
  dispatcher-risk: medium
  dispatcher-writes-files: false
---

# Functional Coverage Plan Generation

Use this skill after the requirements are clear enough to plan against.

## 1. Prerequisite

- Start from confirmed requirements or a clearly labeled analysis baseline.
- If major assumptions remain, keep them visible in the plan instead of burying them.

## 2. Generate the Scenarios

- Aim for meaningful functional completeness, not mechanical scenario inflation.
- Cover the paths that change confidence: core success paths, important variations, failure handling, boundary conditions, permissions, and role differences when relevant.
- Avoid duplicate scenarios that test the same risk with different wording.
- Choose the lowest-cost execution type that still validates the behavior well.

Recommended scenario classes:

1. Happy paths
2. Important variations
3. Negative and error handling
4. Boundary and resilience behavior

## 3. Formatting the Plan

Produce a coverage plan table like this:

| Priority | Requirement ID | Scenario | Coverage Type | Execution Type | Risk Covered | Notes |
|---|---|---|---|---|---|---|

Use `Execution Type` values such as `UI`, `API`, or `Component`.

Use `Coverage Type` values such as `happy-path`, `variation`, `negative`, `edge`, or `resilience` when helpful.

## 4. Next Step

Use dispatcher intent `review_cypress_coverage_plan` when explicit review or sign-off is needed before implementation or documentation.

If dispatcher routing is unavailable, use `cypress-coverage-plan-review`.
