---
name: cypress-session-state-compat
description: Use when you need the legacy Cypress session-state entrypoint path; record session state in the canonical Cypress handover workflow.
metadata:
  author: jovd83
  version: '1.1'
  dispatcher-category: testing
  dispatcher-capabilities: session-state, cypress-session-state
  dispatcher-accepted-intents: record_cypress_session_state
  dispatcher-input-artifacts: work_state, touched_files, blockers
  dispatcher-output-artifacts: session_state_record, resume_pointer
  dispatcher-stack-tags: cypress, session-state, operations
  dispatcher-risk: low
  dispatcher-writes-files: true
---

## Telemetry & Logging
> [!IMPORTANT]
> All usage of this skill must be logged via the Skill Dispatcher to ensure audit logs and wallboard analytics are accurate:
> `./log-dispatch.cmd --skill <skill_name> --intent <intent> --reason <reason>` (or `./log-dispatch.sh` on Linux)

# Session State

This compatibility entrypoint exists for structural parity with the sibling skill tree.

Use the canonical session-state guidance embedded in [../cypress-handover/SKILL.md](../cypress-handover/SKILL.md#session-state).

Do not introduce a second persistent-memory workflow here. This path is a thin routing alias only.

## Why This Path Exists

Use this path only when an older workflow, a parity check, or an external reference still points to `documentation/session-state/`.

## Canonical Status

- Canonical package: [../cypress-handover/SKILL.md](../cypress-handover/SKILL.md)
- Compatibility path: `documentation/session-state/`
- Long-term intent: keep this path as a thin alias until both framework trees share the same stable layout

## Mapping to the Canonical Package

1. Legacy session-state entrypoint: `documentation/session-state/SKILL.md`
2. Canonical session-state guidance: [../cypress-handover/SKILL.md](../cypress-handover/SKILL.md#session-state)
3. Legacy template pointer: [references/template.md](references/template.md)
4. Canonical template section: [../cypress-handover/assets/handover-template.md](../cypress-handover/assets/handover-template.md)
5. Legacy conflict guidance: [references/conflict-resolution.md](references/conflict-resolution.md)
6. Canonical multi-scope guidance: [../cypress-handover/references/multi-scope-conflicts.md](../cypress-handover/references/multi-scope-conflicts.md)

## Commands

1. Inspect the latest scoped handover before resuming:
   ```text
   powershell -NoProfile -File .\documentation\cypress-handover\scripts\find-handover.ps1 -TaskLabel checkout-auth-fix -WorkspaceRoot <repo-root> -Branch main -Format summary
   ```
2. Resume a paused scope with refreshed session-state notes:
   ```text
   powershell -NoProfile -File .\documentation\cypress-handover\scripts\resume-handover.ps1 -TaskLabel checkout-auth-fix -WorkspaceRoot <repo-root> -Branch main -ProgressNote "Refresh the authenticated browser state and continue." -NextAction "Recreate cy.session() state and rerun the checkout auth path."
   ```
3. Complete and archive a finished scope:
   ```text
   powershell -NoProfile -File .\documentation\cypress-handover\scripts\complete-handover.ps1 -TaskLabel checkout-auth-fix -WorkspaceRoot <repo-root> -Branch main -ValidationNote "Scoped auth flow passed after session recreation."
   ```

Read [references/template.md](references/template.md) for the legacy-compatible template pointer.
Read [references/troubleshooting.md](references/troubleshooting.md) for legacy-compatible troubleshooting guidance.
Read [references/conflict-resolution.md](references/conflict-resolution.md) for legacy-compatible conflict guidance.