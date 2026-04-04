param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"
$rootAbs = (Resolve-Path -LiteralPath $Root).Path
$reportPath = Join-Path $rootAbs "reports/skill-inventory.md"

if (-not (Test-Path -LiteralPath $reportPath -PathType Leaf)) {
  throw "check-skill-inventory-report-structure failed: missing reports/skill-inventory.md"
}

$text = Get-Content -Raw -LiteralPath $reportPath
  $text = $text -replace "\r", ""
$issues = @()

$requiredPatterns = @(
  "Header::(?m)^# Skill Inventory\s*$",
  "Summary::(?m)^## Summary\s*$",
  "Coverage By Area::(?m)^## Coverage By Area\s*$",
  "Skill Table::(?m)^## Skill Table\s*$",
  "Summary Total Skills::(?m)^- Total skills: `\d+`\s*$",
  "Summary Metadata Coverage::(?m)^- Skills with `agents/openai\.yaml`: `\d+/\d+`\s*$",
  "Coverage Table Header::(?m)^\| Area \| Skills \| Metadata Coverage \|\s*$",
  "Skill Table Header::(?m)^\| Path \| Skill Name \| Display Name \| Area \| Metadata \|\s*$"
)

foreach ($rule in $requiredPatterns) {
  $label = $rule.Split("::")[0]
  $pattern = $rule.Split("::")[1]
  if ($text -notmatch $pattern) {
    $issues += "missing $label"
  }
}

$skillCount = (Get-ChildItem -Path $rootAbs -Recurse -File -Filter SKILL.md).Count
$lines = Get-Content -LiteralPath $reportPath
$skillTableIndex = -1
for ($i = 0; $i -lt $lines.Count; $i++) {
  if ($lines[$i] -match '^## Skill Table\s*$') {
    $skillTableIndex = $i
    break
  }
}

$tableLines = @()
if ($skillTableIndex -ge 0) {
  for ($i = $skillTableIndex + 1; $i -lt $lines.Count; $i++) {
    $line = $lines[$i].Trim()
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    if ($line -notmatch '^\|') { break }
    if ($line -match '^\|---') { continue }
    if ($line -eq '| Path | Skill Name | Display Name | Area | Metadata |') { continue }
    $tableLines += $line
  }
}

if ($tableLines.Count -ne $skillCount) {
  $issues += ("skill table row count mismatch: expected {0}, found {1}" -f $skillCount, $tableLines.Count)
}

$metadataFiles = @(
  Get-ChildItem -Path $rootAbs -Recurse -File -Filter openai.yaml |
    Where-Object { $_.FullName -match [regex]::Escape([System.IO.Path]::DirectorySeparatorChar + "agents" + [System.IO.Path]::DirectorySeparatorChar + "openai.yaml") }
)

$summaryMatch = [regex]::Match($text, '(?m)^- Skills with `agents/openai\.yaml`: `(?<count>\d+)/(?<total>\d+)`\s*$')
if ($summaryMatch.Success) {
  $summaryCount = [int]$summaryMatch.Groups["count"].Value
  $summaryTotal = [int]$summaryMatch.Groups["total"].Value
  if ($summaryCount -ne $metadataFiles.Count) {
    $issues += ("metadata summary count mismatch: expected {0}, found {1}" -f $metadataFiles.Count, $summaryCount)
  }
  if ($summaryTotal -ne $skillCount) {
    $issues += ("summary total mismatch: expected {0}, found {1}" -f $skillCount, $summaryTotal)
  }
}

if ($issues.Count -gt 0) {
  Write-Host "check-skill-inventory-report-structure failed with $($issues.Count) issue(s)"
  $issues | ForEach-Object { Write-Host ("- " + $_) }
  throw "check-skill-inventory-report-structure failed"
}

Write-Host ("check-skill-inventory-report-structure: OK ({0} skill rows)" -f $skillCount)
