param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"
$rootAbs = (Resolve-Path -LiteralPath $Root).Path
$issues = @()

$targets = @(
  "migration/from-playwright.md",
  "migration/from-selenium.md"
)

foreach ($relative in $targets) {
  $path = Join-Path $rootAbs $relative
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    $issues += [pscustomobject]@{
      File = $relative
      Line = 0
      Issue = "missing file"
      Text = ""
    }
    continue
  }

  $text = Get-Content -Raw -LiteralPath $path
  $section = [regex]::Match($text, '(?ms)^## Command Mapping\s*(?<body>.*?)(?=^## |\z)')
  if (-not $section.Success) {
    $issues += [pscustomobject]@{
      File = $relative
      Line = 0
      Issue = "missing '## Command Mapping' section"
      Text = ""
    }
    continue
  }

  $body = $section.Groups["body"].Value
  $lines = $body -split "`r?`n"
  for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    if ($line -notmatch '^\|') { continue }
    if ($line -match '^\|\s*-') { continue }
    if ($line -match '^\|\s*(Playwright|Selenium)\s*\|') { continue }

    $cells = $line.Split('|')
    if ($cells.Count -lt 3) { continue }
    $sourceColumn = $cells[1].Trim()

    if ($sourceColumn -match '(^|`)cy\.[A-Za-z_]') {
      $issues += [pscustomobject]@{
        File = $relative
        Line = $i + 1
        Issue = "source-framework column contains Cypress command"
        Text = $line.Trim()
      }
    }
  }
}

if ($issues.Count -gt 0) {
  Write-Host "check-migration-source-column-purity failed with $($issues.Count) issue(s)"
  $issues | ForEach-Object {
    if ($_.Line -gt 0) {
      Write-Host ("- {0}:{1} :: {2} :: {3}" -f $_.File, $_.Line, $_.Issue, $_.Text)
    } else {
      Write-Host ("- {0} :: {1}" -f $_.File, $_.Issue)
    }
  }
  throw "check-migration-source-column-purity failed"
}

Write-Host ("check-migration-source-column-purity: OK ({0} migration guides)" -f $targets.Count)
