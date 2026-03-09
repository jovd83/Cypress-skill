param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"
$rootAbs = (Resolve-Path -LiteralPath $Root).Path
$issues = @()
$nameMap = @{}

function Add-Issue([string]$File, [string]$Message) {
  $script:issues += [pscustomobject]@{
    File = $File
    Message = $Message
  }
}

Get-ChildItem -Path $rootAbs -Recurse -File -Filter SKILL.md | ForEach-Object {
  $file = $_.FullName
  $rel = $file.Substring($rootAbs.Length + 1).Replace('\', '/')
  $lines = Get-Content -LiteralPath $file

  if ($lines.Count -lt 3) {
    Add-Issue -File $rel -Message "file too short to contain valid frontmatter"
    return
  }

  if ($lines[0].Trim() -ne "---") {
    Add-Issue -File $rel -Message "missing opening frontmatter delimiter (---)"
    return
  }

  $endIndex = -1
  for ($i = 1; $i -lt $lines.Count; $i++) {
    if ($lines[$i].Trim() -eq "---") {
      $endIndex = $i
      break
    }
  }
  if ($endIndex -lt 0) {
    Add-Issue -File $rel -Message "missing closing frontmatter delimiter (---)"
    return
  }

  $name = ""
  $desc = ""
  for ($i = 1; $i -lt $endIndex; $i++) {
    $line = $lines[$i]
    if ($line -match '^name:\s*(.+)$' -and [string]::IsNullOrWhiteSpace($name)) {
      $name = $Matches[1].Trim()
      continue
    }
    if ($line -match '^description:\s*(.+)$' -and [string]::IsNullOrWhiteSpace($desc)) {
      $desc = $Matches[1].Trim()
      continue
    }
  }

  if ([string]::IsNullOrWhiteSpace($name)) {
    Add-Issue -File $rel -Message "frontmatter missing name"
  } else {
    if ($name -notmatch '^cypress-[a-z0-9-]+$') {
      Add-Issue -File $rel -Message "name must match ^cypress-[a-z0-9-]+$"
    }
    if ($nameMap.ContainsKey($name)) {
      Add-Issue -File $rel -Message ("duplicate name '{0}' (also in {1})" -f $name, $nameMap[$name])
    } else {
      $nameMap[$name] = $rel
    }
  }

  if ([string]::IsNullOrWhiteSpace($desc)) {
    Add-Issue -File $rel -Message "frontmatter missing description"
  } else {
    $descNorm = ($desc -replace '\s+', ' ').Trim()
    if ($descNorm.Length -lt 25) {
      Add-Issue -File $rel -Message "description too short (min 25 chars)"
    }
    if ($descNorm.Length -gt 500) {
      Add-Issue -File $rel -Message "description too long (max 500 chars)"
    }
    if ($descNorm -notmatch '[A-Za-z]') {
      Add-Issue -File $rel -Message "description must contain readable text"
    }
  }
}

if ($issues.Count -gt 0) {
  Write-Host "check-skill-frontmatter failed with $($issues.Count) issue(s)"
  $issues | ForEach-Object {
    Write-Host ("- {0}: {1}" -f $_.File, $_.Message)
  }
  throw "check-skill-frontmatter failed"
}

Write-Host ("check-skill-frontmatter: OK ({0} skills)" -f $nameMap.Count)
