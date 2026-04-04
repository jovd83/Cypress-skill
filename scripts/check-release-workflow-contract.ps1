param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"
$rootAbs = (Resolve-Path -LiteralPath $Root).Path
$workflowPath = Join-Path $rootAbs ".github/workflows/release.yml"

if (-not (Test-Path -LiteralPath $workflowPath -PathType Leaf)) {
  throw "check-release-workflow-contract failed: missing .github/workflows/release.yml"
}

$text = Get-Content -Raw -LiteralPath $workflowPath
$issues = @()

$requiredPatterns = @(
  "Workflow Name::(?m)^name:\s*release\s*$",
  "Push Trigger::(?m)^\s*push:\s*$",
  'Tag Trigger::(?m)^\s*-\s*"v\*"\s*$',
  "Workflow Dispatch::(?m)^\s*workflow_dispatch:\s*$",
  "Contents Write Permission::(?m)^\s*contents:\s*write\s*$",
  "Ensure Pester Step::(?m)^\s*-\s*name:\s*Ensure Pester\s*$",
  "Preflight Step::(?m)^\s*run:\s*\./scripts/preflight\.ps1\s*$",
  "Upload Artifact Action::(?m)^\s*uses:\s*actions/upload-artifact@v4\s*$",
  "GitHub Release Action::(?m)^\s*uses:\s*softprops/action-gh-release@v2\s*$",
  "Release Notes Enabled::(?m)^\s*generate_release_notes:\s*true\s*$"
)

foreach ($rule in $requiredPatterns) {
  $label = $rule.Split("::")[0]
  $pattern = $rule.Split("::")[1]
  if ($text -notmatch $pattern) {
    $issues += "missing $label"
  }
}

$expectedArtifactInputs = @(
  "./README.md",
  "./SKILL.md",
  "./CHANGELOG.md",
  "./CONTRIBUTING.md",
  "./LICENSE",
  "./reports",
  "./scripts",
  "./tests"
)

foreach ($item in $expectedArtifactInputs) {
  if ($text -notmatch [regex]::Escape($item)) {
    $issues += ("release artifact package is missing expected path {0}" -f $item)
  }
}

if ($issues.Count -gt 0) {
  Write-Host "check-release-workflow-contract failed with $($issues.Count) issue(s)"
  $issues | ForEach-Object { Write-Host ("- " + $_) }
  throw "check-release-workflow-contract failed"
}

Write-Host "check-release-workflow-contract: OK"
