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

function Replace-MetadataLine([string]$Markdown, [string]$Label, [string]$Value) {
  $pattern = '(?m)^- ' + [regex]::Escape($Label) + ':\s*.+$'
  $replacement = ('- {0}: {1}' -f $Label, $Value)
  return [regex]::Replace($Markdown, $pattern, $replacement, 1)
}

$validatorScript = Join-Path $PSScriptRoot "validate-handover.ps1"
if (-not (Test-Path -LiteralPath $validatorScript -PathType Leaf)) {
  throw "Validator script not found: $validatorScript"
}

$resolvedDocsRoot = Get-ResolvedPath $DocsRoot
$handoverDir = Join-Path $resolvedDocsRoot "handovers"
$handoverDirNormalized = $handoverDir -replace '\\', '/'
if (-not (Test-Path -LiteralPath $handoverDirNormalized -PathType Container)) {
  throw "Handover directory does not exist: $handoverDirNormalized"
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

$entries = @(
  $inputs | ForEach-Object {
    $file = $_.File
    $candidatePathNormalized = $file.FullName -replace '\\', '/'
    $taskLabel = Get-HandoverMetadataValue -Path $candidatePathNormalized -Label "Task label"
    $workspace = Get-HandoverMetadataValue -Path $candidatePathNormalized -Label "Workspace root"
    $branchValue = Get-HandoverMetadataValue -Path $candidatePathNormalized -Label "Branch"
    $timestamp = Get-HandoverMetadataValue -Path $candidatePathNormalized -Label "Timestamp"
    $normalizedEntryTaskLabel = Normalize-TaskLabel -Value $taskLabel
    $normalizedEntryWorkspace = Normalize-WorkspaceRoot -Value $workspace
    $normalizedEntryBranch = Normalize-Branch -Value $branchValue
    [pscustomobject]@{
      Location = $_.Location
      Path = Get-ResolvedPath $file.FullName
      Timestamp = $timestamp
      ParsedTimestamp = Parse-HandoverTimestamp -Value $timestamp
      TaskLabel = $taskLabel
      NormalizedTaskLabel = $normalizedEntryTaskLabel
      WorkspaceRoot = $workspace
      NormalizedWorkspaceRoot = $normalizedEntryWorkspace
      Branch = $branchValue
      NormalizedBranch = $normalizedEntryBranch
      ScopeKey = ("{0}|{1}|{2}" -f $normalizedEntryTaskLabel, $normalizedEntryWorkspace, $normalizedEntryBranch)
      LocationScopeKey = ("{0}|{1}" -f $_.Location, ("{0}|{1}|{2}" -f $normalizedEntryTaskLabel, $normalizedEntryWorkspace, $normalizedEntryBranch))
      # Ensure metadata stored in pscustomobject is normalized for cross-platform consistency
      PreviousHandover = (Get-HandoverMetadataValue -Path $file.FullName -Label "Previous handover" -replace '\\', '/')
    }
  }
)

if (-not [string]::IsNullOrWhiteSpace($normalizedTaskLabel)) {
  $entries = @($entries | Where-Object { $_.NormalizedTaskLabel -eq $normalizedTaskLabel })
}
if (-not [string]::IsNullOrWhiteSpace($normalizedWorkspaceRoot)) {
  $entries = @($entries | Where-Object { $_.NormalizedWorkspaceRoot -eq $normalizedWorkspaceRoot })
}
if (-not [string]::IsNullOrWhiteSpace($normalizedBranch)) {
  $entries = @($entries | Where-Object { $_.NormalizedBranch -eq $normalizedBranch })
}

if ($entries.Count -eq 0) {
  if ([string]::IsNullOrWhiteSpace($TaskLabel)) {
    throw "No handovers found for the requested filters in location '$Location'"
  }
  throw "No handover scope found for task label '$TaskLabel' in location '$Location'"
}

$scopeGroups = @($entries | Group-Object LocationScopeKey)
$originalContentByPath = @{}
$changedPaths = New-Object 'System.Collections.Generic.List[string]'
$scopeResults = New-Object 'System.Collections.Generic.List[object]'
$noPriorValue = "No prior handover found"

try {
  foreach ($scopeGroup in $scopeGroups) {
    $orderedEntries = @(
      $scopeGroup.Group |
        Sort-Object `
          @{ Expression = "ParsedTimestamp"; Descending = $true }, `
          @{ Expression = "Path"; Descending = $true }
    )

    $updatedPaths = New-Object 'System.Collections.Generic.List[string]'
    for ($index = 0; $index -lt $orderedEntries.Count; $index++) {
      $entry = $orderedEntries[$index]
      $expectedPreviousRaw = if ($index -lt ($orderedEntries.Count - 1)) { $orderedEntries[$index + 1].Path } else { $noPriorValue }
      
      $currentPreviousCanonical = Resolve-HandoverLink -ContainingFilePath $entry.Path -LinkValue $entry.PreviousHandover
      $expectedPreviousCanonical = Get-ResolvedPath $expectedPreviousRaw

      if ($currentPreviousCanonical -eq $expectedPreviousCanonical) {
        continue
      }

      $expectedPreviousStored = if ($expectedPreviousRaw -eq $noPriorValue) { $noPriorValue } else { $expectedPreviousRaw -replace '\\', '/' }

      if (-not $originalContentByPath.ContainsKey($entry.Path)) {
        $originalContentByPath[$entry.Path] = Get-Content -Raw -LiteralPath $entry.Path
      }

      $updatedText = Replace-MetadataLine -Markdown $originalContentByPath[$entry.Path] -Label "Previous handover" -Value $expectedPreviousStored
      Set-Content -LiteralPath $entry.Path -Value $updatedText -Encoding UTF8
      [void]$changedPaths.Add($entry.Path)
      [void]$updatedPaths.Add($entry.Path)
      $entry.PreviousHandover = $expectedPreviousStored
    }

    foreach ($entry in $orderedEntries) {
      & $validatorScript -Path $entry.Path | Out-Null
    }

    $head = $orderedEntries | Select-Object -First 1
    $scopeResults.Add([pscustomobject]@{
      Location = $head.Location
      TaskLabel = $head.TaskLabel
      WorkspaceRoot = $head.WorkspaceRoot
      Branch = $head.Branch
      FileCount = $orderedEntries.Count
      RewrittenFiles = $updatedPaths.Count
      UpdatedPaths = @($updatedPaths)
    }) | Out-Null
  }
} catch {
  foreach ($path in $changedPaths) {
    if ($originalContentByPath.ContainsKey($path)) {
      Set-Content -LiteralPath $path -Value $originalContentByPath[$path] -Encoding UTF8
    }
  }
  throw
}

$resolvedDocsRoot = (Resolve-Path -Path ($DocsRoot -replace '\\', '/')).Path
$scopeResultArray = @($scopeResults | ForEach-Object { $_ })
$result = [pscustomobject]@{
  DocsRoot = $resolvedDocsRoot
  RepairLocation = [string]$Location
  ScopeCount = [int]$scopeResultArray.Count
  RewrittenFiles = [int]$changedPaths.Count
  ScopeResults = $scopeResultArray
}

switch ($Format) {
  "json" {
    $result | ConvertTo-Json -Depth 5
  }
  default {
    Write-Host ("Repaired scope count: {0}" -f $result.ScopeCount)
    Write-Host ("Rewritten files: {0}" -f $result.RewrittenFiles)
    Write-Host ("Docs root: {0}" -f $result.DocsRoot)
    foreach ($scope in $result.ScopeResults) {
      Write-Host ("- [{0}] {1} | workspace={2} | branch={3} | files={4} | rewritten={5}" -f $scope.Location, $scope.TaskLabel, $scope.WorkspaceRoot, $scope.Branch, $scope.FileCount, $scope.RewrittenFiles)
      foreach ($updatedPath in $scope.UpdatedPaths) {
        Write-Host ("  Updated: {0}" -f $updatedPath)
      }
    }
  }
}
