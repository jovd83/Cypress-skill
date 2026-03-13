param(
  [string]$Root = ".",
  [switch]$CheckOnly
)

$ErrorActionPreference = "Stop"
$rootAbs = (Resolve-Path -LiteralPath $Root).Path
$updates = 0
$drifts = @()

function Has-ContentDrift([string[]]$Expected, [object]$Actual) {
  if ($null -eq $Actual) { return $true }
  $actualLines = @($Actual)
  if ($actualLines.Count -eq 0) { return $true }
  return [bool](Compare-Object -ReferenceObject $Expected -DifferenceObject $actualLines)
}

function EscapeYaml([string]$s) {
  if ($null -eq $s) { return "" }
  return $s.Replace('"', '\"')
}

function NormalizeWhitespace([string]$s) {
  if ($null -eq $s) { return "" }
  return (($s -replace '\s+', ' ').Trim())
}

function Trim-ToWordBoundary([string]$value, [int]$maxLength) {
  $v = NormalizeWhitespace $value
  if ($v.Length -le $maxLength) { return $v }

  $slice = $v.Substring(0, $maxLength).TrimEnd()
  $lastSpace = $slice.LastIndexOf(" ")
  if ($lastSpace -gt 15) {
    $slice = $slice.Substring(0, $lastSpace).TrimEnd()
  }
  return $slice
}

function Get-FirstSentence([string]$text) {
  $t = NormalizeWhitespace $text
  if ([string]::IsNullOrWhiteSpace($t)) { return $t }
  $m = [regex]::Match($t, '^(.*?[.!?])(\s|$)')
  if ($m.Success) {
    return $m.Groups[1].Value.Trim()
  }
  return $t
}

function Get-FirstClause([string]$text) {
  $t = NormalizeWhitespace $text
  if ([string]::IsNullOrWhiteSpace($t)) { return $t }
  $split = $t -split '[,;:]\s+', 2
  return $split[0].Trim()
}

function LowerFirst([string]$s) {
  if ([string]::IsNullOrWhiteSpace($s)) { return $s }
  if ($s.Length -eq 1) { return $s.ToLowerInvariant() }
  return $s.Substring(0, 1).ToLowerInvariant() + $s.Substring(1)
}

function Build-DisplayName([string]$skillName) {
  $display = ($skillName -replace '[-_]', ' ' -replace '\s+', ' ').Trim()
  if ([string]::IsNullOrWhiteSpace($display)) { return "Cypress Skill" }
  return (Get-Culture).TextInfo.ToTitleCase($display)
}

function Build-ShortDescription([string]$description) {
  $short = Get-FirstClause (Get-FirstSentence $description)
  if ($short -match '^(?i)a skill to\s+(.+)$') { $short = $Matches[1].Trim() }
  if ($short -match '^(?i)an orchestrator skill that\s+(.+)$') { $short = $Matches[1].Trim() }
  if ($short -match '^(?i)use(?:\s+this\s+skill)?\s+when\s+(.+)$') { $short = $Matches[1].Trim() }
  if ($short -match '^(?i)you need\s+(.+)$') { $short = "need " + $Matches[1].Trim() }
  $short = Trim-ToWordBoundary -value $short -maxLength 64

  if ($short.Length -lt 25) {
    $short = Trim-ToWordBoundary -value ($short + " Cypress workflow guidance") -maxLength 64
  }

  return $short.TrimEnd('.')
}

function Build-DefaultPrompt([string]$skillName, [string]$description) {
  $desc = NormalizeWhitespace (Get-FirstClause (Get-FirstSentence $description))
  $desc = $desc.TrimEnd('.')
  $action = ""

  if ($desc -match '^(?i)a skill to\s+(.+)$') {
    $action = $Matches[1].Trim()
  } elseif ($desc -match '^(?i)an orchestrator skill that\s+(.+)$') {
    $rest = $Matches[1].Trim()
    $restMatch = [regex]::Match($rest, '^(?i)acts?\s+as\s+(.+)$')
    if ($restMatch.Success) {
      $action = "act as " + $restMatch.Groups[1].Value.Trim()
    } else {
      $action = "act as " + $rest
    }
  } elseif ($desc -match '^(?i)use(?:\s+this\s+skill)?\s+when\s+(.+)$') {
    $rest = $Matches[1].Trim()
    if ($rest -match '^(?i)you need\s+(.+)$') {
      $action = "help when you need " + $Matches[1].Trim()
    } else {
      $action = "help when " + (LowerFirst $rest)
    }
  } else {
    $action = "help with " + (LowerFirst $desc)
  }

  if ([string]::IsNullOrWhiteSpace($action)) {
    $action = "help with this Cypress workflow"
  }
  $action = Trim-ToWordBoundary -value $action -maxLength 130

  $prompt = "Use `$${skillName} to $action."
  if ($prompt.Length -gt 220) {
    $prompt = "Use `$${skillName} to help with this Cypress workflow."
  }
  return $prompt
}

