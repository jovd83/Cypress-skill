---
name: cypress-coverage-plan-generation
description: A skill to generate a functional coverage plan mapping the confirmed requirements to necessary Cypress test scenarios.
---

# Functional Coverage Plan Generation

This skill provides a structured approach to generating a coverage plan from the confirmed requirements.

## 1. Prerequisite
Ensure that you have successfully completed the `cypress-analysis-requirements` skill phase and that the user has verified the Acceptance Criteria (AC).

## 2. Generate the Scenarios
For each accepted Epic, User Story, or AC, generate a list of distinct test scenarios.
You must cover:
1. **Happy Paths (MSS)**: The primary and most common workflows. **Always list these first as they are the foundation.**
2. **Alternative Paths (EXT)**: Valid deviations from the primary workflow.
3. **Negative/Error Paths (ERR)**: Form validation errors, unauthorized access, invalid inputs.
4. **Boundary Values (BND)**: Limits, maximum inputs, etc.

## 3. Formatting the Plan
Structure the output using markdown tables mapping the `Requirement/AC ID` to the `Proposed Test Scenario` and the `Execution Type` (UI / API / Component).

## 4. Next Step
Proceed to use the `cypress-coverage-plan-review` skill to present this generated plan to the user.









