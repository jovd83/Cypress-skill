param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"
$rootAbs = (Resolve-Path -LiteralPath $Root).Path
$reportPath = Join-Path $rootAbs "reports/skill-inventory.md"

if (-not (Test-Path -LiteralPath $reportPath -PathType Leaf)) {
  throw "check-skill-inventory-freshness failed: missing reports/skill-inventory.md"
}

$tempPath = [System.IO.Path]::GetTempFileName()

try {
  & (Join-Path $rootAbs "scripts/generate-skill-inventory.ps1") -Root $rootAbs -OutputPath $tempPath | Out-Null

  $expected = Get-Content -Raw -LiteralPath $tempPath
  $expected = $expected -replace "`r", ""
  
  $actual = Get-Content -Raw -LiteralPath $reportPath
  $actual = $actual -replace "`r", ""

  if ($expected -ne $actual) {
    # If they still don't match, show the temp path for debugging in some context? No, just throw.
    throw "reports/skill-inventory.md is stale; regenerate it with powershell -NoProfile -File .\scripts\generate-skill-inventory.ps1"
  }
} finally {
  if (Test-Path -LiteralPath $tempPath) {
    Remove-Item -LiteralPath $tempPath -Force
  }
}

Write-Host "check-skill-inventory-freshness: OK"
