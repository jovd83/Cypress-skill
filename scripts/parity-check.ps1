param(
  [string]$SourceRoot = "..\Playwright-skill",
  [string]$TargetRoot = ".",
  [switch]$RequireSource
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $SourceRoot)) {
  if ($RequireSource) {
    throw "Source root not found: $SourceRoot"
  }

  Write-Host "parity-check: SKIPPED (source not found at $SourceRoot)"
  return
}

$srcAbs = (Resolve-Path -LiteralPath $SourceRoot).Path
$dstAbs = (Resolve-Path -LiteralPath $TargetRoot).Path

function Get-RelativeMarkdownPaths([string]$RootPath) {
  Get-ChildItem -Path $RootPath -Recurse -File -Filter *.md |
    ForEach-Object { $_.FullName.Substring($RootPath.Length + 1).Replace('\', '/') }
}

$srcSet = Get-RelativeMarkdownPaths $srcAbs |
  ForEach-Object {
    $_ -replace '^playwright-cli/', 'cypress-cli/' `
       -replace '^migration/from-cypress\.md$', 'migration/from-playwright.md' `
       -replace '^cypress-cli/tracing-and-debugging\.md$', 'cypress-cli/debugging-and-artifacts.md'
  } |
  Sort-Object -Unique

$dstSet = Get-RelativeMarkdownPaths $dstAbs | Sort-Object -Unique
$diff = Compare-Object -ReferenceObject $srcSet -DifferenceObject $dstSet

$missing = $diff | Where-Object { $_.SideIndicator -eq "<=" } | Select-Object -ExpandProperty InputObject
$extra = $diff | Where-Object { $_.SideIndicator -eq "=>" } | Select-Object -ExpandProperty InputObject

if ($missing.Count -gt 0 -or $extra.Count -gt 0) {
  Write-Host "parity-check failed"
  Write-Host "missing=$($missing.Count)"
  $missing | ForEach-Object { Write-Host "- missing: $_" }
  Write-Host "extra=$($extra.Count)"
  $extra | ForEach-Object { Write-Host "- extra: $_" }
  throw "parity-check failed"
}

Write-Host "parity-check: OK (missing=0, extra=0)"
