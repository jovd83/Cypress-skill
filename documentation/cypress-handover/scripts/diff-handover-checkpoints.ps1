param(
  [string]$TaskLabel = "",
  [string]$DocsRoot = "docs/tests",
  [ValidateSet("active", "archive", "all")]
  [string]$Location = "active",
  [string]$WorkspaceRoot = "",
  [string]$Branch = "",
  [ValidateSet("summary", "json")]
  [string]$Format = "summary"
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

function Get-SectionBody([string]$Markdown, [string]$Heading) {
  $pattern = '(?sm)^' + [regex]::Escape($Heading) + '\s*(?<body>.*?)(?=^### |\z)'
  $match = [regex]::Match($Markdown, $pattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)
  if (-not $match.Success) {
    return ""
  }
  return ($match.Groups["body"].Value -replace '\s+', ' ').Trim()
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

function Get-HandoverLocation([string]$Path, [string]$ArchiveDir) {
  $normalizedPath = (($Path -replace '\\', '/').Trim()).TrimEnd('/').ToLowerInvariant()
  $normalizedArchiveDir = (($ArchiveDir -replace '\\', '/').Trim()).TrimEnd('/').ToLowerInvariant()
  if ($normalizedPath.StartsWith($normalizedArchiveDir + "/")) {
    return "archive"
  }
  return "active"
}

function Get-HandoverRecord([string]$Path) {
  $text = Get-Content -Raw -LiteralPath $Path
  return [pscustomobject]@{
    Path = $Path
    Timestamp = Get-HandoverMetadataValue -Path $Path -Label "Timestamp"
    TaskLabel = Get-HandoverMetadataValue -Path $Path -Label "Task label"
    WorkspaceRoot = Get-HandoverMetadataValue -Path $Path -Label "Workspace root"
    Branch = Get-HandoverMetadataValue -Path $Path -Label "Branch"
    PreviousHandover = Get-HandoverMetadataValue -Path $Path -Label "Previous handover"
    CurrentStatus = Get-SectionBody -Markdown $text -Heading "### Current status"
    WhatWasDone = Get-SectionBody -Markdown $text -Heading "### What was done"
    InProgress = Get-SectionBody -Markdown $text -Heading "### In progress"
    RemainingWork = Get-SectionBody -Markdown $text -Heading "### Remaining work"
    Blockers = Get-SectionBody -Markdown $text -Heading "### Blockers and open questions"
    NextAction = Get-SectionBody -Markdown $text -Heading "### Next action"
    SessionState = Get-SectionBody -Markdown $text -Heading "### Session state"
    HowToResume = Get-SectionBody -Markdown $text -Heading "### How to resume"
    Validation = Get-SectionBody -Markdown $text -Heading "### Validation and evidence"
    FilesAddedModified = Get-SectionBody -Markdown $text -Heading "### Files added/modified"
  }
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

$normalizedTaskLabel = Normalize-TaskLabel -Value $TaskLabel
$normalizedWorkspaceRoot = Normalize-WorkspaceRoot -Value $WorkspaceRoot
$normalizedBranch = Normalize-Branch -Value $Branch

$candidates = @(
  $inputs | ForEach-Object {
    $file = $_.File
    $candidateTaskLabel = Get-HandoverMetadataValue -Path $file.FullName -Label "Task label"
    $candidateWorkspaceRoot = Get-HandoverMetadataValue -Path $file.FullName -Label "Workspace root"
    $candidateBranch = Get-HandoverMetadataValue -Path $file.FullName -Label "Branch"
    $candidateTimestamp = Get-HandoverMetadataValue -Path $file.FullName -Label "Timestamp"
    $scopeKey = ("{0}|{1}|{2}" -f (Normalize-TaskLabel -Value $candidateTaskLabel), (Normalize-WorkspaceRoot -Value $candidateWorkspaceRoot), (Normalize-Branch -Value $candidateBranch))
    [pscustomobject]@{
      Location = $_.Location
      Path = $file.FullName
      Timestamp = $candidateTimestamp
      ParsedTimestamp = Parse-HandoverTimestamp -Value $candidateTimestamp
      TaskLabel = $candidateTaskLabel
      NormalizedTaskLabel = Normalize-TaskLabel -Value $candidateTaskLabel
      WorkspaceRoot = $candidateWorkspaceRoot
      NormalizedWorkspaceRoot = Normalize-WorkspaceRoot -Value $candidateWorkspaceRoot
      Branch = $candidateBranch
      NormalizedBranch = Normalize-Branch -Value $candidateBranch
      ScopeKey = $scopeKey
      LocationScopeKey = ("{0}|{1}" -f $_.Location, $scopeKey)
    }
  } |
  Sort-Object `
    @{ Expression = "ParsedTimestamp"; Descending = $true }, `
    @{ Expression = "Path"; Descending = $true }
)

if (-not [string]::IsNullOrWhiteSpace($normalizedTaskLabel)) {
  $candidates = @($candidates | Where-Object { $_.NormalizedTaskLabel -eq $normalizedTaskLabel })
}
if (-not [string]::IsNullOrWhiteSpace($normalizedWorkspaceRoot)) {
  $candidates = @($candidates | Where-Object { $_.NormalizedWorkspaceRoot -eq $normalizedWorkspaceRoot })
}
if (-not [string]::IsNullOrWhiteSpace($normalizedBranch)) {
  $candidates = @($candidates | Where-Object { $_.NormalizedBranch -eq $normalizedBranch })
}

if ($candidates.Count -eq 0) {
  if ([string]::IsNullOrWhiteSpace($TaskLabel)) {
    throw "No handovers found for location '$Location' in $handoverDir"
  }
  throw "No handover found for task label '$TaskLabel' in location '$Location'"
}

$scopeCount = @($candidates | Group-Object LocationScopeKey).Count
if (($scopeCount -gt 1) -and (-not [string]::IsNullOrWhiteSpace($normalizedTaskLabel))) {
  if ($Location -eq "all") {
    throw "Multiple handover scopes found for task label '$TaskLabel'. Rerun with -Location and/or -WorkspaceRoot and/or -Branch to diff one scope."
  }
  throw "Multiple handover scopes found for task label '$TaskLabel'. Rerun with -WorkspaceRoot and/or -Branch to diff one scope."
}

$latest = $candidates | Select-Object -First 1
$latestRecord = Get-HandoverRecord -Path $latest.Path
if ([string]::IsNullOrWhiteSpace($latestRecord.PreviousHandover) -or ($latestRecord.PreviousHandover -eq "No prior handover found")) {
  throw "No previous handover is available to compare for the selected scope."
}

if (-not (Test-Path -LiteralPath $latestRecord.PreviousHandover -PathType Leaf)) {
  throw "Previous handover path does not exist: $($latestRecord.PreviousHandover)"
}

$previousRecord = Get-HandoverRecord -Path ((Resolve-Path -LiteralPath $latestRecord.PreviousHandover).Path)
$fieldMap = @(
  @{ Label = "Current status"; Previous = $previousRecord.CurrentStatus; Current = $latestRecord.CurrentStatus },
  @{ Label = "What was done"; Previous = $previousRecord.WhatWasDone; Current = $latestRecord.WhatWasDone },
  @{ Label = "In progress"; Previous = $previousRecord.InProgress; Current = $latestRecord.InProgress },
  @{ Label = "Remaining work"; Previous = $previousRecord.RemainingWork; Current = $latestRecord.RemainingWork },
  @{ Label = "Blockers and open questions"; Previous = $previousRecord.Blockers; Current = $latestRecord.Blockers },
  @{ Label = "Next action"; Previous = $previousRecord.NextAction; Current = $latestRecord.NextAction },
  @{ Label = "Session state"; Previous = $previousRecord.SessionState; Current = $latestRecord.SessionState },
  @{ Label = "How to resume"; Previous = $previousRecord.HowToResume; Current = $latestRecord.HowToResume },
  @{ Label = "Validation and evidence"; Previous = $previousRecord.Validation; Current = $latestRecord.Validation },
  @{ Label = "Files added/modified"; Previous = $previousRecord.FilesAddedModified; Current = $latestRecord.FilesAddedModified }
)

$changes = @(
  $fieldMap | ForEach-Object {
    [pscustomobject]@{
      Field = $_.Label
      Previous = $_.Previous
      Current = $_.Current
      Changed = ($_.Previous -ne $_.Current)
    }
  }
)

$result = [pscustomobject]@{
  LatestLocation = Get-HandoverLocation -Path $latestRecord.Path -ArchiveDir $archiveDir
  LatestPath = $latestRecord.Path
  LatestTimestamp = $latestRecord.Timestamp
  PreviousLocation = Get-HandoverLocation -Path $previousRecord.Path -ArchiveDir $archiveDir
  PreviousPath = $previousRecord.Path
  PreviousTimestamp = $previousRecord.Timestamp
  TaskLabel = $latestRecord.TaskLabel
  WorkspaceRoot = $latestRecord.WorkspaceRoot
  Branch = $latestRecord.Branch
  ChangedFields = @($changes | Where-Object Changed)
  UnchangedFieldCount = (@($changes | Where-Object { -not $_.Changed })).Count
}

switch ($Format) {
  "json" {
    $result | ConvertTo-Json -Depth 5
  }
  default {
    Write-Host ("Task: {0}" -f $result.TaskLabel)
    Write-Host ("Workspace: {0}" -f $result.WorkspaceRoot)
    Write-Host ("Branch: {0}" -f $result.Branch)
    Write-Host ("Latest: [{0}] {1} | {2}" -f $result.LatestLocation, $result.LatestTimestamp, $result.LatestPath)
    Write-Host ("Previous: [{0}] {1} | {2}" -f $result.PreviousLocation, $result.PreviousTimestamp, $result.PreviousPath)
    if ($result.ChangedFields.Count -eq 0) {
      Write-Host "Changed fields: none"
    } else {
      Write-Host "Changed fields:"
      foreach ($change in $result.ChangedFields) {
        Write-Host ("- {0}" -f $change.Field)
        Write-Host ("  Previous: {0}" -f $change.Previous)
        Write-Host ("  Current: {0}" -f $change.Current)
      }
    }
    Write-Host ("Unchanged tracked fields: {0}" -f $result.UnchangedFieldCount)
  }
}
