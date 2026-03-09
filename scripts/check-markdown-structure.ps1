param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"
$rootAbs = (Resolve-Path -LiteralPath $Root).Path
$issues = @()

$files = Get-ChildItem -Path $rootAbs -Recurse -File -Filter *.md
foreach ($file in $files) {
  $rel = $file.FullName.Substring($rootAbs.Length + 1).Replace('\', '/')
  $lines = Get-Content -LiteralPath $file.FullName

  $inFence = $false
  $fenceCount = 0
  $inTable = $false
  $expectedPipeCount = 0

  for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]

    if ($line -match '^\s*```') {
      $inFence = -not $inFence
      $fenceCount++
      $inTable = $false
      $expectedPipeCount = 0
      continue
    }

    if ($inFence) {
      continue
    }

    $trimmed = $line.TrimEnd()
    if ($trimmed -match '^\|') {
      $pipeCount = ([regex]::Matches($trimmed, '\|')).Count
      if (-not $inTable) {
        $inTable = $true
        $expectedPipeCount = $pipeCount
      } elseif ($pipeCount -ne $expectedPipeCount) {
        $issues += [pscustomobject]@{
          File = $rel
          Line = $i + 1
          Rule = "table pipe count mismatch"
          Text = $trimmed
        }
      }
    } else {
      $inTable = $false
      $expectedPipeCount = 0
    }
  }

  if (($fenceCount % 2) -ne 0) {
    $issues += [pscustomobject]@{
      File = $rel
      Line = 0
      Rule = "unbalanced fenced code blocks"
      Text = "odd number of markdown code fence delimiters"
    }
  }
}

if ($issues.Count -gt 0) {
  Write-Host "check-markdown-structure failed with $($issues.Count) issue(s)"
  $issues | ForEach-Object {
    if ($_.Line -gt 0) {
      Write-Host ("- {0}:{1} [{2}] :: {3}" -f $_.File, $_.Line, $_.Rule, $_.Text)
    } else {
      Write-Host ("- {0} [{1}] :: {2}" -f $_.File, $_.Rule, $_.Text)
    }
  }
  throw "check-markdown-structure failed"
}

Write-Host ("check-markdown-structure: OK ({0} markdown files scanned)" -f $files.Count)
