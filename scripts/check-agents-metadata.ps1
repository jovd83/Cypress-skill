param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"
$rootAbs = (Resolve-Path -LiteralPath $Root).Path
$violations = @()

function Add-Violation([string]$File, [string]$Message) {
  $script:violations += [pscustomobject]@{
    File = $File
    Message = $Message
  }
}

Get-ChildItem -Path $rootAbs -Recurse -File -Filter SKILL.md | ForEach-Object {
  $skillFile = $_.FullName
  $skillDir = Split-Path $skillFile -Parent
  if ($skillDir.Length -le $rootAbs.Length) {
    $relSkillDir = "."
  } else {
    $relSkillDir = $skillDir.Substring($rootAbs.Length + 1).Replace('\', '/')
    if ($relSkillDir -eq "") { $relSkillDir = "." }
  }

  $name = ""
  Get-Content -LiteralPath $skillFile | ForEach-Object {
    if ($_ -match '^name:\s*(.+)$' -and $name -eq "") {
      $name = $Matches[1].Trim()
    }
  }
  if ([string]::IsNullOrWhiteSpace($name)) {
    Add-Violation -File $relSkillDir -Message "SKILL.md frontmatter missing name"
    return
  }

  $agentFile = Join-Path $skillDir "agents/openai.yaml"
  $relAgent = Join-Path $relSkillDir "agents/openai.yaml"
  $relAgent = $relAgent.Replace('\', '/')
  if ($relSkillDir -eq ".") { $relAgent = "agents/openai.yaml" }

  if (-not (Test-Path -LiteralPath $agentFile)) {
    Add-Violation -File $relSkillDir -Message "missing agents/openai.yaml"
    return
  }

  $yaml = Get-Content -LiteralPath $agentFile

  $hasInterface = $yaml -match '^\s*interface:\s*$'
  $hasPolicy = $yaml -match '^\s*policy:\s*$'
  $displayLine = $yaml | Where-Object { $_ -match '^\s*display_name:\s*"(.+)"\s*$' } | Select-Object -First 1
  $shortLine = $yaml | Where-Object { $_ -match '^\s*short_description:\s*"(.+)"\s*$' } | Select-Object -First 1
  $promptLine = $yaml | Where-Object { $_ -match '^\s*default_prompt:\s*"(.+)"\s*$' } | Select-Object -First 1
  $allowLine = $yaml | Where-Object { $_ -match '^\s*allow_implicit_invocation:\s*true\s*$' } | Select-Object -First 1

  if (-not $hasInterface) {
    Add-Violation -File $relAgent -Message "missing interface section"
  }
  if (-not $hasPolicy) {
    Add-Violation -File $relAgent -Message "missing policy section"
  }
  if (-not $displayLine) {
    Add-Violation -File $relAgent -Message "missing or unquoted interface.display_name"
  }
  if (-not $shortLine) {
    Add-Violation -File $relAgent -Message "missing or unquoted interface.short_description"
  } else {
    if ($shortLine -match '^\s*short_description:\s*"(.+)"\s*$') {
      $short = $Matches[1]
      if ($short.Length -lt 25 -or $short.Length -gt 64) {
        Add-Violation -File $relAgent -Message "short_description length must be 25..64"
      }
      if ($short -match '\.\.\.') {
        Add-Violation -File $relAgent -Message "short_description must not contain ellipsis"
      }
      if ($short -match '\s{2,}') {
        Add-Violation -File $relAgent -Message "short_description contains repeated spaces"
      }
    }
  }
  if (-not $promptLine) {
    Add-Violation -File $relAgent -Message "missing or unquoted interface.default_prompt"
  } else {
    if ($promptLine -match '^\s*default_prompt:\s*"(.+)"\s*$') {
      $prompt = $Matches[1]
      $expectedRef = '$' + $name
      $expectedPrefixPattern = "^Use\s+\$" + [regex]::Escape($name) + "\s+to\s+.+"
      if ($prompt -notmatch $expectedPrefixPattern) {
        Add-Violation -File $relAgent -Message ("default_prompt must start with 'Use {0} to ...'" -f $expectedRef)
      }
      if ($prompt.Length -gt 220) {
        Add-Violation -File $relAgent -Message "default_prompt too long (max 220 chars)"
      }
      if ($prompt -match '\.\.\.') {
        Add-Violation -File $relAgent -Message "default_prompt must not contain ellipsis"
      }
      if (-not $prompt.EndsWith('.')) {
        Add-Violation -File $relAgent -Message "default_prompt must end with a period"
      }
      $sentenceMarkers = [regex]::Matches($prompt, '[.!?]').Count
      if ($sentenceMarkers -gt 1) {
        Add-Violation -File $relAgent -Message "default_prompt must be a single sentence"
      }
      if ($prompt -match '\s{2,}') {
        Add-Violation -File $relAgent -Message "default_prompt contains repeated spaces"
      }
    }
  }
  if (-not $allowLine) {
    Add-Violation -File $relAgent -Message "policy.allow_implicit_invocation must be true"
  }
}

if ($violations.Count -gt 0) {
  Write-Host "check-agents-metadata failed with $($violations.Count) issue(s)"
  $violations | ForEach-Object {
    Write-Host ("- {0}: {1}" -f $_.File, $_.Message)
  }
  throw "check-agents-metadata failed"
}

Write-Host "check-agents-metadata: OK"
