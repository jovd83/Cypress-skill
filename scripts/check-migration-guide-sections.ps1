param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"
$rootAbs = (Resolve-Path -LiteralPath $Root).Path
$issues = @()

$migrationDir = Join-Path $rootAbs "migration"
if (-not (Test-Path -LiteralPath $migrationDir -PathType Container)) {
  throw "check-migration-guide-sections failed: missing directory 'migration'"
}

$requiredPatterns = @(
  "When to use::(?m)^> \*\*When to use\*\*:",
  "Prerequisites::(?m)^> \*\*Prerequisites\*\*:",
  "Anti-Patterns::(?m)^## Anti-Patterns|^## Anti-patterns",
  "Checklist::(?m)^## Checklist"
)

$files = Get-ChildItem -Path $migrationDir -File -Filter *.md | Where-Object { $_.Name -ne "SKILL.md" }
foreach ($file in $files) {
  $rel = $file.FullName.Substring($rootAbs.Length + 1).Replace('\', '/')
  $text = Get-Content -Raw -LiteralPath $file.FullName
  $text = $text -replace "`r", ""
  $missing = @()

  foreach ($rule in $requiredPatterns) {
    $label = $rule.Split("::")[0]
    $pattern = $rule.Split("::")[1]
    if ($text -notmatch $pattern) {
      $missing += $label
    }
  }

  if ($missing.Count -gt 0) {
    $issues += [pscustomobject]@{
      File = $rel
      Missing = ($missing -join ", ")
    }
  }
}

if ($issues.Count -gt 0) {
  Write-Host "check-migration-guide-sections failed with $($issues.Count) file(s)"
  $issues | ForEach-Object {
    Write-Host ("- {0}: missing {1}" -f $_.File, $_.Missing)
  }
  throw "check-migration-guide-sections failed"
}

Write-Host ("check-migration-guide-sections: OK ({0} migration guides)" -f $files.Count)
