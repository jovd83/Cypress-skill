param(
  [string]$TaskLabel = "task",
  [string]$DocsRoot = "docs/tests",
  [string]$PreviousHandover = "",
  [switch]$Force
)

$ErrorActionPreference = "Stop"

function Get-GitValue([string[]]$Arguments) {
  try {
    $result = & git @Arguments 2>$null
    if ($LASTEXITCODE -ne 0) { return "" }
    return (($result | Select-Object -First 1) -as [string]).Trim()
  } catch {
    return ""
  }
}

function Get-HandoverMetadataValue([string]$Path, [string]$Label) {
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    return ""
  }

  $pattern = '(?mi)^(?:\s*-\s*|\s*)' + [regex]::Escape($Label) + ':\s*(?<value>.+)$'
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

function Get-HandoverEntries([string]$SearchDir) {
  if (-not (Test-Path -LiteralPath $SearchDir -PathType Container)) {
    return @()
  }

  return @(
    Get-ChildItem -LiteralPath $SearchDir -File -Filter "*_CypressSkillHandover.md" | ForEach-Object {
      $candidateTaskLabel = Get-HandoverMetadataValue -Path $_.FullName -Label "Task label"
      $candidateWorkspaceRoot = Get-HandoverMetadataValue -Path $_.FullName -Label "Workspace root"
      $candidateBranch = Get-HandoverMetadataValue -Path $_.FullName -Label "Branch"
      [pscustomobject]@{
        Path = $_.FullName
        FileLastWriteTimeUtc = $_.LastWriteTimeUtc
        TaskLabel = $candidateTaskLabel
        NormalizedTaskLabel = Normalize-TaskLabel -Value $candidateTaskLabel
        WorkspaceRoot = $candidateWorkspaceRoot
        NormalizedWorkspaceRoot = Normalize-WorkspaceRoot -Value $candidateWorkspaceRoot
        Branch = $candidateBranch
        NormalizedBranch = Normalize-Branch -Value $candidateBranch
      }
    } |
    Sort-Object FileLastWriteTimeUtc -Descending
  )
}

function Get-HandoverEntryByResolvedPath([object[]]$Entries, [string]$ResolvedPath) {
  foreach ($entry in $Entries) {
    $entryResolved = Get-ResolvedPath $entry.Path
    if ($entryResolved -eq $ResolvedPath) {
      return $entry
    }
  }
  return $null
}

# Helper to resolve symlinks and return absolute, canonical paths with forward slashes.
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

