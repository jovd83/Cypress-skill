---
name: cypress-handover
description: Use when you need a Cypress task handover that preserves status, session state, blockers, and exact resume steps for a human or later agent.
metadata:
  author: jovd83
  version: "1.0"
  dispatcher-category: testing
  dispatcher-capabilities: handover, cypress-handover
  dispatcher-accepted-intents: create_cypress_handover
  dispatcher-input-artifacts: work_summary, validation_status, blockers
  dispatcher-output-artifacts: handover_document, resume_steps
  dispatcher-stack-tags: cypress, handover, operations
  dispatcher-risk: low
  dispatcher-writes-files: true
---

# Handover to Human-in-the-Loop

Create a clear handover document at task completion summarizing completed work, current state, session state, blockers, and the exact next step so a human or a later agent can resume without rediscovery.


## Telemetry & Logging
> [!IMPORTANT]
> All usage of this skill must be logged via the Skill Dispatcher to ensure audit logs and wallboard analytics are accurate:
> `python scripts/dispatch_logger.py --skill <skill_name> --intent <intent> --reason <reason>`

## 1. Storage and Naming

- **Directory**: `<test_documentation_root>/handovers/`
  - Default root: `docs/tests/`
- **Archive directory**: `<test_documentation_root>/handovers/archive/`
  - Use it only for completed scopes that were archived out of the active handover queue.
- **Filename format**: `YYYYMMDD_HHmm_CypressSkillHandover.md`
  - On Windows, do not use `:` in filenames.
- **Lifecycle rule**: the latest handover must reflect the latest known state of the task. If work is resumed later, update the existing handover or create a new handover that references the previous one.

## 2. Content Structure

The handover must include:

### Task summary
State the objective, scope, and intended outcome of the task.

Record these metadata lines at the top of the handover before the section headings:
- `Timestamp`
- `Task label`
- `Workspace root`
- `Branch`
- `Previous handover`

`Task label` must use lowercase letters, digits, and hyphens only, for example `checkout-auth-fix`.
Keep it stable across the same task chain and let `Workspace root` plus `Branch` disambiguate parallel scopes.

`Previous handover` must be either:
- `No prior handover found`
- an existing path to an earlier handover for the same `Task label`

The full `Previous handover` chain must remain valid:
- no missing ancestor files
- no cycles
- no cross-task links
- no cross-workspace links
- no cross-branch links
- timestamps must move backward in time through the chain

### Current status
State one explicit status: `Completed`, `In progress`, `Blocked`, or `Awaiting approval`.

### What was done
Summary of completed actions.

### In progress
List work that was started but not finished.

### Remaining work
List work that still needs to be done or was intentionally deferred.

### Blockers and open questions
List anything preventing completion, including missing information, failing environments, approvals, or unresolved decisions.

### Next action
State the single highest-priority next step in one or two sentences.

### Session state
Record the runtime state needed to continue safely:
- active role, account, or persona
- auth approach used (for example: `cy.session()`, API login, seeded backend state, or CLI `state-save/state-load`)
- relevant browser or app state (cookies, localStorage, sessionStorage, feature flags, seeded data, base URL, browser profile)
- any state artifact paths or cache keys that can be reused
- how to recreate or refresh the state if it is expired or non-portable

Do not store raw secrets, tokens, or cookie values in the handover. Reference the source of truth instead, such as environment variables, secret stores, fixtures, or setup commands.

### How to resume
Provide the concrete restart path:
- files to open first
- commands to run
- environment variables, accounts, or services needed
- session-state artifacts or setup steps needed before running tests
- where the last meaningful stopping point was

### Validation and evidence
Record tests, checks, or manual verification already performed and what still needs verification.
Use explicit fallback values such as `None.`, `Not run because ...`, or `Unknown. Recreate by ...` only when they are true.
Do not use low-signal filler such as `TBD`, `TODO`, `N/A`, `pending`, or blank section bodies.

### Skills and subskills used
List all skills used and why.

### Non-skill actions and suggestions
Actions not covered by skills, plus proposals for new skills/subskills.

### Patterns used
Architecture or implementation patterns used (for example: POM, custom commands, fixtures).

### Anti-patterns used
Any unavoidable anti-patterns and justification.

