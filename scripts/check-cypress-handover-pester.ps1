param(
  [string]$Root = ".",
  [string]$ResultsPath = ""
)

$ErrorActionPreference = "Stop"
$rootAbs = (Resolve-Path -LiteralPath $Root).Path
$testPath = Join-Path $rootAbs "tests/pester/cypress-handover.Tests.ps1"

if (-not (Test-Path -LiteralPath $testPath -PathType Leaf)) {
  throw "check-cypress-handover-pester failed: missing $testPath"
}

$module = Get-Module -ListAvailable Pester | Sort-Object Version -Descending | Select-Object -First 1
if ($null -eq $module) {
  throw "check-cypress-handover-pester failed: Pester module not found"
}

Import-Module $module.Path -Force | Out-Null

if (-not [string]::IsNullOrWhiteSpace($ResultsPath)) {
  $resultsParent = Split-Path -Parent $ResultsPath
  if (-not [string]::IsNullOrWhiteSpace($resultsParent)) {
    New-Item -ItemType Directory -Path $resultsParent -Force | Out-Null
  }
}

if ($module.Version.Major -ge 5) {
  $configuration = New-PesterConfiguration
  $configuration.Run.Path = $testPath
  $configuration.Run.PassThru = $true
  $configuration.Output.Verbosity = "Detailed"
  if (-not [string]::IsNullOrWhiteSpace($ResultsPath)) {
    $configuration.TestResult.Enabled = $true
    $configuration.TestResult.OutputPath = $ResultsPath
    $configuration.TestResult.OutputFormat = "NUnitXml"
  }
  $result = Invoke-Pester -Configuration $configuration
  if ($result.FailedCount -gt 0) {
    throw "check-cypress-handover-pester failed: $($result.FailedCount) Pester test(s) failed"
  }
} else {
  if (-not [string]::IsNullOrWhiteSpace($ResultsPath)) {
    $result = Invoke-Pester -Script $testPath -PassThru -OutputFile $ResultsPath -OutputFormat NUnitXml
  } else {
    $result = Invoke-Pester -Script $testPath -PassThru
  }
  if (($result.FailedCount -gt 0) -or ($result.Result -eq "Failed")) {
    throw "check-cypress-handover-pester failed: $($result.FailedCount) Pester test(s) failed"
  }
}

Write-Host "check-cypress-handover-pester: OK"
