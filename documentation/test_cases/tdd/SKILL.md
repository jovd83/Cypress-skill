---
name: cypress-documentation-tdd
description: Legacy Cypress-specific alias for TDD-style case documentation. Prefer the standalone `test-artifact-export-skill` skill for formatting approved test cases or building export-ready artifacts, and use this only when Cypress-local conventions must be preserved explicitly.
metadata:
  author: jovd83
  version: "1.1"
---

# Documenting Test Cases: TDD format

Use this skill when the team wants formal, traceable test-case documents rather than lightweight notes.

## 1. Storage & Organization

Store TDD-style test cases in a stable, feature-oriented structure:

- Root directory: `docs/tests/`
- Subfolders: one folder per feature, epic, or domain area
- Files: one markdown file per scenario group, story, or coherent test slice

Example structure:

```text
docs/tests/
|-- auth/
|   |-- registration.md
|   `-- login.md
`-- collections/
    `-- create-collection.md
```

## 2. Granular Traceability

Link the document to the automation at the test level whenever possible, not just the file level.

- Required format: ``file_name @ file_path#test_name``
- Example: `auth-settings.cy.ts @ cypress/e2e/regression/auth-settings.cy.ts#AUTH-US02: User Login`

If the test does not exist yet, keep the intended script field explicit and mark the document as design-stage output.

## 3. Structure & Fields

Produce a markdown document with these fields:

- `title`: informative, unique, and requirement-aware
- `description`: concise purpose of the scenario
- `test_suite`: feature, epic, or suite grouping
- `Covered requirement`: the requirement, story, or acceptance-criteria reference
- `preconditions`: system state required before execution, formatted as a lettered list
- `steps`: markdown table with `Step`, `Action`, and `Expected result`
- `execution_type`: usually `Automated`, but can be explicit when mixed or manual
- `design_status`: `Draft`, `Ready`, or `Obsolete`
- `test_engineer`: engineer or agent identifier
- `test_level`: priority or level using the team convention
- `jira`: relevant Jira or tracker reference when available
- `Test script`: granular implementation link or planned destination

## 4. Example Template

```markdown
title: [AUTH-US02] MSS: User Login
description: Validates end-to-end UI behavior for "User Login" in epic "Authentication & Settings".
test_suite: Authentication & Settings
Covered requirement: AUTH-US02
preconditions:
A) Test database is seeded with fixtures.
B) Application is running.
steps:
| Step | Action | Expected result |
|---|---|---|
| 1 | Navigate to login page | Page renders |
| 2 | Enter credentials | Login successful |
execution_type: Automated
design_status: Ready
test_engineer: Codex
test_level: 1
jira: AUTH-102
Test script: auth-settings.cy.ts @ cypress/e2e/regression/auth-settings.cy.ts#AUTH-US02: User Login
```
