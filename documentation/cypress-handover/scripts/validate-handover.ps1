param(
  [Parameter(Mandatory = $true)]
  [string]$Path
)

$ErrorActionPreference = "Stop"

function Get-HandoverMetadataValue([string]$Markdown, [string]$Label) {
  if ([string]::IsNullOrWhiteSpace($Markdown)) { return "" }
  $Markdown = $Markdown -replace "`r", ""
  $pattern = '(?mi)^(?:\s*-\s*|\s*)' + [regex]::Escape($Label) + ':\s*(?<value>.+)$'
  $match = [regex]::Match($Markdown, $pattern)
  if (-not $match.Success) { return "" }
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

function Get-SectionBody([string]$Markdown, [string]$Heading) {
  if ([string]::IsNullOrWhiteSpace($Markdown)) { return "" }
  $Markdown = $Markdown -replace "`r", ""
  $pattern = '(?smi)^' + [regex]::Escape($Heading) + '\s*(?<body>.*?)(?=^### |\z)'
  $match = [regex]::Match($Markdown, $pattern)
  if (-not $match.Success) { return "" }
  return $match.Groups["body"].Value.Trim()
}

function Normalize-SectionBody([string]$Body) {
  if ($null -eq $Body) { return "" }
  return (($Body -replace '\s+', ' ').Trim())
}

function Normalize-TaskLabel([string]$Value) {
  if ($null -eq $Value) { return "" }
  $normalized = $Value.Trim().ToLowerInvariant()
  $normalized = $normalized -replace '[^a-z0-9]+', '-'
  $normalized = $normalized -replace '-{2,}', '-'
  return $normalized.Trim('-')
}

function Test-TaskLabelFormat([string]$Value) {
  if ([string]::IsNullOrWhiteSpace($Value)) {
    return $false
  }

  if ($Value.Length -gt 64) {
    return $false
  }

  return ($Value -cmatch '^[a-z0-9]+(?:-[a-z0-9]+)*$')
}

function Normalize-WorkspaceRoot([string]$Value) {
  if ($null -eq $Value) { return "" }
  $normalized = (($Value -replace '\\', '/').Trim())
  return $normalized.TrimEnd('/').ToLowerInvariant()
}

function Parse-HandoverTimestamp([string]$Value, [string]$ContextLabel) {
  if ([string]::IsNullOrWhiteSpace($Value)) {
    throw ("validate-handover failed: {0} timestamp must not be empty" -f $ContextLabel)
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
    throw ("validate-handover failed: {0} timestamp must use yyyy-MM-dd HH:mm" -f $ContextLabel)
  }

  return $parsed
}

function Assert-PreviousHandoverChain(
  [string]$CurrentPath,
  [string]$TaskLabel,
  [string]$PreviousHandover,
  [string]$WorkspaceRoot,
  [string]$Branch,
  [datetime]$CurrentTimestamp
) {
  $noPriorValue = "No prior handover found"
  if ($PreviousHandover -eq $noPriorValue) {
    return
  }

  $visited = New-Object 'System.Collections.Generic.HashSet[string]'
  $currentResolvedPathCanonical = Get-ResolvedPath ((Resolve-Path -LiteralPath $CurrentPath).Path)
  [void]$visited.Add($currentResolvedPathCanonical)
  $expectedWorkspaceRoot = Normalize-WorkspaceRoot -Value $WorkspaceRoot
  $expectedBranch = (($Branch -replace '\s+', ' ').Trim()).ToLowerInvariant()
  $newerTimestamp = $CurrentTimestamp

  $nextPath = $PreviousHandover
  while ($nextPath -ne $noPriorValue) {
    $nextPathNormalized = $nextPath -replace '\\', '/'
    if (-not (Test-Path -LiteralPath $nextPathNormalized -PathType Leaf)) {
      throw "validate-handover failed: Previous handover path does not exist"
    }

    $resolvedPath = Resolve-HandoverLink -ContainingFilePath $currentResolvedPathCanonical -LinkValue $nextPath
    if ($visited.Contains($resolvedPath)) {
      throw "validate-handover failed: Previous handover chain contains a cycle"
    }
    [void]$visited.Add($resolvedPath)

    $previousText = Get-Content -Raw -LiteralPath $resolvedPath
    $previousTaskLabel = Get-HandoverMetadataValue -Markdown $previousText -Label "Task label"
    if ((Normalize-TaskLabel -Value $previousTaskLabel) -ne (Normalize-TaskLabel -Value $TaskLabel)) {
      throw "validate-handover failed: Previous handover must have the same Task label"
    }

    $previousWorkspaceRoot = Get-HandoverMetadataValue -Markdown $previousText -Label "Workspace root"
    if ((Normalize-WorkspaceRoot -Value $previousWorkspaceRoot) -ne $expectedWorkspaceRoot) {
      throw "validate-handover failed: Previous handover must have the same Workspace root"
    }

    $previousBranch = Get-HandoverMetadataValue -Markdown $previousText -Label "Branch"
    if ((($previousBranch -replace '\s+', ' ').Trim()).ToLowerInvariant() -ne $expectedBranch) {
      throw "validate-handover failed: Previous handover must have the same Branch"
    }

    $previousTimestamp = Get-HandoverMetadataValue -Markdown $previousText -Label "Timestamp"
    $parsedPreviousTimestamp = Parse-HandoverTimestamp -Value $previousTimestamp -ContextLabel "Previous handover"
    if ($parsedPreviousTimestamp -ge $newerTimestamp) {
      throw "validate-handover failed: Previous handover chain must move backward in time"
    }
    $newerTimestamp = $parsedPreviousTimestamp

    $nextPath = Get-HandoverMetadataValue -Markdown $previousText -Label "Previous handover"
    if ([string]::IsNullOrWhiteSpace($nextPath)) {
      throw "validate-handover failed: Previous handover chain contains a missing ancestor link"
    }
  }
}

function Test-LowSignalBody([string]$Body) {
  $normalized = (Normalize-SectionBody -Body $Body).ToLowerInvariant()
  if ([string]::IsNullOrWhiteSpace($normalized)) {
    return $true
  }

  $patterns = @(
    '^(tbd|todo|to do)\.?$',
    '^(n/?a|na)\.?$',
    '^pending\.?$',
    '^later\.?$',
    '^unknown\.?$',
    '^not sure\.?$',
    '^same as above\.?$',
    '^see above\.?$',
    '^not run\.?$'
  )

  foreach ($pattern in $patterns) {
    if ($normalized -match $pattern) {
      return $true
    }
  }

  return $false
}

if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
  throw "Handover file not found: $Path"
}

