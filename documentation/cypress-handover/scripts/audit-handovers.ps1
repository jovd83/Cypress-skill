param(
  [string]$DocsRoot = "docs/tests",
  [ValidateSet("active", "archive", "all")]
  [string]$Location = "active",
  [ValidateSet("summary", "json")]
  [string]$Format = "summary",
  [switch]$FailOnIssues
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

function Get-DisplayTaskLabel([pscustomobject]$Entry) {
  if (-not [string]::IsNullOrWhiteSpace($Entry.TaskLabel)) {
    return $Entry.TaskLabel
  }
  return "(empty task label)"
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
  throw "No handovers found for location '$Location'"
}

$results = foreach ($input in $inputs) {
  $file = $input.File
  $taskLabel = Get-HandoverMetadataValue -Path $file.FullName -Label "Task label"
  $workspaceRoot = Get-HandoverMetadataValue -Path $file.FullName -Label "Workspace root"
  $branch = Get-HandoverMetadataValue -Path $file.FullName -Label "Branch"
  $timestamp = Get-HandoverMetadataValue -Path $file.FullName -Label "Timestamp"
  $parsedTimestamp = Parse-HandoverTimestamp -Value $timestamp

  $isValid = $true
  $validationError = ""
  try {
    & $validatorScript -Path $file.FullName | Out-Null
  } catch {
    $isValid = $false
    $validationError = $_.Exception.Message.Trim()
  }

  $normalizedTaskLabel = Normalize-TaskLabel -Value $taskLabel
  $normalizedWorkspaceRoot = Normalize-WorkspaceRoot -Value $workspaceRoot
  $normalizedBranch = Normalize-Branch -Value $branch

  [pscustomobject]@{
    Location = $input.Location
    ScopeKey = ("{0}|{1}|{2}" -f $normalizedTaskLabel, $normalizedWorkspaceRoot, $normalizedBranch)
    # Normalize path to native separators for robust reporting and lookup
    Path = Get-ResolvedPath $file.FullName
    FileName = $file.Name
    Timestamp = $timestamp
    ParsedTimestamp = $parsedTimestamp
    TaskLabel = $taskLabel
    NormalizedTaskLabel = $normalizedTaskLabel
    WorkspaceRoot = $workspaceRoot
    NormalizedWorkspaceRoot = $normalizedWorkspaceRoot
    Branch = $branch
    NormalizedBranch = $normalizedBranch
    IsValid = $isValid
    ValidationError = $validationError
  }
}

$invalidHandovers = @($results | Where-Object { -not $_.IsValid })
$latestByScope = @(
  $results |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_.NormalizedTaskLabel) } |
    Group-Object ScopeKey |
    ForEach-Object {
      $_.Group |
        Sort-Object `
          @{ Expression = "ParsedTimestamp"; Descending = $true }, `
          @{ Expression = "Path"; Descending = $true } |
        Select-Object -First 1
    }
)

$duplicateTaskLabelCollisions = @(
  $latestByScope |
    Group-Object NormalizedTaskLabel |
    ForEach-Object {
      $scopeHeads = @($_.Group)
      if ($scopeHeads.Count -le 1) {
        return
      }

      $displayTaskLabel = ($scopeHeads |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_.TaskLabel) } |
        Select-Object -First 1 -ExpandProperty TaskLabel)

      [pscustomobject]@{
        TaskLabel = $displayTaskLabel
        ScopeCount = $scopeHeads.Count
        Heads = @(
          $scopeHeads |
            Sort-Object `
              @{ Expression = "ParsedTimestamp"; Descending = $true }, `
              @{ Expression = "WorkspaceRoot"; Descending = $false }, `
              @{ Expression = "Branch"; Descending = $false } |
            Select-Object TaskLabel, Timestamp, WorkspaceRoot, Branch, Path
        )
      }
    } |
    Sort-Object TaskLabel
)

$crossLocationScopeCollisions = @(
  $results |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_.NormalizedTaskLabel) } |
    Group-Object ScopeKey |
    ForEach-Object {
      $locations = @($_.Group | Select-Object -ExpandProperty Location -Unique)
      if (($locations -notcontains "active") -or ($locations -notcontains "archive")) {
        return
      }

      $entries = @(
        $_.Group |
          Sort-Object `
            @{ Expression = "Location"; Descending = $false }, `
            @{ Expression = "ParsedTimestamp"; Descending = $true }, `
            @{ Expression = "Path"; Descending = $false } |
          Select-Object Location, TaskLabel, Timestamp, WorkspaceRoot, Branch, Path
      )
      $displayTaskLabel = ($entries |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_.TaskLabel) } |
        Select-Object -First 1 -ExpandProperty TaskLabel)

      [pscustomobject]@{
        TaskLabel = $displayTaskLabel
        WorkspaceRoot = ($entries | Select-Object -First 1 -ExpandProperty WorkspaceRoot)
        Branch = ($entries | Select-Object -First 1 -ExpandProperty Branch)
        Entries = $entries
      }
    } |
    Sort-Object TaskLabel, WorkspaceRoot, Branch
)