### Strengths of the changes
Main benefits.

### Weaknesses of the changes
Known risks and limitations.

### Improvements
Concrete next improvements.

### Files added/modified
Categorize by:
- Documentation
- POMs
- Test scripts
- Configurations
- Other
Include short rationale per category.

Write the sections in the order above so the next human or agent can scan status first and details second.

## 3. Execution

Create and store this handover document at the end of each task unless the user asks otherwise.
When the task is incomplete, the handover must still be written and must clearly identify the stopping point, remaining work, and restart instructions.

## 4. Prerequisites and Fallbacks

1. Confirm the relevant workspace, branch, and task scope before writing the handover.
2. Confirm whether `docs/tests/` already exists.
   - If it does not exist, create `docs/tests/handovers/` before saving the handover.
3. Check for an earlier handover for the same task.
   - If one exists, update it or create a new handover that references the earlier file.
   - If none exists, create a new handover and state that no prior handover was available.
4. Confirm whether session state can be inspected safely.
   - If state details are unavailable, record `Unknown` and state exactly how the next human or agent should recreate the session.
5. Confirm whether verification was actually run.
   - If no checks were run, state `Not run` rather than implying success.
6. Confirm whether the current branch can be resolved.
   - If Git metadata is unavailable, record `Unknown` for `Branch` and continue.

## 5. Workflow

When asked to create or update a handover:

1. Identify the exact task boundary.
2. Gather the latest evidence from changed files, commands run, test output, and user decisions.
3. Determine the current status: `Completed`, `In progress`, `Blocked`, or `Awaiting approval`.
4. Record unfinished work, blockers, open questions, and the single highest-priority next action.
5. Record session state without copying raw secrets, tokens, or cookie values.
6. Record how to resume the task, including files, commands, environment requirements, and state recreation steps.
7. Record validation evidence and any verification still missing.
8. When you need health status for the whole handover set, run `scripts/audit-handovers.ps1` before resuming or triaging shared work.
   - Use it to validate every stored handover and surface duplicate `Task label` collisions across different workspace or branch scopes.
   - Use `-Location all` when you need one audit across both active and archived handovers.
   - The audit also reports the bad state where the same task scope exists in both active and archived storage at once.
   - Use `-FailOnIssues` when the audit must stop on invalid files or ambiguous labels.
   - If the audit reports a bad or conflicting task label in an existing scope, repair it with `scripts/rename-task-label.ps1` before resuming work.
   - Use `-Location archive` when the broken or duplicate scope exists only in archived storage.
   - When the audit reports the same scope in both active and archive, resolve it with `scripts/resolve-handover-location-conflict.ps1` instead of deleting files manually.
9. When one scope needs a deterministic next-step recommendation, run `scripts/doctor-handover.ps1`.
   - Use it when you need the tool to tell you whether the next action is `resume`, `restore`, `archive`, `repair`, or `complete`.
   - It inspects both the selected scope and the audit state, then returns the recommended action plus the exact command to run next.
   - Link-related chain failures are directed to `scripts/repair-handover-links.ps1`.
   - Active/archive duplication conflicts are directed to `scripts/resolve-handover-location-conflict.ps1`.
10. When triaging multiple open or paused tasks, run `scripts/overview-handovers.ps1` first to see the latest handover per task scope.
   - The default scope is `Task label + Workspace root + Branch`.
   - Use `-Location archive` to inspect archived scopes or `-Location all` to inspect both active and archived queues in one view.
   - Even with `-GroupBy task`, the overview keeps active and archived scopes distinct so archive duplication cannot be hidden.
   - Use `-GroupBy task` only when label-only aggregation is intentional and scope differences do not matter.
   - Use `-Sort priority` to rank resume-ready tasks first.
   - Use `-Status "In progress","Awaiting approval"` to focus on actionable tasks.
   - Use `-ExcludeCompleted` to hide closed work from the overview.
   - Use `-OnlyStale -StaleAfterDays <n>` to surface tasks whose handovers have gone stale.
