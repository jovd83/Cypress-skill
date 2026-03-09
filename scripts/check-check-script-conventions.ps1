param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"
$rootAbs = (Resolve-Path -LiteralPath $Root).Path
$scriptsDir = Join-Path $rootAbs "scripts"
$issues = @()

if (-not (Test-Path -LiteralPath $scriptsDir -PathType Container)) {
  throw "check-check-script-conventions failed: missing scripts directory"
}

$files = Get-ChildItem -Path $scriptsDir -File -Filter "check-*.ps1"
if ($files.Count -eq 0) {
  throw "check-check-script-conventions failed: no check scripts found"
}

foreach ($file in $files) {
  $text = Get-Content -Raw -LiteralPath $file.FullName

  $paramBlockMatch = [regex]::Match($text, '(?s)^param\((?<block>.*?)\)')
  $hasParamRoot = $false
  if ($paramBlockMatch.Success) {
    $paramBlock = $paramBlockMatch.Groups["block"].Value
    $hasParamRoot = $paramBlock -match '\[string\]\$Root\s*=\s*"\."'
  }
  $hasFailFast = $text -match '\$ErrorActionPreference\s*=\s*("Stop"|''Stop'')'

  if (-not $hasParamRoot) {
    $issues += [pscustomobject]@{
      File = $file.Name
      Issue = 'missing Root param with default "." in param(...) block'
    }
  }

  if (-not $hasFailFast) {
    $issues += [pscustomobject]@{
      File = $file.Name
      Issue = 'missing fail-fast setting: $ErrorActionPreference = "Stop"'
    }
  }
}

if ($issues.Count -gt 0) {
  Write-Host "check-check-script-conventions failed with $($issues.Count) issue(s)"
  $issues | ForEach-Object {
    Write-Host ("- {0}: {1}" -f $_.File, $_.Issue)
  }
  throw "check-check-script-conventions failed"
}

Write-Host ("check-check-script-conventions: OK ({0} check scripts)" -f $files.Count)
