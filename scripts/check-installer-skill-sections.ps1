param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"
$rootAbs = (Resolve-Path -LiteralPath $Root).Path
$issues = @()

$installerDir = Join-Path $rootAbs "installers"
if (-not (Test-Path -LiteralPath $installerDir -PathType Container)) {
  throw "check-installer-skill-sections failed: missing directory 'installers'"
}

$files = Get-ChildItem -Path $installerDir -Recurse -File -Filter SKILL.md
if ($files.Count -eq 0) {
  throw "check-installer-skill-sections failed: no installer SKILL.md files found"
}

foreach ($file in $files) {
  $rel = $file.FullName.Substring($rootAbs.Length + 1).Replace('\', '/')
  $text = Get-Content -Raw -LiteralPath $file.FullName
  $text = $text -replace "\r", ""
  $missing = @()

  if ($text -notmatch '(?m)^# .+Installation') {
    $missing += "Header"
  }

  if ($text -notmatch '(?m)^## Prerequisites') {
    $missing += "Prerequisites"
  }

  if ($text -notmatch '(?m)^## Installation Steps') {
    $missing += "Installation Steps"
  }

  if ($missing.Count -gt 0) {
    $issues += [pscustomobject]@{
      File = $rel
      Missing = ($missing -join ", ")
    }
  }
}

if ($issues.Count -gt 0) {
  Write-Host "check-installer-skill-sections failed with $($issues.Count) file(s)"
  $issues | ForEach-Object {
    Write-Host ("- {0}: missing {1}" -f $_.File, $_.Missing)
  }
  throw "check-installer-skill-sections failed"
}

Write-Host ("check-installer-skill-sections: OK ({0} installer skills)" -f $files.Count)
