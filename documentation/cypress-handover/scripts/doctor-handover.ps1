param(
  [Parameter(Mandatory = $true)]
  [string]$TaskLabel,
  [string]$DocsRoot = "docs/tests",
  [ValidateSet("active", "archive", "all")]
  [string]$Location = "all",
  [string]$WorkspaceRoot = "",
  [string]$Branch = "",
  [ValidateSet("summary", "json")]
  [string]$Format = "summary"
)

$ErrorActionPreference = "Stop"

function Normalize-TaskLabel([string]$Value) {
  if ($null -eq $Value) { return "" }
  $normalized = $Value.Trim().ToLowerInvariant()
  $normalized = $normalized -replace '[^a-z0-9]+', '-'
  $normalized = $normalized -replace '-{2,}', '-'
  return $normalized.Trim('-')
}

function Normalize-WorkspaceRoot([string]$Value) {
  if ($null -eq $Value) { return "" }
  $normalized = (($Value -replace '\\', '/').Trim())
  return $normalized.TrimEnd('/').ToLowerInvariant()
}

function Normalize-Branch([string]$Value) {
  if ($null -eq $Value) { return "" }
  return (($Value -replace '\s+', ' ').Trim()).ToLowerInvariant()
}

function Normalize-Status([string]$Value) {
  if ($null -eq $Value) { return "" }
  return (($Value -replace '\s+', ' ').Trim()).ToLowerInvariant()
}

function Is-EmptySignal([string]$Value) {
  $normalized = Normalize-Branch -Value $Value
  return ([string]::IsNullOrWhiteSpace($normalized) -or ($normalized -eq "none.") -or ($normalized -eq "none"))
}

function Is-UsableValidation([string]$Value) {
  $normalized = Normalize-Branch -Value $Value
  if ([string]::IsNullOrWhiteSpace($normalized)) {
    return $false
  }
  return ($normalized -notlike 'not run*') -and ($normalized -notlike 'unknown*')
}

function Get-ResolvedPath([string]$Path) {
  if ([string]::IsNullOrWhiteSpace($Path) -or ($Path -eq "No prior handover found")) {
    return $Path
  }
  $normalized = $Path -replace '\\', '/'
  try {
    $resolved = Resolve-Path -LiteralPath $normalized -ErrorAction SilentlyContinue
    if ($null -ne $resolved) {
      return $resolved.Path
    }
  } catch {}
  return [System.IO.Path]::GetFullPath($normalized)
}

function Get-ScopedCommandSuffix([pscustomobject]$Scope) {
  $parts = @(
    ('-TaskLabel "{0}"' -f $Scope.TaskLabel)
  )
  if (-not [string]::IsNullOrWhiteSpace($Scope.WorkspaceRoot)) {
    $parts += ('-WorkspaceRoot "{0}"' -f $Scope.WorkspaceRoot)
  }
  if (-not [string]::IsNullOrWhiteSpace($Scope.Branch)) {
    $parts += ('-Branch "{0}"' -f $Scope.Branch)
  }
  $parts += ('-DocsRoot "{0}"' -f $Scope.DocsRoot)
  return ($parts -join ' ')
}

$auditScript = Join-Path $PSScriptRoot "audit-handovers.ps1"
$findScript = Join-Path $PSScriptRoot "find-handover.ps1"
$resolveConflictScript = Join-Path $PSScriptRoot "resolve-handover-location-conflict.ps1"
if (-not (Test-Path -LiteralPath $auditScript -PathType Leaf)) {
  throw "Audit script not found: $auditScript"
}
if (-not (Test-Path -LiteralPath $findScript -PathType Leaf)) {
  throw "Find script not found: $findScript"
}
if (-not (Test-Path -LiteralPath $resolveConflictScript -PathType Leaf)) {
  throw "Location-conflict resolver not found: $resolveConflictScript"
}

$resolvedDocsRoot = Get-ResolvedPath $DocsRoot
$normalizedTaskLabel = Normalize-TaskLabel -Value $TaskLabel
$normalizedWorkspaceRoot = Normalize-WorkspaceRoot -Value $WorkspaceRoot
$normalizedBranch = Normalize-Branch -Value $Branch

$findParams = @{
  DocsRoot = $resolvedDocsRoot
  Location = $Location
  Format = "json"
}
if (-not [string]::IsNullOrWhiteSpace($TaskLabel)) { $findParams.TaskLabel = $TaskLabel }
if (-not [string]::IsNullOrWhiteSpace($WorkspaceRoot)) { $findParams.WorkspaceRoot = $WorkspaceRoot }
if (-not [string]::IsNullOrWhiteSpace($Branch)) { $findParams.Branch = $Branch }

