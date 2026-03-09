# File Operations

> **When to use**: Handle upload selection, file validation, generated exports, filesystem checks, and file-driven workflows in Cypress.

## Golden Rules

1. Use `cy.selectFile()` for upload interactions.
2. Verify downloads via network aliases and filesystem assertions.
3. Keep upload fixtures deterministic and small.
4. Assert both UI feedback and backend/network behavior.

## Quick Reference

```typescript
// Upload
cy.get('input[type=file]').selectFile('cypress/fixtures/report.pdf', { force: true });

// Download request assertion
cy.intercept('GET', '**/api/export/csv').as('exportCsv');
cy.findByRole('button', { name: /export csv/i }).click();
cy.wait('@exportCsv').its('response.statusCode').should('eq', 200);

// Download file content assertion (if app writes to downloads folder)
cy.readFile('cypress/downloads/report.csv').should('contain', 'id,name');
```

## Upload Patterns

### Single File Upload

```typescript
it('uploads profile avatar', () => {
  cy.visit('/settings/profile');

  cy.get('input[type=file][name=avatar]').selectFile('cypress/fixtures/avatar.png', { force: true });
  cy.findByText('avatar.png').should('be.visible');

  cy.findByRole('button', { name: /save/i }).click();
  cy.findByRole('status').should('contain.text', 'Profile updated');
});
```

### Multiple File Upload

```typescript
it('uploads multiple attachments', () => {
  cy.visit('/support/ticket');

  cy.get('input[type=file][multiple]').selectFile(
    ['cypress/fixtures/log1.txt', 'cypress/fixtures/log2.txt'],
    { force: true }
  );

  cy.findByText('log1.txt').should('be.visible');
  cy.findByText('log2.txt').should('be.visible');
});
```

### In-Memory File

```typescript
it('uploads generated csv content', () => {
  cy.visit('/imports');

  cy.get('input[type=file]').selectFile({
    contents: Cypress.Buffer.from('name,email\nJane,jane@example.com'),
    fileName: 'users.csv',
    mimeType: 'text/csv'
  }, { force: true });

  cy.findByText('users.csv').should('be.visible');
});
```

## Drag-and-Drop Upload

```typescript
it('uploads through dropzone', () => {
  cy.visit('/media');

  cy.get('[data-cy=dropzone]').selectFile('cypress/fixtures/photo.jpg', {
    action: 'drag-drop'
  });

  cy.findByText('photo.jpg').should('be.visible');
});
```

## Download Verification Patterns

### Verify Export Request + Response

```typescript
it('exports report as csv', () => {
  cy.intercept('GET', '**/api/reports/export?format=csv').as('exportCsv');

  cy.visit('/reports');
  cy.findByRole('button', { name: /export csv/i }).click();

  cy.wait('@exportCsv').then(({ response }) => {
    expect(response && response.statusCode).to.eq(200);
    expect(response && response.headers['content-type']).to.include('text/csv');
  });
});
```

### Verify Downloaded File (if available in your setup)

```typescript
it('validates downloaded csv file contents', () => {
  cy.visit('/reports');
  cy.findByRole('button', { name: /export csv/i }).click();

  cy.readFile('cypress/downloads/report.csv').should('contain', 'total_revenue');
});
```

## File Type and Size Validation

```typescript
it('rejects unsupported file type', () => {
  cy.visit('/imports');

  cy.get('input[type=file]').selectFile('cypress/fixtures/malware.exe', { force: true });
  cy.findByRole('alert').should('contain.text', 'Unsupported file type');
});

it('rejects files above size limit', () => {
  cy.visit('/imports');

  cy.get('input[type=file]').selectFile('cypress/fixtures/large-file.zip', { force: true });
  cy.findByRole('alert').should('contain.text', 'File exceeds 10MB limit');
});
```

## Anti-Patterns

- Using non-Cypress `download` / `filechooser` events in Cypress docs.
- Validating only UI toast without checking request status.
- Upload tests that rely on environment-specific absolute file paths.
- Huge binary fixtures in regular CI runs.

## Related

- [core/file-upload-download.md](file-upload-download.md)
- [core/network-mocking.md](network-mocking.md)
- [core/assertions-and-waiting.md](assertions-and-waiting.md)
