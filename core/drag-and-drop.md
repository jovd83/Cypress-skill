# Drag and Drop

> **When to use**: Kanban boards, sortable lists, file drop zones, and canvas-like interactions.
> **Prerequisites**: [locators.md](locators.md), [assertions-and-waiting.md](assertions-and-waiting.md)

## Cypress Strategy

Use one of these approaches:

1. `@4tw/cypress-drag-drop` for standard draggable/drop-target UI.
2. Native event simulation via `trigger('dragstart')`, `trigger('drop')`.
3. Coordinate-based `trigger('mousedown'/'mousemove'/'mouseup')` only when required by custom libs.

## Quick Reference

```typescript
it('moves card to In Progress', () => {
  cy.visit('/board');
  cy.findByText('Fix login bug').drag('[data-column="in-progress"]');
  cy.get('[data-column="in-progress"]').should('contain.text', 'Fix login bug');
});
```

## Setup (Recommended)

```bash
npm i -D @4tw/cypress-drag-drop
```

```typescript
// cypress/support/e2e.ts
import '@4tw/cypress-drag-drop';
```

## Pattern 1: Basic Item Move

**TypeScript**
```typescript
it('moves item from todo to done', () => {
  cy.visit('/board');

  cy.findByText('Task A').drag('[data-column="done"]');
  cy.get('[data-column="done"]').should('contain.text', 'Task A');
  cy.get('[data-column="todo"]').should('not.contain.text', 'Task A');
});
```

**JavaScript**
```javascript
it('moves item from todo to done', () => {
  cy.visit('/board');
  cy.findByText('Task A').drag('[data-column="done"]');
  cy.get('[data-column="done"]').should('contain.text', 'Task A');
});
```

## Pattern 2: Reordering in Same List

```typescript
it('reorders task list', () => {
  cy.visit('/list');

  cy.findByText('Task C').drag('[data-testid="task-a-handle"]');

  cy.get('[data-testid="task-list"] [data-testid="task-title"]').then(($els) => {
    const items = [...$els].map((el) => el.textContent?.trim());
    expect(items?.[0]).to.eq('Task C');
  });
});
```

## Pattern 3: Verify Network Persistence

```typescript
it('persists board move through API', () => {
  cy.intercept('PATCH', '/api/cards/*').as('patchCard');
  cy.visit('/board');

  cy.findByText('Fix login bug').drag('[data-column="in-progress"]');
  cy.wait('@patchCard').then(({ request, response }) => {
    expect(response?.statusCode).to.eq(200);
    expect(request.body).to.include({ column: 'in-progress' });
  });
});
```

## Pattern 4: HTML5 Native Drag Events (No Plugin)

```typescript
it('drags using native drag events', () => {
  cy.visit('/board');

  const dataTransfer = new DataTransfer();
  cy.get('[data-testid="card-1"]').trigger('dragstart', { dataTransfer });
  cy.get('[data-column="in-progress"]').trigger('drop', { dataTransfer });
  cy.get('[data-testid="card-1"]').trigger('dragend');

  cy.get('[data-column="in-progress"]').should('contain.text', 'Card 1');
});
```

## Pattern 5: File Drop Zone

Prefer selecting files on the hidden input used by the drop area.

```typescript
it('uploads file through drop-zone input', () => {
  cy.visit('/upload');

  cy.get('input[type="file"]').selectFile('cypress/fixtures/sample-document.pdf', {
    force: true,
  });

  cy.findByText('sample-document.pdf').should('be.visible');
});
```

For drag-drop style file upload:

```typescript
it('simulates file drop on drop zone', () => {
  cy.visit('/upload');

  cy.fixture('sample-document.pdf', 'base64').then((content) => {
    const blob = Cypress.Blob.base64StringToBlob(content, 'application/pdf');
    const testFile = new File([blob], 'sample-document.pdf', { type: 'application/pdf' });
    const dataTransfer = new DataTransfer();
    dataTransfer.items.add(testFile);

    cy.get('[data-testid="file-drop-zone"]').trigger('drop', { dataTransfer });
  });

  cy.findByText('sample-document.pdf').should('be.visible');
});
```

## Pattern 6: Coordinate-Based Drag (Custom Libraries)

Use only if plugin/native events are insufficient.

```typescript
it('moves shape on canvas-like surface', () => {
  cy.visit('/canvas-editor');

  cy.get('[data-testid="shape-1"]').trigger('mousedown', { button: 0, clientX: 100, clientY: 100 });
  cy.get('body').trigger('mousemove', { button: 0, clientX: 300, clientY: 220 });
  cy.get('body').trigger('mouseup');

  cy.get('[data-testid="shape-1"]').should(($el) => {
    const rect = $el[0].getBoundingClientRect();
    expect(rect.left).to.be.greaterThan(250);
    expect(rect.top).to.be.greaterThan(180);
  });
});
```

## Anti-Patterns

| Anti-pattern | Why it fails | Better approach |
|---|---|---|
| Fixed `cy.wait(2000)` after drag | Flaky timing | Assert on destination state or network alias |
| Asserting only visual placeholder | Can pass without persistence | Also assert API request + post-reload state |
| Using unstable selectors for cards | Breaks on UI refactors | Use role/name or `data-testid` |
| Forcing clicks during drag setup by default | Masks real issues | Ensure draggable is visible and enabled first |

## Troubleshooting

### Item does not move in CI

- Verify app uses HTML5 DnD vs pointer-event library.
- Switch between plugin and manual event strategy accordingly.
- Assert element visibility and scroll into view before drag.

### Drag works locally but not headless

- Ensure viewport is large enough.
- Disable CSS transitions for test mode if movement is animation-driven.

### File drop test fails

- Confirm accepted MIME/type list.
- Use `selectFile` with `{ force: true }` on hidden file input.

## Related Guides

- [file-upload-download.md](file-upload-download.md)
- [network-mocking.md](network-mocking.md)
- [test-data-management.md](test-data-management.md)
