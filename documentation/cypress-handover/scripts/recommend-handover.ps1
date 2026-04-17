param(
  [string]$DocsRoot = "docs/tests",
  [ValidateSet("active", "archive", "all")]
  [string]$Location = "active",
  [string]$TaskLabel = "",
  [string]$WorkspaceRoot = "",
  [string]$Branch = "",
  [ValidateSet("summary", "json", "path", "task")]
  [string]$Format = "summary",
  [ValidateSet("scope", "task")]
  [string]$GroupBy = "scope",
  [ValidateSet("priority", "recent", "stale")]
  [string]$Sort = "priority",
  [ValidateSet("Completed", "In progress", "Blocked", "Awaiting approval")]
  [string[]]$Status = @(),
  [switch]$IncludeCompleted,
  [int]$StaleAfterDays = 3,
  [switch]$OnlyStale
)

$ErrorActionPreference = "Stop"

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

$overviewScript = Join-Path $PSScriptRoot "overview-handovers.ps1"
if (-not (Test-Path -LiteralPath $overviewScript -PathType Leaf)) {
  throw "Overview script not found: $overviewScript"
}

$parameters = @{
  DocsRoot = (Get-ResolvedPath $DocsRoot)
  Location = $Location
  Format = "json"
}

if (-not [string]::IsNullOrWhiteSpace($WorkspaceRoot)) {
  $parameters.WorkspaceRoot = $WorkspaceRoot
}

if (-not [string]::IsNullOrWhiteSpace($Branch)) {
  $parameters.Branch = $Branch
}

if ($Status.Count -gt 0) {
  $parameters.Status = $Status
} elseif (-not $IncludeCompleted) {
  $parameters.ExcludeCompleted = $true
}

if ($OnlyStale) {
  $parameters.OnlyStale = $true
}

$jsonText = (& $overviewScript @parameters | Out-String).Trim()
$items = @((ConvertFrom-Json -InputObject $jsonText))
if ($items.Count -eq 0) {
  throw "No candidate handovers found for the requested filters"
}

$top = $items | Select-Object -First 1
$reasonParts = @()

if ($top.CurrentStatus -eq "In progress") {
  $reasonParts += "already in progress"
} elseif ($top.CurrentStatus -eq "Awaiting approval") {
  $reasonParts += "awaiting a decision before more work starts"
} elseif ($top.CurrentStatus -eq "Blocked") {
  $reasonParts += "highest remaining priority after actionable tasks"
}

if ($top.Location -eq "archive") {
  $reasonParts += "selected from archive storage"
}

if ($top.IsStale) {
  $reasonParts += ("stale for {0} day(s)" -f $top.AgeDays)
}

$reason = ($reasonParts -join "; ")
if ([string]::IsNullOrWhiteSpace($reason)) {
  $reason = "top result from overview ranking"
}

$result = [pscustomobject]@{
  Location = $top.Location
  TaskLabel = $top.TaskLabel
  Timestamp = $top.Timestamp
  WorkspaceRoot = $top.WorkspaceRoot
  Branch = $top.Branch
  CurrentStatus = $top.CurrentStatus
  PriorityRank = $top.PriorityRank
  AgeDays = $top.AgeDays
  IsStale = $top.IsStale
  NextAction = $top.NextAction
  Blockers = $top.Blockers
  Path = $top.Path
  RecommendationReason = $reason
}

switch ($Format) {
  "path" {
    Write-Host $result.Path
  }
  "task" {
    Write-Host $result.TaskLabel
  }
  "json" {
    $result | ConvertTo-Json -Depth 3
  }
  default {
    Write-Host ("Recommended task: {0}" -f $result.TaskLabel)
    Write-Host ("Location: {0}" -f $result.Location)
    Write-Host ("Workspace root: {0}" -f $result.WorkspaceRoot)
    Write-Host ("Branch: {0}" -f $result.Branch)
    Write-Host ("Status: {0}" -f $result.CurrentStatus)
    Write-Host ("Reason: {0}" -f $result.RecommendationReason)
    Write-Host ("Next: {0}" -f $result.NextAction)
    Write-Host ("Blockers: {0}" -f $result.Blockers)
    Write-Host ("Path: {0}" -f $result.Path)
  }
}

