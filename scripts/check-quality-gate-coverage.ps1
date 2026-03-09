param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"
$rootAbs = (Resolve-Path -LiteralPath $Root).Path
$scriptsDir = Join-Path $rootAbs "scripts"
$qualityGatePath = Join-Path $scriptsDir "quality-gate.ps1"

if (-not (Test-Path -LiteralPath $qualityGatePath -PathType Leaf)) {
  throw "check-quality-gate-coverage failed: missing scripts/quality-gate.ps1"
}

$qualityGateText = Get-Content -Raw -LiteralPath $qualityGatePath
$checkScripts = Get-ChildItem -Path $scriptsDir -File -Filter "check-*.ps1"
$missing = @()

foreach ($script in $checkScripts) {
  if ($qualityGateText -notmatch [regex]::Escape($script.Name)) {
    $missing += $script.Name
  }
}

if ($missing.Count -gt 0) {
  Write-Host "check-quality-gate-coverage failed with $($missing.Count) missing check(s)"
  $missing | Sort-Object | ForEach-Object {
    Write-Host ("- {0}" -f $_)
  }
  throw "check-quality-gate-coverage failed"
}

Write-Host ("check-quality-gate-coverage: OK ({0} check scripts wired)" -f $checkScripts.Count)
