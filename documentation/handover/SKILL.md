---
name: cypress-handover-compat
description: Use when you need the legacy Cypress handover entrypoint path; follow the canonical Cypress handover workflow in documentation/cypress-handover.
--- 

# Handover

This compatibility entrypoint exists for structural parity with the sibling skill tree.

Use the canonical handover workflow in [../cypress-handover/SKILL.md](../cypress-handover/SKILL.md).

## Why This Path Exists

Use this path only when an older workflow, a parity check, or an external reference still points to `documentation/handover/`.

## Canonical Status

- Canonical package: [../cypress-handover/SKILL.md](../cypress-handover/SKILL.md)
- Compatibility path: `documentation/handover/`
- Long-term intent: keep this path as a thin alias until both framework trees share the same stable layout

## Mapping to the Canonical Package

1. Legacy handover entrypoint: `documentation/handover/SKILL.md`
2. Canonical implementation: [../cypress-handover/SKILL.md](../cypress-handover/SKILL.md)
3. Legacy template pointer: [references/template.md](references/template.md)
4. Canonical template: [../cypress-handover/assets/handover-template.md](../cypress-handover/assets/handover-template.md)
5. Legacy conflict guidance: [references/conflict-resolution.md](references/conflict-resolution.md)
6. Canonical multi-scope guidance: [../cypress-handover/references/multi-scope-conflicts.md](../cypress-handover/references/multi-scope-conflicts.md)

## Commands

1. Find the latest handover for one scope:
   ```text
   powershell -NoProfile -File .\documentation\cypress-handover\scripts\find-handover.ps1 -TaskLabel checkout-auth-fix -WorkspaceRoot <repo-root> -Branch main -Format summary
   ```
2. Create a new handover checkpoint:
   ```text
   powershell -NoProfile -File .\documentation\cypress-handover\scripts\new-handover.ps1 -TaskLabel checkout-auth-fix -DocsRoot docs/tests
   ```
3. Resume a paused scope:
   ```text
   powershell -NoProfile -File .\documentation\cypress-handover\scripts\resume-handover.ps1 -TaskLabel checkout-auth-fix -WorkspaceRoot <repo-root> -Branch main -ProgressNote "Continue the failing checkout auth investigation." -NextAction "Run the scoped Cypress auth spec and inspect session state."
   ```

Read [references/template.md](references/template.md) for the legacy-compatible template pointer.
Read [references/troubleshooting.md](references/troubleshooting.md) for legacy-compatible troubleshooting guidance.
Read [references/conflict-resolution.md](references/conflict-resolution.md) for legacy-compatible conflict guidance.
