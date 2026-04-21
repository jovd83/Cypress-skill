param(
  [string]$DocsRoot = "docs/tests",
  [ValidateSet("active", "archive", "all")]
  [string]$Location = "active",
  [string]$TaskLabel = "",
  [string]$WorkspaceRoot = "",
  [string]$Branch = "",
  [ValidateSet("summary", "json")]
  [string]$Format = "summary",
  [int]$Limit = 0,
  [ValidateSet("scope", "task")]
  [string]$GroupBy = "scope",
  [ValidateSet("priority", "recent", "stale")]
  [string]$Sort = "priority",
  [ValidateSet("Completed", "In progress", "Blocked", "Awaiting approval")]
  [string[]]$Status = @(),
  [switch]$ExcludeCompleted,
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

function Get-HandoverMetadataValue([string]$Path, [string]$Label) {
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return "" }
  $text = Get-Content -Raw -LiteralPath $Path
  $text = $text -replace "`r", ""
  $pattern = '(?mi)^(?:\s*-\s*|\s*)' + [regex]::Escape($Label) + ':\s*(?<value>.+)$'
  $match = [regex]::Match($text, $pattern)
  if (-not $match.Success) { return "" }
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

function Normalize-Status([string]$Value) {
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

function Get-ChainDepth([string]$Path) {
  $noPriorValue = "No prior handover found"
  $visited = New-Object 'System.Collections.Generic.HashSet[string]'
  $resolvedCurrent = (Resolve-Path -LiteralPath $Path).Path
  [void]$visited.Add($resolvedCurrent)

  $depth = 0
  $nextPath = Get-HandoverMetadataValue -Path $resolvedCurrent -Label "Previous handover"
  while (($nextPath -ne $noPriorValue) -and (-not [string]::IsNullOrWhiteSpace($nextPath)) -and (Test-Path -LiteralPath $nextPath -PathType Leaf)) {
    $resolvedNext = (Resolve-Path -LiteralPath $nextPath).Path
    if ($visited.Contains($resolvedNext)) {
      break
    }

    [void]$visited.Add($resolvedNext)
    $depth++
    $nextPath = Get-HandoverMetadataValue -Path $resolvedNext -Label "Previous handover"
  }

  return $depth
}

function Get-SectionBody([string]$Markdown, [string]$Heading) {
  $pattern = '(?sm)^' + [regex]::Escape($Heading) + '\s*(?<body>.*?)(?=^### |\z)'
  $match = [regex]::Match($Markdown, $pattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)
  if (-not $match.Success) { return "" }
  return ($match.Groups["body"].Value -replace '\s+', ' ').Trim()
}

function Get-StatusPriority([string]$Status) {
  switch (Normalize-Status -Value $Status) {
    "in progress" { return 0 }
    "awaiting approval" { return 1 }
    "blocked" { return 2 }
    "completed" { return 3 }
    default { return 99 }
  }
}

function Get-AgeDays([datetime]$Timestamp, [datetime]$Now) {
  if ($Timestamp -eq [datetime]::MinValue) {
    return -1
  }

  return [int][math]::Floor(($Now - $Timestamp).TotalDays)
}

$resolvedDocsRoot = Get-ResolvedPath $DocsRoot
$handoverDir = Join-Path $resolvedDocsRoot "handovers"
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
$now = Get-Date
$entries = $inputs | ForEach-Object {
  $file = $_.File
  $text = Get-Content -Raw -LiteralPath $file.FullName
  $taskLabel = Get-HandoverMetadataValue -Path $file.FullName -Label "Task label"
  $workspaceRoot = Get-HandoverMetadataValue -Path $file.FullName -Label "Workspace root"
  $branch = Get-HandoverMetadataValue -Path $file.FullName -Label "Branch"
  $currentStatus = Get-SectionBody -Markdown $text -Heading "### Current status"
  $parsedTimestamp = Parse-HandoverTimestamp -Value (Get-HandoverMetadataValue -Path $file.FullName -Label "Timestamp")
  $ageDays = Get-AgeDays -Timestamp $parsedTimestamp -Now $now
  $normalizedEntryTaskLabel = Normalize-TaskLabel -Value $taskLabel
  $normalizedEntryWorkspaceRoot = Normalize-WorkspaceRoot -Value $workspaceRoot
  $normalizedEntryBranch = Normalize-Branch -Value $branch
  $scopeKey = ("{0}|{1}|{2}" -f $normalizedEntryTaskLabel, $normalizedEntryWorkspaceRoot, $normalizedEntryBranch)
  [pscustomobject]@{
    Location = $_.Location
    Path = $file.FullName
    TaskLabel = $taskLabel
    NormalizedTaskLabel = $normalizedEntryTaskLabel
    Timestamp = Get-HandoverMetadataValue -Path $file.FullName -Label "Timestamp"
    ParsedTimestamp = $parsedTimestamp
    WorkspaceRoot = $workspaceRoot
    NormalizedWorkspaceRoot = $normalizedEntryWorkspaceRoot
    Branch = $branch
    NormalizedBranch = $normalizedEntryBranch
    ScopeKey = $scopeKey
    LocationScopeKey = ("{0}|{1}" -f $_.Location, $scopeKey)
    LocationTaskKey = ("{0}|{1}" -f $_.Location, $normalizedEntryTaskLabel)
    CurrentStatus = $currentStatus
    NormalizedStatus = Normalize-Status -Value $currentStatus
    PriorityRank = Get-StatusPriority -Status $currentStatus
    AgeDays = $ageDays
    IsStale = (($ageDays -ge 0) -and ($ageDays -ge $StaleAfterDays))
    NextAction = Get-SectionBody -Markdown $text -Heading "### Next action"
    Blockers = Get-SectionBody -Markdown $text -Heading "### Blockers and open questions"
    ChainDepth = Get-ChainDepth -Path $file.FullName
  }
}

if (-not $entries) {
  throw "No handovers found for location '$Location' in $handoverDir"
}

if (-not [string]::IsNullOrWhiteSpace($normalizedTaskLabel)) {
  $entries = $entries | Where-Object {
    $_.NormalizedTaskLabel -eq $normalizedTaskLabel
  }
}

if (-not [string]::IsNullOrWhiteSpace($normalizedWorkspaceRoot)) {
  $entries = $entries | Where-Object {
    $_.NormalizedWorkspaceRoot -eq $normalizedWorkspaceRoot
  }
}

if (-not [string]::IsNullOrWhiteSpace($normalizedBranch)) {
  $entries = $entries | Where-Object {
    $_.NormalizedBranch -eq $normalizedBranch
  }
}

if (-not $entries) {
  throw "No handovers found for the requested filters in location '$Location'"
}

$groupKey = if ($GroupBy -eq "task") { "LocationTaskKey" } else { "LocationScopeKey" }
$latestByTask = $entries |
  Group-Object $groupKey |
  ForEach-Object {
    $_.Group |
      Sort-Object ParsedTimestamp, Path -Descending |
      Select-Object -First 1
  }

$normalizedStatuses = @($Status | ForEach-Object { Normalize-Status -Value $_ })
if ($normalizedStatuses.Count -gt 0) {
  $latestByTask = $latestByTask | Where-Object {
    $normalizedStatuses -contains $_.NormalizedStatus
  }
} elseif ($ExcludeCompleted) {
  $latestByTask = $latestByTask | Where-Object {
    $_.NormalizedStatus -ne "completed"
  }
}

if ($OnlyStale) {
  $latestByTask = $latestByTask | Where-Object {
    $_.IsStale
  }
}

if ($Sort -eq "recent") {
  $latestByTask = $latestByTask | Sort-Object `
    @{ Expression = "ParsedTimestamp"; Descending = $true }, `
    @{ Expression = "TaskLabel"; Descending = $false }
} elseif ($Sort -eq "stale") {
  $latestByTask = $latestByTask | Sort-Object `
    @{ Expression = "IsStale"; Descending = $true }, `
    @{ Expression = "AgeDays"; Descending = $true }, `
    @{ Expression = "PriorityRank"; Descending = $false }, `
    @{ Expression = "TaskLabel"; Descending = $false }
} else {
  $latestByTask = $latestByTask | Sort-Object `
    @{ Expression = "PriorityRank"; Descending = $false }, `
    @{ Expression = "IsStale"; Descending = $true }, `
    @{ Expression = "ParsedTimestamp"; Descending = $true }, `
    @{ Expression = "TaskLabel"; Descending = $false }
}

if ($Limit -gt 0) {
  $latestByTask = $latestByTask | Select-Object -First $Limit
}

switch ($Format) {
  "json" {
    $latestByTask | Select-Object Location, TaskLabel, Timestamp, WorkspaceRoot, Branch, CurrentStatus, PriorityRank, AgeDays, IsStale, ChainDepth, NextAction, Blockers, Path | ConvertTo-Json -Depth 3
  }
  default {
    foreach ($entry in $latestByTask) {
      Write-Host ("[{0}] [{1}] {2} | workspace={3} | branch={4} | status={5} | priority={6} | age={7}d | stale={8} | chain={9}" -f $entry.Location, $entry.TaskLabel, $entry.Timestamp, $entry.WorkspaceRoot, $entry.Branch, $entry.CurrentStatus, $entry.PriorityRank, $entry.AgeDays, $entry.IsStale.ToString().ToLowerInvariant(), $entry.ChainDepth)
      Write-Host ("  Next: {0}" -f $entry.NextAction)
      Write-Host ("  Blockers: {0}" -f $entry.Blockers)
      Write-Host ("  Path: {0}" -f $entry.Path)
    }
  }
}



