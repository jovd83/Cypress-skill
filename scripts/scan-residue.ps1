param(
  [string]$Root = ".",
  [switch]$Strict
)

$ErrorActionPreference = "Stop"
$rootAbs = (Resolve-Path -LiteralPath $Root).Path

$allowed = @(
  "migration/from-playwright.md",
  "migration/SKILL.md",
  "README.md",
  "SKILL.md"
) | ForEach-Object { $_.ToLowerInvariant() }

$residuePattern = '(?i)(playswright|playwright|@playwright/test|playwright\.config|test\.extend|page\.(goto|route|locator|getByRole|getByLabel|getByText|getByTestId|waitForResponse|waitForURL|waitForLoadState)|frameLocator|expect\(locator\)|toBeVisible\(|toHaveText\(|browser\.newContext|context\.newPage|storageState|route\.(fulfill|abort|continue))'
$residueHits = @()

$mdFiles = Get-ChildItem -Path $rootAbs -Recurse -File -Filter *.md
foreach ($file in $mdFiles) {
  $rel = $file.FullName.Substring($rootAbs.Length + 1).Replace('\', '/')
  $lines = Get-Content -LiteralPath $file.FullName
  for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match $residuePattern) {
      $residueHits += [pscustomobject]@{
        File = $rel
        Line = $i + 1
        Text = $lines[$i].Trim()
      }
    }
  }
}

if ($Strict) {
  if ($residueHits.Count -gt 0) {
    Write-Host "Residue matches found (strict mode): $($residueHits.Count)"
    $residueHits | ForEach-Object {
      Write-Host ("- {0}:{1} :: {2}" -f $_.File, $_.Line, $_.Text)
    }
    throw "scan-residue failed in strict mode"
  }

  Write-Host "scan-residue: OK (strict mode, zero matches)"
  return
}

$violations = @($residueHits | Where-Object {
  $allowed -notcontains $_.File.ToLowerInvariant()
})

if ($violations.Count -gt 0) {
  Write-Host "Non-allowed residue matches found: $($violations.Count)"
  $violations | ForEach-Object {
    Write-Host ("- {0}:{1} :: {2}" -f $_.File, $_.Line, $_.Text)
  }
  throw "scan-residue failed"
}

Write-Host "scan-residue: OK ($($residueHits.Count) allowed matches in migration/index docs)"
