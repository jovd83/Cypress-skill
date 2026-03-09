param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"
$rootAbs = (Resolve-Path -LiteralPath $Root).Path
$cliDir = Join-Path $rootAbs "cypress-cli"

if (-not (Test-Path -LiteralPath $cliDir)) {
  throw "cypress-cli directory not found at $cliDir"
}

$violations = @()
$mdFiles = Get-ChildItem -Path $cliDir -File -Filter *.md

foreach ($file in $mdFiles) {
  $lines = Get-Content -LiteralPath $file.FullName
  $blocks = @()

  $i = 0
  while ($i -lt $lines.Count) {
    $line = $lines[$i].Trim()
    if ($line -match '^```([A-Za-z0-9_-]+)\s*$') {
      $lang = $Matches[1].ToLowerInvariant()
      $start = $i + 1
      $j = $i + 1
      while ($j -lt $lines.Count -and $lines[$j].Trim() -ne '```') {
        $j++
      }

      if ($j -lt $lines.Count) {
        $end = $j + 1
        $content = ""
        if ($j -gt ($i + 1)) {
          $content = ($lines[($i + 1)..($j - 1)] -join "`n")
        }
        $blocks += [pscustomobject]@{
          Lang = $lang
          Start = $start
          End = $end
          Content = $content
        }
        $i = $j + 1
        continue
      }
    }
    $i++
  }

  for ($b = 0; $b -lt $blocks.Count; $b++) {
    $block = $blocks[$b]
    if ($block.Lang -ne "bash") { continue }

    $isWorkflowScript =
      $block.Content -match '#!/bin/bash' -or
      $block.Content -match 'set -euo pipefail' -or
      $block.Content -match '(^|\n)\s*(for|while|until)\s+' -or
      $block.Content -match '(^|\n)\s*export\s+\w+='

    if (-not $isWorkflowScript) { continue }

    $nextBashStart = [int]::MaxValue
    for ($k = $b + 1; $k -lt $blocks.Count; $k++) {
      if ($blocks[$k].Lang -eq "bash") {
        $nextBashStart = $blocks[$k].Start
        break
      }
    }

    $hasNearbyPowerShell = $false
    for ($k = $b + 1; $k -lt $blocks.Count; $k++) {
      if ($blocks[$k].Start -ge $nextBashStart) { break }
      if ($blocks[$k].Lang -eq "powershell") {
        $hasNearbyPowerShell = $true
        break
      }
    }

    if (-not $hasNearbyPowerShell) {
      $rel = $file.FullName.Substring($rootAbs.Length + 1).Replace('\', '/')
      $violations += [pscustomobject]@{
        File = $rel
        Line = $block.Start
      }
    }
  }
}

if ($violations.Count -gt 0) {
  Write-Host "Bash workflow blocks missing nearby PowerShell examples: $($violations.Count)"
  $violations | ForEach-Object {
    Write-Host ("- {0}:{1}" -f $_.File, $_.Line)
  }
  throw "shell-example-parity-check failed"
}

Write-Host "shell-example-parity-check: OK"
