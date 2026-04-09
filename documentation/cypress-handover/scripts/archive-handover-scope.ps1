param(
  [Parameter(Mandatory = $true)]
  [string]$TaskLabel,
  [string]$DocsRoot = "docs/tests",
  [string]$WorkspaceRoot = "",
  [string]$Branch = "",
  [ValidateSet("summary", "json")]
  [string]$Format = "summary",
  [switch]$Force
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

function Replace-MetadataLine([string]$Markdown, [string]$Label, [string]$Value) {
  $pattern = '(?m)^- ' + [regex]::Escape($Label) + ':\s*.+$'
  $replacement = ('- {0}: {1}' -f $Label, $Value)
  return [regex]::Replace($Markdown, $pattern, $replacement, 1)
}

$validatorScript = Join-Path $PSScriptRoot "validate-handover.ps1"
if (-not (Test-Path -LiteralPath $validatorScript -PathType Leaf)) {
  throw "Validator script not found: $validatorScript"
}

$handoverDir = Join-Path $DocsRoot "handovers"
$handoverDirNormalized = $handoverDir -replace '\\', '/'
if (-not (Test-Path -Path $handoverDirNormalized -PathType Container)) {
  throw "Handover directory not found: $handoverDir"
}

$archiveDir = Join-Path $handoverDir "archive"
New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null

$normalizedTaskLabel = Normalize-TaskLabel -Value $TaskLabel
if ([string]::IsNullOrWhiteSpace($normalizedTaskLabel)) {
  throw "Task label must contain at least one lowercase letter or digit after normalization"
}

$normalizedWorkspaceRoot = Normalize-WorkspaceRoot -Value $WorkspaceRoot
$normalizedBranch = Normalize-Branch -Value $Branch

$candidates = @(
  Get-ChildItem -Path $handoverDirNormalized -File -Filter "*_CypressSkillHandover.md" | ForEach-Object {
    $candidatePathNormalized = $_.FullName -replace '\\', '/'
    $candidateTaskLabel = Get-HandoverMetadataValue -Path $candidatePathNormalized -Label "Task label"
    $candidateWorkspaceRoot = Get-HandoverMetadataValue -Path $candidatePathNormalized -Label "Workspace root"
    $candidateBranch = Get-HandoverMetadataValue -Path $_.FullName -Label "Branch"
    $candidateTimestamp = Get-HandoverMetadataValue -Path $_.FullName -Label "Timestamp"
    [pscustomobject]@{
      Path = $_.FullName
      Timestamp = $candidateTimestamp
      ParsedTimestamp = Parse-HandoverTimestamp -Value $candidateTimestamp
      TaskLabel = $candidateTaskLabel
      NormalizedTaskLabel = Normalize-TaskLabel -Value $candidateTaskLabel
      WorkspaceRoot = $candidateWorkspaceRoot
      NormalizedWorkspaceRoot = Normalize-WorkspaceRoot -Value $candidateWorkspaceRoot
      Branch = $candidateBranch
      NormalizedBranch = Normalize-Branch -Value $candidateBranch
      ScopeKey = ("{0}|{1}|{2}" -f (Normalize-TaskLabel -Value $candidateTaskLabel), (Normalize-WorkspaceRoot -Value $candidateWorkspaceRoot), (Normalize-Branch -Value $candidateBranch))
    }
  } |
  Sort-Object `
    @{ Expression = "ParsedTimestamp"; Descending = $true }, `
    @{ Expression = "Path"; Descending = $true }
)

$candidates = @($candidates | Where-Object { $_.NormalizedTaskLabel -eq $normalizedTaskLabel })
if (-not [string]::IsNullOrWhiteSpace($normalizedWorkspaceRoot)) {
  $candidates = @($candidates | Where-Object { $_.NormalizedWorkspaceRoot -eq $normalizedWorkspaceRoot })
}
if (-not [string]::IsNullOrWhiteSpace($normalizedBranch)) {
  $candidates = @($candidates | Where-Object { $_.NormalizedBranch -eq $normalizedBranch })
}

if ($candidates.Count -eq 0) {
  throw "No handover found for task label '$TaskLabel' in $handoverDir"
}

$scopeCount = @($candidates | Group-Object ScopeKey).Count
if (($scopeCount -gt 1) -and [string]::IsNullOrWhiteSpace($normalizedWorkspaceRoot) -and [string]::IsNullOrWhiteSpace($normalizedBranch)) {
  throw "Multiple handover scopes found for task label '$TaskLabel'. Rerun with -WorkspaceRoot and/or -Branch to archive one scope."
}

$latest = $candidates | Select-Object -First 1
$latestText = Get-Content -Raw -LiteralPath $latest.Path
$latestStatus = Get-SectionBody -Markdown $latestText -Heading "### Current status"
if ($latestStatus -ne "Completed") {
  throw "Only completed handover scopes can be archived"
}

$chain = New-Object 'System.Collections.Generic.List[object]'
$visited = New-Object 'System.Collections.Generic.HashSet[string]'
$currentPath = $latest.Path
$noPriorValue = "No prior handover found"

while (-not [string]::IsNullOrWhiteSpace($currentPath)) {
  $currentPathNormalized = $currentPath -replace '\\', '/'
  if (-not (Test-Path -Path $currentPathNormalized -PathType Leaf)) {
    throw "Previous handover path does not exist while archiving: $currentPath"
  }

  $resolvedCurrentPath = (Resolve-Path -Path $currentPathNormalized).Path
  if ($visited.Contains($resolvedCurrentPath)) {
    throw "Previous handover chain contains a cycle while archiving: $resolvedCurrentPath"
  }
  [void]$visited.Add($resolvedCurrentPath)

  $previousValue = Get-HandoverMetadataValue -Path $resolvedCurrentPath -Label "Previous handover"
  $chain.Add([pscustomobject]@{
    Path = $resolvedCurrentPath
    PreviousHandover = ($previousValue -replace '\\', '/')
  }) | Out-Null

  if ($previousValue -eq $noPriorValue) {
    break
  }

  $currentPath = $previousValue
}

$orderedChain = @($chain | Sort-Object Path)
$targetPathBySource = @{}
foreach ($entry in $orderedChain) {
  $targetPath = Join-Path $archiveDir ([System.IO.Path]::GetFileName($entry.Path))
  if ((Test-Path -LiteralPath $targetPath) -and (-not $Force)) {
    throw "Archive target already exists: $targetPath"
  }
  $targetPathBySource[$entry.Path] = $targetPath
}

$writtenTargets = New-Object 'System.Collections.Generic.List[string]'
try {
  foreach ($entry in $orderedChain) {
    $text = Get-Content -Raw -LiteralPath $entry.Path
    $updatedPreviousRaw = $entry.PreviousHandover
    if (($updatedPreviousRaw -ne $noPriorValue)) {
      # Normalize search key to native separators to match targetPathBySource keys
      $lookupKey = $updatedPreviousRaw -replace '/', [System.IO.Path]::DirectorySeparatorChar
      if ($targetPathBySource.ContainsKey($lookupKey)) {
        $updatedPrevious = $targetPathBySource[$lookupKey] -replace '\\', '/'
        $text = Replace-MetadataLine -Markdown $text -Label "Previous handover" -Value $updatedPrevious
      }
    }

    $targetPath = $targetPathBySource[$entry.Path]
    Set-Content -LiteralPath $targetPath -Value $text -Encoding UTF8
    [void]$writtenTargets.Add($targetPath)
  }

  foreach ($targetPath in $writtenTargets) {
    & $validatorScript -Path $targetPath | Out-Null
  }

  foreach ($entry in $orderedChain) {
    Remove-Item -LiteralPath $entry.Path -Force
  }
} catch {
  foreach ($targetPath in $writtenTargets) {
    Remove-Item -LiteralPath $targetPath -Force -ErrorAction SilentlyContinue
  }
  throw
}

$result = [pscustomobject]@{
  TaskLabel = $latest.TaskLabel
  WorkspaceRoot = $latest.WorkspaceRoot
  Branch = $latest.Branch
  ArchivedCount = $orderedChain.Count
  ArchiveDirectory = (Resolve-Path -Path ($archiveDir -replace '\\', '/')).Path
  ArchivedPaths = @(
    $orderedChain |
      Sort-Object @{ Expression = "Path"; Descending = $false } |
      ForEach-Object { $targetPathBySource[$_.Path] }
  )
}

switch ($Format) {
  "json" {
    $result | ConvertTo-Json -Depth 4
  }
  default {
    Write-Host ("Archived task: {0}" -f $result.TaskLabel)
    Write-Host ("Workspace: {0}" -f $result.WorkspaceRoot)
    Write-Host ("Branch: {0}" -f $result.Branch)
    Write-Host ("Archive directory: {0}" -f $result.ArchiveDirectory)
    Write-Host ("Archived files: {0}" -f $result.ArchivedCount)
    foreach ($archivedPath in $result.ArchivedPaths) {
      Write-Host ("- {0}" -f $archivedPath)
    }
  }
}