11. When you need a single deterministic recommendation for what to resume next, run `scripts/recommend-handover.ps1`.
   - Use it after the overview when you want one next task instead of a full list.
   - Use `-Location archive -IncludeCompleted` when choosing an archived scope to inspect or restore next.
   - Use `-Status` and `-OnlyStale` to constrain the recommendation.
   - Pass `-WorkspaceRoot` and `-Branch` when the same `Task label` exists in more than one scope.
12. When resuming an existing task, run `scripts/find-handover.ps1` first to locate the latest relevant handover and extract the current state.
   - Pass `-TaskLabel <label>` when the task label is known.
   - Use `-Location archive` to inspect an archived scope before restoring it, or `-Location all` when you do not know whether the scope is active or archived yet.
   - Pass `-WorkspaceRoot <path>` and `-Branch <name>` when the same `Task label` exists in multiple scopes.
   - Use the summary output to confirm `Current status`, `Next action`, `Session state`, and `How to resume` before changing files.
13. When you need the full history for one task scope, run `scripts/trace-handover-chain.ps1`.
   - Use it to inspect every handover in the chain from newest to oldest before auditing drift, closing a task, or reviewing how the scope evolved.
   - Use `-Location archive` to inspect archived chains directly, or `-Location all` when you do not know whether the scope is active or archived yet.
   - Pass `-WorkspaceRoot` and `-Branch` when the same `Task label` exists in multiple scopes.
14. When you need to know what changed since the previous checkpoint in one task scope, run `scripts/diff-handover-checkpoints.ps1`.
   - Use it before resuming work, during handoff review, or before closing a task so you can see the delta between the latest handover and its immediate predecessor.
   - Use `-Location archive` to compare archived checkpoints before restore or historical review.
   - Pass `-WorkspaceRoot` and `-Branch` when the same `Task label` exists in multiple scopes.
15. When a completed scope should leave the active queue without losing history, run `scripts/archive-handover-scope.ps1`.
   - Use it only after the latest handover in the selected scope is `Completed`.
   - It moves the whole scope chain into `handovers/archive/` and rewrites internal `Previous handover` links to the archived paths.
16. When an archived scope needs to re-enter the active queue, run `scripts/restore-handover-scope.ps1`.
   - Use it before resuming work on a previously archived completed scope.
   - It moves the archived scope chain back into `handovers/` and rewrites internal `Previous handover` links to the active paths.
17. When work resumes and you need a fresh active checkpoint instead of editing the previous handover in place, run `scripts/resume-handover.ps1`.
   - Pass `-ProgressNote` and `-NextAction` so the new checkpoint records what changed since the prior handover.
   - Use `-Status "Blocked"` or `-Status "Awaiting approval"` when resumed work discovered a new blocker or approval gate.
   - If the selected scope exists only in archive, restore it first with `scripts/restore-handover-scope.ps1`.
   - Pass `-WorkspaceRoot` and `-Branch` when the same `Task label` exists in more than one scope.
18. Run `scripts/new-handover.ps1` to scaffold the handover file from `assets/handover-template.md`.
   - Pass a human-readable label if needed; the script normalizes it to lowercase hyphen-case before writing the handover.
   - Let the script auto-detect `Workspace root`, `Branch`, and the newest earlier handover in the same scope (`Task label + Workspace root + Branch`) when possible.
   - If the same scope exists only in archive, restore it first with `scripts/restore-handover-scope.ps1` instead of creating a fresh active chain.
   - If the earlier handover must be overridden manually, pass `-PreviousHandover <path>` only when that file exists in the same active scope and is not in archive.
19. When files were moved manually, the repo root changed, or `Previous handover` paths drifted, run `scripts/repair-handover-links.ps1`.
   - It rebuilds `Previous handover` links from task metadata and timestamp order within the selected scope or location.
   - Use `-Location archive` to repair archived chains in place without restoring them first.
20. When external tooling or dashboards need a machine-readable view, run `scripts/export-handover-index.ps1`.
   - It combines the latest scope overview with audit results into one JSON export.
   - Use `-OutputPath <file>` to persist the export for downstream tools.
   - Use `-IncludeHistory` when downstream tools also need full newest-to-oldest checkpoint chains per latest scope.
   - Use `-Format csv` when a flat latest-scope table is easier for spreadsheets or simple dashboards than nested JSON.
