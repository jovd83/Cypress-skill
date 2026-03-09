---
name: cypress-documentation-root-cause
description: A skill to perform root cause analysis on failed Cypress test runs and generate developer-friendly diagnostics.
---

# Root Cause Analysis Documentation

This skill accelerates debugging by automatically triaging test failures.

## Action
When requested to analyze a failure:
1. Read Cypress command logs, screenshots/videos, console output, network logs, and failure messages.
2. Determine: "Is it the test or a bug?"
   - **Flaky Test:** E.g., a timeout waiting for a network request, or a brittle selector.
   - **True Bug:** The UI behavior changed, an API responded with a 500, or a feature is broken.
3. Generate a Root Cause Report for the human-in-the-loop:
   - **Test Name:** Which test failed.
   - **The Error:** The literal error from Cypress.
   - **Triage Decision:** Bug OR Flaky Test.
   - **Evidence:** Snippets from command log, DOM, network output, or screenshots that prove the decision.
   - **Proposed Fix:** What should be done to fix the test or the application.









