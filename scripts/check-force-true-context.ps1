param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"
$rootAbs = (Resolve-Path -LiteralPath $Root).Path
$issues = @()

function Is-AllowedForceTrue([string[]]$BlockLines, [int]$Index) {
  $line = $BlockLines[$Index]

  if ($line -match 'selectFile\(') {
    return $true
  }

  if ($line -match '\.trigger\(') {
    return $true
  }

  # Allow split-argument style where { force: true } appears a few lines after selectFile/trigger.
  $windowStart = [Math]::Max(0, $Index - 10)
  for ($j = $windowStart; $j -le $Index; $j++) {
    if ($BlockLines[$j] -match 'selectFile\(') {
      return $true
    }
    if ($BlockLines[$j] -match '\.trigger\(') {
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
  $blockLines = New-Object System.Collections.Generic.List[string]
  $blockStartLine = 0

  for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]

    if ($line -match '^\s*```') {
      if (-not $inFence) {
        $inFence = $true
        $blockLines = New-Object System.Collections.Generic.List[string]
        $blockStartLine = $i + 1
      } else {
        for ($k = 0; $k -lt $blockLines.Count; $k++) {
          if ($blockLines[$k] -match 'force\s*:\s*true') {
            if (-not (Is-AllowedForceTrue -BlockLines $blockLines.ToArray() -Index $k)) {
              $issues += [pscustomobject]@{
                File = $rel
                Line = $blockStartLine + $k
                Text = $blockLines[$k].Trim()
              }
            }
          }
        }
        $inFence = $false
      }
      continue
    }

    if ($inFence) {
      [void]$blockLines.Add($line)
    }
  }
}

if ($issues.Count -gt 0) {
  Write-Host "check-force-true-context failed with $($issues.Count) issue(s)"
  $issues | ForEach-Object {
    Write-Host ("- {0}:{1} :: {2}" -f $_.File, $_.Line, $_.Text)
  }
  throw "check-force-true-context failed"
}

Write-Host ("check-force-true-context: OK ({0} markdown files scanned)" -f $files.Count)
