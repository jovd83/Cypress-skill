param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"
$rootAbs = (Resolve-Path -LiteralPath $Root).Path
$issues = @()

$contracts = @(
  @{
    File = "documentation/tests/SKILL.md"
    Rules = @(
      "Header::(?m)^# Documenting Existing Tests",
      "Action::(?m)^## Action"
    )
  },
  @{
    File = "documentation/root_cause/SKILL.md"
    Rules = @(
      "Header::(?m)^# Root Cause Analysis Documentation",
      "Action::(?m)^## Action"
    )
  },
  @{
    File = "documentation/test_cases/tdd/SKILL.md"
    Rules = @(
      "Header::(?m)^# Documenting Test Cases: TDD format",
      "Storage and Organization::(?m)^## 1\\. Storage\\s*&\\s*Organization",
      "Structure and Fields::(?m)^## 3\\. Structure\\s*&\\s*Fields",
      "Example Template::(?m)^## 4\\. Example Template"
    )
  },
  @{
    File = "documentation/test_cases/bdd/SKILL.md"
    Rules = @(
      "Header::(?m)^# Documenting Test Cases: BDD \\(Gherkin\\) format",
      "Structure::(?m)^## Structure",
      "Best Practices::(?m)^## Best Practices",
      "Usage::(?m)^## Usage"
    )
  },
  @{
    File = "documentation/test_cases/plain_text/SKILL.md"
    Rules = @(
      "Header::(?m)^# Documenting Test Cases: Plain Text format",
      "Structure::(?m)^## Structure",
      "Usage::(?m)^## Usage"
    )
  },
  @{
    File = "documentation/cypress-handover/SKILL.md"
    Rules = @(
      "Header::(?m)^# Handover to Human-in-the-Loop",
      "Storage and Naming::(?m)^## 1\\. Storage and Naming",
      "Content Structure::(?m)^## 2\\. Content Structure",
      "Execution::(?m)^## 3\\. Execution"
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
  Write-Host "check-documentation-skill-sections failed with $($issues.Count) file(s)"
  $issues | ForEach-Object {
    Write-Host ("- {0}: missing {1}" -f $_.File, $_.Missing)
  }
  throw "check-documentation-skill-sections failed"
}

Write-Host ("check-documentation-skill-sections: OK ({0} skill docs)" -f $contracts.Count)
