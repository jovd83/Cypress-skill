param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"
$rootAbs = (Resolve-Path -LiteralPath $Root).Path
$issues = @()

function Is-AllowedHardWait([string]$Line) {
  if ($Line -match '^\s*(//|#)') {
    return $true
  }

  if ($Line -match 'cy\.wait\((?<ms>\d+)\)' -and $Line -match 'waitForJobCompletion') {
    $ms = [int]$Matches["ms"]
    if ($ms -le 1000) {
      return $true
    }
  }

  return $false
}

$files = Get-ChildItem -Path $rootAbs -Recurse -File -Filter *.md
foreach ($file in $files) {
  $rel = $file.FullName.Substring($rootAbs.Length + 1).Replace('\', '/')
  $lines = Get-Content -LiteralPath $file.FullName
  $inFence = $false

  for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    if ($line -match '^\s*```') {
      $inFence = -not $inFence
      continue
    }

    if (-not $inFence) {
      continue
    }

    if ($line -match 'cy\.wait\([0-9]{2,}\)') {
      if (-not (Is-AllowedHardWait -Line $line.Trim())) {
        $issues += [pscustomobject]@{
          File = $rel
          Line = $i + 1
          Text = $line.Trim()
        }
      }
    }
  }
}

if ($issues.Count -gt 0) {
  Write-Host "check-hard-waits-in-code failed with $($issues.Count) issue(s)"
  $issues | ForEach-Object {
    Write-Host ("- {0}:{1} :: {2}" -f $_.File, $_.Line, $_.Text)
  }
  throw "check-hard-waits-in-code failed"
}

Write-Host ("check-hard-waits-in-code: OK ({0} markdown files scanned)" -f $files.Count)
