param(
  [string]$TaskLabel = "",
  [string]$DocsRoot = "docs/tests",
  [ValidateSet("active", "archive", "all")]
  [string]$Location = "active",
  [string]$WorkspaceRoot = "",
  [string]$Branch = "",
  [ValidateSet("summary", "path", "json")]
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
  if (-not $match.Success) {
    return ""
  }
  return ($match.Groups["body"].Value -replace '\s+', ' ').Trim()
}

$handoverDir = Join-Path $DocsRoot "handovers"
$handoverDirNormalized = $handoverDir -replace '\\', '/'
if (-not (Test-Path -Path $handoverDirNormalized -PathType Container)) {
  throw "Handover directory not found: $handoverDir"
}

$archiveDir = Join-Path $handoverDir "archive"
$archiveDirNormalized = $archiveDir -replace '\\', '/'
$inputs = New-Object 'System.Collections.Generic.List[object]'

if (($Location -eq "active") -or ($Location -eq "all")) {
  foreach ($file in (Get-ChildItem -Path $handoverDirNormalized -File -Filter "*_CypressSkillHandover.md" | Sort-Object FullName)) {
    $inputs.Add([pscustomobject]@{
      Location = "active"
      File = $file
    }) | Out-Null
  }
}

if (($Location -eq "archive") -or ($Location -eq "all")) {
  if (-not (Test-Path -Path $archiveDirNormalized -PathType Container)) {
    if ($Location -eq "archive") {
      throw "Archive directory not found: $archiveDir"
    }
  } else {
    foreach ($file in (Get-ChildItem -Path $archiveDirNormalized -File -Filter "*_CypressSkillHandover.md" | Sort-Object FullName)) {
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

$candidates = $inputs | ForEach-Object {
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
} | Sort-Object `
  @{ Expression = "ParsedTimestamp"; Descending = $true }, `
  @{ Expression = "Path"; Descending = $true }

if (-not [string]::IsNullOrWhiteSpace($normalizedTaskLabel)) {
  $candidates = $candidates | Where-Object {
    $_.NormalizedTaskLabel -eq $normalizedTaskLabel
  }
}

if (-not [string]::IsNullOrWhiteSpace($normalizedWorkspaceRoot)) {
  $candidates = $candidates | Where-Object {
    $_.NormalizedWorkspaceRoot -eq $normalizedWorkspaceRoot
  }
}

if (-not [string]::IsNullOrWhiteSpace($normalizedBranch)) {
  $candidates = $candidates | Where-Object {
    $_.NormalizedBranch -eq $normalizedBranch
  }
}

$scopeCount = @($candidates | Group-Object LocationScopeKey).Count
if (($scopeCount -gt 1) -and (-not [string]::IsNullOrWhiteSpace($normalizedTaskLabel))) {
  if ($Location -eq "all") {
    throw "Multiple handovers found for task label '$TaskLabel'. Rerun with -Location and/or -WorkspaceRoot and/or -Branch to disambiguate scope."
  }
  throw "Multiple handovers found for task label '$TaskLabel'. Rerun with -WorkspaceRoot and/or -Branch to disambiguate scope."
}

$selected = $candidates | Select-Object -First 1
if ($null -eq $selected) {
  if ([string]::IsNullOrWhiteSpace($TaskLabel)) {
    throw "No handovers found for location '$Location' in $handoverDir"
  }
  throw "No handover found for task label '$TaskLabel' in location '$Location'"
}

$text = Get-Content -Raw -LiteralPath $selected.Path
$result = [pscustomobject]@{
  Location = $selected.Location
  Path = $selected.Path
  Timestamp = $selected.Timestamp
  TaskLabel = $selected.TaskLabel
  WorkspaceRoot = $selected.WorkspaceRoot
  Branch = $selected.Branch
  PreviousHandover = Get-HandoverMetadataValue -Path $selected.Path -Label "Previous handover"
  ChainDepth = Get-ChainDepth -Path $selected.Path
  ParsedTimestamp = $selected.ParsedTimestamp
  CurrentStatus = Get-SectionBody -Markdown $text -Heading "### Current status"
  NextAction = Get-SectionBody -Markdown $text -Heading "### Next action"
  SessionState = Get-SectionBody -Markdown $text -Heading "### Session state"
  HowToResume = Get-SectionBody -Markdown $text -Heading "### How to resume"
  RemainingWork = Get-SectionBody -Markdown $text -Heading "### Remaining work"
  Blockers = Get-SectionBody -Markdown $text -Heading "### Blockers and open questions"
  Validation = Get-SectionBody -Markdown $text -Heading "### Validation and evidence"
}

switch ($Format) {
  "path" {
    Write-Host $result.Path
  }
  "json" {
    $result | ConvertTo-Json -Depth 3
  }
  default {
    @(
      ("Location: {0}" -f $result.Location),
      ("Path: {0}" -f $result.Path),
      ("Timestamp: {0}" -f $result.Timestamp),
      ("Task label: {0}" -f $result.TaskLabel),
      ("Workspace root: {0}" -f $result.WorkspaceRoot),
      ("Branch: {0}" -f $result.Branch),
      ("Previous handover: {0}" -f $result.PreviousHandover),
      ("Chain depth: {0}" -f $result.ChainDepth),
      ("Timestamp parsed: {0}" -f $result.ParsedTimestamp.ToString("yyyy-MM-dd HH:mm")),
      ("Current status: {0}" -f $result.CurrentStatus),
      ("Next action: {0}" -f $result.NextAction),
      ("Session state: {0}" -f $result.SessionState),
      ("How to resume: {0}" -f $result.HowToResume),
      ("Remaining work: {0}" -f $result.RemainingWork),
      ("Blockers: {0}" -f $result.Blockers),
      ("Validation: {0}" -f $result.Validation)
    ) | ForEach-Object { Write-Host $_ }
  }
}
