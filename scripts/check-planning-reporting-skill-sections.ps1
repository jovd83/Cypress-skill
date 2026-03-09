param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"
$rootAbs = (Resolve-Path -LiteralPath $Root).Path
$issues = @()

$contracts = @(
  @{
    File = "orchestrator/SKILL.md"
    Rules = @(
      "Header::(?m)^# Cypress Orchestrator",
      "Deterministic First Question::(?m)^## Deterministic First Question",
      "Intent Routing Table::(?m)^## Intent Routing Table",
      "Orchestration Rules::(?m)^## Orchestration Rules"
    )
  },
  @{
    File = "analysis/SKILL.md"
    Rules = @(
      "Header::(?m)^# Analysis\\s*&\\s*Requirements Skill",
      "Information Gathering::(?m)^## 1\\. Information Gathering",
      "Requirement Extraction::(?m)^## 2\\. Requirement Extraction",
      "User Validation::(?m)^## 3\\. User Validation"
    )
  },
  @{
    File = "coverage_plan/generation/SKILL.md"
    Rules = @(
      "Header::(?m)^# Functional Coverage Plan Generation",
      "Prerequisite::(?m)^## 1\\. Prerequisite",
      "Generate Scenarios::(?m)^## 2\\. Generate the Scenarios",
      "Formatting::(?m)^## 3\\. Formatting the Plan",
      "Next Step::(?m)^## 4\\. Next Step"
    )
  },
  @{
    File = "coverage_plan/review/SKILL.md"
    Rules = @(
      "Header::(?m)^# Functional Coverage Plan Review",
      "Present Plan::(?m)^## 1\\. Present the Plan",
      "Prompt Feedback::(?m)^## 2\\. Prompt for Feedback",
      "Iterate::(?m)^## 3\\. Iterate",
      "Proceed::(?m)^## 4\\. Proceed"
    )
  },
  @{
    File = "reporting/stakeholder/SKILL.md"
    Rules = @(
      "Header::(?m)^# Stakeholder Execution Report",
      "Action::(?m)^## Action"
    )
  }
)

foreach ($contract in $contracts) {
  $path = Join-Path $rootAbs $contract.File
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    $issues += [pscustomobject]@{
      File = $contract.File
      Missing = "file"
    }
    continue
  }

  $text = Get-Content -Raw -LiteralPath $path
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
  Write-Host "check-planning-reporting-skill-sections failed with $($issues.Count) file(s)"
  $issues | ForEach-Object {
    Write-Host ("- {0}: missing {1}" -f $_.File, $_.Missing)
  }
  throw "check-planning-reporting-skill-sections failed"
}

Write-Host ("check-planning-reporting-skill-sections: OK ({0} skill docs)" -f $contracts.Count)
