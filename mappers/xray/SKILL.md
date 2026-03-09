---
name: cypress-mapper-xray
description: A skill to map Xray unique IDs back to local Cypress test documentation.
---

# Xray Mapper

After Xray ingestion, JSON/CSV tests receive unique Issue IDs or Test Keys.

## Action
When requested:
1. Obtain the Jira Test Keys for the uploaded tests from the user.
2. Link the Xray ID into the markdown documentation `Covers Xray ID: XRAY-42`.
3. Link the test in Cypress using standard Xray tags or naming conventions for JUnit output: `it('@XRAY-42 verify ...', () => {})` or include the key in the title (for example `XRAY-42: verify ...`).









