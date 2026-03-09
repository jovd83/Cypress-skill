param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"
$rootAbs = (Resolve-Path -LiteralPath $Root).Path
$issues = @()

# Common mojibake artifacts seen when UTF-8 text is decoded with a legacy code page.
# Use Unicode escapes to keep this script ASCII-safe.
$artifactPattern = '(\u00E2\u20AC\u201D|\u00E2\u20AC\u201C|\u00E2\u20AC|\u00C3|\uFFFD|\u00C2)'

$files = Get-ChildItem -Path $rootAbs -Recurse -File | Where-Object {
  $_.Extension -in @(".md", ".yaml", ".yml", ".ps1")
}

foreach ($file in $files) {
  $rel = $file.FullName.Substring($rootAbs.Length + 1).Replace('\', '/')
  $lines = Get-Content -LiteralPath $file.FullName
  for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    if ($line -match $artifactPattern) {
      $issues += [pscustomobject]@{
        File = $rel
        Line = $i + 1
        Text = $line.Trim()
      }
    }
  }
}

if ($issues.Count -gt 0) {
  Write-Host "check-text-integrity failed with $($issues.Count) issue(s)"
  $issues | ForEach-Object {
    Write-Host ("- {0}:{1} :: {2}" -f $_.File, $_.Line, $_.Text)
  }
  throw "check-text-integrity failed"
}

Write-Host ("check-text-integrity: OK ({0} files scanned)" -f $files.Count)
