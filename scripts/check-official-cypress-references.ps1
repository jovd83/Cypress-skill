param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"
$rootAbs = (Resolve-Path -LiteralPath $Root).Path
$issues = @()

$requiredUrl = "https://docs.cypress.io/guides/references/best-practices"
$targets = @(
  "SKILL.md",
  "core/SKILL.md",
  "cypress-cli/SKILL.md",
  "ci/SKILL.md",
  "migration/SKILL.md"
)

foreach ($relative in $targets) {
  $path = Join-Path $rootAbs $relative
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    $issues += [pscustomobject]@{
      File = $relative
      Issue = "missing file"
    }
    continue
  }

  $text = Get-Content -Raw -LiteralPath $path
  $text = $text -replace "\r", ""
  if ($text -notmatch [regex]::Escape($requiredUrl)) {
    $issues += [pscustomobject]@{
      File = $relative
      Issue = "missing official best-practices URL"
    }
  }
}

if ($issues.Count -gt 0) {
  Write-Host "check-official-cypress-references failed with $($issues.Count) issue(s)"
  $issues | ForEach-Object {
    Write-Host ("- {0}: {1}" -f $_.File, $_.Issue)
  }
  throw "check-official-cypress-references failed"
}

Write-Host ("check-official-cypress-references: OK ({0} files)" -f $targets.Count)
