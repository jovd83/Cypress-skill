param(
  [Parameter(Mandatory = $true)]
  [string]$OldTaskLabel,
  [Parameter(Mandatory = $true)]
  [string]$NewTaskLabel,
  [string]$DocsRoot = "docs/tests",
  [ValidateSet("active", "archive", "all")]
  [string]$Location = "active",
  [string]$WorkspaceRoot = "",
  [string]$Branch = ""
)

$ErrorActionPreference = "Stop"

function Get-HandoverMetadataValue([string]$Path, [string]$Label) {
  $pattern = '(?m)^- ' + [regex]::Escape($Label) + ':\s*(?<value>.+)$'
  $text = Get-Content -Raw -LiteralPath $Path
  $match = [regex]::Match($text, $pattern)
  if (-not $match.Success) {
    return ""
  }
  return $match.Groups["value"].Value.Trim()
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

function Parse-HandoverTimestamp([string]$Value) {
  if ([string]::IsNullOrWhiteSpace($Value)) {
    return [datetime]::MinValue
  }

  $parsed = [datetime]::MinValue
  $ok = [datetime]::TryParseExact(
    $Value.Trim(),
    "yyyy-MM-dd HH:mm",
    [System.Globalization.CultureInfo]::InvariantCulture,
    [System.Globalization.DateTimeStyles]::None,
    [ref]$parsed
  )

  if (-not $ok) {
    return [datetime]::MinValue
  }

  return $parsed
}

$validatorScript = Join-Path $PSScriptRoot "validate-handover.ps1"
if (-not (Test-Path -LiteralPath $validatorScript -PathType Leaf)) {
  throw "Validator script not found: $validatorScript"
}

$handoverDir = Join-Path $DocsRoot "handovers"
if (-not (Test-Path -LiteralPath $handoverDir -PathType Container)) {
  throw "Handover directory not found: $handoverDir"
}

$archiveDir = Join-Path $handoverDir "archive"
$inputs = New-Object 'System.Collections.Generic.List[object]'

if (($Location -eq "active") -or ($Location -eq "all")) {
  foreach ($file in (Get-ChildItem -LiteralPath $handoverDir -File -Filter "*_CypressSkillHandover.md" | Sort-Object FullName)) {
    $inputs.Add([pscustomobject]@{
      Location = "active"
      File = $file
    }) | Out-Null
  }
}

if (($Location -eq "archive") -or ($Location -eq "all")) {
  if (-not (Test-Path -LiteralPath $archiveDir -PathType Container)) {
    if ($Location -eq "archive") {
      throw "Archive directory not found: $archiveDir"
    }
  } else {
    foreach ($file in (Get-ChildItem -LiteralPath $archiveDir -File -Filter "*_CypressSkillHandover.md" | Sort-Object FullName)) {
      $inputs.Add([pscustomobject]@{
        Location = "archive"
        File = $file
      }) | Out-Null
    }
  }
}

if ($inputs.Count -eq 0) {
  if ($Location -eq "archive") {
    throw "No handovers found in $archiveDir"
  }
  throw "No handovers found for location '$Location' in $handoverDir"
}

$normalizedOldTaskLabel = Normalize-TaskLabel -Value $OldTaskLabel
if ([string]::IsNullOrWhiteSpace($normalizedOldTaskLabel)) {
  throw "Old task label must contain at least one lowercase letter or digit after normalization"
}

$normalizedNewTaskLabel = Normalize-TaskLabel -Value $NewTaskLabel
if ([string]::IsNullOrWhiteSpace($normalizedNewTaskLabel)) {
  throw "New task label must contain at least one lowercase letter or digit after normalization"
}
if ($normalizedNewTaskLabel.Length -gt 64) {
  throw "New task label must be 64 characters or fewer after normalization"
}
if ($normalizedOldTaskLabel -eq $normalizedNewTaskLabel) {
  throw "New task label must differ from the existing task label after normalization"
}

$normalizedWorkspaceRoot = Normalize-WorkspaceRoot -Value $WorkspaceRoot
$normalizedBranch = Normalize-Branch -Value $Branch

$entries = @(
  $inputs | ForEach-Object {
    $file = $_.File
    $taskLabel = Get-HandoverMetadataValue -Path $file.FullName -Label "Task label"
    $entryWorkspaceRoot = Get-HandoverMetadataValue -Path $file.FullName -Label "Workspace root"
    $entryBranch = Get-HandoverMetadataValue -Path $file.FullName -Label "Branch"
    $timestamp = Get-HandoverMetadataValue -Path $file.FullName -Label "Timestamp"
    $normalizedEntryWorkspaceRoot = Normalize-WorkspaceRoot -Value $entryWorkspaceRoot
    $normalizedEntryBranch = Normalize-Branch -Value $entryBranch
    [pscustomobject]@{
      Location = $_.Location
      Path = $file.FullName
      TaskLabel = $taskLabel
      NormalizedTaskLabel = Normalize-TaskLabel -Value $taskLabel
      Timestamp = $timestamp
      ParsedTimestamp = Parse-HandoverTimestamp -Value $timestamp
      WorkspaceRoot = $entryWorkspaceRoot
      NormalizedWorkspaceRoot = $normalizedEntryWorkspaceRoot
      Branch = $entryBranch
      NormalizedBranch = $normalizedEntryBranch
      ScopeIdentity = ("{0}|{1}" -f $normalizedEntryWorkspaceRoot, $normalizedEntryBranch)
      LocationScopeIdentity = ("{0}|{1}|{2}" -f $_.Location, $normalizedEntryWorkspaceRoot, $normalizedEntryBranch)
    }
  }
)

$matches = @($entries | Where-Object { $_.NormalizedTaskLabel -eq $normalizedOldTaskLabel })
if (-not [string]::IsNullOrWhiteSpace($normalizedWorkspaceRoot)) {
  $matches = @($matches | Where-Object { $_.NormalizedWorkspaceRoot -eq $normalizedWorkspaceRoot })
}
if (-not [string]::IsNullOrWhiteSpace($normalizedBranch)) {
  $matches = @($matches | Where-Object { $_.NormalizedBranch -eq $normalizedBranch })
}

if ($matches.Count -eq 0) {
  throw "No handovers found for task label '$OldTaskLabel' in location '$Location'"
}

$scopeMatches = @($matches | Group-Object LocationScopeIdentity)
if ($scopeMatches.Count -gt 1) {
  if ($Location -eq "all") {
    throw "Multiple handover scopes found for task label '$OldTaskLabel'. Rerun with -Location and/or -WorkspaceRoot and/or -Branch to target one scope."
  }
  throw "Multiple handover scopes found for task label '$OldTaskLabel'. Rerun with -WorkspaceRoot and/or -Branch to target one scope."
}

$targetLocationScopeIdentity = $scopeMatches[0].Name
$targetEntries = @($matches | Where-Object { $_.LocationScopeIdentity -eq $targetLocationScopeIdentity })
$targetScope = $targetEntries | Select-Object -First 1

$conflicts = @(
  $entries | Where-Object {
    ($_.LocationScopeIdentity -eq $targetLocationScopeIdentity) -and
    ($_.NormalizedTaskLabel -eq $normalizedNewTaskLabel) -and
    ($targetEntries.Path -notcontains $_.Path)
  }
)
if ($conflicts.Count -gt 0) {
  throw "New task label already exists in the target scope"
}

$originalContentByPath = @{}
try {
  foreach ($entry in $targetEntries) {
    $originalContentByPath[$entry.Path] = Get-Content -Raw -LiteralPath $entry.Path
  }

  foreach ($entry in $targetEntries) {
    $updatedText = [regex]::Replace(
      $originalContentByPath[$entry.Path],
      '(?m)^- Task label:\s*.+$',
      ("- Task label: {0}" -f $normalizedNewTaskLabel)
    )
    Set-Content -LiteralPath $entry.Path -Value $updatedText -Encoding UTF8
  }

  foreach ($entry in $targetEntries) {
    & $validatorScript -Path $entry.Path | Out-Null
  }
} catch {
  foreach ($path in $originalContentByPath.Keys) {
    Set-Content -LiteralPath $path -Value $originalContentByPath[$path] -Encoding UTF8
  }
  throw
}

$renamedEntries = $targetEntries | Sort-Object `
  @{ Expression = "ParsedTimestamp"; Descending = $false }, `
  @{ Expression = "Path"; Descending = $false }

Write-Host ("Renamed task label '{0}' to '{1}' in {2} handover(s)." -f $normalizedOldTaskLabel, $normalizedNewTaskLabel, $renamedEntries.Count)
Write-Host ("Location: {0}" -f $targetScope.Location)
Write-Host ("Scope: workspace={0} | branch={1}" -f $targetScope.WorkspaceRoot, $targetScope.Branch)
foreach ($entry in $renamedEntries) {
  Write-Host ("- {0}" -f $entry.Path)
}
