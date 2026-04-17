param(
  [string]$Root = ".",
  [string]$SourceRoot = "..\Playwright-skill",
  [switch]$StrictResidue,
  [switch]$RequireParitySource,
  [switch]$Verbose
)

$ErrorActionPreference = "Stop"
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$failures = 0

function Invoke-Check([string]$Name, [scriptblock]$Check) {
  Write-Host "==> $Name"
  try {
    & $Check
    Write-Host "PASS: $Name"
  } catch {
    Write-Host "FAIL: $Name"
    Write-Host $_.Exception.Message
    $script:failures++
  }
}

Invoke-Check -Name "Markdown link integrity" -Check {
  & "$scriptRoot\check-links.ps1" -Root $Root
}

Invoke-Check -Name "Quality gate check coverage" -Check {
  & "$scriptRoot\check-quality-gate-coverage.ps1" -Root $Root
}

Invoke-Check -Name "Quality gate integrity" -Check {
  & "$scriptRoot\check-quality-gate-integrity.ps1" -Root $Root
}

Invoke-Check -Name "Check-script conventions" -Check {
  & "$scriptRoot\check-check-script-conventions.ps1" -Root $Root
}

Invoke-Check -Name "Text integrity (mojibake scan)" -Check {
  & "$scriptRoot\check-text-integrity.ps1" -Root $Root
}

Invoke-Check -Name "Playwright spelling sanity" -Check {
  & "$scriptRoot\check-playwright-spelling.ps1" -Root $Root
}

Invoke-Check -Name "Markdown structural integrity" -Check {
  & "$scriptRoot\check-markdown-structure.ps1" -Root $Root
}

Invoke-Check -Name "Fenced code language tags" -Check {
  & "$scriptRoot\check-fenced-code-language-tags.ps1" -Root $Root
}

Invoke-Check -Name "Code fence language policy by directory" -Check {
  & "$scriptRoot\check-code-fence-language-policy.ps1" -Root $Root
}

Invoke-Check -Name "CLI snippet command smoke check" -Check {
  & "$scriptRoot\snippet-smoke-check.ps1" -Root $Root
}

Invoke-Check -Name "CLI Bash/PowerShell workflow parity" -Check {
  & "$scriptRoot\shell-example-parity-check.ps1" -Root $Root
}

Invoke-Check -Name "Cypress command queue safety patterns" -Check {
  & "$scriptRoot\check-command-queue-safety.ps1" -Root $Root
}

Invoke-Check -Name "No hard waits in runnable code examples" -Check {
  & "$scriptRoot\check-hard-waits-in-code.ps1" -Root $Root
}

Invoke-Check -Name "Force-true usage context" -Check {
  & "$scriptRoot\check-force-true-context.ps1" -Root $Root
}

Invoke-Check -Name "Agents metadata coverage and validity" -Check {
  & "$scriptRoot\check-agents-metadata.ps1" -Root $Root
}

Invoke-Check -Name "Agents metadata sync drift check" -Check {
  & "$scriptRoot\sync-agents-metadata.ps1" -Root $Root -CheckOnly
}

Invoke-Check -Name "Skill inventory freshness" -Check {
  & "$scriptRoot\check-skill-inventory-freshness.ps1" -Root $Root
}

Invoke-Check -Name "Skill inventory report structure" -Check {
  & "$scriptRoot\check-skill-inventory-report-structure.ps1" -Root $Root
}

Invoke-Check -Name "Skill index coverage (local guides linked)" -Check {
  & "$scriptRoot\check-skill-index-coverage.ps1" -Root $Root
}

Invoke-Check -Name "Long-form guide contract" -Check {
  & "$scriptRoot\check-long-form-guide-contract.ps1" -Root $Root
}

Invoke-Check -Name "Core guide section contract" -Check {
  & "$scriptRoot\check-core-guide-sections.ps1" -Root $Root
}

Invoke-Check -Name "Cypress-cli guide section contract" -Check {
  & "$scriptRoot\check-cypress-cli-guide-sections.ps1" -Root $Root
}

