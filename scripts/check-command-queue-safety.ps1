param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"
$rootAbs = (Resolve-Path -LiteralPath $Root).Path
$issues = @()

$rules = @(
  @{
    Name = "await cy usage"
    Pattern = 'await\s+cy\.[A-Za-z_]'
  },
  @{
    Name = "Promise.all with Cypress commands"
    Pattern = 'Promise\.all\(\s*\[\s*cy\.[A-Za-z_]'
  }
)

$files = Get-ChildItem -Path $rootAbs -Recurse -File -Filter *.md
foreach ($file in $files) {
  $rel = $file.FullName.Substring($rootAbs.Length + 1).Replace('\', '/')
  $lines = Get-Content -LiteralPath $file.FullName

  for ($i = 0; $i -lt $lines.Count; $i++) {
    foreach ($rule in $rules) {
      if ($lines[$i] -match $rule.Pattern) {
        $issues += [pscustomobject]@{
          File = $rel
          Line = $i + 1
          Rule = $rule.Name
          Text = $lines[$i].Trim()
        }
      }
    }
  }
}

if ($issues.Count -gt 0) {
  Write-Host "check-command-queue-safety failed with $($issues.Count) issue(s)"
  $issues | ForEach-Object {
    Write-Host ("- {0}:{1} [{2}] :: {3}" -f $_.File, $_.Line, $_.Rule, $_.Text)
  }
  throw "check-command-queue-safety failed"
}

Write-Host ("check-command-queue-safety: OK ({0} markdown files scanned)" -f $files.Count)
