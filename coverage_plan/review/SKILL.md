---
name: cypress-coverage-plan-review
description: Coverage-plan review skill for Cypress work. Use when Codex needs to present a proposed coverage plan, surface assumptions and tradeoffs, collect user feedback, and secure explicit approval before large implementation or documentation work.
metadata:
  author: jovd83
  version: "1.1"
---

# Functional Coverage Plan Review

Use this skill to turn a proposed plan into an approved plan.

## 1. Present the Plan

Present the plan in a compact, scannable format. Highlight what is included, what is deferred, and where the highest-risk coverage sits.

## 2. Prompt for Feedback

Ask for additions, removals, reprioritization, or approval only where that decision matters. A compact prompt is preferred over a long questionnaire.

Use a prompt such as:

> "Here is the proposed Cypress coverage plan. Please confirm what should be approved, deferred, removed, or expanded before implementation starts."

## 3. Iterate

If feedback changes the plan materially, refresh the presented version before proceeding.

When useful, maintain a review table:

| Requirement ID | Scenario | Priority | Status | Notes |
|---|---|---|---|---|

Use `Status` values such as `proposed`, `approved`, `deferred`, or `removed`.

## 4. Proceed

If the user already approved the scope in the same thread, do not force a second approval loop.

If the plan is large, costly, or assumption-heavy, get explicit approval before implementation or documentation.
