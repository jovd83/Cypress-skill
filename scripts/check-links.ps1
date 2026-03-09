param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"
$rootAbs = (Resolve-Path -LiteralPath $Root).Path
$pattern = '\[[^\]]+\]\(([^)]+)\)'
$broken = @()

$mdFiles = Get-ChildItem -Path $rootAbs -Recurse -File -Filter *.md
foreach ($file in $mdFiles) {
  $lines = Get-Content -LiteralPath $file.FullName
  for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    [regex]::Matches($line, $pattern) | ForEach-Object {
      $raw = $_.Groups[1].Value.Trim()
      if ($raw -match '^<(.+)>$') {
        $raw = $Matches[1].Trim()
      }

      if ($raw -match '^(https?:|mailto:|#|data:|cci:)') { return }

      $pathPart = $raw.Split('#')[0].Trim()
      if ([string]::IsNullOrWhiteSpace($pathPart)) { return }
      if ($pathPart -match '^".*"$') { return }

      $resolved = Join-Path $file.DirectoryName $pathPart
      if (-not (Test-Path -LiteralPath $resolved)) {
        $rel = $file.FullName.Substring($rootAbs.Length + 1).Replace('\', '/')
        $broken += [pscustomobject]@{
          File = $rel
          Line = $i + 1
          Link = $raw
        }
      }
    }
  }
}

if ($broken.Count -gt 0) {
  Write-Host "Broken markdown links found: $($broken.Count)"
  $broken | ForEach-Object {
    Write-Host ("- {0}:{1} -> {2}" -f $_.File, $_.Line, $_.Link)
  }
  throw "check-links failed"
}

Write-Host "check-links: OK ($($mdFiles.Count) markdown files scanned)"
