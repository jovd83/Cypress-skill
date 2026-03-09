param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"
$rootAbs = (Resolve-Path -LiteralPath $Root).Path
$issues = @()

$targets = @(
  "installers/vscode-codex/SKILL.md",
  "installers/intellij-junie/SKILL.md"
)

foreach ($relative in $targets) {
  $path = Join-Path $rootAbs $relative
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    $issues += [pscustomobject]@{
      File = $relative
      Issue = "missing file"
    }
    continue
  }

  $text = Get-Content -Raw -LiteralPath $path
  if ($text -notmatch '(?i)npm init cypress@latest') {
    $issues += [pscustomobject]@{
      File = $relative
      Issue = "missing canonical init command 'npm init cypress@latest'"
    }
  }

  if ($text -cmatch 'npm init Cypress@latest') {
    $issues += [pscustomobject]@{
      File = $relative
      Issue = "contains non-canonical command casing 'npm init Cypress@latest'"
    }
  }
}

if ($issues.Count -gt 0) {
  Write-Host "check-installer-command-canonical failed with $($issues.Count) issue(s)"
  $issues | ForEach-Object {
    Write-Host ("- {0}: {1}" -f $_.File, $_.Issue)
  }
  throw "check-installer-command-canonical failed"
}

Write-Host ("check-installer-command-canonical: OK ({0} files)" -f $targets.Count)