$found = ((& $findScript @findParams | Out-String).Trim() | ConvertFrom-Json)
$scope = $null
if ($found -is [array]) {
  $scope = $found | Select-Object -First 1
} else {
  $scope = $found
}

if ($null -eq $scope -or [string]::IsNullOrWhiteSpace($scope.TaskLabel)) {
  throw "No handover found matching label '$TaskLabel' at location '$Location'"
}

$audit = ((& $auditScript -DocsRoot $DocsRoot -Location $Location -Format json) | ConvertFrom-Json)
$matchingCrossLocationCollisions = @(
  $audit.CrossLocationScopeCollisions |
    Where-Object {
      (Normalize-TaskLabel -Value $_.TaskLabel) -eq $normalizedTaskLabel -and
      ([string]::IsNullOrWhiteSpace($normalizedWorkspaceRoot) -or ((Normalize-WorkspaceRoot -Value $_.WorkspaceRoot) -eq $normalizedWorkspaceRoot)) -and
      ([string]::IsNullOrWhiteSpace($normalizedBranch) -or ((Normalize-Branch -Value $_.Branch) -eq $normalizedBranch))
    }
)

$matchingInvalids = @(
  $audit.InvalidHandovers |
    Where-Object {
      (Normalize-TaskLabel -Value $_.TaskLabel) -eq $normalizedTaskLabel -and
      (Normalize-WorkspaceRoot -Value $_.WorkspaceRoot) -eq (Normalize-WorkspaceRoot -Value $scope.WorkspaceRoot) -and
      (Normalize-Branch -Value $_.Branch) -eq (Normalize-Branch -Value $scope.Branch)
    }
)

$status = Normalize-Status -Value $scope.CurrentStatus
$recommendedAction = "resume"
$reason = "Active work can continue from the latest handover."
$command = 'powershell -NoProfile -File .\documentation\cypress-handover\scripts\resume-handover.ps1 {0} -ProgressNote "<progress update>" -NextAction "<next action>"' -f (Get-ScopedCommandSuffix -Scope ([pscustomobject]@{
  TaskLabel = $scope.TaskLabel
  WorkspaceRoot = $scope.WorkspaceRoot
  Branch = $scope.Branch
  DocsRoot = $DocsRoot
}))
$alternativeActions = New-Object 'System.Collections.Generic.List[string]'

if ($matchingCrossLocationCollisions.Count -gt 0) {
  $recommendedAction = "repair"
  $reason = "The same scope exists in both active and archive storage and must be reconciled before more lifecycle changes."
  $command = 'powershell -NoProfile -File .\documentation\cypress-handover\scripts\resolve-handover-location-conflict.ps1 {0} -KeepLocation {1}' -f (Get-ScopedCommandSuffix -Scope ([pscustomobject]@{
    TaskLabel = $scope.TaskLabel
    WorkspaceRoot = $scope.WorkspaceRoot
    Branch = $scope.Branch
    DocsRoot = $DocsRoot
  })), $scope.Location
} elseif ($matchingInvalids.Count -gt 0) {
  $validationMessages = @($matchingInvalids | Select-Object -ExpandProperty ValidationError)
  $linkRepairable = $false
  foreach ($validationMessage in $validationMessages) {
    if (($validationMessage -like '*Previous handover path does not exist*') -or ($validationMessage -like '*missing ancestor link*') -or ($validationMessage -like '*contains a cycle*') -or ($validationMessage -like '*move backward in time*')) {
      $linkRepairable = $true
      break
    }
  }

  if ($linkRepairable) {
    $recommendedAction = "repair"
    $reason = "The selected scope has invalid previous-handover links that can be rebuilt from metadata and timestamp order."
    $command = 'powershell -NoProfile -File .\documentation\cypress-handover\scripts\repair-handover-links.ps1 {0} -Location {1}' -f (Get-ScopedCommandSuffix -Scope ([pscustomobject]@{
      TaskLabel = $scope.TaskLabel
      WorkspaceRoot = $scope.WorkspaceRoot
      Branch = $scope.Branch
      DocsRoot = $DocsRoot
    })), $scope.Location
  } else {
    $recommendedAction = "repair"
    $reason = "The selected scope is invalid, but the failure is not a simple link-rewrite case. Inspect the validator error before resuming."
    $command = 'powershell -NoProfile -File .\documentation\cypress-handover\scripts\validate-handover.ps1 -Path "{0}"' -f $scope.Path
  }
} elseif ($scope.Location -eq "archive") {
  $recommendedAction = "restore"
  $reason = "The selected scope exists only in archive and must be restored before active work can continue."
  $command = 'powershell -NoProfile -File .\documentation\cypress-handover\scripts\restore-handover-scope.ps1 {0}' -f (Get-ScopedCommandSuffix -Scope ([pscustomobject]@{
    TaskLabel = $scope.TaskLabel
    WorkspaceRoot = $scope.WorkspaceRoot
    Branch = $scope.Branch
    DocsRoot = $DocsRoot
  }))
} elseif ($status -eq "completed") {
  $recommendedAction = "archive"
  $reason = "The latest active handover is already completed, so the next lifecycle step is to archive the scope out of the active queue."
  $command = 'powershell -NoProfile -File .\documentation\cypress-handover\scripts\archive-handover-scope.ps1 {0}' -f (Get-ScopedCommandSuffix -Scope ([pscustomobject]@{
    TaskLabel = $scope.TaskLabel
    WorkspaceRoot = $scope.WorkspaceRoot
    Branch = $scope.Branch
    DocsRoot = $DocsRoot
  }))
} elseif (($status -eq "in progress") -and (Is-EmptySignal -Value $scope.RemainingWork) -and (Is-EmptySignal -Value $scope.Blockers) -and (Is-UsableValidation -Value $scope.Validation)) {
  $recommendedAction = "complete"
  $reason = "The latest active handover has no remaining work, no blockers, and usable validation evidence, so it is ready for a completion checkpoint."
  $command = 'powershell -NoProfile -File .\documentation\cypress-handover\scripts\complete-handover.ps1 {0} -ValidationNote "<final validation note>"' -f (Get-ScopedCommandSuffix -Scope ([pscustomobject]@{
    TaskLabel = $scope.TaskLabel
    WorkspaceRoot = $scope.WorkspaceRoot
    Branch = $scope.Branch
    DocsRoot = $DocsRoot
  }))
} elseif (($status -eq "blocked") -or ($status -eq "awaiting approval") -or ($status -eq "in progress")) {
  $recommendedAction = "resume"
  $reason = "The latest active handover is still open, so the next deterministic step is to create a resumed checkpoint once work continues."
}

