param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"
$rootAbs = (Resolve-Path -LiteralPath $Root).Path
$issues = @()

$files = Get-ChildItem -Path $rootAbs -Recurse -File -Filter *.md
foreach ($file in $files) {
  $rel = $file.FullName.Substring($rootAbs.Length + 1).Replace('\', '/')
  $lines = Get-Content -LiteralPath $file.FullName
  for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '(?i)\bplayswright\b') {
      $issues += [pscustomobject]@{
        File = $rel
        Line = $i + 1
        Text = $lines[$i].Trim()
      }
    }
  }
}

if ($issues.Count -gt 0) {
  Write-Host "check-playwright-spelling failed with $($issues.Count) issue(s)"
  $issues | ForEach-Object {
    Write-Host ("- {0}:{1} :: {2}" -f $_.File, $_.Line, $_.Text)
  }
  throw "check-playwright-spelling failed"
}

Write-Host ("check-playwright-spelling: OK ({0} markdown files scanned)" -f $files.Count)