$text = Get-Content -Raw -LiteralPath $Path`n  $text = $text -replace "`r", ""
$requiredMetadataLines = @(
  "- Timestamp:",
  "- Task label:",
  "- Workspace root:",
  "- Branch:",
  "- Previous handover:"
)

$missingMetadata = @()
foreach ($metadataLine in $requiredMetadataLines) {
  $cleanLabel = $metadataLine -replace "^- ", ""
  if ($text -notmatch ("(?mi)^(?:\s*-\s*|\s*)" + [regex]::Escape($cleanLabel) + "\s+.+$")) {
    $missingMetadata += $metadataLine
  }
}

if ($missingMetadata.Count -gt 0) {
  Write-Host "validate-handover failed: missing metadata lines"
  $missingMetadata | ForEach-Object { Write-Host ("- {0}" -f $_) }
  throw "validate-handover failed"
}

$requiredHeadings = @(
  "### Task summary",
  "### Current status",
  "### What was done",
  "### In progress",
  "### Remaining work",
  "### Blockers and open questions",
  "### Next action",
  "### Session state",
  "### How to resume",
  "### Validation and evidence",
  "### Skills and subskills used",
  "### Non-skill actions and suggestions",
  "### Patterns used",
  "### Anti-patterns used",
  "### Strengths of the changes",
  "### Weaknesses of the changes",
  "### Improvements",
  "### Files added/modified"
)

$missing = @()
foreach ($heading in $requiredHeadings) {
  if ($text -notmatch ("(?mi)^" + [regex]::Escape($heading) + "\s*$")) {
    $missing += $heading
  }
}

if ($missing.Count -gt 0) {
  Write-Host "validate-handover failed: missing headings"
  $missing | ForEach-Object { Write-Host ("- {0}" -f $_) }
  throw "validate-handover failed"
}

if ($text -match '\{\{[A-Z0-9_]+\}\}') {
  throw "validate-handover failed: unresolved template placeholders remain"
}

$workspaceMetadata = [regex]::Match($text, '(?mi)^(?:\s*-\s*|\s*)Workspace root:\s*(?<value>.+)$')
if (-not $workspaceMetadata.Success -or [string]::IsNullOrWhiteSpace($workspaceMetadata.Groups["value"].Value.Trim())) {
  throw "validate-handover failed: Workspace root must not be empty"
}

$currentTimestampRaw = Get-HandoverMetadataValue -Markdown $text -Label "Timestamp"
$currentTimestamp = Parse-HandoverTimestamp -Value $currentTimestampRaw -ContextLabel "Current handover"

