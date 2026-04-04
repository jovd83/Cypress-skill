param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"
$rootAbs = (Resolve-Path -LiteralPath $Root).Path
$migrationDir = Join-Path $rootAbs "migration"
$issues = @()

if (-not (Test-Path -LiteralPath $migrationDir -PathType Container)) {
  throw "check-migration-alias-wait-pairing failed: missing directory 'migration'"
}

$files = Get-ChildItem -Path $migrationDir -File -Filter *.md | Where-Object { $_.Name -ne "SKILL.md" }
$blockPattern = '(?ms)\*\*Cypress \((?<label>TypeScript|JavaScript)\)\*\*\s*```(?<fence>typescript|javascript)\s*(?<code>.*?)\s*```'

foreach ($file in $files) {
  $rel = $file.FullName.Substring($rootAbs.Length + 1).Replace('\', '/')
  $text = Get-Content -Raw -LiteralPath $file.FullName
  $text = $text -replace "\r", ""
  $blocks = [regex]::Matches($text, $blockPattern)

  $blockIndex = 0
  foreach ($block in $blocks) {
    $blockIndex++
    $label = $block.Groups["label"].Value
    $code = $block.Groups["code"].Value
    $aliasMatches = [regex]::Matches($code, '\.as\(\s*["''](?<alias>[^"'']+)["'']\s*\)')

    foreach ($aliasMatch in $aliasMatches) {
      $alias = $aliasMatch.Groups["alias"].Value
      $waitPattern = "cy\.wait\(\s*[""']@" + [regex]::Escape($alias) + "[""']\s*\)"
      if ($code -notmatch $waitPattern) {
        $issues += [pscustomobject]@{
          File = $rel
          Block = $blockIndex
          Language = $label
          Alias = $alias
        }
      }
    }
  }
}

if ($issues.Count -gt 0) {
  Write-Host "check-migration-alias-wait-pairing failed with $($issues.Count) issue(s)"
  $issues | ForEach-Object {
    Write-Host ("- {0} [Cypress {1} block #{2}] alias '{3}' has no matching cy.wait('@{3}')" -f $_.File, $_.Language, $_.Block, $_.Alias)
  }
  throw "check-migration-alias-wait-pairing failed"
}

Write-Host ("check-migration-alias-wait-pairing: OK ({0} migration guides)" -f $files.Count)
