---
name: cypress-documentation-plaintext
description: Legacy Cypress-specific alias for plain-text case formatting. Prefer the standalone `test-artifact-export-skill` skill for lightweight narrative case output, and use this only when Cypress-local conventions must be preserved explicitly.
metadata:
  author: jovd83
  version: "1.1"
---

# Documenting Test Cases: Plain Text format

Use this skill when the goal is fast, lightweight documentation rather than a formal template.

## Structure

Produce a concise paragraph list or bullet list that covers:

- the goal of the test,
- the setup or preconditions,
- the main execution flow,
- the expected outcome,
- any requirement or risk reference that matters.

Keep the structure simple, but make sure the document is still actionable.

## Usage

Use `.md` or `.txt` output as requested by the user.

This format is best for rapid capture, early planning, low-ceremony reviews, or transitional documentation that may later be promoted into TDD or BDD artifacts.