21. Fill the generated handover file with task-specific facts. Do not leave placeholder values in place.
   - Use explicit statements such as `None.`, `Not run because ...`, or `Unknown. Recreate by ...` when needed.
   - Do not leave sections as `TBD`, `TODO`, `N/A`, or other low-signal filler.
22. Run `scripts/validate-handover.ps1 -Path <handover-file>` before stopping.
   - The validator enforces heading coverage, low-signal rejection, and full `Previous handover` chain integrity across task label, workspace root, and timestamp order.
23. When the task is finished and you need a fresh completion checkpoint, run `scripts/complete-handover.ps1` to create a new `Completed` handover that references the latest prior handover in the selected scope.
   - Pass `-ValidationNote` with the final validation result that proves the task is complete.
   - If the selected scope exists only in archive, restore it first with `scripts/restore-handover-scope.ps1`.
   - Pass `-WorkspaceRoot` and `-Branch` when the same `Task label` exists in more than one scope.
24. Save the validated handover in `docs/tests/handovers/` using the required filename format.

## 6. Deterministic Assets and Commands

1. Use `assets/handover-template.md` as the default document shape.
2. Use `references/blocked-handover-example.md` when the current task is incomplete or blocked and a concrete example is needed.
3. Run the audit script when you need to validate the whole handover set:
   ```powershell
   powershell -NoProfile -File .\scripts\audit-handovers.ps1
   ```
   It validates every handover in `docs/tests/handovers/` and reports invalid files plus duplicate `Task label` collisions across workspace and branch scopes.
   To include archived handovers in the same report:
   ```powershell
   powershell -NoProfile -File .\scripts\audit-handovers.ps1 -Location all
   ```
   To fail immediately when issues exist:
   ```powershell
   powershell -NoProfile -File .\scripts\audit-handovers.ps1 -FailOnIssues
   ```
4. Run the doctor script when you need one exact next lifecycle action for a selected scope:
   ```powershell
   powershell -NoProfile -File .\scripts\doctor-handover.ps1 -TaskLabel "checkout-auth-fix" -WorkspaceRoot "C:\projects\shop-app" -Branch "fix/checkout-auth-refresh"
   ```
   It recommends whether to `resume`, `restore`, `archive`, `repair`, or `complete`, and prints the exact command to run next.
5. Run the export script when external tools need a machine-readable snapshot:
   ```powershell
   powershell -NoProfile -File .\scripts\export-handover-index.ps1 -Location all -OutputPath .\handover-index.json
   ```
   It writes a JSON object containing audit summary, invalid handovers, collisions, and the latest scope index.
   To include full chain history per latest scope:
   ```powershell
   powershell -NoProfile -File .\scripts\export-handover-index.ps1 -Location all -IncludeHistory -OutputPath .\handover-index.json
   ```
   To emit a flat CSV table of the latest scopes:
   ```powershell
   powershell -NoProfile -File .\scripts\export-handover-index.ps1 -Location all -Format csv -OutputPath .\handover-index.csv
   ```
6. Run the repair script when `Previous handover` links drift after manual file moves, renames, or repo relocation:
   ```powershell
   powershell -NoProfile -File .\scripts\repair-handover-links.ps1 -TaskLabel "checkout-auth-fix" -WorkspaceRoot "C:\projects\shop-app" -Branch "fix/checkout-auth-refresh"
   ```
   It rewrites the `Previous handover` metadata in timestamp order and validates the repaired scope before finishing.
7. Run the active/archive duplication resolver when the same scope exists in both locations and one copy must become canonical:
   ```powershell
   powershell -NoProfile -File .\scripts\resolve-handover-location-conflict.ps1 -TaskLabel "checkout-auth-fix" -WorkspaceRoot "C:\projects\shop-app" -Branch "fix/auth-refresh" -KeepLocation active
   ```
   It validates the kept location, removes the duplicate files from the other location, and leaves one canonical scope.
