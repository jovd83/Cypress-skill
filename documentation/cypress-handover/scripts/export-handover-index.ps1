param(
  [string]$DocsRoot = "docs/tests",
  [ValidateSet("active", "archive", "all")]
  [string]$Location = "all",
  [ValidateSet("summary", "json", "csv")]
  [string]$Format = "summary",
  [string]$OutputPath = "",
  [switch]$IncludeHistory
)

$ErrorActionPreference = "Stop"

$auditScript = Join-Path $PSScriptRoot "audit-handovers.ps1"
$overviewScript = Join-Path $PSScriptRoot "overview-handovers.ps1"
$traceScript = Join-Path $PSScriptRoot "trace-handover-chain.ps1"
if (-not (Test-Path -LiteralPath $auditScript -PathType Leaf)) {
  throw "Audit script not found: $auditScript"
}
if (-not (Test-Path -LiteralPath $overviewScript -PathType Leaf)) {
  throw "Overview script not found: $overviewScript"
}
if ($IncludeHistory -and (-not (Test-Path -LiteralPath $traceScript -PathType Leaf))) {
  throw "Trace script not found: $traceScript"
}

function Get-ResolvedPath([string]$Path) {
  if ([string]::IsNullOrWhiteSpace($Path) -or ($Path -eq "No prior handover found")) {
    return $Path
  }
  $normalized = $Path -replace '\\', '/'
  try {
    $resolved = Resolve-Path -LiteralPath $normalized -ErrorAction SilentlyContinue
    if ($null -ne $resolved) {
      $resolvedPath = $resolved.Path -replace '\\', '/'
      Write-Host "DEBUG: Get-ResolvedPath resolved '$normalized' -> '$resolvedPath'"
      return $resolvedPath
    }
  } catch {}
  $fallback = ([System.IO.Path]::GetFullPath($normalized)) -replace '\\', '/'
  Write-Host "DEBUG: Get-ResolvedPath fallback '$normalized' -> '$fallback'"
  return $fallback
}

$resolvedDocsRoot = Get-ResolvedPath $DocsRoot
$audit = ((& $auditScript -DocsRoot $DocsRoot -Location $Location -Format json) | ConvertFrom-Json)
$latestScopes = @(((& $overviewScript -DocsRoot $DocsRoot -Location $Location -Format json) | ConvertFrom-Json))
$exportScopes = @(
  foreach ($scope in $latestScopes) {
    $history = @()
    if ($IncludeHistory) {
      $history = @(((& $traceScript -DocsRoot $DocsRoot -TaskLabel $scope.TaskLabel -Location $scope.Location -WorkspaceRoot $scope.WorkspaceRoot -Branch $scope.Branch -Format json) | ConvertFrom-Json))
    }

    [pscustomobject]@{
      Location = $scope.Location
      TaskLabel = $scope.TaskLabel
      Timestamp = $scope.Timestamp
      WorkspaceRoot = $scope.WorkspaceRoot
      Branch = $scope.Branch
      CurrentStatus = $scope.CurrentStatus
      PriorityRank = $scope.PriorityRank
      AgeDays = $scope.AgeDays
      IsStale = $scope.IsStale
      ChainDepth = $scope.ChainDepth
      NextAction = $scope.NextAction
      Blockers = $scope.Blockers
      Path = $scope.Path
      History = @($history)
    }
  }
)

$index = [pscustomobject]@{
  GeneratedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
  DocsRoot = $resolvedDocsRoot
  Location = $Location
  IncludedHistory = [bool]$IncludeHistory
  Summary = $audit.Summary
  LatestScopes = @($exportScopes)
  InvalidHandovers = @($audit.InvalidHandovers)
  DuplicateTaskLabelCollisions = @($audit.DuplicateTaskLabelCollisions)
  CrossLocationScopeCollisions = @($audit.CrossLocationScopeCollisions)
}

$csvRows = @(
  $exportScopes | ForEach-Object {
    [pscustomobject]@{
      Location = $_.Location
      TaskLabel = $_.TaskLabel
      Timestamp = $_.Timestamp
      WorkspaceRoot = $_.WorkspaceRoot
      Branch = $_.Branch
      CurrentStatus = $_.CurrentStatus
      PriorityRank = $_.PriorityRank
      AgeDays = $_.AgeDays
      IsStale = $_.IsStale
      ChainDepth = $_.ChainDepth
      HistoryCount = @($_.History).Count
      NextAction = $_.NextAction
      Blockers = $_.Blockers
      Path = $_.Path
    }
  }
)

if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
  $parent = Split-Path -Parent $OutputPath
  if (-not [string]::IsNullOrWhiteSpace($parent)) {
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
  }

  if ($Format -eq "csv") {
    $csvRows | ConvertTo-Csv -NoTypeInformation | Set-Content -LiteralPath $OutputPath -Encoding UTF8
  } else {
    $index | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
  }
}

switch ($Format) {
  "csv" {
    $csvRows | ConvertTo-Csv -NoTypeInformation
  }
  "json" {
    $index | ConvertTo-Json -Depth 8
  }
  default {
    Write-Host ("Generated: {0}" -f $index.GeneratedAt)
    Write-Host ("Docs root: {0}" -f $index.DocsRoot)
    Write-Host ("Location: {0}" -f $index.Location)
    Write-Host ("Included history: {0}" -f $index.IncludedHistory.ToString().ToLowerInvariant())
    Write-Host ("Latest scopes: {0}" -f (@($index.LatestScopes)).Count)
    Write-Host ("Invalid handovers: {0}" -f (@($index.InvalidHandovers)).Count)
    Write-Host ("Duplicate task-label collisions: {0}" -f (@($index.DuplicateTaskLabelCollisions)).Count)
    Write-Host ("Cross-location scope collisions: {0}" -f (@($index.CrossLocationScopeCollisions)).Count)
    if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
      Write-Host ("Output path: {0}" -f $OutputPath)
    }
  }
}
