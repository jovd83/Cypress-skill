---
name: cypress-analysis-requirements
description: Requirements-analysis skill for Cypress planning and implementation. Use when Codex needs to extract testable behaviors, acceptance criteria, risks, dependencies, or open questions from tickets, specs, markdown docs, or other requirement sources before writing tests or coverage plans.
metadata:
  author: jovd83
  version: "1.1"
---

# Analysis & Requirements Skill

Use this skill to turn raw product or engineering artifacts into a trustworthy testing baseline for Cypress work.

## 1. Information Gathering

Use the best available sources in this order:

1. user-provided tickets, specs, exports, or links,
2. repository-local docs such as `docs/`, markdown files, issue exports, or feature notes,
3. nearby automation or product artifacts that clarify behavior.

Do not keep searching indefinitely once you have enough evidence to form a reliable baseline.

## 2. Requirement Extraction

Produce a concise requirements baseline that separates:

- confirmed behaviors,
- inferred behaviors,
- risks and edge cases,
- open questions or missing evidence,
- source evidence.

When tabular output helps, use:

| Requirement ID | Behavior | Evidence | Confidence | Notes |
|---|---|---|---|---|

Normalize vague prose into testable behaviors. Capture authorization rules, data constraints, negative paths, and dependencies when the source implies them.

## 3. User Validation

Pause for confirmation when ambiguity would materially change the downstream plan, implementation, or documentation.

Use a direct validation prompt such as:

> "Here is the requirements baseline I derived for the Cypress work. Please confirm the confirmed behaviors, call out any missing evidence, and tell me what should stay assumption-only before I plan or implement."

If the user asked only for the baseline, stop after this step.

If the requirements are clear enough and the same request also asks for downstream planning, continue while keeping assumptions explicit and auditable.
