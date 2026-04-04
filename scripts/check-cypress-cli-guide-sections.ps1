param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"
$rootAbs = (Resolve-Path -LiteralPath $Root).Path
$cliDir = Join-Path $rootAbs "cypress-cli"

if (-not (Test-Path -LiteralPath $cliDir -PathType Container)) {
  throw "check-cypress-cli-guide-sections failed: missing cypress-cli directory"
}

$issues = @()
$files = Get-ChildItem -Path $cliDir -File -Filter *.md | Where-Object { $_.Name -ne "SKILL.md" }

foreach ($file in $files) {
  $rel = $file.FullName.Substring($rootAbs.Length + 1).Replace('\', '/')
  $text = Get-Content -Raw -LiteralPath $file.FullName
  $text = $text -replace "\r", ""
  $missing = @()

  if ($text -notmatch '(?m)^> \*\*When to use\*\*:') {
    $missing += "When to use"
  }
  if ($text -notmatch '(?m)^> \*\*Prerequisites\*\*:') {
    $missing += "Prerequisites"
  }
  if ($text -notmatch '(?m)^## Anti-Patterns|^## Anti-patterns') {
    $missing += "Anti-Patterns"
  }

  if ($missing.Count -gt 0) {
    $issues += [pscustomobject]@{
      File = $rel
      Missing = ($missing -join ", ")
    }
  }
}

if ($issues.Count -gt 0) {
  Write-Host "check-cypress-cli-guide-sections failed with $($issues.Count) file(s)"
  $issues | ForEach-Object {
    Write-Host ("- {0}: missing {1}" -f $_.File, $_.Missing)
  }
  throw "check-cypress-cli-guide-sections failed"
}

Write-Host ("check-cypress-cli-guide-sections: OK ({0} cypress-cli guides)" -f $files.Count)
