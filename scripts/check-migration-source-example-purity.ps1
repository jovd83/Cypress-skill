param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"
$rootAbs = (Resolve-Path -LiteralPath $Root).Path
$issues = @()

$contracts = @(
  @{
    File = "migration/from-playwright.md"
    LabelPattern = '(?i)\*\*Playwright(?:\s*\([^)]+\))?\*\*'
    ForbiddenPattern = '(^|\s)cy\.'
    RequiredAny = @('@playwright/test', 'page\.', 'locator', 'test\(')
    SourceName = "Playwright"
  },
  @{
    File = "migration/from-selenium.md"
    LabelPattern = '(?i)\*\*Selenium(?:\s*\([^)]+\))?\*\*'
    ForbiddenPattern = '(^|\s)cy\.'
    RequiredAny = @('driver\.', '\bBy\.', 'WebDriverWait', 'ExpectedConditions')
    SourceName = "Selenium"
  }
)

foreach ($contract in $contracts) {
  $path = Join-Path $rootAbs $contract.File
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    $issues += [pscustomobject]@{
      File = $contract.File
      Block = 0
      Issue = "missing file"
    }
    continue
  }

  $text = Get-Content -Raw -LiteralPath $path
  $text = $text -replace "\r", ""
  $blockPattern = '(?ms)' + $contract.LabelPattern + '\s*```(?<fence>[a-zA-Z0-9_-]+)\s*(?<code>.*?)\s*```'
  $blocks = [regex]::Matches($text, $blockPattern)

  if ($blocks.Count -eq 0) {
    $issues += [pscustomobject]@{
      File = $contract.File
      Block = 0
      Issue = ("no {0} source code blocks found" -f $contract.SourceName)
    }
    continue
  }

  $index = 0
  foreach ($block in $blocks) {
    $index++
    $code = $block.Groups["code"].Value

    if ($code -match $contract.ForbiddenPattern) {
      $issues += [pscustomobject]@{
        File = $contract.File
        Block = $index
        Issue = ("{0} source block contains Cypress command usage" -f $contract.SourceName)
      }
    }

    $hasRequired = $false
    foreach ($req in $contract.RequiredAny) {
      if ($code -match $req) {
        $hasRequired = $true
        break
      }
    }

    if (-not $hasRequired) {
      $issues += [pscustomobject]@{
        File = $contract.File
        Block = $index
        Issue = ("{0} source block missing expected source-framework syntax markers" -f $contract.SourceName)
      }
    }
  }
}

if ($issues.Count -gt 0) {
  Write-Host "check-migration-source-example-purity failed with $($issues.Count) issue(s)"
  $issues | ForEach-Object {
    if ($_.Block -gt 0) {
      Write-Host ("- {0} [block #{1}] :: {2}" -f $_.File, $_.Block, $_.Issue)
    } else {
      Write-Host ("- {0} :: {1}" -f $_.File, $_.Issue)
    }
  }
  throw "check-migration-source-example-purity failed"
}

Write-Host "check-migration-source-example-purity: OK"
