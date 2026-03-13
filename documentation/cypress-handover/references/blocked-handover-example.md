# Cypress Skill Handover

- Timestamp: 2026-03-11 15:30
- Task label: checkout-auth-fix
- Workspace root: C:\projects\shop-app
- Branch: fix/checkout-auth-refresh
- Previous handover: No prior handover found

### Task summary
Stabilize the Cypress checkout flow after the app switched from cookie login to token refresh.

### Current status
Blocked

### What was done
Updated the checkout spec to use the current login helper, replaced a removed selector with a role-based selector, and confirmed the failure now occurs after login instead of before navigation.

### In progress
Investigating why the refreshed token is not persisted after the first protected API call.

### Remaining work
Verify the backend refresh response, update the auth helper if the storage key changed, rerun the checkout suite, and capture a passing artifact.

### Blockers and open questions
The `CYPRESS_QA_PASSWORD` secret is not available in this shell session, so the login helper cannot complete end-to-end verification.

### Next action
Load the missing QA secret, rerun the auth bootstrap test, and inspect the refreshed token storage key after login succeeds.

### Session state
Active role is `qa-buyer`. Auth uses API bootstrap plus `cy.session(['api', 'qa-buyer'])`. Base URL is `http://localhost:3000`. No reusable state artifact was saved because the shell session is missing the QA password. Recreate state by exporting `CYPRESS_QA_PASSWORD` and rerunning `npx cypress run --spec cypress/e2e/auth/bootstrap.cy.ts`.

### How to resume
Open `cypress/e2e/checkout/checkout.cy.ts` and `cypress/support/commands.ts` first. Run `npm run dev` in one shell and `npx cypress run --spec cypress/e2e/auth/bootstrap.cy.ts` in another. After auth passes, rerun `npx cypress run --spec cypress/e2e/checkout/checkout.cy.ts`.

### Validation and evidence
Ran `npx cypress run --spec cypress/e2e/checkout/checkout.cy.ts` and reproduced the post-login failure. Did not complete final validation because the QA password secret was unavailable.

### Skills and subskills used
Used `cypress-handover` to structure the resume document and `cypress-documentation-root-cause` to summarize the failed auth bootstrap evidence.

### Non-skill actions and suggestions
Manually compared previous auth helper behavior with the updated storage contract. A dedicated Cypress auth-migration diagnostic skill could automate this diff.

### Patterns used
Used `cy.session()` for deterministic auth reuse and role-specific test state.

### Anti-patterns used
None.

### Strengths of the changes
The suite now fails at the real auth persistence problem instead of at a stale selector, which narrows the next debugging step.

### Weaknesses of the changes
The final checkout path is still unverified until the missing secret is restored.

### Improvements
Add a smoke test that asserts the token refresh storage key immediately after login so future auth changes fail faster.

### Files added/modified
- Documentation: Added the handover so another human or agent can resume without rediscovery.
- POMs: None.
- Test scripts: Updated `cypress/e2e/checkout/checkout.cy.ts`.
- Configurations: None.
- Other: Updated `cypress/support/commands.ts`.