8. For concrete multi-branch, multi-workspace, and active/archive conflict examples, read `references/multi-scope-conflicts.md`.
9. Run the overview script when multiple handovers exist and you need the latest state per task scope:
   ```powershell
   powershell -NoProfile -File .\scripts\overview-handovers.ps1
   ```
   It returns the latest handover per `Task label + Workspace root + Branch`, including location, status, priority rank, age in days, stale flag, chain depth, next action, blockers, and path.
   Use filters and priority sorting when needed:
   ```powershell
   powershell -NoProfile -File .\scripts\overview-handovers.ps1 -Sort priority -Status "In progress","Awaiting approval" -ExcludeCompleted
   ```
   To inspect archived scopes without restoring them:
   ```powershell
   powershell -NoProfile -File .\scripts\overview-handovers.ps1 -Location archive -Sort recent
   ```
   To inspect both active and archived queues together:
   ```powershell
   powershell -NoProfile -File .\scripts\overview-handovers.ps1 -Location all
   ```
   To aggregate strictly by task label when scope differences do not matter:
   ```powershell
   powershell -NoProfile -File .\scripts\overview-handovers.ps1 -GroupBy task
   ```
   To focus on stale work:
   ```powershell
   powershell -NoProfile -File .\scripts\overview-handovers.ps1 -Sort stale -OnlyStale -StaleAfterDays 5
   ```
10. Run the recommender script when you want exactly one next task:
   ```powershell
   powershell -NoProfile -File .\scripts\recommend-handover.ps1 -Sort priority -Status "In progress","Awaiting approval"
   ```
   It returns the single highest-ranked handover for the requested filters and explains why it was chosen.
   To choose one archived scope for restore review:
   ```powershell
   powershell -NoProfile -File .\scripts\recommend-handover.ps1 -Location archive -IncludeCompleted -Sort recent
   ```
11. Run the finder script before resuming an existing task:
   ```powershell
   powershell -NoProfile -File .\scripts\find-handover.ps1 -TaskLabel "checkout-auth-fix"
   ```
   It returns the newest matching handover and prints the key resume fields needed to continue the task safely.
   To inspect an archived scope before restoring it:
   ```powershell
   powershell -NoProfile -File .\scripts\find-handover.ps1 -TaskLabel "checkout-auth-fix" -Location archive
   ```
   When the same task label exists in multiple scopes, disambiguate with:
   ```powershell
   powershell -NoProfile -File .\scripts\find-handover.ps1 -TaskLabel "checkout-auth-fix" -WorkspaceRoot "C:\projects\shop-app" -Branch "fix/checkout-auth-refresh"
   ```
12. Run the chain-trace script when you need the full scope history from newest to oldest:
   ```powershell
   powershell -NoProfile -File .\scripts\trace-handover-chain.ps1 -TaskLabel "checkout-auth-fix" -WorkspaceRoot "C:\projects\shop-app" -Branch "fix/checkout-auth-refresh"
   ```
   It prints every handover in the selected chain, including location, status, next action, validation, previous link, and path.
   To trace an archived chain without restoring it:
   ```powershell
   powershell -NoProfile -File .\scripts\trace-handover-chain.ps1 -TaskLabel "checkout-auth-fix" -Location archive
   ```
13. Run the checkpoint-diff script when you need to compare the latest scope checkpoint to the one before it:
   ```powershell
   powershell -NoProfile -File .\scripts\diff-handover-checkpoints.ps1 -TaskLabel "checkout-auth-fix" -WorkspaceRoot "C:\projects\shop-app" -Branch "fix/checkout-auth-refresh"
   ```
   It reports the changed tracked fields between the newest handover and its immediate predecessor, including location, status, work summary, blockers, next action, validation, and file-change notes.
   To compare archived checkpoints without restoring the scope:
   ```powershell
   powershell -NoProfile -File .\scripts\diff-handover-checkpoints.ps1 -TaskLabel "checkout-auth-fix" -Location archive
   ```
14. Run the archive script when a completed scope should leave the active handover queue:
   ```powershell
   powershell -NoProfile -File .\scripts\archive-handover-scope.ps1 -TaskLabel "checkout-auth-fix" -WorkspaceRoot "C:\projects\shop-app" -Branch "fix/checkout-auth-refresh"
   ```
   It moves the full completed chain into `docs/tests/handovers/archive/`, rewrites internal `Previous handover` paths to the archived files, validates the archived copies, and removes the active copies after success.
