param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"
$rootAbs = (Resolve-Path -LiteralPath $Root).Path
$issues = @()

$migrationDir = Join-Path $rootAbs "migration"
if (-not (Test-Path -LiteralPath $migrationDir -PathType Container)) {
  throw "check-migration-example-language-parity failed: missing directory 'migration'"
}

$files = Get-ChildItem -Path $migrationDir -File -Filter *.md | Where-Object { $_.Name -ne "SKILL.md" }
foreach ($file in $files) {
  $rel = $file.FullName.Substring($rootAbs.Length + 1).Replace('\', '/')
  $text = Get-Content -Raw -LiteralPath $file.FullName
  $text = $text -replace "`r", ""

  $sectionMatches = [regex]::Matches($text, '(?ms)^## Example:.*?(?=^## |\z)')
  if ($sectionMatches.Count -eq 0) {
    $issues += [pscustomobject]@{
      File = $rel
      Section = "<none>"
      Missing = "Example sections"
    }
    continue
  }

  foreach ($section in $sectionMatches) {
    $sectionText = $section.Value
    $headerMatch = [regex]::Match($sectionText, '(?m)^## Example:\s*(.+)$')
    $header = if ($headerMatch.Success) { $headerMatch.Groups[1].Value.Trim() } else { "<unknown>" }
    $missing = @()

    if ($sectionText -notmatch '(?s)\*\*Cypress \(TypeScript\)\*\*\s*```typescript') {
      $missing += "Cypress (TypeScript) fenced block"
    }

    if ($sectionText -notmatch '(?s)\*\*Cypress \(JavaScript\)\*\*\s*```javascript') {
      $missing += "Cypress (JavaScript) fenced block"
    }

    if ($missing.Count -gt 0) {
      $issues += [pscustomobject]@{
        File = $rel
        Section = $header
        Missing = ($missing -join ", ")
      }
    }
  }
}

if ($issues.Count -gt 0) {
  Write-Host "check-migration-example-language-parity failed with $($issues.Count) issue(s)"
  $issues | ForEach-Object {
    Write-Host ("- {0} [Example: {1}] missing {2}" -f $_.File, $_.Section, $_.Missing)
  }
  throw "check-migration-example-language-parity failed"
}

Write-Host ("check-migration-example-language-parity: OK ({0} migration guides)" -f $files.Count)
