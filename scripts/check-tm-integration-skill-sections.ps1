param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"
$rootAbs = (Resolve-Path -LiteralPath $Root).Path
$issues = @()

$directories = @(
  "mappers",
  "transformers",
  "reporters"
)

$files = @()
foreach ($dir in $directories) {
  $absDir = Join-Path $rootAbs $dir
  if (-not (Test-Path -LiteralPath $absDir -PathType Container)) {
    throw "check-tm-integration-skill-sections failed: missing directory '$dir'"
  }

  $files += Get-ChildItem -Path $absDir -Recurse -File -Filter SKILL.md
}

if ($files.Count -eq 0) {
  throw "check-tm-integration-skill-sections failed: no SKILL.md files found"
}

foreach ($file in $files) {
  $rel = $file.FullName.Substring($rootAbs.Length + 1).Replace('\', '/')
  $text = Get-Content -Raw -LiteralPath $file.FullName
  $text = $text -replace "`r", ""
  $missing = @()

  if ($text -notmatch '(?m)^# .+') {
    $missing += "Header"
  }

  if ($text -notmatch '(?m)^## Action') {
    $missing += "Action"
  }

  if ($missing.Count -gt 0) {
    $issues += [pscustomobject]@{
      File = $rel
      Missing = ($missing -join ", ")
    }
  }
}

if ($issues.Count -gt 0) {
  Write-Host "check-tm-integration-skill-sections failed with $($issues.Count) file(s)"
  $issues | ForEach-Object {
    Write-Host ("- {0}: missing {1}" -f $_.File, $_.Missing)
  }
  throw "check-tm-integration-skill-sections failed"
}

Write-Host ("check-tm-integration-skill-sections: OK ({0} skill docs)" -f $files.Count)
