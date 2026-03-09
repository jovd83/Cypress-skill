# Migrating from Selenium to Cypress

> **When to use**: When converting Selenium/WebDriver suites to Cypress v13+.
> **Prerequisites**: [core/locators.md](../core/locators.md), [core/assertions-and-waiting.md](../core/assertions-and-waiting.md)

## Key Mindset Shifts

### 1. No WebDriver Client/Driver Layer

Selenium uses WebDriver protocol + browser drivers. Cypress runs with an integrated automation model and browser control.

### 2. Explicit Waits Become Retryable Assertions

Selenium patterns like `WebDriverWait` and `ExpectedConditions` should map to Cypress retryable chains (`cy.get(...).should(...)`).

### 3. Element Handles vs Chain Re-queries

Selenium element references can go stale. Cypress re-queries in command chains and retries assertions automatically.

### 4. Framework Assembly vs Included Runner

Selenium needs separate runner and reporting stack. Cypress includes runner, screenshots/videos, and rich debug output.

### 5. Test Synchronization Style

Replace sleeps and polling loops with aliases (`cy.intercept` + `cy.wait('@alias')`) and UI assertions.

## Command Mapping

| Selenium | Cypress | Notes |
|---|---|---|
| `driver.get(url)` | `cy.visit(url)` | Uses `baseUrl` if configured |
| `driver.findElement(By.cssSelector('x'))` | `cy.get('x')` | Prefer semantic queries when possible |
| `driver.findElement(By.id('x'))` | `cy.get('#x')` | For stable IDs only |
| `driver.findElement(By.xpath('...'))` | `cy.xpath('...')` | Requires plugin; avoid when possible |
| `element.click()` | `cy.get(...).click()` | Built-in actionability checks |
| `element.sendKeys('abc')` | `cy.get(...).type('abc')` | User-like typing |
| `element.clear()` | `cy.get(...).clear()` | Clear input value |
| `new Select(el).selectByVisibleText('US')` | `cy.get('select').select('US')` | Native select support |
| `WebDriverWait(...).until(visibilityOf(...))` | `cy.get(...).should('be.visible')` | Retryable assertion |
| `Thread.sleep(2000)` | Avoid | Use aliases/assertions instead |
| `driver.getCurrentUrl()` | `cy.url()` | Chain with `.should(...)` |
| `driver.getTitle()` | `cy.title()` | Chain with `.should(...)` |
| `driver.manage().addCookie(...)` | `cy.setCookie(...)` | Cookie API available |
| `driver.manage().deleteAllCookies()` | `cy.clearCookies()` | Clear cookies per test state |
| `driver.executeScript(...)` | `cy.window().then(win => ...)` | Browser-side script access |

## Example: Form Submission

**Selenium (Java)**
```java
driver.get("https://app.example.com/login");
driver.findElement(By.id("email")).sendKeys("user@example.com");
driver.findElement(By.id("password")).sendKeys("password123");
driver.findElement(By.cssSelector("button[type='submit']")).click();
new WebDriverWait(driver, Duration.ofSeconds(10))
  .until(ExpectedConditions.visibilityOfElementLocated(By.cssSelector("h1")));
```

**Cypress (TypeScript)**
```typescript
describe('login', () => {
  it('submits and lands on dashboard', () => {
    cy.visit('/login');
    cy.get('#email').type('user@example.com');
    cy.get('#password').type('password123');
    cy.get('button[type="submit"]').click();
    cy.findByRole('heading', { name: 'Dashboard' }).should('be.visible');
  });
});
```

**Cypress (JavaScript)**
```javascript
describe('login', () => {
  it('submits and lands on dashboard', () => {
    cy.visit('/login');
    cy.get('#email').type('user@example.com');
    cy.get('#password').type('password123');
    cy.get('button[type="submit"]').click();
    cy.findByRole('heading', { name: 'Dashboard' }).should('be.visible');
  });
});
```

## Example: API Synchronization

**Selenium mindset**: wait for DOM after click or poll manually.

**Cypress (TypeScript)**
```typescript
cy.intercept('POST', '**/api/orders').as('createOrder');

cy.findByRole('button', { name: 'Submit Order' }).click();
cy.wait('@createOrder').its('response.statusCode').should('eq', 201);
cy.findByText(/order created/i).should('be.visible');
```

**Cypress (JavaScript)**
```javascript
cy.intercept('POST', '**/api/orders').as('createOrder');

cy.findByRole('button', { name: 'Submit Order' }).click();
cy.wait('@createOrder').its('response.statusCode').should('eq', 201);
cy.findByText(/order created/i).should('be.visible');
```

## Anti-Patterns During Migration

| Anti-pattern | Why it fails | Correct approach |
|---|---|---|
| Keeping explicit sleep calls | Flaky and slow | Alias waits + retryable assertions |
| Porting fragile XPath chains verbatim | Hard to maintain | Prefer role/label/test-id selectors |
| Reusing mutable global driver-like state | Creates cross-test coupling | Keep Cypress tests isolated |
| Using forced clicks everywhere | Masks real UX defects | Fix overlays/state/actionability |

## Checklist

1. Replace Selenium locators with Cypress semantic locator strategy.
2. Remove sleeps and `ExpectedConditions` calls.
3. Add `cy.intercept` aliasing for network-dependent flows.
4. Validate state changes with user-visible assertions.
5. Stabilize auth and setup using hooks plus `cy.session()`.







