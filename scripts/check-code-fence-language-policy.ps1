param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"
$rootAbs = (Resolve-Path -LiteralPath $Root).Path
$issues = @()

$policy = @{
  "ci" = @("yaml", "bash", "powershell", "typescript", "javascript", "js", "json", "dockerfile", "groovy")
  "core" = @("typescript", "tsx", "javascript", "bash", "json", "text", "powershell")
  "cypress-cli" = @("bash", "powershell", "typescript", "javascript", "json", "gitignore")
  "documentation" = @("gherkin", "markdown", "text", "typescript")
  "migration" = @("typescript", "javascript", "java")
  "pom" = @("typescript", "javascript", "text")
  "README.md" = @("bash", "powershell")
  "SKILL.md" = @("powershell")
}

$documentationOverrides = @{
  "documentation/cypress-handover/SKILL.md" = @("gherkin", "markdown", "text", "typescript", "powershell")
  "documentation/cypress-handover/references/multi-scope-conflicts.md" = @("gherkin", "markdown", "text", "typescript", "powershell")
}

function Get-Scope([string]$RelativePath) {
  if ($RelativePath.Contains('/')) {
    return $RelativePath.Split('/')[0]
  }

  return $RelativePath
}

function Get-AllowedLanguages([string]$RelativePath, [string]$Scope) {
  if ($documentationOverrides.ContainsKey($RelativePath)) {
    return $documentationOverrides[$RelativePath]
  }

  if ($policy.ContainsKey($Scope)) {
    return $policy[$Scope]
  }

  return @()
}

$files = Get-ChildItem -Path $rootAbs -Recurse -File -Filter *.md
foreach ($file in $files) {
  $rel = $file.FullName.Substring($rootAbs.Length + 1).Replace('\', '/')
  $scope = Get-Scope -RelativePath $rel
  $allowed = Get-AllowedLanguages -RelativePath $rel -Scope $scope
  if ($allowed.Count -eq 0) {
    continue
  }
  $lines = Get-Content -LiteralPath $file.FullName
  $inFence = $false

  for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i].Trim()
    if ($line -match '^```') {
      if (-not $inFence) {
        $lang = $line.Substring(3).Trim().ToLowerInvariant()
        if (-not [string]::IsNullOrWhiteSpace($lang)) {
          if ($allowed -notcontains $lang) {
            $issues += [pscustomobject]@{
              File = $rel
              Line = $i + 1
              Scope = $scope
              Language = $lang
              Allowed = ($allowed -join ", ")
            }
          }
        }
        $inFence = $true
      } else {
        $inFence = $false
      }
    }
  }
}

if ($issues.Count -gt 0) {
  Write-Host "check-code-fence-language-policy failed with $($issues.Count) issue(s)"
  $issues | ForEach-Object {
    Write-Host ("- {0}:{1} [scope={2}] language '{3}' not allowed (allowed: {4})" -f $_.File, $_.Line, $_.Scope, $_.Language, $_.Allowed)
  }
  throw "check-code-fence-language-policy failed"
}

Write-Host ("check-code-fence-language-policy: OK ({0} markdown files scanned)" -f $files.Count)