15. Run the restore script when an archived completed scope needs to become active again:
   ```powershell
   powershell -NoProfile -File .\scripts\restore-handover-scope.ps1 -TaskLabel "checkout-auth-fix" -WorkspaceRoot "C:\projects\shop-app" -Branch "fix/checkout-auth-refresh"
   ```
   It moves the archived chain back into `docs/tests/handovers/`, rewrites internal `Previous handover` paths to the active files, validates the restored copies, and removes the archived copies after success.
16. Run the resume script when you want a new in-progress checkpoint copied from the latest scoped handover:
   ```powershell
   powershell -NoProfile -File .\scripts\resume-handover.ps1 -TaskLabel "checkout-auth-fix" -WorkspaceRoot "C:\projects\shop-app" -Branch "fix/checkout-auth-refresh" -ProgressNote "Revalidated the auth helper after the backend patch and confirmed the login step now passes." -NextAction "Rerun the checkout suite and capture the final pass artifact."
   ```
   It creates a new timestamped handover, links it to the previous handover, keeps prior context, updates the active status, and validates the new checkpoint before finishing.
17. Run the scaffolding script from the skill directory:
   ```powershell
   powershell -NoProfile -File .\scripts\new-handover.ps1 -TaskLabel "checkout-auth-fix"
   ```
   It auto-fills `Workspace root`, `Branch`, normalizes `Task label` to lowercase hyphen-case, and records the most recent earlier handover path for the same task scope in the target `handovers/` directory.
18. Run the validation script before ending the task:
   ```powershell
   powershell -NoProfile -File .\scripts\validate-handover.ps1 -Path .\docs\tests\handovers\20260311_1530_CypressSkillHandover.md
   ```
19. Run the task-label repair script when an existing scope needs a corrected or more specific label:
   ```powershell
   powershell -NoProfile -File .\scripts\rename-task-label.ps1 -OldTaskLabel "checkout-auth-fix" -NewTaskLabel "checkout-auth-phase-2" -WorkspaceRoot "C:\projects\shop-app" -Branch "fix/checkout-auth-refresh"
   ```
   It normalizes the new label to lowercase hyphen-case, updates every matching handover in the selected location, workspace, and branch scope, and validates the rewritten files before finishing.
   To repair an archived scope in place:
   ```powershell
   powershell -NoProfile -File .\scripts\rename-task-label.ps1 -OldTaskLabel "checkout-auth-fix" -NewTaskLabel "checkout-auth-phase-2" -Location archive -WorkspaceRoot "C:\projects\shop-app" -Branch "fix/checkout-auth-refresh"
   ```
20. Run the completion script when the latest handover scope is finished and needs a new completed checkpoint:
   ```powershell
   powershell -NoProfile -File .\scripts\complete-handover.ps1 -TaskLabel "checkout-auth-fix" -WorkspaceRoot "C:\projects\shop-app" -Branch "fix/checkout-auth-refresh" -ValidationNote "Ran npx cypress run --spec cypress/e2e/checkout/checkout.cy.ts and the suite passed."
   ```
   It creates a new timestamped handover, links it to the previous handover, marks the scope `Completed`, clears unfinished-work sections, and validates the new file before finishing.

## 7. Troubleshooting

1. Missing `docs/tests/handovers/`
   - Run `scripts/new-handover.ps1`. It creates the directory automatically.
2. No previous handover exists
   - Create a new handover and state `No prior handover found` in the file.
   - If the auto-detected result is not the correct prior handover, rerun `scripts/new-handover.ps1` with `-PreviousHandover <path>`.
   - If it reports the same scope exists only in archive, run `scripts/restore-handover-scope.ps1` first instead of creating a fresh active chain.
   - If it rejects the manual override, confirm that the file exists and matches the same task label, workspace root, and branch.
3. The finder script returns the wrong task or no result
   - Rerun `scripts/find-handover.ps1 -TaskLabel <label>` with the exact task label from the handover metadata.
   - If no result exists, start a new handover and state `No prior handover found`.
4. The audit script reports invalid handovers
   - Rerun `scripts/validate-handover.ps1 -Path <handover-file>` for each failing path.
   - Fix the reported metadata, headings, chain link, or low-signal section content and rerun the audit.
