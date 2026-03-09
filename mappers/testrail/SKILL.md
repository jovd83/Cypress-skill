---
name: cypress-mapper-testrail
description: A skill to map TestRail unique IDs back to local Cypress test documentation.
---

# TestRail Mapper

After adding test cases to a TestRail suite, they get assigned an ID (e.g., `C12345`).

## Action
When requested:
1. Ask the user for the TestRail Case ID mappings.
2. Insert the TestRail ID into the markdown test documentation.
3. Integrate the Case ID into Cypress test titles (which is required by the TestRail reporter plugin): `it('C12345 Verify user login...', () => {})` or using tags `@C12345`.









