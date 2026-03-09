---
name: cypress-reporter-xray
description: A skill to use Xray APIs to report Cypress test execution results.
---

# Xray API Reporter

This skill handles importing execution results to Jira Xray.

## Action
When requested:
1. Ask the user for Jira Credentials (API token).
2. Install the `@xray-app/cypress-junit-reporter` or `cypress-xray-helper` npm library.
3. Configure the `cypress.config.ts` to output enriched JUnit or JSON.
4. Submit the results to the Xray `/import/execution` REST endpoint using the custom reporter built-in uploading logic or curl.
5. Verify the Jira issue was updated securely, and report back the Execution Issue ID.