$activeCount = (@($results | Where-Object { $_.Location -eq "active" })).Count
$archiveCount = (@($results | Where-Object { $_.Location -eq "archive" })).Count

$summary = [pscustomobject]@{
  HandoverDirectory = Get-ResolvedPath ((Resolve-Path -LiteralPath $handoverDirNormalized).Path)
  AuditLocation = $Location
  TotalFiles = $results.Count
  ActiveFiles = $activeCount
  ArchivedFiles = $archiveCount
  ValidFiles = (@($results | Where-Object IsValid)).Count
  InvalidFiles = $invalidHandovers.Count
  DuplicateTaskLabelCollisionCount = $duplicateTaskLabelCollisions.Count
  CrossLocationScopeCollisionCount = $crossLocationScopeCollisions.Count
}

$output = [pscustomobject]@{
  Summary = $summary
  InvalidHandovers = @(
    $invalidHandovers |
      Sort-Object `
        @{ Expression = "ParsedTimestamp"; Descending = $true }, `
        @{ Expression = "Path"; Descending = $false } |
      Select-Object Location, TaskLabel, Timestamp, WorkspaceRoot, Branch, ValidationError, Path
  )
  DuplicateTaskLabelCollisions = $duplicateTaskLabelCollisions
  CrossLocationScopeCollisions = $crossLocationScopeCollisions
}

switch ($Format) {
  "json" {
    $output | ConvertTo-Json -Depth 6
  }
  default {
    Write-Host ("Audit summary: location={0} files={1} active={2} archived={3} valid={4} invalid={5} collisions={6} cross-location={7}" -f $summary.AuditLocation, $summary.TotalFiles, $summary.ActiveFiles, $summary.ArchivedFiles, $summary.ValidFiles, $summary.InvalidFiles, $summary.DuplicateTaskLabelCollisionCount, $summary.CrossLocationScopeCollisionCount)
    Write-Host ("Directory: {0}" -f $summary.HandoverDirectory)

    if ($invalidHandovers.Count -gt 0) {
      Write-Host "Invalid handovers:"
      foreach ($entry in $output.InvalidHandovers) {
        $displayTaskLabel = if ([string]::IsNullOrWhiteSpace($entry.TaskLabel)) { "(empty task label)" } else { $entry.TaskLabel }
        Write-Host ("- [{0}] {1} | location={2} | workspace={3} | branch={4}" -f $displayTaskLabel, $entry.Timestamp, $entry.Location, $entry.WorkspaceRoot, $entry.Branch)
        Write-Host ("  Error: {0}" -f $entry.ValidationError)
        Write-Host ("  Path: {0}" -f $entry.Path)
      }
    } else {
      Write-Host "Invalid handovers: none"
    }

    if ($duplicateTaskLabelCollisions.Count -gt 0) {
      Write-Host "Duplicate task labels across workspace/branch:"
      foreach ($collision in $duplicateTaskLabelCollisions) {
        $displayTaskLabel = if ([string]::IsNullOrWhiteSpace($collision.TaskLabel)) { "(empty task label)" } else { $collision.TaskLabel }
        Write-Host ("- {0} ({1} active scopes)" -f $displayTaskLabel, $collision.ScopeCount)
        foreach ($head in $collision.Heads) {
          Write-Host ("  [{0}] workspace={1} | branch={2}" -f $head.Timestamp, $head.WorkspaceRoot, $head.Branch)
          Write-Host ("  Path: {0}" -f $head.Path)
        }
      }
    } else {
      Write-Host "Duplicate task labels across workspace/branch: none"
    }

    if ($crossLocationScopeCollisions.Count -gt 0) {
      Write-Host "Same scope exists in both active and archive:"
      foreach ($collision in $crossLocationScopeCollisions) {
        $displayTaskLabel = if ([string]::IsNullOrWhiteSpace($collision.TaskLabel)) { "(empty task label)" } else { $collision.TaskLabel }
        Write-Host ("- {0} | workspace={1} | branch={2}" -f $displayTaskLabel, $collision.WorkspaceRoot, $collision.Branch)
        foreach ($entry in $collision.Entries) {
          Write-Host ("  [{0}] {1} | {2}" -f $entry.Location, $entry.Timestamp, $entry.Path)
        }
      }
    } else {
      Write-Host "Same scope exists in both active and archive: none"
    }
  }
}

if ($FailOnIssues -and (($invalidHandovers.Count -gt 0) -or ($duplicateTaskLabelCollisions.Count -gt 0) -or ($crossLocationScopeCollisions.Count -gt 0))) {
  throw "audit-handovers failed: detected invalid handovers, duplicate task-label collisions, or active/archive scope duplication"
}
