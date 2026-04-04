---
name: cypress-coverage-matrix-auto-sync
description: Coverage-maintenance skill for Cypress planning and documentation. Use when Codex needs to synchronize coverage plans, scenario IDs, traceability links, and summary counts after tests, requirements, or narrative test documents change.
metadata:
  author: jovd83
  version: "1.1"
---

# Coverage Matrix Auto-Sync

Use this skill to keep planning artifacts aligned with reality after the suite changes.

## 1. Traceability Maintenance

Identify added, removed, renamed, or moved scenarios and reconcile them across:

- the coverage plan or matrix,
- narrative TDD or BDD documents,
- implementation references such as `.cy.ts` files, titles, tags, or scenario IDs.

Do not invent implementation links that you cannot verify.

## 2. Coverage Stats Recalculation

Recalculate summary counts only after the underlying scenario rows are correct.

Flag drift explicitly when the plan claims coverage that the implementation cannot prove.

## 3. Anchor & ID Standards

- Prefer stable scenario IDs over human-readable titles for traceability joins.
- Keep anchors and IDs consistent across plan, docs, and code.
- Ensure each requirement or acceptance-criteria item can be traced to at least one scenario when the matrix is intended to be complete.

## 4. Documentation Sync Workflow

1. Treat `coverage_plan/*.md` as the source of truth for planned scope.
2. Treat `docs/tests/**/*.md` as the narrative traceability layer when those files exist.
3. Treat Cypress implementation as the proof layer for executed behavior.
4. Report unmapped requirements, stale IDs, broken links, or evidence gaps explicitly.

## Checklist

- [ ] Stats updated after row-level reconciliation
- [ ] IDs and links verified
- [ ] Unmapped requirements or scenarios called out explicitly
- [ ] Scenario names and references consistent across plan, docs, and code
