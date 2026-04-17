param(
  [string]$TaskLabel = "",
  [string]$DocsRoot = "docs/tests",
  [ValidateSet("active", "archive", "all")]
  [string]$Location = "active",
  [string]$WorkspaceRoot = "",
  [string]$Branch = "",
  [ValidateSet("summary", "json", "paths")]
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

function Get-HandoverMetadataValue([string]$Path, [string]$Label) {
  $pattern = '(?mi)^(?:\s*-\s*|\s*)' + [regex]::Escape($Label) + ':\s*(?<value>.+)$'
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
    throw "Multiple handover scopes found for task label '$TaskLabel'. Rerun with -Location and/or -WorkspaceRoot and/or -Branch to trace one scope."
  }
  throw "Multiple handover scopes found for task label '$TaskLabel'. Rerun with -WorkspaceRoot and/or -Branch to trace one scope."
}

$selected = $candidates | Select-Object -First 1
$chain = New-Object 'System.Collections.Generic.List[object]'
$visited = New-Object 'System.Collections.Generic.HashSet[string]'
$currentPath = $selected.Path
$index = 0
$noPriorValue = "No prior handover found"

while (-not [string]::IsNullOrWhiteSpace($currentPath)) {
  $currentPathNormalized = $currentPath -replace '\\', '/'
  if (-not (Test-Path -Path $currentPathNormalized -PathType Leaf)) {
    throw "Previous handover path does not exist while tracing chain: $currentPath"
  }

  $resolvedCurrentPath = (Resolve-Path -Path $currentPathNormalized).Path
  if ($visited.Contains($resolvedCurrentPath)) {
    throw "Previous handover chain contains a cycle while tracing: $resolvedCurrentPath"
  }
  [void]$visited.Add($resolvedCurrentPath)

  $text = Get-Content -Raw -LiteralPath $resolvedCurrentPath
  $previousHandover = Get-HandoverMetadataValue -Path $resolvedCurrentPath -Label "Previous handover"
  $chain.Add([pscustomobject]@{
    ChainIndex = $index
    Location = Get-HandoverLocation -Path $resolvedCurrentPath -ArchiveDir $archiveDir
    Path = $resolvedCurrentPath
    Timestamp = Get-HandoverMetadataValue -Path $resolvedCurrentPath -Label "Timestamp"
    ParsedTimestamp = Parse-HandoverTimestamp -Value (Get-HandoverMetadataValue -Path $resolvedCurrentPath -Label "Timestamp")
    TaskLabel = Get-HandoverMetadataValue -Path $resolvedCurrentPath -Label "Task label"
    WorkspaceRoot = Get-HandoverMetadataValue -Path $resolvedCurrentPath -Label "Workspace root"
    Branch = Get-HandoverMetadataValue -Path $resolvedCurrentPath -Label "Branch"
    CurrentStatus = Get-SectionBody -Markdown $text -Heading "### Current status"
    NextAction = Get-SectionBody -Markdown $text -Heading "### Next action"
    Validation = Get-SectionBody -Markdown $text -Heading "### Validation and evidence"
    PreviousHandover = $previousHandover
  }) | Out-Null

  if ($previousHandover -eq $noPriorValue) {
    break
  }

  $currentPath = $previousHandover
  $index++
}

switch ($Format) {
  "paths" {
    foreach ($entry in $chain) {
      Write-Host $entry.Path
    }
  }
  "json" {
    $chain | ConvertTo-Json -Depth 4
  }
  default {
    foreach ($entry in $chain) {
      Write-Host ("[{0}] [{1}] {2} | status={3}" -f $entry.ChainIndex, $entry.Location, $entry.Timestamp, $entry.CurrentStatus)
      Write-Host ("  Task: {0}" -f $entry.TaskLabel)
      Write-Host ("  Workspace: {0}" -f $entry.WorkspaceRoot)
      Write-Host ("  Branch: {0}" -f $entry.Branch)
      Write-Host ("  Next: {0}" -f $entry.NextAction)
      Write-Host ("  Validation: {0}" -f $entry.Validation)
      Write-Host ("  Previous: {0}" -f $entry.PreviousHandover)
      Write-Host ("  Path: {0}" -f $entry.Path)
    }
  }
}

