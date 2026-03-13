param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"
$rootAbs = (Resolve-Path -LiteralPath $Root).Path
$workflowRel = ".github/workflows/quality-gate.yml"
$workflowPath = Join-Path $rootAbs $workflowRel

if (-not (Test-Path -LiteralPath $workflowPath)) {
  throw "check-ci-workflow failed: missing $workflowRel"
}

$content = Get-Content -Raw -LiteralPath $workflowPath
$issues = @()

if ($content -notmatch '(?m)^\s*pull_request:\s*$') {
  $issues += "missing pull_request trigger"
}
if ($content -notmatch '(?m)^\s*push:\s*$') {
  $issues += "missing push trigger"
}
if ($content -notmatch '(?m)^\s*shell:\s*pwsh\s*$') {
  $issues += "missing pwsh shell for gate step"
}
if ($content -notmatch '(?m)^\s*run:\s*\./scripts/quality-gate\.ps1\s*$') {
  $issues += "missing run command './scripts/quality-gate.ps1'"
}
if ($content -notmatch '(?m)^\s*run:\s*\./scripts/check-cypress-handover-pester\.ps1(?:\s+.+)?\s*$') {
  $issues += "missing run command './scripts/check-cypress-handover-pester.ps1'"
}
if ($content -notmatch '(?m)^\s*-\s*name:\s*Ensure Pester\s*$') {
  $issues += "missing Ensure Pester step"
}
if ($content -notmatch '(?m)^\s*uses:\s*actions/upload-artifact@v4\s*$') {
  $issues += "missing upload-artifact step for Cypress handover Pester results"
}

if ($issues.Count -gt 0) {
  Write-Host "check-ci-workflow failed with $($issues.Count) issue(s)"
  $issues | ForEach-Object { Write-Host ("- " + $_) }
  throw "check-ci-workflow failed"
}

Write-Host "check-ci-workflow: OK"
