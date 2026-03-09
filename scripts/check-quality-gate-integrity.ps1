param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"
$rootAbs = (Resolve-Path -LiteralPath $Root).Path
$scriptsDir = Join-Path $rootAbs "scripts"
$qualityGatePath = Join-Path $scriptsDir "quality-gate.ps1"

if (-not (Test-Path -LiteralPath $qualityGatePath -PathType Leaf)) {
  throw "check-quality-gate-integrity failed: missing scripts/quality-gate.ps1"
}

$text = Get-Content -Raw -LiteralPath $qualityGatePath
$issues = @()

# 1) Invoke-Check names must be unique and non-empty.
$nameMatches = [regex]::Matches($text, 'Invoke-Check\s+-Name\s+"(?<name>[^"]+)"')
$names = @($nameMatches | ForEach-Object { $_.Groups["name"].Value.Trim() })

if ($names.Count -eq 0) {
  $issues += "no Invoke-Check entries found"
} else {
  $emptyNames = @($names | Where-Object { [string]::IsNullOrWhiteSpace($_) })
  if ($emptyNames.Count -gt 0) {
    $issues += "one or more Invoke-Check entries have an empty name"
  }

  $duplicateNames = @(
    $names |
      Group-Object |
      Where-Object { $_.Count -gt 1 } |
      Select-Object -ExpandProperty Name
  )
  foreach ($dup in $duplicateNames) {
    $issues += ("duplicate Invoke-Check name: {0}" -f $dup)
  }
}

# 2) Every check script must be invoked exactly once in quality-gate.
$checkScripts = Get-ChildItem -Path $scriptsDir -File -Filter "check-*.ps1" | Select-Object -ExpandProperty Name
foreach ($scriptName in $checkScripts) {
  $count = ([regex]::Matches($text, [regex]::Escape($scriptName))).Count
  if ($count -eq 0) {
    $issues += ("missing check script invocation: {0}" -f $scriptName)
  } elseif ($count -gt 1) {
    $issues += ("duplicate check script invocation: {0} (count={1})" -f $scriptName, $count)
  }
}

if ($issues.Count -gt 0) {
  Write-Host "check-quality-gate-integrity failed with $($issues.Count) issue(s)"
  $issues | ForEach-Object {
    Write-Host ("- {0}" -f $_)
  }
  throw "check-quality-gate-integrity failed"
}

Write-Host ("check-quality-gate-integrity: OK ({0} checks, {1} check scripts)" -f $names.Count, $checkScripts.Count)
