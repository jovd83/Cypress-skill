param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"
$rootAbs = (Resolve-Path -LiteralPath $Root).Path
$issues = @()

$skillFiles = Get-ChildItem -Path $rootAbs -Recurse -File -Filter SKILL.md
if ($skillFiles.Count -eq 0) {
  throw "check-skill-name-prefix failed: no SKILL.md files found"
}

foreach ($file in $skillFiles) {
  $rel = $file.FullName.Substring($rootAbs.Length + 1).Replace('\', '/')
  $text = Get-Content -Raw -LiteralPath $file.FullName
  $frontmatter = [regex]::Match($text, '(?s)^---\s*(?<fm>.*?)\s*---')

  if (-not $frontmatter.Success) {
    $issues += [pscustomobject]@{
      File = $rel
      Issue = "missing YAML frontmatter block"
    }
    continue
  }

  $nameMatch = [regex]::Match($frontmatter.Groups["fm"].Value, '(?m)^name:\s*(?<name>[^\r\n#]+)')
  if (-not $nameMatch.Success) {
    $issues += [pscustomobject]@{
      File = $rel
      Issue = "missing 'name' field in frontmatter"
    }
    continue
  }

  $name = $nameMatch.Groups["name"].Value.Trim()
  if ($name -notmatch '^cypress-') {
    $issues += [pscustomobject]@{
      File = $rel
      Issue = ("skill name must start with 'cypress-': {0}" -f $name)
    }
  }
}

if ($issues.Count -gt 0) {
  Write-Host "check-skill-name-prefix failed with $($issues.Count) issue(s)"
  $issues | ForEach-Object {
    Write-Host ("- {0}: {1}" -f $_.File, $_.Issue)
  }
  throw "check-skill-name-prefix failed"
}

Write-Host ("check-skill-name-prefix: OK ({0} skills)" -f $skillFiles.Count)