Invoke-Check -Name "CI and POM guide section contract" -Check {
  & "$scriptRoot\check-ci-pom-guide-sections.ps1" -Root $Root
}

Invoke-Check -Name "Migration guide section contract" -Check {
  & "$scriptRoot\check-migration-guide-sections.ps1" -Root $Root
}

Invoke-Check -Name "Migration example language parity" -Check {
  & "$scriptRoot\check-migration-example-language-parity.ps1" -Root $Root
}

Invoke-Check -Name "Migration alias/wait pairing" -Check {
  & "$scriptRoot\check-migration-alias-wait-pairing.ps1" -Root $Root
}

Invoke-Check -Name "Playwright migration mapping table sanity" -Check {
  & "$scriptRoot\check-playwright-mapping-table.ps1" -Root $Root
}

Invoke-Check -Name "Migration source-column purity" -Check {
  & "$scriptRoot\check-migration-source-column-purity.ps1" -Root $Root
}

Invoke-Check -Name "Migration source-example purity" -Check {
  & "$scriptRoot\check-migration-source-example-purity.ps1" -Root $Root
}

Invoke-Check -Name "Documentation skill section contract" -Check {
  & "$scriptRoot\check-documentation-skill-sections.ps1" -Root $Root
}

Invoke-Check -Name "Cypress handover package contract" -Check {
  & "$scriptRoot\check-cypress-handover-package.ps1" -Root $Root
}

Invoke-Check -Name "Cypress handover package smoke" -Check {
  & "$scriptRoot\check-cypress-handover-smoke.ps1" -Root $Root
}

Invoke-Check -Name "Cypress handover Pester suite" -Check {
  & "$scriptRoot\check-cypress-handover-pester.ps1" -Root $Root -Verbose:$Verbose
}

Invoke-Check -Name "Planning/reporting skill section contract" -Check {
  & "$scriptRoot\check-planning-reporting-skill-sections.ps1" -Root $Root
}

Invoke-Check -Name "Test-management integration skill section contract" -Check {
  & "$scriptRoot\check-tm-integration-skill-sections.ps1" -Root $Root
}

Invoke-Check -Name "Installer skill section contract" -Check {
  & "$scriptRoot\check-installer-skill-sections.ps1" -Root $Root
}

Invoke-Check -Name "Installer command canonical form" -Check {
  & "$scriptRoot\check-installer-command-canonical.ps1" -Root $Root
}

Invoke-Check -Name "Official Cypress references in entry skills" -Check {
  & "$scriptRoot\check-official-cypress-references.ps1" -Root $Root
}

Invoke-Check -Name "Skill frontmatter integrity" -Check {
  & "$scriptRoot\check-skill-frontmatter.ps1" -Root $Root
}

Invoke-Check -Name "Skill name prefix convention" -Check {
  & "$scriptRoot\check-skill-name-prefix.ps1" -Root $Root
}

Invoke-Check -Name "Skill description Cypress convention" -Check {
  & "$scriptRoot\check-skill-description-cypress.ps1" -Root $Root
}

Invoke-Check -Name "CI workflow quality gate wiring" -Check {
  & "$scriptRoot\check-ci-workflow.ps1" -Root $Root
}

Invoke-Check -Name "Release workflow contract" -Check {
  & "$scriptRoot\check-release-workflow-contract.ps1" -Root $Root
}

Invoke-Check -Name "Playwright residue policy" -Check {
  if ($StrictResidue) {
    & "$scriptRoot\scan-residue.ps1" -Root $Root -Strict
  } else {
    & "$scriptRoot\scan-residue.ps1" -Root $Root
  }
}

Invoke-Check -Name "Structural parity with Playwright-skill" -Check {
  if ($RequireParitySource) {
    & "$scriptRoot\parity-check.ps1" -SourceRoot $SourceRoot -TargetRoot $Root -RequireSource
  } else {
    & "$scriptRoot\parity-check.ps1" -SourceRoot $SourceRoot -TargetRoot $Root
  }
}

if ($failures -gt 0) {
  throw "quality-gate failed with $failures failing check(s)"
}

Write-Host "quality-gate: OK (all checks passed)"
