---
name: cypress-documentation-tests
description: Automation-code documentation skill for Cypress suites. Use when Codex needs to add or improve human-readable comments, docblocks, or file-level explanations around existing Cypress tests without drowning the code in redundant commentary.
metadata:
  author: jovd83
  version: "1.1"
  dispatcher-category: testing
  dispatcher-capabilities: automation-documentation, cypress-test-documentation
  dispatcher-accepted-intents: document_cypress_tests
  dispatcher-input-artifacts: test_suite, repo_context, traceability_artifacts
  dispatcher-output-artifacts: automation_docs, documentation_update
  dispatcher-stack-tags: cypress, documentation, automation
  dispatcher-risk: low
  dispatcher-writes-files: true
---

# Documenting Existing Tests

Use this skill to improve readability of existing Cypress code.


## Telemetry & Logging
> [!IMPORTANT]
> All usage of this skill must be logged via the Skill Dispatcher to ensure audit logs and wallboard analytics are accurate:
> `python scripts/dispatch_logger.py --skill <skill_name> --intent <intent> --reason <reason>`

## Action

1. Read the target spec or support module first.
2. Identify where documentation would materially help a future maintainer.
3. Add concise documentation at the file, suite, test, helper, command, or page-object level as appropriate.

Commenting rules:

- Prefer high-signal docblocks over line-by-line narration.
- Explain intent, scope, business meaning, or non-obvious behavior.
- Do not restate code that is already obvious from the test title or method name.
- Avoid comment spam in straightforward tests.

After editing, summarize what was documented, why those locations mattered, and any areas that likely need refactoring rather than more comments.
