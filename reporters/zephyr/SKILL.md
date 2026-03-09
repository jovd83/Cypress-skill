---
name: cypress-reporter-zephyr
description: A skill to use Zephyr Scale APIs to report Cypress test execution results.
---

# Zephyr Scale API Reporter

This skill interacts with the Zephyr Scale REST API to publish test results.

## Action
When requested to report results to Zephyr:
1. Ask the user for the Zephyr Bearer Token.
2. Install the `@gurglosa/cypress-zephyr-jira-reporter` or `cypress-zephyr` npm library.
3. Configure the reporter in `cypress.config.ts`.
4. Parse the local Cypress results. Match the `CYP-T123:` keys to determine the target Test Cases.
5. Formulate the JSON payload for the `/testruns` endpoint or let the reporter plugin handle the Jira test cycle sync automatically.