function Get-FrontmatterValues([string]$skillFile) {
  $name = ""
  $description = ""
  $lines = Get-Content -LiteralPath $skillFile
  $inFrontmatter = $false
  $frontmatterDone = $false

  for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    if ($i -eq 0 -and $line.Trim() -eq "---") {
      $inFrontmatter = $true
      continue
    }
    if ($inFrontmatter -and $line.Trim() -eq "---") {
      $frontmatterDone = $true
      break
    }
    if ($inFrontmatter) {
      if ($line -match '^name:\s*(.+)$' -and [string]::IsNullOrWhiteSpace($name)) {
        $name = $Matches[1].Trim()
      }
      if ($line -match '^description:\s*(.+)$' -and [string]::IsNullOrWhiteSpace($description)) {
        $description = $Matches[1].Trim()
      }
    }
  }

  if (-not $inFrontmatter -or -not $frontmatterDone) {
    foreach ($line in $lines) {
      if ($line -match '^name:\s*(.+)$' -and [string]::IsNullOrWhiteSpace($name)) {
        $name = $Matches[1].Trim()
      }
      if ($line -match '^description:\s*(.+)$' -and [string]::IsNullOrWhiteSpace($description)) {
        $description = $Matches[1].Trim()
      }
      if (-not [string]::IsNullOrWhiteSpace($name) -and -not [string]::IsNullOrWhiteSpace($description)) {
        break
      }
    }
  }

  return [pscustomobject]@{
    Name = $name
    Description = $description
  }
}

function Build-YamlLines([string]$skillName, [string]$description) {
  $display = Build-DisplayName $skillName
  $short = Build-ShortDescription $description
  $prompt = Build-DefaultPrompt $skillName $description

  return @(
    "interface:",
    ("  display_name: `"{0}`"" -f (EscapeYaml $display)),
    ("  short_description: `"{0}`"" -f (EscapeYaml $short)),
    ("  default_prompt: `"{0}`"" -f (EscapeYaml $prompt)),
    "",
    "policy:",
    "  allow_implicit_invocation: true"
  )
}

Get-ChildItem -Path $rootAbs -Recurse -File -Filter SKILL.md | ForEach-Object {
  $skillFile = $_.FullName
  $skillDir = Split-Path $skillFile -Parent

  $meta = Get-FrontmatterValues -skillFile $skillFile
  if ([string]::IsNullOrWhiteSpace($meta.Name)) {
    throw "Missing name in frontmatter: $skillFile"
  }
  if ([string]::IsNullOrWhiteSpace($meta.Description)) {
    throw "Missing description in frontmatter: $skillFile"
  }

  $expected = Build-YamlLines -skillName $meta.Name -description $meta.Description
  $agentDir = Join-Path $skillDir "agents"
  $agentFile = Join-Path $agentDir "openai.yaml"

  if ($CheckOnly) {
    $rel = ""
    if ($agentFile.Length -le $rootAbs.Length) {
      $rel = "agents/openai.yaml"
    } else {
      $rel = $agentFile.Substring($rootAbs.Length + 1).Replace('\', '/')
    }

    if (-not (Test-Path -LiteralPath $agentFile)) {
      $drifts += [pscustomobject]@{ File = $rel; Reason = "missing file" }
      return
    }

    $actual = Get-Content -LiteralPath $agentFile
    if (Has-ContentDrift -Expected $expected -Actual $actual) {
      $drifts += [pscustomobject]@{ File = $rel; Reason = "content drift" }
    }
  } else {
    New-Item -ItemType Directory -Path $agentDir -Force | Out-Null
    $write = $true
    if (Test-Path -LiteralPath $agentFile) {
      $actual = Get-Content -LiteralPath $agentFile
      $write = Has-ContentDrift -Expected $expected -Actual $actual
    }
    if ($write) {
      Set-Content -LiteralPath $agentFile -Value $expected -Encoding UTF8
      $updates++
    }
  }
}

if ($CheckOnly) {
  if ($drifts.Count -gt 0) {
    Write-Host "sync-agents-metadata check failed with $($drifts.Count) drift issue(s)"
    $drifts | ForEach-Object {
      Write-Host ("- {0}: {1}" -f $_.File, $_.Reason)
    }
    throw "sync-agents-metadata check failed"
  }
  Write-Host "sync-agents-metadata: OK (no drift)"
  return
}

Write-Host "sync-agents-metadata: updated $updates file(s)"
