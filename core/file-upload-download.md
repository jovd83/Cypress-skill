# File Upload and Download Recipes

> **When to use**: Build reliable Cypress tests for upload controls, drag/drop zones, export downloads, and file validation workflows.

## Recipe 1: Single Upload via Input

### TypeScript

```typescript
it('uploads one document', () => {
  cy.visit('/documents');

  cy.get('input[type=file]').selectFile('cypress/fixtures/report.pdf', { force: true });
  cy.findByText('report.pdf').should('be.visible');

  cy.findByRole('button', { name: 'Upload' }).click();
  cy.findByRole('status').should('contain.text', 'File uploaded successfully');
});
```

### JavaScript

```javascript
it('uploads one document', () => {
  cy.visit('/documents');

  cy.get('input[type=file]').selectFile('cypress/fixtures/report.pdf', { force: true });
  cy.findByText('report.pdf').should('be.visible');

  cy.findByRole('button', { name: 'Upload' }).click();
  cy.findByRole('status').should('contain.text', 'File uploaded successfully');
});
```

## Recipe 2: Multi-File Upload

```typescript
it('uploads multiple attachments', () => {
  cy.visit('/documents');

  cy.get('input[type=file][multiple]').selectFile(
    [
      'cypress/fixtures/manual.pdf',
      'cypress/fixtures/release-notes.txt'
    ],
    { force: true }
  );

  cy.findByText('manual.pdf').should('be.visible');
  cy.findByText('release-notes.txt').should('be.visible');
});
```

## Recipe 3: Drag-and-Drop Upload Zone

```typescript
it('uploads file through dropzone', () => {
  cy.visit('/media');

  cy.get('[data-cy=upload-dropzone]').selectFile('cypress/fixtures/photo.jpg', {
    action: 'drag-drop'
  });

  cy.findByText('photo.jpg').should('be.visible');
});
```

## Recipe 4: Upload Validation Errors

```typescript
it('shows validation for unsupported extension', () => {
  cy.visit('/imports');

  cy.get('input[type=file]').selectFile('cypress/fixtures/script.bat', { force: true });
  cy.findByRole('alert').should('contain.text', 'Unsupported file type');
});

it('shows validation for max size exceeded', () => {
  cy.visit('/imports');

  cy.get('input[type=file]').selectFile('cypress/fixtures/oversize.zip', { force: true });
  cy.findByRole('alert').should('contain.text', 'File exceeds allowed size');
});
```

## Recipe 5: Export Download Request Verification

```typescript
it('requests csv export and returns expected headers', () => {
  cy.intercept('GET', '**/api/export?format=csv').as('exportCsv');

  cy.visit('/reports');
  cy.findByRole('button', { name: /export csv/i }).click();

  cy.wait('@exportCsv').then(({ response }) => {
    expect(response && response.statusCode).to.eq(200);
    expect(response && response.headers['content-type']).to.include('text/csv');
  });
});
```

## Recipe 6: Downloaded File Content Check

Use this when your Cypress setup writes files to `cypress/downloads`.

```typescript
it('validates generated csv content', () => {
  cy.visit('/reports');
  cy.findByRole('button', { name: /export csv/i }).click();

  cy.readFile('cypress/downloads/report.csv').should('contain', 'report_id,total');
});
```

## Recipe 7: Upload Then Download Roundtrip

```typescript
it('uploads template then downloads processed result', () => {
  cy.intercept('POST', '**/api/import').as('importFile');
  cy.intercept('GET', '**/api/import/result*').as('downloadResult');

  cy.visit('/imports');
  cy.get('input[type=file]').selectFile('cypress/fixtures/template.csv', { force: true });
  cy.findByRole('button', { name: /process/i }).click();

  cy.wait('@importFile').its('response.statusCode').should('eq', 200);
  cy.findByRole('button', { name: /download result/i }).click();
  cy.wait('@downloadResult').its('response.statusCode').should('eq', 200);
});
```

## Recipe 8: In-Memory Upload File

```typescript
it('uploads generated json data', () => {
  cy.visit('/imports');

  cy.get('input[type=file]').selectFile({
    contents: JSON.stringify({ id: 1, name: 'Jane Doe' }),
    fileName: 'user.json',
    mimeType: 'application/json'
  }, { force: true });

  cy.findByText('user.json').should('be.visible');
});
```

## Troubleshooting

| Issue | Likely Cause | Fix |
|---|---|---|
| Upload element not interactable | Hidden native input | Use `{ force: true }` with `selectFile()` |
| Alias wait never resolves | Intercept registered too late | Register intercept before clicking upload/download action |
| Download file not found | Different downloads path in CI | Configure/download path and assert accordingly |
| Flaky progress bar assertions | Timing-based expectations | Assert terminal state (`Uploaded`, `Failed`) not transient percentages |

## Anti-Patterns

- Using non-Cypress download/filechooser APIs in Cypress tests.
- Asserting only toast text without checking network response.
- Hardcoding OS-specific absolute fixture paths.
- Massive binary fixtures in normal regression runs.

## Related

- [core/file-operations.md](file-operations.md)
- [core/network-mocking.md](network-mocking.md)
- [core/error-and-edge-cases.md](error-and-edge-cases.md)
