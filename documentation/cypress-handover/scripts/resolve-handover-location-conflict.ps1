param(
  [Parameter(Mandatory = $true)]
  [string]$TaskLabel,
  [string]$DocsRoot = "docs/tests",
  [string]$WorkspaceRoot = "",
  [string]$Branch = "",
  [ValidateSet("active", "archive")]
  [string]$KeepLocation = "active",
  [ValidateSet("summary", "json")]
  [string]$Format = "summary"
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

$auditScript = Join-Path $PSScriptRoot "audit-handovers.ps1"
$validatorScript = Join-Path $PSScriptRoot "validate-handover.ps1"
if (-not (Test-Path -LiteralPath $auditScript -PathType Leaf)) {
  throw "Audit script not found: $auditScript"
}
if (-not (Test-Path -LiteralPath $validatorScript -PathType Leaf)) {
  throw "Validator script not found: $validatorScript"
}

$normalizedTaskLabel = Normalize-TaskLabel -Value $TaskLabel
if ([string]::IsNullOrWhiteSpace($normalizedTaskLabel)) {
  throw "Task label must contain at least one lowercase letter or digit after normalization"
}

$normalizedWorkspaceRoot = Normalize-WorkspaceRoot -Value $WorkspaceRoot
$normalizedBranch = Normalize-Branch -Value $Branch

$resolvedDocsRoot = Get-ResolvedPath $DocsRoot
$audit = ((& $auditScript -DocsRoot $resolvedDocsRoot -Location all -Format json) | ConvertFrom-Json)
$matchingCollisions = @(
  $audit.CrossLocationScopeCollisions |
    Where-Object {
      (Normalize-TaskLabel -Value $_.TaskLabel) -eq $normalizedTaskLabel -and
      ([string]::IsNullOrWhiteSpace($normalizedWorkspaceRoot) -or ((Normalize-WorkspaceRoot -Value $_.WorkspaceRoot) -eq $normalizedWorkspaceRoot)) -and
      ([string]::IsNullOrWhiteSpace($normalizedBranch) -or ((Normalize-Branch -Value $_.Branch) -eq $normalizedBranch))
    }
)

if ($matchingCollisions.Count -eq 0) {
  throw "No active/archive location conflict found for task label '$TaskLabel'"
}

if (($matchingCollisions.Count -gt 1) -and [string]::IsNullOrWhiteSpace($normalizedWorkspaceRoot) -and [string]::IsNullOrWhiteSpace($normalizedBranch)) {
  throw "Multiple active/archive location conflicts found for task label '$TaskLabel'. Rerun with -WorkspaceRoot and/or -Branch to resolve one scope."
}

$collision = $matchingCollisions | Select-Object -First 1
$entries = @($collision.Entries)
$keptEntries = @($entries | Where-Object { $_.Location -eq $KeepLocation })
$removedEntries = @($entries | Where-Object { $_.Location -ne $KeepLocation })

if ($keptEntries.Count -eq 0) {
  throw "No $KeepLocation entries found for the conflicting scope"
}
if ($removedEntries.Count -eq 0) {
  throw "No removable entries found for the conflicting scope"
}

foreach ($entry in $keptEntries) {
  & $validatorScript -Path $entry.Path | Out-Null
}

foreach ($entry in $removedEntries) {
  if (Test-Path -LiteralPath $entry.Path -PathType Leaf) {
    Remove-Item -LiteralPath $entry.Path -Force
  }
}

$result = [pscustomobject]@{
  TaskLabel = $collision.TaskLabel
  WorkspaceRoot = $collision.WorkspaceRoot
  Branch = $collision.Branch
  KeptLocation = $KeepLocation
  RemovedLocation = if ($KeepLocation -eq "active") { "archive" } else { "active" }
  KeptPaths = @($keptEntries | ForEach-Object { $_.Path })
  RemovedPaths = @($removedEntries | ForEach-Object { $_.Path })
}

switch ($Format) {
  "json" {
    $result | ConvertTo-Json -Depth 4
  }
  default {
    Write-Host ("Resolved location conflict for task: {0}" -f $result.TaskLabel)
    Write-Host ("Workspace: {0}" -f $result.WorkspaceRoot)
    Write-Host ("Branch: {0}" -f $result.Branch)
    Write-Host ("Kept location: {0}" -f $result.KeptLocation)
    Write-Host ("Removed location: {0}" -f $result.RemovedLocation)
    foreach ($path in $result.RemovedPaths) {
      Write-Host ("- Removed: {0}" -f $path)
    }
  }
}