if (($scope.Location -eq "active") -and ($status -ne "completed")) {
  $alternativeActions.Add("resume") | Out-Null
  if (($status -eq "in progress") -and (Is-EmptySignal -Value $scope.RemainingWork) -and (Is-EmptySignal -Value $scope.Blockers) -and (Is-UsableValidation -Value $scope.Validation)) {
    $alternativeActions.Add("complete") | Out-Null
  }
}
if ($scope.Location -eq "archive") {
  $alternativeActions.Add("restore") | Out-Null
}
if ($status -eq "completed" -and $scope.Location -eq "active") {
  $alternativeActions.Add("archive") | Out-Null
}
if ($matchingInvalids.Count -gt 0) {
  $alternativeActions.Add("repair") | Out-Null
}
if ($matchingCrossLocationCollisions.Count -gt 0) {
  $alternativeActions.Add("repair") | Out-Null
}

$result = [pscustomobject]@{
  TaskLabel = $scope.TaskLabel
  DocsRoot = $resolvedDocsRoot
  Location = $scope.Location
  WorkspaceRoot = $scope.WorkspaceRoot
  Branch = $scope.Branch
  CurrentStatus = $scope.CurrentStatus
  RecommendedAction = $recommendedAction
  Reason = $reason
  Command = $command
  AvailableActions = @($alternativeActions | Select-Object -Unique)
  RemainingWork = $scope.RemainingWork
  Blockers = $scope.Blockers
  Validation = $scope.Validation
  Path = $scope.Path
  InvalidMatchCount = $matchingInvalids.Count
  CrossLocationCollisionCount = $matchingCrossLocationCollisions.Count
}

switch ($Format) {
  "json" {
    $result | ConvertTo-Json -Depth 5
  }
  default {
    Write-Host ("Task label: {0}" -f $result.TaskLabel)
    Write-Host ("Location: {0}" -f $result.Location)
    Write-Host ("Workspace root: {0}" -f $result.WorkspaceRoot)
    Write-Host ("Branch: {0}" -f $result.Branch)
    Write-Host ("Current status: {0}" -f $result.CurrentStatus)
    Write-Host ("Recommended action: {0}" -f $result.RecommendedAction)
    Write-Host ("Reason: {0}" -f $result.Reason)
    Write-Host ("Command: {0}" -f $result.Command)
    Write-Host ("Available actions: {0}" -f (($result.AvailableActions -join ", ")))
    Write-Host ("Remaining work: {0}" -f $result.RemainingWork)
    Write-Host ("Blockers: {0}" -f $result.Blockers)
    Write-Host ("Validation: {0}" -f $result.Validation)
    Write-Host ("Path: {0}" -f $result.Path)
  }
}

