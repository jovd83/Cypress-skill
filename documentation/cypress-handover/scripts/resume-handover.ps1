param(
  [Parameter(Mandatory = $true)]
  [string]$TaskLabel,
  [Parameter(Mandatory = $true)]
  [string]$ProgressNote,
  [Parameter(Mandatory = $true)]
  [string]$NextAction,
  [string]$DocsRoot = "docs/tests",
  [string]$WorkspaceRoot = "",
  [string]$Branch = "",
  [ValidateSet("In progress", "Blocked", "Awaiting approval")]
  [string]$Status = "In progress",
  [string]$BlockersNote = "",
  [string]$RemainingWorkNote = "",
  [string]$ValidationNote = "",
  [switch]$Force
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
  $text = Get-Content -Raw -LiteralPath $Path`n  $text = $text -replace "`r", ""
  $pattern = '(?mi)^(?:\s*-\s*|\s*)' + [regex]::Escape($Label) + ':\s*(?<value>.+)$'
  $match = [regex]::Match($text, $pattern)
  if (-not $match.Success) { return "" }
  return $match.Groups["value"].Value.Trim()
}

function Get-SectionBody([string]$Markdown, [string]$Heading) {
  if ([string]::IsNullOrWhiteSpace($Markdown)) { return "" }
  $pattern = '(?smi)^' + [regex]::Escape($Heading) + '\s*(?<body>.*?)(?=^### |\z)'
  $match = [regex]::Match($Markdown, $pattern)
  if (-not $match.Success) { return "" }
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

function Get-HandoverEntries([string]$SearchDir) {
  if (-not (Test-Path -LiteralPath $SearchDir -PathType Container)) {
    return @()
  }

  return @(
    Get-ChildItem -LiteralPath $SearchDir -File -Filter "*_CypressSkillHandover.md" | ForEach-Object {
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
}

function Replace-MetadataLine([string]$Markdown, [string]$Label, [string]$Value) {
  $pattern = '(?mi)^(?:\s*-\s*|\s*)' + [regex]::Escape($Label) + ':\s*.+$'
  $replacement = ('- {0}: {1}' -f $Label, $Value)
  return [regex]::Replace($Markdown, $pattern, $replacement, 1)
}

function Replace-SectionBody([string]$Markdown, [string]$Heading, [string]$Body) {
  $pattern = '(?sm)^' + [regex]::Escape($Heading) + '\s*.*?(?=^### |\z)'
  $replacement = $Heading + "`r`n" + $Body.Trim() + "`r`n`r`n"
  return [regex]::Replace($Markdown, $pattern, $replacement, 1)
}

function Append-Sentence([string]$Existing, [string]$NewText) {
  if ([string]::IsNullOrWhiteSpace($Existing)) {
    return $NewText.Trim()
  }

  if ([string]::IsNullOrWhiteSpace($NewText)) {
    return $Existing.Trim()
  }

  return ($Existing.Trim().TrimEnd('.') + ". " + $NewText.Trim())
}

$validatorScript = Join-Path $PSScriptRoot "validate-handover.ps1"
if (-not (Test-Path -LiteralPath $validatorScript -PathType Leaf)) {
  throw "Validator script not found: $validatorScript"
}

$resolvedDocsRoot = Get-ResolvedPath $DocsRoot
$handoverDir = Join-Path $resolvedDocsRoot "handovers"
if (-not (Test-Path -LiteralPath $handoverDir -PathType Container)) {
  throw "Handover directory not found: $handoverDir"
}
$archiveDir = Join-Path $handoverDir "archive"

$normalizedTaskLabel = Normalize-TaskLabel -Value $TaskLabel
if ([string]::IsNullOrWhiteSpace($normalizedTaskLabel)) {
  throw "Task label must contain at least one lowercase letter or digit after normalization"
}

$normalizedWorkspaceRoot = Normalize-WorkspaceRoot -Value $WorkspaceRoot
$normalizedBranch = Normalize-Branch -Value $Branch

$candidates = @(Get-HandoverEntries -SearchDir $handoverDir)

$candidates = @($candidates | Where-Object { $_.NormalizedTaskLabel -eq $normalizedTaskLabel })
if (-not [string]::IsNullOrWhiteSpace($normalizedWorkspaceRoot)) {
  $candidates = @($candidates | Where-Object { $_.NormalizedWorkspaceRoot -eq $normalizedWorkspaceRoot })
}
if (-not [string]::IsNullOrWhiteSpace($normalizedBranch)) {
  $candidates = @($candidates | Where-Object { $_.NormalizedBranch -eq $normalizedBranch })
}

if ($candidates.Count -eq 0) {
  $archivedCandidates = @(Get-HandoverEntries -SearchDir $archiveDir | Where-Object { $_.NormalizedTaskLabel -eq $normalizedTaskLabel })
  if (-not [string]::IsNullOrWhiteSpace($normalizedWorkspaceRoot)) {
    $archivedCandidates = @($archivedCandidates | Where-Object { $_.NormalizedWorkspaceRoot -eq $normalizedWorkspaceRoot })
  }
  if (-not [string]::IsNullOrWhiteSpace($normalizedBranch)) {
    $archivedCandidates = @($archivedCandidates | Where-Object { $_.NormalizedBranch -eq $normalizedBranch })
  }

  if ($archivedCandidates.Count -gt 0) {
    $archivedScopeCount = @($archivedCandidates | Group-Object ScopeKey).Count
    if (($archivedScopeCount -gt 1) -and [string]::IsNullOrWhiteSpace($normalizedWorkspaceRoot) -and [string]::IsNullOrWhiteSpace($normalizedBranch)) {
      throw "Archived handover scopes exist for task label '$TaskLabel'. Rerun with -WorkspaceRoot and/or -Branch, then run restore-handover-scope.ps1 before resuming."
    }
    throw "Task label '$TaskLabel' exists only in archive. Run restore-handover-scope.ps1 before resuming this scope."
  }

  throw "No handover found for task label '$TaskLabel' in $handoverDir"
}

$scopeCount = @($candidates | Group-Object ScopeKey).Count
if (($scopeCount -gt 1) -and [string]::IsNullOrWhiteSpace($normalizedWorkspaceRoot) -and [string]::IsNullOrWhiteSpace($normalizedBranch)) {
  throw "Multiple handover scopes found for task label '$TaskLabel'. Rerun with -WorkspaceRoot and/or -Branch to resume one scope."
}

$selected = $candidates | Select-Object -First 1
$sourceText = Get-Content -Raw -LiteralPath $selected.Path

$timestampFile = Get-Date -Format "yyyyMMdd_HHmm"
$outputPath = Join-Path $handoverDir ("{0}_CypressSkillHandover.md" -f $timestampFile)
if ((Test-Path -LiteralPath $outputPath) -and (-not $Force)) {
  throw "Resumed handover already exists: $outputPath"
}

$newTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
$whatWasDone = Append-Sentence -Existing (Get-SectionBody -Markdown $sourceText -Heading "### What was done") -NewText $ProgressNote
$validationBody = Get-SectionBody -Markdown $sourceText -Heading "### Validation and evidence"
if (-not [string]::IsNullOrWhiteSpace($ValidationNote)) {
  $validationBody = Append-Sentence -Existing $validationBody -NewText $ValidationNote
}

$inProgressBody = if ($Status -eq "In progress") {
  $ProgressNote.Trim()
} else {
  "None."
}

$blockersBody = Get-SectionBody -Markdown $sourceText -Heading "### Blockers and open questions"
if (-not [string]::IsNullOrWhiteSpace($BlockersNote)) {
  $blockersBody = $BlockersNote.Trim()
} elseif ($Status -eq "Blocked" -and [string]::IsNullOrWhiteSpace($blockersBody)) {
  $blockersBody = "Blocked. See next action for the required unblock step."
} elseif ($Status -ne "Blocked" -and [string]::IsNullOrWhiteSpace($blockersBody)) {
  $blockersBody = "None."
}

$remainingWorkBody = Get-SectionBody -Markdown $sourceText -Heading "### Remaining work"
if (-not [string]::IsNullOrWhiteSpace($RemainingWorkNote)) {
  $remainingWorkBody = $RemainingWorkNote.Trim()
}

$updatedText = $sourceText
$updatedText = Replace-MetadataLine -Markdown $updatedText -Label "Timestamp" -Value $newTimestamp
$updatedText = Replace-MetadataLine -Markdown $updatedText -Label "Previous handover" -Value ($selected.Path -replace '\\', '/')
$updatedText = Replace-SectionBody -Markdown $updatedText -Heading "### Current status" -Body $Status
$updatedText = Replace-SectionBody -Markdown $updatedText -Heading "### What was done" -Body $whatWasDone
$updatedText = Replace-SectionBody -Markdown $updatedText -Heading "### In progress" -Body $inProgressBody
$updatedText = Replace-SectionBody -Markdown $updatedText -Heading "### Remaining work" -Body $remainingWorkBody
$updatedText = Replace-SectionBody -Markdown $updatedText -Heading "### Blockers and open questions" -Body $blockersBody
$updatedText = Replace-SectionBody -Markdown $updatedText -Heading "### Next action" -Body $NextAction.Trim()
$updatedText = Replace-SectionBody -Markdown $updatedText -Heading "### Validation and evidence" -Body $validationBody

Set-Content -LiteralPath $outputPath -Value $updatedText -Encoding UTF8

try {
  & $validatorScript -Path $outputPath | Out-Null
} catch {
  Remove-Item -LiteralPath $outputPath -Force -ErrorAction SilentlyContinue
  throw
}

Write-Host $outputPath



