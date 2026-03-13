param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"
$rootAbs = (Resolve-Path -LiteralPath $Root).Path
$issues = @()

function Add-Issue([string]$Message) {
  $script:issues += $Message
}

$skillRoot = Join-Path $rootAbs "documentation/cypress-handover"
$requiredFiles = @(
  "SKILL.md",
  "agents/openai.yaml",
  "assets/handover-template.md",
  "references/blocked-handover-example.md",
  "references/multi-scope-conflicts.md",
  "scripts/audit-handovers.ps1",
  "scripts/archive-handover-scope.ps1",
  "scripts/complete-handover.ps1",
  "scripts/doctor-handover.ps1",
  "scripts/diff-handover-checkpoints.ps1",
  "scripts/export-handover-index.ps1",
  "scripts/find-handover.ps1",
  "scripts/overview-handovers.ps1",
  "scripts/repair-handover-links.ps1",
  "scripts/rename-task-label.ps1",
  "scripts/recommend-handover.ps1",
  "scripts/resolve-handover-location-conflict.ps1",
  "scripts/restore-handover-scope.ps1",
  "scripts/resume-handover.ps1",
  "scripts/trace-handover-chain.ps1",
  "scripts/new-handover.ps1",
  "scripts/validate-handover.ps1"
)

foreach ($relative in $requiredFiles) {
  $path = Join-Path $skillRoot $relative
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    Add-Issue ("missing required file: documentation/cypress-handover/{0}" -f $relative.Replace('\', '/'))
  }
}

$skillPath = Join-Path $skillRoot "SKILL.md"
if (Test-Path -LiteralPath $skillPath -PathType Leaf) {
  $skillText = Get-Content -Raw -LiteralPath $skillPath
  $requiredSections = @(
    "## 4. Prerequisites and Fallbacks",
    "## 5. Workflow",
    "## 6. Deterministic Assets and Commands",
    "## 7. Troubleshooting"
  )
  foreach ($section in $requiredSections) {
    if ($skillText -notmatch "(?m)^$([regex]::Escape($section))\s*$") {
      Add-Issue ("missing skill section: {0}" -f $section)
    }
  }

  $requiredMentions = @(
    "assets/handover-template.md",
    "references/blocked-handover-example.md",
    "references/multi-scope-conflicts.md",
    "scripts/audit-handovers.ps1",
    "scripts/archive-handover-scope.ps1",
    "scripts/complete-handover.ps1",
    "scripts/doctor-handover.ps1",
    "scripts/diff-handover-checkpoints.ps1",
    "scripts/export-handover-index.ps1",
    "scripts/find-handover.ps1",
    "scripts/overview-handovers.ps1",
    "scripts/repair-handover-links.ps1",
    "scripts/rename-task-label.ps1",
    "scripts/recommend-handover.ps1",
    "scripts/resolve-handover-location-conflict.ps1",
    "scripts/restore-handover-scope.ps1",
    "scripts/resume-handover.ps1",
    "scripts/trace-handover-chain.ps1",
    "scripts/new-handover.ps1",
    "scripts/validate-handover.ps1"
  )
  foreach ($mention in $requiredMentions) {
    if ($skillText -notmatch [regex]::Escape($mention)) {
      Add-Issue ("SKILL.md missing required reference: {0}" -f $mention)
    }
  }
}

$templatePath = Join-Path $skillRoot "assets/handover-template.md"
if (Test-Path -LiteralPath $templatePath -PathType Leaf) {
  $templateText = Get-Content -Raw -LiteralPath $templatePath
  $requiredPlaceholders = @(
    "{{TASK_SUMMARY}}",
    "{{CURRENT_STATUS}}",
    "{{WORKSPACE_ROOT}}",
    "{{BRANCH}}",
    "{{NEXT_ACTION}}",
    "{{SESSION_STATE}}",
    "{{HOW_TO_RESUME}}",
    "{{VALIDATION_AND_EVIDENCE}}"
  )
  foreach ($placeholder in $requiredPlaceholders) {
    if ($templateText -notmatch [regex]::Escape($placeholder)) {
      Add-Issue ("handover template missing placeholder: {0}" -f $placeholder)
    }
  }
}

$auditScriptPath = Join-Path $skillRoot "scripts/audit-handovers.ps1"
if (Test-Path -LiteralPath $auditScriptPath -PathType Leaf) {
  $auditText = Get-Content -Raw -LiteralPath $auditScriptPath
  if ($auditText -notmatch [regex]::Escape('ValidateSet("active", "archive", "all")')) {
    Add-Issue "audit-handovers.ps1 must support active, archive, and all audit locations"
  }
  if ($auditText -notmatch [regex]::Escape("validate-handover.ps1")) {
    Add-Issue "audit-handovers.ps1 must validate handovers by calling validate-handover.ps1"
  }
  if ($auditText -notmatch [regex]::Escape('ValidateSet("summary", "json")')) {
    Add-Issue "audit-handovers.ps1 must support summary and json outputs"
  }
  if ($auditText -notmatch [regex]::Escape('$FailOnIssues')) {
    Add-Issue "audit-handovers.ps1 must support failing when invalid handovers or collisions are detected"
  }
  if ($auditText -notmatch [regex]::Escape("Duplicate task labels across workspace/branch")) {
    Add-Issue "audit-handovers.ps1 must report duplicate task-label collisions across workspace and branch scopes"
  }
  if ($auditText -notmatch [regex]::Escape("Same scope exists in both active and archive")) {
    Add-Issue "audit-handovers.ps1 must report active/archive scope duplication"
  }
}

$archiveScriptPath = Join-Path $skillRoot "scripts/archive-handover-scope.ps1"
if (Test-Path -LiteralPath $archiveScriptPath -PathType Leaf) {
  $archiveText = Get-Content -Raw -LiteralPath $archiveScriptPath
  if ($archiveText -notmatch [regex]::Escape("validate-handover.ps1")) {
    Add-Issue "archive-handover-scope.ps1 must validate archived handovers by calling validate-handover.ps1"
  }
  if ($archiveText -notmatch [regex]::Escape('ValidateSet("summary", "json")')) {
    Add-Issue "archive-handover-scope.ps1 must support summary and json outputs"
  }
  if ($archiveText -notmatch [regex]::Escape('[string]$WorkspaceRoot')) {
    Add-Issue "archive-handover-scope.ps1 must support workspace-root filtering"
  }
  if ($archiveText -notmatch [regex]::Escape('[string]$Branch')) {
    Add-Issue "archive-handover-scope.ps1 must support branch filtering"
  }
  if ($archiveText -notmatch [regex]::Escape("Multiple handover scopes found for task label")) {
    Add-Issue "archive-handover-scope.ps1 must reject ambiguous archive scopes"
  }
  if ($archiveText -notmatch [regex]::Escape("Only completed handover scopes can be archived")) {
    Add-Issue "archive-handover-scope.ps1 must require completed scopes"
  }
}

$restoreScriptPath = Join-Path $skillRoot "scripts/restore-handover-scope.ps1"
if (Test-Path -LiteralPath $restoreScriptPath -PathType Leaf) {
  $restoreText = Get-Content -Raw -LiteralPath $restoreScriptPath
  if ($restoreText -notmatch [regex]::Escape("validate-handover.ps1")) {
    Add-Issue "restore-handover-scope.ps1 must validate restored handovers by calling validate-handover.ps1"
  }
  if ($restoreText -notmatch [regex]::Escape('ValidateSet("summary", "json")')) {
    Add-Issue "restore-handover-scope.ps1 must support summary and json outputs"
  }
  if ($restoreText -notmatch [regex]::Escape('[string]$WorkspaceRoot')) {
    Add-Issue "restore-handover-scope.ps1 must support workspace-root filtering"
  }
  if ($restoreText -notmatch [regex]::Escape('[string]$Branch')) {
    Add-Issue "restore-handover-scope.ps1 must support branch filtering"
  }
  if ($restoreText -notmatch [regex]::Escape("Multiple archived handover scopes found for task label")) {
    Add-Issue "restore-handover-scope.ps1 must reject ambiguous restore scopes"
  }
  if ($restoreText -notmatch [regex]::Escape("Archive directory not found")) {
    Add-Issue "restore-handover-scope.ps1 must report when the archive directory is missing"
  }
}

$completeScriptPath = Join-Path $skillRoot "scripts/complete-handover.ps1"
if (Test-Path -LiteralPath $completeScriptPath -PathType Leaf) {
  $completeText = Get-Content -Raw -LiteralPath $completeScriptPath
  if ($completeText -notmatch [regex]::Escape("validate-handover.ps1")) {
    Add-Issue "complete-handover.ps1 must validate the new completed handover by calling validate-handover.ps1"
  }
  if ($completeText -notmatch [regex]::Escape('[string]$ValidationNote')) {
    Add-Issue "complete-handover.ps1 must require a completion validation note"
  }
  if ($completeText -notmatch [regex]::Escape('[string]$WorkspaceRoot')) {
    Add-Issue "complete-handover.ps1 must support workspace-root filtering"
  }
  if ($completeText -notmatch [regex]::Escape('[string]$Branch')) {
    Add-Issue "complete-handover.ps1 must support branch filtering"
  }
  if ($completeText -notmatch [regex]::Escape("Multiple handover scopes found for task label")) {
    Add-Issue "complete-handover.ps1 must reject ambiguous completion scopes"
  }
  if ($completeText -notmatch [regex]::Escape("exists only in archive")) {
    Add-Issue "complete-handover.ps1 must report archived-only scopes and direct the user to restore first"
  }
  if ($completeText -notmatch [regex]::Escape("restore-handover-scope.ps1")) {
    Add-Issue "complete-handover.ps1 must reference restore-handover-scope.ps1 for archived-only scopes"
  }
  if ($completeText -notmatch [regex]::Escape("### Current status") -or $completeText -notmatch [regex]::Escape("Completed")) {
    Add-Issue "complete-handover.ps1 must mark the new handover as Completed"
  }
}

$doctorScriptPath = Join-Path $skillRoot "scripts/doctor-handover.ps1"
if (Test-Path -LiteralPath $doctorScriptPath -PathType Leaf) {
  $doctorText = Get-Content -Raw -LiteralPath $doctorScriptPath
  if ($doctorText -notmatch [regex]::Escape('[Parameter(Mandatory = $true)]')) {
    Add-Issue "doctor-handover.ps1 must require a task label"
  }
  if ($doctorText -notmatch [regex]::Escape('ValidateSet("active", "archive", "all")')) {
    Add-Issue "doctor-handover.ps1 must support active, archive, and all inspection locations"
  }
  if ($doctorText -notmatch [regex]::Escape('ValidateSet("summary", "json")')) {
    Add-Issue "doctor-handover.ps1 must support summary and json outputs"
  }
  if ($doctorText -notmatch [regex]::Escape("audit-handovers.ps1")) {
    Add-Issue "doctor-handover.ps1 must inspect audit-handovers.ps1 results"
  }
  if ($doctorText -notmatch [regex]::Escape("find-handover.ps1")) {
    Add-Issue "doctor-handover.ps1 must inspect the selected scope via find-handover.ps1"
  }
  if ($doctorText -notmatch [regex]::Escape("RecommendedAction")) {
    Add-Issue "doctor-handover.ps1 must return a recommended action"
  }
  if ($doctorText -notmatch [regex]::Escape("repair-handover-links.ps1")) {
    Add-Issue "doctor-handover.ps1 must direct link-related repair cases to repair-handover-links.ps1"
  }
  if ($doctorText -notmatch [regex]::Escape("resolve-handover-location-conflict.ps1")) {
    Add-Issue "doctor-handover.ps1 must direct active/archive duplicate scopes to resolve-handover-location-conflict.ps1"
  }
  if ($doctorText -notmatch [regex]::Escape("restore-handover-scope.ps1")) {
    Add-Issue "doctor-handover.ps1 must direct archived scopes to restore-handover-scope.ps1"
  }
  if ($doctorText -notmatch [regex]::Escape("archive-handover-scope.ps1")) {
    Add-Issue "doctor-handover.ps1 must direct completed active scopes to archive-handover-scope.ps1"
  }
  if ($doctorText -notmatch [regex]::Escape("complete-handover.ps1")) {
    Add-Issue "doctor-handover.ps1 must support completion recommendations when evidence is sufficient"
  }
}

$diffScriptPath = Join-Path $skillRoot "scripts/diff-handover-checkpoints.ps1"
if (Test-Path -LiteralPath $diffScriptPath -PathType Leaf) {
  $diffText = Get-Content -Raw -LiteralPath $diffScriptPath
  if ($diffText -notmatch [regex]::Escape('ValidateSet("active", "archive", "all")')) {
    Add-Issue "diff-handover-checkpoints.ps1 must support active, archive, and all history locations"
  }
  if ($diffText -notmatch [regex]::Escape('ValidateSet("summary", "json")')) {
    Add-Issue "diff-handover-checkpoints.ps1 must support summary and json outputs"
  }
  if ($diffText -notmatch [regex]::Escape('[string]$WorkspaceRoot')) {
    Add-Issue "diff-handover-checkpoints.ps1 must support workspace-root filtering"
  }
  if ($diffText -notmatch [regex]::Escape('[string]$Branch')) {
    Add-Issue "diff-handover-checkpoints.ps1 must support branch filtering"
  }
  if ($diffText -notmatch [regex]::Escape("Multiple handover scopes found for task label")) {
    Add-Issue "diff-handover-checkpoints.ps1 must reject ambiguous diff scopes"
  }
  if ($diffText -notmatch [regex]::Escape("No previous handover is available to compare")) {
    Add-Issue "diff-handover-checkpoints.ps1 must report when no previous handover exists"
  }
  if ($diffText -notmatch [regex]::Escape("LatestLocation")) {
    Add-Issue "diff-handover-checkpoints.ps1 must report the storage location of compared checkpoints"
  }
}

$exportScriptPath = Join-Path $skillRoot "scripts/export-handover-index.ps1"
if (Test-Path -LiteralPath $exportScriptPath -PathType Leaf) {
  $exportText = Get-Content -Raw -LiteralPath $exportScriptPath
  if ($exportText -notmatch [regex]::Escape('ValidateSet("active", "archive", "all")')) {
    Add-Issue "export-handover-index.ps1 must support active, archive, and all export locations"
  }
  if ($exportText -notmatch [regex]::Escape('ValidateSet("summary", "json", "csv")')) {
    Add-Issue "export-handover-index.ps1 must support summary, json, and csv outputs"
  }
  if ($exportText -notmatch [regex]::Escape('[string]$OutputPath')) {
    Add-Issue "export-handover-index.ps1 must support writing the export to disk"
  }
  if ($exportText -notmatch [regex]::Escape("audit-handovers.ps1")) {
    Add-Issue "export-handover-index.ps1 must build on audit-handovers.ps1"
  }
  if ($exportText -notmatch [regex]::Escape("overview-handovers.ps1")) {
    Add-Issue "export-handover-index.ps1 must build on overview-handovers.ps1"
  }
  if ($exportText -notmatch [regex]::Escape("LatestScopes")) {
    Add-Issue "export-handover-index.ps1 must export the latest scope index"
  }
  if ($exportText -notmatch [regex]::Escape("ConvertTo-Csv")) {
    Add-Issue "export-handover-index.ps1 must support CSV export for latest scope rows"
  }
  if ($exportText -notmatch [regex]::Escape('$IncludeHistory')) {
    Add-Issue "export-handover-index.ps1 must support optional scope-history export"
  }
  if ($exportText -notmatch [regex]::Escape("trace-handover-chain.ps1")) {
    Add-Issue "export-handover-index.ps1 must build scope histories by calling trace-handover-chain.ps1"
  }
}

$resumeScriptPath = Join-Path $skillRoot "scripts/resume-handover.ps1"
if (Test-Path -LiteralPath $resumeScriptPath -PathType Leaf) {
  $resumeText = Get-Content -Raw -LiteralPath $resumeScriptPath
  if ($resumeText -notmatch [regex]::Escape("validate-handover.ps1")) {
    Add-Issue "resume-handover.ps1 must validate the new resumed handover by calling validate-handover.ps1"
  }
  if ($resumeText -notmatch [regex]::Escape('[string]$ProgressNote')) {
    Add-Issue "resume-handover.ps1 must require a progress note"
  }
  if ($resumeText -notmatch [regex]::Escape('[string]$NextAction')) {
    Add-Issue "resume-handover.ps1 must require a next-action update"
  }
  if ($resumeText -notmatch [regex]::Escape('ValidateSet("In progress", "Blocked", "Awaiting approval")')) {
    Add-Issue "resume-handover.ps1 must support active-status transitions"
  }
  if ($resumeText -notmatch [regex]::Escape("Multiple handover scopes found for task label")) {
    Add-Issue "resume-handover.ps1 must reject ambiguous resume scopes"
  }
  if ($resumeText -notmatch [regex]::Escape("exists only in archive")) {
    Add-Issue "resume-handover.ps1 must report archived-only scopes and direct the user to restore first"
  }
  if ($resumeText -notmatch [regex]::Escape("restore-handover-scope.ps1")) {
    Add-Issue "resume-handover.ps1 must reference restore-handover-scope.ps1 for archived-only scopes"
  }
}

$newScriptPath = Join-Path $skillRoot "scripts/new-handover.ps1"
if (Test-Path -LiteralPath $newScriptPath -PathType Leaf) {
  $newScriptText = Get-Content -Raw -LiteralPath $newScriptPath
  if ($newScriptText -notmatch [regex]::Escape("assets/handover-template.md")) {
    Add-Issue "new-handover.ps1 must load assets/handover-template.md"
  }
  if ($newScriptText -notmatch [regex]::Escape("CypressSkillHandover.md")) {
    Add-Issue "new-handover.ps1 must use the CypressSkillHandover filename suffix"
  }
  if ($newScriptText -notmatch [regex]::Escape('Label "Task label"')) {
    Add-Issue "new-handover.ps1 must resolve previous handovers by Task label metadata"
  }
  if ($newScriptText -notmatch [regex]::Escape('Label "Workspace root"')) {
    Add-Issue "new-handover.ps1 must resolve previous handovers by Workspace root metadata"
  }
  if ($newScriptText -notmatch [regex]::Escape('Label "Branch"')) {
    Add-Issue "new-handover.ps1 must resolve previous handovers by Branch metadata"
  }
  if ($newScriptText -notmatch [regex]::Escape("Previous handover path does not exist")) {
    Add-Issue "new-handover.ps1 must validate manual previous-handover path existence"
  }
  if ($newScriptText -notmatch [regex]::Escape("Previous handover must have the same Task label")) {
    Add-Issue "new-handover.ps1 must validate manual previous-handover task-label scope"
  }
  if ($newScriptText -notmatch [regex]::Escape("Previous handover must have the same Workspace root")) {
    Add-Issue "new-handover.ps1 must validate manual previous-handover workspace-root scope"
  }
  if ($newScriptText -notmatch [regex]::Escape("Previous handover must have the same Branch")) {
    Add-Issue "new-handover.ps1 must validate manual previous-handover branch scope"
  }
  if ($newScriptText -notmatch [regex]::Escape("Previous handover must be inside the active handover directory")) {
    Add-Issue "new-handover.ps1 must reject manual previous-handover paths outside the active handover directory"
  }
  if ($newScriptText -notmatch [regex]::Escape("restore-handover-scope.ps1")) {
    Add-Issue "new-handover.ps1 must direct archived-only same-scope matches to restore-handover-scope.ps1"
  }
  if ($newScriptText -notmatch [regex]::Escape("exists only in archive")) {
    Add-Issue "new-handover.ps1 must report archived-only same-scope matches before creating a new active handover"
  }
  if ($newScriptText -notmatch [regex]::Escape("[^a-z0-9]+")) {
    Add-Issue "new-handover.ps1 must normalize task labels to lowercase hyphen-case"
  }
}

$validatorPath = Join-Path $skillRoot "scripts/validate-handover.ps1"
$validatorText = ""
if (Test-Path -LiteralPath $validatorPath -PathType Leaf) {
  $validatorText = Get-Content -Raw -LiteralPath $validatorPath
  if ($validatorText -notmatch [regex]::Escape("Previous handover path does not exist")) {
    Add-Issue "validate-handover.ps1 must enforce previous handover path existence"
  }
  if ($validatorText -notmatch [regex]::Escape("Previous handover must have the same Task label")) {
    Add-Issue "validate-handover.ps1 must enforce previous handover task-label matching"
  }
  if ($validatorText -notmatch [regex]::Escape("Previous handover chain contains a cycle")) {
    Add-Issue "validate-handover.ps1 must enforce previous handover cycle detection"
  }
  if ($validatorText -notmatch [regex]::Escape("Previous handover chain contains a missing ancestor link")) {
    Add-Issue "validate-handover.ps1 must enforce previous handover ancestor-link validation"
  }
  if ($validatorText -notmatch [regex]::Escape("Previous handover must have the same Workspace root")) {
    Add-Issue "validate-handover.ps1 must enforce previous handover workspace-root matching"
  }
  if ($validatorText -notmatch [regex]::Escape("Previous handover must have the same Branch")) {
    Add-Issue "validate-handover.ps1 must enforce previous handover branch matching"
  }
  if ($validatorText -notmatch [regex]::Escape("Previous handover chain must move backward in time")) {
    Add-Issue "validate-handover.ps1 must enforce previous handover timestamp ordering"
  }
  if ($validatorText -notmatch [regex]::Escape("Task label must use lowercase letters, digits, and hyphens only")) {
    Add-Issue "validate-handover.ps1 must enforce task-label format rules"
  }
  if ($validatorText -notmatch [regex]::Escape("Task label must already be normalized")) {
    Add-Issue "validate-handover.ps1 must enforce normalized task labels"
  }
}

$overviewScriptPath = Join-Path $skillRoot "scripts/overview-handovers.ps1"
if (Test-Path -LiteralPath $overviewScriptPath -PathType Leaf) {
  $overviewText = Get-Content -Raw -LiteralPath $overviewScriptPath
  if ($overviewText -notmatch [regex]::Escape('ValidateSet("active", "archive", "all")')) {
    Add-Issue "overview-handovers.ps1 must support active, archive, and all discovery locations"
  }
  if ($overviewText -notmatch [regex]::Escape('[string]$TaskLabel')) {
    Add-Issue "overview-handovers.ps1 must support task-label filtering"
  }
  if ($overviewText -notmatch [regex]::Escape('[string]$WorkspaceRoot')) {
    Add-Issue "overview-handovers.ps1 must support workspace-root filtering"
  }
  if ($overviewText -notmatch [regex]::Escape('[string]$Branch')) {
    Add-Issue "overview-handovers.ps1 must support branch filtering"
  }
  if ($overviewText -notmatch [regex]::Escape('ValidateSet("scope", "task")')) {
    Add-Issue "overview-handovers.ps1 must support scope and task grouping"
  }
  if ($overviewText -notmatch [regex]::Escape('ValidateSet("priority", "recent", "stale")')) {
    Add-Issue "overview-handovers.ps1 must support priority, recent, and stale sorting"
  }
  if ($overviewText -notmatch [regex]::Escape('[string[]]$Status')) {
    Add-Issue "overview-handovers.ps1 must support status filtering"
  }
  if ($overviewText -notmatch [regex]::Escape('$ExcludeCompleted')) {
    Add-Issue "overview-handovers.ps1 must support excluding completed tasks"
  }
  if ($overviewText -notmatch [regex]::Escape('$StaleAfterDays')) {
    Add-Issue "overview-handovers.ps1 must support stale-age thresholds"
  }
  if ($overviewText -notmatch [regex]::Escape('$OnlyStale')) {
    Add-Issue "overview-handovers.ps1 must support stale-only filtering"
  }
  if ($overviewText -notmatch [regex]::Escape("LocationScopeKey")) {
    Add-Issue "overview-handovers.ps1 must keep archive and active scopes distinct when grouping"
  }
}

$recommendScriptPath = Join-Path $skillRoot "scripts/recommend-handover.ps1"
if (Test-Path -LiteralPath $recommendScriptPath -PathType Leaf) {
  $recommendText = Get-Content -Raw -LiteralPath $recommendScriptPath
  if ($recommendText -notmatch [regex]::Escape("overview-handovers.ps1")) {
    Add-Issue "recommend-handover.ps1 must build on overview-handovers.ps1"
  }
  if ($recommendText -notmatch [regex]::Escape('[string]$WorkspaceRoot')) {
    Add-Issue "recommend-handover.ps1 must support workspace-root filtering"
  }
  if ($recommendText -notmatch [regex]::Escape('[string]$Branch')) {
    Add-Issue "recommend-handover.ps1 must support branch filtering"
  }
  if ($recommendText -notmatch [regex]::Escape('ValidateSet("active", "archive", "all")')) {
    Add-Issue "recommend-handover.ps1 must support active, archive, and all discovery locations"
  }
  if ($recommendText -notmatch [regex]::Escape('ValidateSet("scope", "task")')) {
    Add-Issue "recommend-handover.ps1 must support scope and task grouping"
  }
  if ($recommendText -notmatch [regex]::Escape('ValidateSet("summary", "json", "path", "task")')) {
    Add-Issue "recommend-handover.ps1 must support summary, json, path, and task outputs"
  }
  if ($recommendText -notmatch [regex]::Escape('$IncludeCompleted')) {
    Add-Issue "recommend-handover.ps1 must support including completed tasks when explicitly requested"
  }
  if ($recommendText -notmatch [regex]::Escape('Location = $top.Location')) {
    Add-Issue "recommend-handover.ps1 must carry location through in its result"
  }
}

$findScriptPath = Join-Path $skillRoot "scripts/find-handover.ps1"
if (Test-Path -LiteralPath $findScriptPath -PathType Leaf) {
  $findText = Get-Content -Raw -LiteralPath $findScriptPath
  if ($findText -notmatch [regex]::Escape('ValidateSet("active", "archive", "all")')) {
    Add-Issue "find-handover.ps1 must support active, archive, and all discovery locations"
  }
  if ($findText -notmatch [regex]::Escape('[string]$WorkspaceRoot')) {
    Add-Issue "find-handover.ps1 must support workspace-root filtering"
  }
  if ($findText -notmatch [regex]::Escape('[string]$Branch')) {
    Add-Issue "find-handover.ps1 must support branch filtering"
  }
  if ($findText -notmatch [regex]::Escape("Multiple handovers found for task label")) {
    Add-Issue "find-handover.ps1 must report ambiguous task labels across scopes"
  }
  if ($findText -notmatch [regex]::Escape("LocationScopeKey")) {
    Add-Issue "find-handover.ps1 must distinguish active and archived scopes"
  }
}

$traceScriptPath = Join-Path $skillRoot "scripts/trace-handover-chain.ps1"
if (Test-Path -LiteralPath $traceScriptPath -PathType Leaf) {
  $traceText = Get-Content -Raw -LiteralPath $traceScriptPath
  if ($traceText -notmatch [regex]::Escape('ValidateSet("active", "archive", "all")')) {
    Add-Issue "trace-handover-chain.ps1 must support active, archive, and all history locations"
  }
  if ($traceText -notmatch [regex]::Escape('ValidateSet("summary", "json", "paths")')) {
    Add-Issue "trace-handover-chain.ps1 must support summary, json, and paths outputs"
  }
  if ($traceText -notmatch [regex]::Escape('[string]$WorkspaceRoot')) {
    Add-Issue "trace-handover-chain.ps1 must support workspace-root filtering"
  }
  if ($traceText -notmatch [regex]::Escape('[string]$Branch')) {
    Add-Issue "trace-handover-chain.ps1 must support branch filtering"
  }
  if ($traceText -notmatch [regex]::Escape("Multiple handover scopes found for task label")) {
    Add-Issue "trace-handover-chain.ps1 must reject ambiguous chain traces across scopes"
  }
  if ($traceText -notmatch [regex]::Escape("Previous handover chain contains a cycle while tracing")) {
    Add-Issue "trace-handover-chain.ps1 must detect cycles while walking the chain"
  }
  if ($traceText -notmatch [regex]::Escape("Location = Get-HandoverLocation")) {
    Add-Issue "trace-handover-chain.ps1 must report entry locations while tracing"
  }
}

$renameScriptPath = Join-Path $skillRoot "scripts/rename-task-label.ps1"
if (Test-Path -LiteralPath $renameScriptPath -PathType Leaf) {
  $renameText = Get-Content -Raw -LiteralPath $renameScriptPath
  if ($renameText -notmatch [regex]::Escape("validate-handover.ps1")) {
    Add-Issue "rename-task-label.ps1 must validate rewritten handovers by calling validate-handover.ps1"
  }
  if ($renameText -notmatch [regex]::Escape('ValidateSet("active", "archive", "all")')) {
    Add-Issue "rename-task-label.ps1 must support active, archive, and all repair locations"
  }
  if ($renameText -notmatch [regex]::Escape('[string]$WorkspaceRoot')) {
    Add-Issue "rename-task-label.ps1 must support workspace-root filtering"
  }
  if ($renameText -notmatch [regex]::Escape('[string]$Branch')) {
    Add-Issue "rename-task-label.ps1 must support branch filtering"
  }
  if ($renameText -notmatch [regex]::Escape("Multiple handover scopes found for task label")) {
    Add-Issue "rename-task-label.ps1 must reject ambiguous task-label scopes"
  }
  if ($renameText -notmatch [regex]::Escape("New task label already exists in the target scope")) {
    Add-Issue "rename-task-label.ps1 must reject collisions with an existing task label in the target scope"
  }
  if ($renameText -notmatch [regex]::Escape("LocationScopeIdentity")) {
    Add-Issue "rename-task-label.ps1 must distinguish active and archived repair scopes"
  }
}

$repairScriptPath = Join-Path $skillRoot "scripts/repair-handover-links.ps1"
if (Test-Path -LiteralPath $repairScriptPath -PathType Leaf) {
  $repairText = Get-Content -Raw -LiteralPath $repairScriptPath
  if ($repairText -notmatch [regex]::Escape('ValidateSet("active", "archive", "all")')) {
    Add-Issue "repair-handover-links.ps1 must support active, archive, and all repair locations"
  }
  if ($repairText -notmatch [regex]::Escape('ValidateSet("summary", "json")')) {
    Add-Issue "repair-handover-links.ps1 must support summary and json outputs"
  }
  if ($repairText -notmatch [regex]::Escape("validate-handover.ps1")) {
    Add-Issue "repair-handover-links.ps1 must validate repaired handovers by calling validate-handover.ps1"
  }
  if ($repairText -notmatch [regex]::Escape('[string]$WorkspaceRoot')) {
    Add-Issue "repair-handover-links.ps1 must support workspace-root filtering"
  }
  if ($repairText -notmatch [regex]::Escape('[string]$Branch')) {
    Add-Issue "repair-handover-links.ps1 must support branch filtering"
  }
  if ($repairText -notmatch [regex]::Escape('Label "Previous handover"')) {
    Add-Issue "repair-handover-links.ps1 must rebuild Previous handover metadata lines"
  }
  if ($repairText -notmatch [regex]::Escape("RewrittenFiles")) {
    Add-Issue "repair-handover-links.ps1 must report how many files were rewritten"
  }
}

$resolveScriptPath = Join-Path $skillRoot "scripts/resolve-handover-location-conflict.ps1"
if (Test-Path -LiteralPath $resolveScriptPath -PathType Leaf) {
  $resolveText = Get-Content -Raw -LiteralPath $resolveScriptPath
  if ($resolveText -notmatch [regex]::Escape('[Parameter(Mandatory = $true)]')) {
    Add-Issue "resolve-handover-location-conflict.ps1 must require a task label"
  }
  if ($resolveText -notmatch [regex]::Escape('ValidateSet("active", "archive")')) {
    Add-Issue "resolve-handover-location-conflict.ps1 must support choosing the kept location"
  }
  if ($resolveText -notmatch [regex]::Escape('ValidateSet("summary", "json")')) {
    Add-Issue "resolve-handover-location-conflict.ps1 must support summary and json outputs"
  }
  if ($resolveText -notmatch [regex]::Escape("audit-handovers.ps1")) {
    Add-Issue "resolve-handover-location-conflict.ps1 must inspect active/archive collisions via audit-handovers.ps1"
  }
  if ($resolveText -notmatch [regex]::Escape("validate-handover.ps1")) {
    Add-Issue "resolve-handover-location-conflict.ps1 must validate the kept location before removing duplicates"
  }
  if ($resolveText -notmatch [regex]::Escape("Multiple active/archive location conflicts found for task label")) {
    Add-Issue "resolve-handover-location-conflict.ps1 must reject ambiguous duplicate scopes"
  }
}

$examplePath = Join-Path $skillRoot "references/blocked-handover-example.md"
if ((Test-Path -LiteralPath $validatorPath -PathType Leaf) -and (Test-Path -LiteralPath $examplePath -PathType Leaf)) {
  try {
    & $validatorPath -Path $examplePath | Out-Null
  } catch {
    Add-Issue ("blocked handover example failed validation: {0}" -f $_.Exception.Message)
  }
}

if ($issues.Count -gt 0) {
  Write-Host "check-cypress-handover-package failed with $($issues.Count) issue(s)"
  $issues | ForEach-Object {
    Write-Host ("- {0}" -f $_)
  }
  throw "check-cypress-handover-package failed"
}

Write-Host "check-cypress-handover-package: OK"
