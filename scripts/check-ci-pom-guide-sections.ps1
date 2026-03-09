param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"
$rootAbs = (Resolve-Path -LiteralPath $Root).Path
$issues = @()

function Check-DirectoryContract([string]$DirName, [string[]]$RequiredPatterns) {
  $dirPath = Join-Path $rootAbs $DirName
  if (-not (Test-Path -LiteralPath $dirPath -PathType Container)) {
    throw "check-ci-pom-guide-sections failed: missing directory '$DirName'"
  }

  $files = Get-ChildItem -Path $dirPath -File -Filter *.md | Where-Object { $_.Name -ne "SKILL.md" }
  foreach ($file in $files) {
    $rel = $file.FullName.Substring($rootAbs.Length + 1).Replace('\', '/')
    $text = Get-Content -Raw -LiteralPath $file.FullName
    $missing = @()

    foreach ($rule in $RequiredPatterns) {
      $label = $rule.Split("::")[0]
      $pattern = $rule.Split("::")[1]
      if ($text -notmatch $pattern) {
        $missing += $label
      }
    }

    if ($missing.Count -gt 0) {
      $script:issues += [pscustomobject]@{
        File = $rel
        Missing = ($missing -join ", ")
      }
    }
  }

  return $files.Count
}

$patterns = @(
  "When to use::(?m)^> \*\*When to use\*\*:",
  "Prerequisites::(?m)^> \*\*Prerequisites\*\*:",
  "Anti-Patterns::(?m)^## Anti-Patterns|^## Anti-patterns"
)

$ciCount = Check-DirectoryContract -DirName "ci" -RequiredPatterns $patterns
$pomCount = Check-DirectoryContract -DirName "pom" -RequiredPatterns $patterns

if ($issues.Count -gt 0) {
  Write-Host "check-ci-pom-guide-sections failed with $($issues.Count) file(s)"
  $issues | ForEach-Object {
    Write-Host ("- {0}: missing {1}" -f $_.File, $_.Missing)
  }
  throw "check-ci-pom-guide-sections failed"
}

Write-Host ("check-ci-pom-guide-sections: OK (ci={0}, pom={1})" -f $ciCount, $pomCount)
