param(
  [string]$Root = ".",
  [switch]$IncludeRoot
)

$ErrorActionPreference = "Stop"
$rootAbs = (Resolve-Path -LiteralPath $Root).Path
$violations = @()

function Is-ExternalLink([string]$rawLink) {
  return $rawLink -match '^(https?:|mailto:|#|data:|cci:)'
}

function NormalizeRel([string]$baseDir, [string]$targetPath) {
  $baseResolved = (Resolve-Path -LiteralPath $baseDir).Path
  $targetResolved = (Resolve-Path -LiteralPath $targetPath).Path

  $baseTrimmed = $baseResolved.TrimEnd('\', '/')
  if ($targetResolved.StartsWith($baseTrimmed, [System.StringComparison]::OrdinalIgnoreCase)) {
    $rel = $targetResolved.Substring($baseTrimmed.Length).TrimStart('\', '/')
    if ([string]::IsNullOrWhiteSpace($rel)) { return "." }
    return $rel.Replace('\', '/')
  }

  $baseUri = New-Object System.Uri(($baseTrimmed + [System.IO.Path]::DirectorySeparatorChar))
  $targetUri = New-Object System.Uri($targetResolved)
  return [System.Uri]::UnescapeDataString($baseUri.MakeRelativeUri($targetUri).ToString().Replace('\', '/'))
}

Get-ChildItem -Path $rootAbs -Recurse -File -Filter SKILL.md | ForEach-Object {
  $skillPath = $_.FullName
  $skillDir = Split-Path $skillPath -Parent

  if (-not $IncludeRoot -and $skillDir -eq $rootAbs) {
    return
  }

  $localGuides = Get-ChildItem -Path $skillDir -File -Filter *.md |
    Where-Object { $_.Name -ne "SKILL.md" } |
    Sort-Object Name

  if ($localGuides.Count -eq 0) {
    return
  }

  $content = Get-Content -Raw -LiteralPath $skillPath
  $referenced = New-Object "System.Collections.Generic.HashSet[string]"

  [regex]::Matches($content, '\[[^\]]+\]\(([^)]+)\)') | ForEach-Object {
    $raw = $_.Groups[1].Value.Trim()
    if ($raw -match '^<(.+)>$') { $raw = $Matches[1].Trim() }
    if ([string]::IsNullOrWhiteSpace($raw)) { return }
    if (Is-ExternalLink $raw) { return }

    $pathPart = $raw.Split('#')[0].Trim()
    if ([string]::IsNullOrWhiteSpace($pathPart)) { return }
    if ($pathPart -match '^".*"$') { return }

    $resolved = Join-Path $skillDir $pathPart
    if (-not (Test-Path -LiteralPath $resolved -PathType Leaf)) { return }
    if ([System.IO.Path]::GetExtension($resolved).ToLowerInvariant() -ne ".md") { return }

    $rel = NormalizeRel -baseDir $skillDir -targetPath $resolved
    [void]$referenced.Add($rel)
  }

  foreach ($guide in $localGuides) {
    $relGuide = NormalizeRel -baseDir $skillDir -targetPath $guide.FullName
    if (-not $referenced.Contains($relGuide)) {
      $skillRel = $skillPath.Substring($rootAbs.Length + 1).Replace('\', '/')
      $guideRel = $guide.FullName.Substring($rootAbs.Length + 1).Replace('\', '/')
      $violations += [pscustomobject]@{
        Skill = $skillRel
        MissingGuide = $guideRel
      }
    }
  }
}

if ($violations.Count -gt 0) {
  Write-Host "check-skill-index-coverage failed with $($violations.Count) missing link(s)"
  $violations | ForEach-Object {
    Write-Host ("- {0} is missing link to {1}" -f $_.Skill, $_.MissingGuide)
  }
  throw "check-skill-index-coverage failed"
}

Write-Host "check-skill-index-coverage: OK"
