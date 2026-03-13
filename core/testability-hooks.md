# Testability Hooks and Automation Contracts

> **When to use**: Standardizing how the application exposes hooks for automation. This reduces selector churn and improves test maintainability.

## Automation Contract Principles

1. **Prefer stable IDs over text**: Content changes frequently; IDs should not.
2. **Standardize naming**: Use a consistent prefix like `data-testid` or `data-automation`.
3. **ARIA as a primary hook**: If it's good for screen readers, it's usually good for Cypress.

## Naming Conventions for `data-testid`

Structure: `[scope]-[component]-[action/element]`

- `login-form-submit`
- `nav-sidebar-toggle`
- `user-table-row-3-delete`
- `modal-settings-close`

## Decision Rules: When to add a hook?

Add a `data-testid` if:
- [ ] The element has no clear ARIA role.
- [ ] The label is dynamic or translated.
- [ ] There are multiple identical elements (e.g., table rows) that are hard to distinguish by text.
- [ ] You find yourself using complex CSS selectors or deeply nested DOM traversal.

## Implementation Examples

### React / Next.js

```tsx
// GOOD: Providing hooks for child elements
const SearchBar = ({ onSearch }) => (
  <div className="search-wrap" data-testid="search-bar-container">
    <input 
      type="text" 
      aria-label="Search items" 
      data-testid="search-input"
    />
    <button 
      onClick={onSearch} 
      data-testid="search-submit"
    >
      Go
    </button>
  </div>
);
```

### Guidance for Developers

- **Don't use classes for behavior**: Classes are for styling. Use `data-testid` for testing.
- **Maintain ARIA integrity**: Adding a test hook should never break accessibility. `aria-label` is often better than a hidden `data-testid`.
- **State Attributes**: Expose state via `aria-busy`, `aria-expanded`, or `data-state="loading"` so Cypress can await the state change automatically via assertions.

## Checklist

- [ ] **Prefix Consistency**: Checked that all hooks use the same attribute name.
- [ ] **Production Removal**: Decision made on whether to strip `data-testid` from production builds (usually not necessary, but optional).
- [ ] **Contract Verification**: Tested the hook actually exists in the rendered DOM before finishing the feature.

## Anti-Patterns

| Anti-pattern | Why it hurts | Better approach |
|---|---|---|
| Reusing CSS classes as test selectors | Styling changes break automation unexpectedly | Use dedicated automation hooks such as `data-testid` |
| Adding hooks with inconsistent naming across features | Increases selector churn and review overhead | Standardize one naming contract and enforce it in code review |
