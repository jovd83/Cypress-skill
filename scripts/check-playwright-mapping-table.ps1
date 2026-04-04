param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"
$rootAbs = (Resolve-Path -LiteralPath $Root).Path
$target = Join-Path $rootAbs "migration/from-playwright.md"

if (-not (Test-Path -LiteralPath $target -PathType Leaf)) {
  throw "check-playwright-mapping-table failed: missing file 'migration/from-playwright.md'"
}

$text = Get-Content -Raw -LiteralPath $target
  $text = $text -replace "`r", ""
$match = [regex]::Match($text, '(?ms)^## Command Mapping\s*(?<section>.*?)(^\#\#\s|\z)')
if (-not $match.Success) {
  throw "check-playwright-mapping-table failed: missing '## Command Mapping' section"
}

$section = $match.Groups["section"].Value
$lines = $section -split "`r?`n"
$issues = @()

for ($i = 0; $i -lt $lines.Count; $i++) {
  $line = $lines[$i]
  if ($line -notmatch '^\|') { continue }
  if ($line -match '^\|\s*-') { continue }
  if ($line -match '^\|\s*Playwright\s*\|') { continue }

  if ($line -match '^\|\s*`cy\.') {
    $issues += [pscustomobject]@{
      Line = $i + 1
      Text = $line.Trim()
      Reason = "Cypress command detected in Playwright column"
    }
  }
}

if ($issues.Count -gt 0) {
  Write-Host "check-playwright-mapping-table failed with $($issues.Count) issue(s)"
  $issues | ForEach-Object {
    Write-Host ("- command-mapping line {0}: {1} :: {2}" -f $_.Line, $_.Reason, $_.Text)
  }
  throw "check-playwright-mapping-table failed"
}

Write-Host "check-playwright-mapping-table: OK"
