param(
  [Parameter(Mandatory = $true)]
  [string]$TaskLabel,
  [Parameter(Mandatory = $true)]
  [string]$ValidationNote,
  [string]$DocsRoot = "docs/tests",
  [string]$WorkspaceRoot = "",
  [string]$Branch = "",
  [string]$CompletionSummary = "Completed the task and captured the final handover state.",
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
  $pattern = '(?m)^- ' + [regex]::Escape($Label) + ':\s*.+$'
  $replacement = ('- {0}: {1}' -f $Label, $Value)
  return [regex]::Replace($Markdown, $pattern, $replacement, 1)
}

function Replace-SectionBody([string]$Markdown, [string]$Heading, [string]$Body) {
  $pattern = '(?sm)^' + [regex]::Escape($Heading) + '\s*.*?(?=^### |\z)'
  $replacement = $Heading + "`r`n" + $Body.Trim() + "`r`n`r`n"
  return [regex]::Replace($Markdown, $pattern, $replacement, 1)
}

$validatorScript = Join-Path $PSScriptRoot "validate-handover.ps1"
if (-not (Test-Path -LiteralPath $validatorScript -PathType Leaf)) {
  throw "Validator script not found: $validatorScript"
}

$handoverDir = Join-Path $DocsRoot "handovers"
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
      throw "Archived handover scopes exist for task label '$TaskLabel'. Rerun with -WorkspaceRoot and/or -Branch, then run restore-handover-scope.ps1 before completing."
    }
    throw "Task label '$TaskLabel' exists only in archive. Run restore-handover-scope.ps1 before completing this scope."
  }

  throw "No handover found for task label '$TaskLabel' in $handoverDir"
}

$scopeCount = @($candidates | Group-Object ScopeKey).Count
if (($scopeCount -gt 1) -and [string]::IsNullOrWhiteSpace($normalizedWorkspaceRoot) -and [string]::IsNullOrWhiteSpace($normalizedBranch)) {
  throw "Multiple handover scopes found for task label '$TaskLabel'. Rerun with -WorkspaceRoot and/or -Branch to complete one scope."
}

$selected = $candidates | Select-Object -First 1
$sourceText = Get-Content -Raw -LiteralPath $selected.Path

$timestampFile = Get-Date -Format "yyyyMMdd_HHmm"
$outputPath = Join-Path $handoverDir ("{0}_CypressSkillHandover.md" -f $timestampFile)
if ((Test-Path -LiteralPath $outputPath) -and (-not $Force)) {
  throw "Completed handover already exists: $outputPath"
}

$newTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
$whatWasDone = Get-SectionBody -Markdown $sourceText -Heading "### What was done"
$validationBody = Get-SectionBody -Markdown $sourceText -Heading "### Validation and evidence"

if ([string]::IsNullOrWhiteSpace($whatWasDone)) {
  $whatWasDone = $CompletionSummary
} else {
  $whatWasDone = ($whatWasDone.TrimEnd('.') + ". " + $CompletionSummary.Trim())
}

if ([string]::IsNullOrWhiteSpace($validationBody)) {
  $validationBody = $ValidationNote.Trim()
} else {
  $validationBody = ($validationBody.TrimEnd('.') + ". " + $ValidationNote.Trim())
}

$updatedText = $sourceText
$updatedText = Replace-MetadataLine -Markdown $updatedText -Label "Timestamp" -Value $newTimestamp
$updatedText = Replace-MetadataLine -Markdown $updatedText -Label "Previous handover" -Value ($selected.Path -replace '\\', '/')
$updatedText = Replace-SectionBody -Markdown $updatedText -Heading "### Current status" -Body "Completed"
$updatedText = Replace-SectionBody -Markdown $updatedText -Heading "### What was done" -Body $whatWasDone
$updatedText = Replace-SectionBody -Markdown $updatedText -Heading "### In progress" -Body "None."
$updatedText = Replace-SectionBody -Markdown $updatedText -Heading "### Remaining work" -Body "None."
$updatedText = Replace-SectionBody -Markdown $updatedText -Heading "### Blockers and open questions" -Body "None."
$updatedText = Replace-SectionBody -Markdown $updatedText -Heading "### Next action" -Body "No further action required. Task is complete."
$updatedText = Replace-SectionBody -Markdown $updatedText -Heading "### How to resume" -Body "No resume action is required. Reopen the task only if a new regression or follow-up scope appears."
$updatedText = Replace-SectionBody -Markdown $updatedText -Heading "### Validation and evidence" -Body $validationBody

Set-Content -LiteralPath $outputPath -Value $updatedText -Encoding UTF8

try {
  & $validatorScript -Path $outputPath | Out-Null
} catch {
  Remove-Item -LiteralPath $outputPath -Force -ErrorAction SilentlyContinue
  throw
}

Write-Host $outputPath