5. The doctor script recommends `repair`
   - If the scope is invalid because of stale `Previous handover` links, run `scripts/repair-handover-links.ps1` with the same task label, workspace root, and branch.
   - If the same scope exists in both active and archive, resolve the storage conflict with `scripts/archive-handover-scope.ps1` or `scripts/restore-handover-scope.ps1` instead of rewriting links.
6. The audit script reports duplicate task labels across workspace or branch scopes
   - Run `scripts/rename-task-label.ps1` with `-Location`, `-WorkspaceRoot`, and `-Branch` so only the intended scope is renamed.
   - If the collision is historical and only affects archived files, repair the archived scope directly with `-Location archive`.
7. The audit script reports the same scope in both active and archive
   - Decide whether the scope belongs in the active queue or the archive.
   - Use `scripts/resolve-handover-location-conflict.ps1` to keep the intended location and remove the duplicate copy deterministically.
   - Use `references/multi-scope-conflicts.md` if you need a concrete active/archive example before deciding.
8. The export script is needed by another tool or dashboard
   - Run `scripts/export-handover-index.ps1 -Location all -OutputPath <file>` and consume the JSON from that file.
   - Add `-IncludeHistory` when the consumer also needs the full checkpoint chain per latest scope.
   - Rerun the export after repairs, restores, archives, or completions so downstream tools see current state.
9. The validator reports an invalid task label format
   - Run `scripts/rename-task-label.ps1` to rewrite the entire affected scope instead of editing individual files by hand.
   - Use `-Location archive` when the invalid label exists only in archived storage.
   - Prefer stable values such as `checkout-auth-fix` instead of prose or sentence-style labels.
10. The task-label repair script reports multiple matching scopes
   - Rerun `scripts/rename-task-label.ps1` with `-Location`, `-WorkspaceRoot`, and `-Branch`.
   - Use `scripts/overview-handovers.ps1` or `scripts/audit-handovers.ps1` first if the correct scope is not obvious.
11. The completion script reports multiple matching scopes
   - Rerun `scripts/complete-handover.ps1` with both `-WorkspaceRoot` and `-Branch`.
   - Use `scripts/find-handover.ps1` or `scripts/overview-handovers.ps1` first to confirm the exact scope you intend to close.
   - If it reports the scope exists only in archive, run `scripts/restore-handover-scope.ps1` first.
12. The completion script reports an existing output file
   - Wait for the next minute so the timestamped filename changes, or rerun with `-Force` if overwriting that just-created file is intentional.
13. The chain-trace script reports multiple matching scopes
   - Rerun `scripts/trace-handover-chain.ps1` with `-Location`, `-WorkspaceRoot`, and `-Branch`.
   - Use `scripts/overview-handovers.ps1` first if the correct scope is not obvious.
14. The checkpoint-diff script reports multiple matching scopes
   - Rerun `scripts/diff-handover-checkpoints.ps1` with `-Location`, `-WorkspaceRoot`, and `-Branch`.
   - Use `scripts/trace-handover-chain.ps1` or `scripts/overview-handovers.ps1` first if the correct scope is not obvious.
15. The checkpoint-diff script reports that no previous handover is available
   - Start by tracing the scope with `scripts/trace-handover-chain.ps1` to confirm whether the selected handover is the first in the chain.
   - If the chain has only one handover, compare manually after the next checkpoint is created.
16. The archive script reports multiple matching scopes
   - Rerun `scripts/archive-handover-scope.ps1` with both `-WorkspaceRoot` and `-Branch`.
   - Use `scripts/trace-handover-chain.ps1` first if the correct completed scope is not obvious.
17. The archive script reports that the latest handover is not completed
   - Run `scripts/complete-handover.ps1` first if the task is actually done.
   - If the task is still active, leave it in the main handover directory and do not archive it.
18. The archive script reports an existing archive target
   - Rerun with `-Force` only if overwriting the archived copies is intentional.
   - Otherwise keep the existing archive and inspect it before trying again.
19. The restore script reports multiple matching scopes
   - Rerun `scripts/restore-handover-scope.ps1` with both `-WorkspaceRoot` and `-Branch`.
   - Use `scripts/trace-handover-chain.ps1` on the archive or inspect the archived metadata first if the correct scope is not obvious.
