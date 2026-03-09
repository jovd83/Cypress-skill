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
  $inFence = $false

  for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    $trim = $line.Trim()

    if ($trim -match '^```') {
      if (-not $inFence) {
        # Opening fence must include a language token.
        if ($trim -match '^```\s*$') {
          $issues += [pscustomobject]@{
            File = $rel
            Line = $i + 1
            Text = $trim
          }
        }
        $inFence = $true
      } else {
        $inFence = $false
      }
    }
  }
}

if ($issues.Count -gt 0) {
  Write-Host "check-fenced-code-language-tags failed with $($issues.Count) issue(s)"
  $issues | ForEach-Object {
    Write-Host ("- {0}:{1} :: opening fence missing language tag" -f $_.File, $_.Line)
  }
  throw "check-fenced-code-language-tags failed"
}

Write-Host ("check-fenced-code-language-tags: OK ({0} markdown files scanned)" -f $files.Count)