function Test-PathUnderDirectory([string]$Path, [string]$Directory) {
  if ([string]::IsNullOrWhiteSpace($Path) -or [string]::IsNullOrWhiteSpace($Directory)) {
    return $false
  }
  if (-not (Test-Path -LiteralPath $Directory -PathType Container)) {
    return $false
  }

  $resolvedPath = (Resolve-Path -LiteralPath $Path).Path
  $resolvedDirectory = (Resolve-Path -LiteralPath $Directory).Path
  $normalizedPath = (($resolvedPath -replace '\\', '/').Trim()).TrimEnd('/').ToLowerInvariant()
  $normalizedDirectory = (($resolvedDirectory -replace '\\', '/').Trim()).TrimEnd('/').ToLowerInvariant()

  return $normalizedPath.StartsWith($normalizedDirectory + "/")
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$skillRoot = Split-Path -Parent $scriptDir
$templatePath = Join-Path $skillRoot "assets/handover-template.md"

if (-not (Test-Path -LiteralPath $templatePath -PathType Leaf)) {
  throw "Template not found: $templatePath"
}

$resolvedDocsRoot = Get-ResolvedPath $DocsRoot
$handoverDir = Join-Path $resolvedDocsRoot "handovers"
if (-not (Test-Path -LiteralPath $handoverDir -PathType Container)) {
  New-Item -ItemType Directory -Path $handoverDir -Force | Out-Null
}
$archiveDir = Join-Path $handoverDir "archive"

$timestamp = Get-Date -Format "yyyyMMdd_HHmm"
$outputPath = Join-Path $handoverDir ("{0}_CypressSkillHandover.md" -f $timestamp)

if ((Test-Path -LiteralPath $outputPath) -and (-not $Force)) {
  throw "Handover already exists: $outputPath"
}

$workspaceRoot = Get-GitValue -Arguments @("rev-parse", "--show-toplevel")
if ([string]::IsNullOrWhiteSpace($workspaceRoot)) {
  $workspaceRoot = (Get-ResolvedPath ".")
}

$branch = Get-GitValue -Arguments @("branch", "--show-current")
if ([string]::IsNullOrWhiteSpace($branch)) {
  $branch = "Unknown"
}

$normalizedTaskLabel = Normalize-TaskLabel -Value $TaskLabel
if ([string]::IsNullOrWhiteSpace($normalizedTaskLabel)) {
  throw "Task label must contain at least one lowercase letter or digit after normalization"
}
if ($normalizedTaskLabel.Length -gt 64) {
  throw "Task label must be 64 characters or fewer after normalization"
}

$normalizedWorkspaceRoot = Normalize-WorkspaceRoot -Value $workspaceRoot
$normalizedBranch = Normalize-Branch -Value $branch
$activeEntries = @(Get-HandoverEntries -SearchDir $handoverDir)
$archivedEntries = @(Get-HandoverEntries -SearchDir $archiveDir)

if (-not [string]::IsNullOrWhiteSpace($PreviousHandover)) {
  if ($PreviousHandover -ne "No prior handover found") {
    if (-not (Test-Path -LiteralPath $PreviousHandover -PathType Leaf)) {
      throw "Previous handover path does not exist: $PreviousHandover"
    }

    $resolvedPreviousHandover = (Resolve-Path -LiteralPath $PreviousHandover).Path
    $archivedPreviousEntry = Get-HandoverEntryByResolvedPath -Entries $archivedEntries -ResolvedPath $resolvedPreviousHandover
    if ($null -ne $archivedPreviousEntry) {
      throw "Previous handover exists only in archive for this scope. Run restore-handover-scope.ps1 before creating a new active handover."
    }

    $activePreviousEntry = Get-HandoverEntryByResolvedPath -Entries $activeEntries -ResolvedPath $resolvedPreviousHandover
    if ($null -eq $activePreviousEntry) {
      throw "Previous handover must be inside the active handover directory for this scope"
    }

    if ($activePreviousEntry.NormalizedTaskLabel -ne $normalizedTaskLabel) {
      throw "Previous handover must have the same Task label"
    }

    if ($activePreviousEntry.NormalizedWorkspaceRoot -ne $normalizedWorkspaceRoot) {
      throw "Previous handover must have the same Workspace root"
    }

    if ($activePreviousEntry.NormalizedBranch -ne $normalizedBranch) {
      throw "Previous handover must have the same Branch"
    }

    $PreviousHandover = $resolvedPreviousHandover
  }
}

if ([string]::IsNullOrWhiteSpace($PreviousHandover)) {
  $previousFile = $activeEntries |
    Where-Object {
      ($_.NormalizedTaskLabel -eq $normalizedTaskLabel) -and
      ($_.NormalizedWorkspaceRoot -eq $normalizedWorkspaceRoot) -and
      ($_.NormalizedBranch -eq $normalizedBranch)
    } |
    Select-Object -First 1
  if ($null -ne $previousFile) {
    $PreviousHandover = $previousFile.Path
  } else {
    $archivedMatch = $archivedEntries |
      Where-Object {
        ($_.NormalizedTaskLabel -eq $normalizedTaskLabel) -and
        ($_.NormalizedWorkspaceRoot -eq $normalizedWorkspaceRoot) -and
        ($_.NormalizedBranch -eq $normalizedBranch)
      } |
      Select-Object -First 1

    if ($null -ne $archivedMatch) {
      throw "Task label '$normalizedTaskLabel' exists only in archive for this scope. Run restore-handover-scope.ps1 before creating a new active handover."
    }

    $PreviousHandover = "No prior handover found"
  }
}

$PreviousHandover = $PreviousHandover -replace '\\', '/'

$template = Get-Content -Raw -LiteralPath $templatePath
$content = $template `
  -replace '\{\{TIMESTAMP\}\}', (Get-Date -Format "yyyy-MM-dd HH:mm") `
  -replace '\{\{TASK_LABEL\}\}', $normalizedTaskLabel `
  -replace '\{\{WORKSPACE_ROOT\}\}', $normalizedWorkspaceRoot `
  -replace '\{\{BRANCH\}\}', $normalizedBranch `
  -replace '\{\{PREVIOUS_HANDOVER\}\}', $PreviousHandover

Set-Content -LiteralPath $outputPath -Value $content -Encoding UTF8
Write-Host $outputPath