20. The restore script reports an existing restore target
   - Rerun with `-Force` only if overwriting the active copies is intentional.
   - Otherwise inspect the active handover queue before restoring.
21. The resume script reports multiple matching scopes
   - Rerun `scripts/resume-handover.ps1` with both `-WorkspaceRoot` and `-Branch`.
   - Use `scripts/find-handover.ps1` or `scripts/trace-handover-chain.ps1` first to confirm the exact scope you intend to continue.
   - If it reports the scope exists only in archive, run `scripts/restore-handover-scope.ps1` first.
22. The resume script reports an existing output file
   - Wait for the next minute so the timestamped filename changes, or rerun with `-Force` if overwriting that just-created file is intentional.
23. The overview script misses or duplicates tasks
   - Confirm each handover has a meaningful `Task label`.
   - Fix duplicate labels if two unrelated tasks were given the same label.
   - Use the default scope-aware grouping or pass `-GroupBy task` only when label-only aggregation is intentional.
   - Use `-Location archive` or `-Location all` when the missing scope was archived instead of active.
   - Rerun `scripts/overview-handovers.ps1` after correcting the metadata.
24. The overview script shows too many tasks or the wrong order
   - Use `-Status` to restrict the overview to `In progress`, `Blocked`, `Awaiting approval`, or `Completed`.
   - Use `-Sort priority` to rank resume-ready tasks first, or `-Sort recent` to sort strictly by newest timestamp.
   - Use `-Sort stale -OnlyStale -StaleAfterDays <n>` to focus on aging handovers.
   - Use `-ExcludeCompleted` to hide completed work.
25. The recommender script picks an unexpected task
   - Rerun `scripts/recommend-handover.ps1` with `-Status` to narrow the candidate set.
   - Use `-Location archive -IncludeCompleted` when you want a restore candidate instead of an active task.
   - Pass `-WorkspaceRoot` and `-Branch` when the same task label exists in multiple scopes.
   - Use `-Sort recent` or `-Sort stale` if priority sorting is not the intended ranking rule.
   - Run `scripts/overview-handovers.ps1` to inspect the full ranked list before continuing.
26. The finder script reports multiple handovers for the same task label
   - Rerun `scripts/find-handover.ps1` with `-Location`, `-WorkspaceRoot`, and `-Branch`.
   - Use `scripts/overview-handovers.ps1` first if the correct scope is not obvious.
27. The validator reports an invalid `Previous handover`
   - Confirm the referenced file still exists.
   - Confirm it belongs to the same `Task label`.
   - If file moves or repo relocation broke otherwise-correct links, run `scripts/repair-handover-links.ps1` instead of editing every file by hand.
   - If there is no valid earlier handover, replace the value with `No prior handover found`.
28. The validator reports a broken or cyclic handover chain
   - Follow the `Previous handover` links manually or with `scripts/find-handover.ps1`.
   - Use `scripts/repair-handover-links.ps1` when the scope metadata is correct and only the stored links drifted.
   - Remove stale references, fix cross-task links, and break cycles by pointing the earliest valid handover to `No prior handover found`.
29. The validator reports a cross-workspace or out-of-order handover chain
   - Confirm the handover belongs to the same workspace as its ancestors.
   - Confirm the handover belongs to the same branch as its ancestors.
   - Ensure each `Previous handover` is older than the current handover it links from.
   - If the chain is wrong, update the reference to the correct earlier handover or reset the earliest valid handover to `No prior handover found`.
30. Git branch or repo root cannot be detected
   - Record `Unknown` for the missing metadata field and continue with the rest of the handover.
31. The session state is expired or not portable
   - Record the original session method and write exact recreation steps instead of copying stale state.
32. Credentials or secrets are unavailable
   - Record the missing dependency, identify the expected secret source, and mark the task `Blocked` or `Awaiting approval`.
33. Verification was not run or failed
   - Record `Not run` or the failing command verbatim and list the next action needed to continue.
34. The validator reports missing sections or placeholders
   - Fill every required heading and remove all `{{PLACEHOLDER}}` tokens before stopping.
35. The validator reports low-signal content
   - Replace `TBD`, `TODO`, `N/A`, `pending`, or similar filler with a factual statement, an explicit `None.`, or a concrete recovery instruction.
