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
  $pattern = '(?mi)^(?:\s*-\s*|\s*)' + [regex]::Escape($Label) + ':\s*(?<value>.+)$'
  $text = Get-Content -Raw -LiteralPath $Path
  $match = [regex]::Match($text, $pattern)
  if (-not $match.Success) {
    return ""
  }
  return $match.Groups["value"].Value.Trim()
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

function Resolve-HandoverLink([string]$ContainingFilePath, [string]$LinkValue) {
  if ([string]::IsNullOrWhiteSpace($LinkValue) -or ($LinkValue -eq "No prior handover found")) {
    return $LinkValue
  }
  $normalized = $LinkValue -replace '\\', '/'
  if ([System.IO.Path]::IsPathRooted($normalized)) {
    return Get-ResolvedPath $normalized
  }
  $dir = [System.IO.Path]::GetDirectoryName($ContainingFilePath)
  $abs = Join-Path $dir $normalized
  return Get-ResolvedPath $abs
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
  $pattern = '(?mi)^(?:\s*-\s*|\s*)' + [regex]::Escape($Label) + ':\s*.+$'
  $replacement = ('- {0}: {1}' -f $Label, $Value)
  return [regex]::Replace($Markdown, $pattern, $replacement, 1)
}

$validatorScript = Join-Path $PSScriptRoot "validate-handover.ps1"
if (-not (Test-Path -LiteralPath $validatorScript -PathType Leaf)) {
  throw "Validator script not found: $validatorScript"
}

$resolvedDocsRoot = Get-ResolvedPath $DocsRoot
$handoverDir = Join-Path $resolvedDocsRoot "handovers"
$activeDir = $handoverDir
$archiveDir = Join-Path $activeDir "archive"
$handoverDirNormalized = $handoverDir -replace '\\', '/'

if (-not (Test-Path -LiteralPath $handoverDirNormalized -PathType Container)) {
  throw "Handover directory not found: $handoverDirNormalized"
}

if (-not (Test-Path -LiteralPath $activeDir -PathType Container)) {
  # Create active directory if missing
  New-Item -ItemType Directory -Path $activeDir -Force | Out-Null
}

if (-not (Test-Path -LiteralPath $archiveDir -PathType Container)) {
  throw "Archive directory not found: $archiveDir"
}

$normalizedTaskLabel = Normalize-TaskLabel -Value $TaskLabel
if ([string]::IsNullOrWhiteSpace($normalizedTaskLabel)) {
  throw "Task label must contain at least one lowercase letter or digit after normalization"
}

$normalizedWorkspaceRoot = Normalize-WorkspaceRoot -Value $WorkspaceRoot
$normalizedBranch = Normalize-Branch -Value $Branch

$candidates = @(
  Get-ChildItem -LiteralPath $archiveDir -File -Filter "*_CypressSkillHandover.md" | ForEach-Object {
    $candidateTaskLabel = Get-HandoverMetadataValue -Path $_.FullName -Label "Task label"
    $candidateWorkspaceRoot = Get-HandoverMetadataValue -Path $_.FullName -Label "Workspace root"
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
  throw "No archived handover found for task label '$TaskLabel' in $archiveDir"
}

$scopeCount = @($candidates | Group-Object ScopeKey).Count
if (($scopeCount -gt 1) -and [string]::IsNullOrWhiteSpace($normalizedWorkspaceRoot) -and [string]::IsNullOrWhiteSpace($normalizedBranch)) {
  throw "Multiple archived handover scopes found for task label '$TaskLabel'. Rerun with -WorkspaceRoot and/or -Branch to restore one scope."
}

$latest = $candidates | Select-Object -First 1
$chain = New-Object 'System.Collections.Generic.List[object]'
$visited = New-Object 'System.Collections.Generic.HashSet[string]'
$currentPath = $latest.Path
$noPriorValue = "No prior handover found"

while ((-not [string]::IsNullOrWhiteSpace($currentPath)) -and ($currentPath -ne $noPriorValue)) {
  $currentPathNormalized = $currentPath -replace '\\', '/'
  Write-Host "DEBUG: restore traversal: checking '$currentPathNormalized'"
  if (-not (Test-Path -LiteralPath $currentPathNormalized -PathType Leaf)) {
    throw "Previous handover path does not exist while restoring: $currentPath"
  }

  $resolvedCurrentPath = (Resolve-Path -LiteralPath $currentPathNormalized).Path
  $resolvedCurrentPathCanonical = Get-ResolvedPath $resolvedCurrentPath
  if ($visited.Contains($resolvedCurrentPathCanonical)) {
    throw "Previous handover chain contains a cycle while restoring: $resolvedCurrentPathCanonical"
  }
  [void]$visited.Add($resolvedCurrentPathCanonical)

  $previousValue = Get-HandoverMetadataValue -Path $resolvedCurrentPath -Label "Previous handover"
  Write-Host "DEBUG: restore traversal: read PreviousValue='$previousValue' inside '$resolvedCurrentPathCanonical'"
  $resolvedPreviousValue = Resolve-HandoverLink -ContainingFilePath $resolvedCurrentPath -LinkValue $previousValue

  $chain.Add([pscustomobject]@{
    Path = $resolvedCurrentPathCanonical
    PreviousHandover = ($previousValue -replace '\\', '/')
  }) | Out-Null

  if ($previousValue -eq $noPriorValue) {
    break
  }

  $currentPath = $resolvedPreviousValue
}

$orderedChain = @($chain | Sort-Object Path)
$targetPathBySource = @{}
foreach ($entry in $orderedChain) {
  $targetPath = Join-Path $handoverDir ([System.IO.Path]::GetFileName($entry.Path))
  if ((Test-Path -LiteralPath $targetPath) -and (-not $Force)) {
    throw "Restore target already exists: $targetPath"
  }
  $entryPathCanonical = Get-ResolvedPath $entry.Path
  Write-Host "DEBUG: restore mapping: mapping key='$entryPathCanonical' -> target='$targetPath'"
  $targetPathBySource[$entryPathCanonical] = $targetPath
}

$writtenTargets = New-Object 'System.Collections.Generic.List[string]'
try {
  foreach ($entry in $orderedChain) {
    $text = Get-Content -Raw -LiteralPath $entry.Path
    $updatedPreviousRaw = $entry.PreviousHandover
    if ($updatedPreviousRaw -ne $noPriorValue) {
      $lookupKey = Get-ResolvedPath $updatedPreviousRaw
      if ($targetPathBySource.ContainsKey($lookupKey)) {
        $updatedPrevious = $targetPathBySource[$lookupKey] -replace '\\', '/'
        $text = Replace-MetadataLine -Markdown $text -Label "Previous handover" -Value $updatedPrevious
      }
    }

    $entryPathCanonical = Get-ResolvedPath $entry.Path
    $targetPath = $targetPathBySource[$entryPathCanonical]
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
  RestoredCount = $orderedChain.Count
  HandoverDirectory = (Resolve-Path -LiteralPath $handoverDir).Path
  RestoredPaths = @(
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
    Write-Host ("Restored task: {0}" -f $result.TaskLabel)
    Write-Host ("Workspace: {0}" -f $result.WorkspaceRoot)
    Write-Host ("Branch: {0}" -f $result.Branch)
    Write-Host ("Handover directory: {0}" -f $result.HandoverDirectory)
    Write-Host ("Restored files: {0}" -f $result.RestoredCount)
    foreach ($restoredPath in $result.RestoredPaths) {
      Write-Host ("- {0}" -f $restoredPath)
    }
  }
}

