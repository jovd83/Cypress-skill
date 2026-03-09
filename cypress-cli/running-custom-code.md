# Running Custom Cypress Code

> **When to use**: CLI commands are not enough and you need custom Cypress logic (network hooks, browser API stubs, iframe helpers, data extraction, or conditional flows).
> **Prerequisites**: [core-commands.md](core-commands.md)

## Golden Rules

1. Cypress uses a command queue. Do not write direct page-handle logic from other frameworks.
2. Prefer `cy.intercept()` plus `cy.wait('@alias')` over arbitrary `cy.wait(2000)`.
3. Do not rely on `force: true` unless there is no accessible user path.
4. Keep custom code deterministic. Avoid brittle DOM timing assumptions.

## Quick Reference

```bash
# Inspect page metadata
cypress-cli run-code "() => {
  cy.title().then((title) => console.log('title:', title));
  cy.url().then((url) => console.log('url:', url));
}"

# Intercept + wait
cypress-cli run-code "() => {
  cy.intercept('GET', '**/api/users').as('getUsers');
  cy.get('button#load-users').click();
  cy.wait('@getUsers').its('response.statusCode').should('eq', 200);
}"
```

## Access Window and Document

```bash
# Read browser globals
cypress-cli run-code "() => {
  cy.window().then((win) => {
    console.log({
      language: win.navigator.language,
      online: win.navigator.onLine,
      width: win.innerWidth,
      height: win.innerHeight
    });
  });
}"

# Run custom DOM extraction
cypress-cli run-code "() => {
  cy.document().then((doc) => {
    const cards = Array.from(doc.querySelectorAll('.product-card')).map((card) => ({
      name: card.querySelector('.name')?.textContent?.trim(),
      price: card.querySelector('.price')?.textContent?.trim()
    }));
    console.log(cards);
  });
}"
```

## Wait Strategies (Cypress-First)

### Wait for API Completion

```bash
cypress-cli run-code "() => {
  cy.intercept('POST', '**/api/orders').as('createOrder');
  cy.get('[data-cy=create-order]').click();
  cy.wait('@createOrder').its('response.statusCode').should('be.oneOf', [200, 201]);
}"
```

### Wait for UI State

```bash
# Spinner goes away
cypress-cli run-code "() => {
  cy.get('.loading-spinner').should('not.exist');
  cy.get('.results-list').should('be.visible');
}"

# URL changes
cypress-cli run-code "() => {
  cy.url().should('include', '/dashboard');
}"
```

### Wait for App Flags

```bash
cypress-cli run-code "() => {
  cy.window().its('appReady').should('eq', true);
}"
```

## Geolocation and Browser API Stubbing

Cypress does not expose direct geolocation/permission control APIs in the same shape. Stub browser APIs instead.

```bash
# Stub geolocation
cypress-cli run-code "() => {
  cy.window().then((win) => {
    cy.stub(win.navigator.geolocation, 'getCurrentPosition').callsFake((cb) => {
      cb({ coords: { latitude: 40.7128, longitude: -74.0060 } });
    });
  });
}"

# Stub clipboard read
cypress-cli run-code "() => {
  cy.window().then((win) => {
    cy.stub(win.navigator.clipboard, 'readText').resolves('mock clipboard text');
  });
}"
```

## Iframes

Cypress does not use frame-handle APIs in this style. Use iframe helpers.

```bash
# Example with cypress-iframe plugin installed
cypress-cli run-code "() => {
  cy.frameLoaded('iframe[name=checkout]');
  cy.iframe('iframe[name=checkout]').find('input[name=card-number]').type('4111111111111111');
  cy.iframe('iframe[name=checkout]').find('input[name=expiry]').type('12/30');
  cy.iframe('iframe[name=checkout]').find('input[name=cvc]').type('123');
}"
```

## File Downloads

Cypress cannot hook a browser `download` event in this style. Validate download behavior using request assertions and filesystem checks.

```bash
cypress-cli run-code "() => {
  cy.intercept('GET', '**/reports/*.csv').as('csv');
  cy.get('[data-cy=export-csv]').click();
  cy.wait('@csv').its('response.statusCode').should('eq', 200);
}"

# If your CLI writes downloads to a known folder:
cypress-cli run-code "() => {
  cy.readFile('cypress/downloads/report.csv').should('contain', 'id,name');
}"
```

## Conditional UI Handling (Without try/catch)

```bash
cypress-cli run-code "() => {
  cy.get('body').then(($body) => {
    const selector = '[data-testid=cookie-accept], .cookie-banner button.accept';
    const btn = $body.find(selector).first();
    if (btn.length) {
      cy.wrap(btn).click();
    }
  });
}"
```

## Complex Workflow Example

```bash
cypress-cli run-code "() => {
  // Step 1: register network aliases
  cy.intercept('GET', '**/api/profile').as('profile');
  cy.intercept('POST', '**/api/settings').as('saveSettings');

  // Step 2: navigate and wait for initial data
  cy.visit('https://app.example.com/settings');
  cy.wait('@profile').its('response.statusCode').should('eq', 200);

  // Step 3: update settings
  cy.findByLabelText('Display name').clear().type('Jane Doe');
  cy.findByRole('button', { name: 'Save settings' }).click();

  // Step 4: assert save success
  cy.wait('@saveSettings').its('response.statusCode').should('eq', 200);
  cy.findByRole('status').should('contain.text', 'Saved');
}"
```

## Anti-Patterns

- Awaiting Cypress chainables: Cypress commands are not standard promises.
- `cy.wait(5000)` as default synchronization strategy.
- Mixing non-Cypress APIs in Cypress docs.
- Using hidden or disabled targets with `force: true` instead of fixing testability.

## Tips

- Use `run-code` for targeted advanced behavior, not for every simple click/fill.
- Prefer stable selectors (`data-cy`, accessible roles/labels).
- Keep setup logic reusable with custom commands and `cy.session()`.
