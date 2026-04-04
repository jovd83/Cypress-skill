param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"
$rootAbs = (Resolve-Path -LiteralPath $Root).Path
$issues = @()

$skillFiles = Get-ChildItem -Path $rootAbs -Recurse -File -Filter SKILL.md
if ($skillFiles.Count -eq 0) {
  throw "check-skill-description-cypress failed: no SKILL.md files found"
}

foreach ($file in $skillFiles) {
  $rel = $file.FullName.Substring($rootAbs.Length + 1).Replace('\', '/')
  $text = Get-Content -Raw -LiteralPath $file.FullName
  $text = $text -replace "`r", ""
  $frontmatter = [regex]::Match($text, '(?s)^---\s*(?<fm>.*?)\s*---')

  if (-not $frontmatter.Success) {
    $issues += [pscustomobject]@{
      File = $rel
      Issue = "missing YAML frontmatter block"
    }
    continue
  }

  $descriptionMatch = [regex]::Match($frontmatter.Groups["fm"].Value, '(?m)^description:\s*(?<description>[^\r\n]+)')
  if (-not $descriptionMatch.Success) {
    $issues += [pscustomobject]@{
      File = $rel
      Issue = "missing 'description' field in frontmatter"
    }
    continue
  }

  $description = $descriptionMatch.Groups["description"].Value.Trim()
  if ($description -notmatch '(?i)cypress') {
    $issues += [pscustomobject]@{
      File = $rel
      Issue = ("description must include 'Cypress': {0}" -f $description)
    }
  }
}

if ($issues.Count -gt 0) {
  Write-Host "check-skill-description-cypress failed with $($issues.Count) issue(s)"
  $issues | ForEach-Object {
    Write-Host ("- {0}: {1}" -f $_.File, $_.Issue)
  }
  throw "check-skill-description-cypress failed"
}

Write-Host ("check-skill-description-cypress: OK ({0} skills)" -f $skillFiles.Count)