$taskLabel = Get-HandoverMetadataValue -Markdown $text -Label "Task label"
if ([string]::IsNullOrWhiteSpace($taskLabel)) {
  throw "validate-handover failed: Task label must not be empty"
}
if (-not (Test-TaskLabelFormat -Value $taskLabel)) {
  throw "validate-handover failed: Task label must use lowercase letters, digits, and hyphens only"
}
if ((Normalize-TaskLabel -Value $taskLabel) -ne $taskLabel) {
  throw "validate-handover failed: Task label must already be normalized"
}

$branchMetadata = [regex]::Match($text, '(?mi)^(?:\s*-\s*|\s*)Branch:\s*(?<value>.+)$')
if (-not $branchMetadata.Success -or [string]::IsNullOrWhiteSpace($branchMetadata.Groups["value"].Value.Trim())) {
  throw "validate-handover failed: Branch must not be empty"
}

$previousHandover = Get-HandoverMetadataValue -Markdown $text -Label "Previous handover"
if ([string]::IsNullOrWhiteSpace($previousHandover)) {
  throw "validate-handover failed: Previous handover must not be empty"
}

Assert-PreviousHandoverChain `
  -CurrentPath $Path `
  -TaskLabel $taskLabel `
  -PreviousHandover $previousHandover `
  -WorkspaceRoot $workspaceMetadata.Groups["value"].Value.Trim() `
  -Branch $branchMetadata.Groups["value"].Value.Trim() `
  -CurrentTimestamp $currentTimestamp

$statusMatch = [regex]::Match(
  $text,
  '(?smi)^### Current status\s*(?<body>.*?)^\s*### '
)

if (-not $statusMatch.Success) {
  throw "validate-handover failed: could not parse Current status section"
}

$statusBody = ($statusMatch.Groups["body"].Value -replace '\s+', ' ').Trim()
$allowedStatuses = @("Completed", "In progress", "Blocked", "Awaiting approval")

if (-not ($allowedStatuses | Where-Object { $statusBody -match ("(?i)\b" + [regex]::Escape($_) + "\b") })) {
  throw "validate-handover failed: Current status must include one of Completed, In progress, Blocked, or Awaiting approval"
}

$sectionRules = @(
  @{ Heading = "### Task summary"; Label = "Task summary"; MinimumLength = 20; AllowLowSignal = $false },
  @{ Heading = "### What was done"; Label = "What was done"; MinimumLength = 20; AllowLowSignal = $false },
  @{ Heading = "### Next action"; Label = "Next action"; MinimumLength = 15; AllowLowSignal = $false },
  @{ Heading = "### Session state"; Label = "Session state"; MinimumLength = 20; AllowLowSignal = $false },
  @{ Heading = "### How to resume"; Label = "How to resume"; MinimumLength = 20; AllowLowSignal = $false },
  @{ Heading = "### Validation and evidence"; Label = "Validation and evidence"; MinimumLength = 15; AllowLowSignal = $false }
)

foreach ($rule in $sectionRules) {
  $body = Get-SectionBody -Markdown $text -Heading $rule.Heading
  $normalizedBody = Normalize-SectionBody -Body $body
  if ($normalizedBody.Length -lt $rule.MinimumLength) {
    throw ("validate-handover failed: {0} is too short to be useful" -f $rule.Label)
  }
  if ((-not $rule.AllowLowSignal) -and (Test-LowSignalBody -Body $body)) {
    throw ("validate-handover failed: {0} contains low-signal filler" -f $rule.Label)
  }
}

$fileCategoryRules = @(
  "Documentation",
  "POMs",
  "Test scripts",
  "Configurations",
  "Other"
)

foreach ($category in $fileCategoryRules) {
  $match = [regex]::Match($text, '(?mi)^(?:\s*-\s*|\s*)' + [regex]::Escape($category) + ':\s*(?<value>.+)$')
  if (-not $match.Success) {
    throw ("validate-handover failed: Files added/modified missing category '{0}'" -f $category)
  }

  $value = Normalize-SectionBody -Body $match.Groups["value"].Value
  if ([string]::IsNullOrWhiteSpace($value)) {
    throw ("validate-handover failed: Files added/modified category '{0}' must not be empty" -f $category)
  }

  $allowedNone = ($value -match '^(?i)none\.?$')
  if ((-not $allowedNone) -and (Test-LowSignalBody -Body $value)) {
    throw ("validate-handover failed: Files added/modified category '{0}' contains low-signal filler" -f $category)
  }
}

Write-Verbose "validate-handover: OK"




