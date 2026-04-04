param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"
$rootAbs = (Resolve-Path -LiteralPath $Root).Path
$coreDir = Join-Path $rootAbs "core"

if (-not (Test-Path -LiteralPath $coreDir -PathType Container)) {
  throw "check-core-guide-sections failed: missing core directory"
}

$issues = @()
$files = Get-ChildItem -Path $coreDir -File -Filter *.md | Where-Object { $_.Name -ne "SKILL.md" }

foreach ($file in $files) {
  $rel = $file.FullName.Substring($rootAbs.Length + 1).Replace('\', '/')
  $text = Get-Content -Raw -LiteralPath $file.FullName
  $text = $text -replace "\r", ""
  $missing = @()

  if ($text -notmatch '(?m)^> \*\*When to use\*\*:') {
    $missing += "When to use"
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
  Write-Host "check-core-guide-sections failed with $($issues.Count) file(s)"
  $issues | ForEach-Object {
    Write-Host ("- {0}: missing {1}" -f $_.File, $_.Missing)
  }
  throw "check-core-guide-sections failed"
}

Write-Host ("check-core-guide-sections: OK ({0} core guides)" -f $files.Count)
