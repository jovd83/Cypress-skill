param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"
$rootAbs = (Resolve-Path -LiteralPath $Root).Path
$issues = @()

$contracts = @(
  @{ File = "core/authentication.md"; Rules = @("Quick Reference::(?m)^## Quick Reference", "Decision Guide::(?m)^## Decision Guide", "Troubleshooting::(?m)^## Troubleshooting", "Related::(?m)^## Related") },
  @{ File = "core/network-mocking.md"; Rules = @("Quick Reference::(?m)^## Quick Reference", "Anti-Patterns::(?m)^## Anti-Patterns|^## Anti-patterns", "Troubleshooting::(?m)^## Troubleshooting", "Related::(?m)^## Related") },
  @{ File = "core/assertions-and-waiting.md"; Rules = @("Quick Reference::(?m)^## Quick Reference", "Decision Guide::(?m)^## Decision Guide", "Troubleshooting::(?m)^## Troubleshooting", "Related::(?m)^## Related") },
  @{ File = "core/locators.md"; Rules = @("Quick Reference::(?m)^## Quick Reference", "Decision Guide::(?m)^## Decision Guide", "Troubleshooting::(?m)^## Troubleshooting", "Related::(?m)^## Related") },
  @{ File = "ci/ci-github-actions.md"; Rules = @("Quick Reference::(?m)^## Quick Reference", "Troubleshooting::(?m)^## Troubleshooting", "Related::(?m)^## Related") },
  @{ File = "ci/docker-and-containers.md"; Rules = @("Quick Reference::(?m)^## Quick Reference", "Troubleshooting::(?m)^## Troubleshooting", "Related::(?m)^## Related") },
  @{ File = "ci/parallel-and-sharding.md"; Rules = @("Quick Reference::(?m)^## Quick Reference", "Troubleshooting::(?m)^## Troubleshooting", "Related::(?m)^## Related") },
  @{ File = "ci/reporting-and-artifacts.md"; Rules = @("Troubleshooting::(?m)^## Troubleshooting", "Related::(?m)^## Related") },
  @{ File = "cypress-cli/core-commands.md"; Rules = @("Quick Reference::(?m)^## Quick Reference", "Anti-Patterns::(?m)^## Anti-Patterns|^## Anti-patterns", "Troubleshooting::(?m)^## Troubleshooting", "Related::(?m)^## Related") },
  @{ File = "cypress-cli/request-mocking.md"; Rules = @("Quick Reference::(?m)^## Quick Reference", "Anti-Patterns::(?m)^## Anti-Patterns|^## Anti-patterns", "Troubleshooting::(?m)^## Troubleshooting", "Related::(?m)^## Related") },
  @{ File = "cypress-cli/running-custom-code.md"; Rules = @("Quick Reference::(?m)^## Quick Reference", "Anti-Patterns::(?m)^## Anti-Patterns|^## Anti-patterns", "Troubleshooting::(?m)^## Troubleshooting", "Related::(?m)^## Related") },
  @{ File = "cypress-cli/debugging-and-artifacts.md"; Rules = @("Quick Reference::(?m)^## Quick Reference", "Anti-Patterns::(?m)^## Anti-Patterns|^## Anti-patterns", "Troubleshooting::(?m)^## Troubleshooting", "Related::(?m)^## Related") },
  @{ File = "cypress-cli/session-management.md"; Rules = @("Quick Reference::(?m)^## Quick Reference", "Anti-Patterns::(?m)^## Anti-Patterns|^## Anti-patterns", "Troubleshooting::(?m)^## Troubleshooting", "Related::(?m)^## Related") }
)

foreach ($contract in $contracts) {
  $path = Join-Path $rootAbs $contract.File
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    $issues += [pscustomobject]@{ File = $contract.File; Missing = "file" }
    continue
  }

  $text = Get-Content -Raw -LiteralPath $path
  $text = $text -replace "\r", ""
  $missing = @()
  foreach ($rule in $contract.Rules) {
    $label = $rule.Split("::")[0]
    $pattern = $rule.Split("::")[1]
    if ($text -notmatch $pattern) {
      $missing += $label
    }
  }

  if ($missing.Count -gt 0) {
    $issues += [pscustomobject]@{
      File = $contract.File
      Missing = ($missing -join ", ")
    }
  }
}

if ($issues.Count -gt 0) {
  Write-Host "check-long-form-guide-contract failed with $($issues.Count) file(s)"
  $issues | ForEach-Object {
    Write-Host ("- {0}: missing {1}" -f $_.File, $_.Missing)
  }
  throw "check-long-form-guide-contract failed"
}

Write-Host ("check-long-form-guide-contract: OK ({0} files)" -f $contracts.Count)
