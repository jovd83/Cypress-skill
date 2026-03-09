param(
  [string]$Root = ".",
  [string]$CatalogPath = "cypress-cli/SKILL.md"
)

$ErrorActionPreference = "Stop"
$rootAbs = (Resolve-Path -LiteralPath $Root).Path

function Get-FirstCommandToken([string[]]$Tokens, [int]$StartIndex) {
  for ($j = $StartIndex; $j -lt $Tokens.Count; $j++) {
    $token = $Tokens[$j].Trim()
    if ([string]::IsNullOrWhiteSpace($token)) { continue }
    if ($token -in @('&&', '||', '|', ';', '\')) { continue }
    if ($token.StartsWith("#")) { return $null }
    if ($token.StartsWith("-")) { continue }
    return $token.Trim("`"","'",",",";",")","(")
  }
  return $null
}

function Get-CypressCliCommandsInCodeBlocks([string]$MarkdownFile) {
  $hits = @()
  $lines = Get-Content -LiteralPath $MarkdownFile
  $inFence = $false

  for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    $trim = $line.Trim()

    if ($trim -match '^```') {
      $inFence = -not $inFence
      continue
    }

    if (-not $inFence) { continue }
    if ($trim.StartsWith("#")) { continue }
    if ($line -notmatch '\bcypress-cli\b') { continue }

    $tokens = $line -split '\s+'
    $cliIndex = [Array]::IndexOf($tokens, "cypress-cli")
    if ($cliIndex -lt 0) { continue }

    $commandToken = Get-FirstCommandToken -Tokens $tokens -StartIndex ($cliIndex + 1)
    if (-not $commandToken) { continue }
    if ($commandToken -match '^[<\[]') { continue }

    $hits += [pscustomobject]@{
      Command = $commandToken.ToLowerInvariant()
      Line = $i + 1
      Text = $line.Trim()
    }
  }

  return $hits
}

$catalogFull = Join-Path $rootAbs $CatalogPath
if (-not (Test-Path -LiteralPath $catalogFull)) {
  throw "Command catalog file not found: $CatalogPath"
}

$catalogHits = Get-CypressCliCommandsInCodeBlocks -MarkdownFile $catalogFull
$knownCommands = New-Object "System.Collections.Generic.HashSet[string]"
$catalogHits | ForEach-Object { [void]$knownCommands.Add($_.Command) }

if ($knownCommands.Count -eq 0) {
  throw "No cypress-cli commands extracted from catalog: $CatalogPath"
}

$unknown = @()
$mdFiles = Get-ChildItem -Path $rootAbs -Recurse -File -Filter *.md
foreach ($file in $mdFiles) {
  $rel = $file.FullName.Substring($rootAbs.Length + 1).Replace('\', '/')
  $hits = Get-CypressCliCommandsInCodeBlocks -MarkdownFile $file.FullName
  foreach ($hit in $hits) {
    if (-not $knownCommands.Contains($hit.Command)) {
      $unknown += [pscustomobject]@{
        File = $rel
        Line = $hit.Line
        Command = $hit.Command
        Text = $hit.Text
      }
    }
  }
}

if ($unknown.Count -gt 0) {
  Write-Host "Unknown cypress-cli commands in docs: $($unknown.Count)"
  $unknown | ForEach-Object {
    Write-Host ("- {0}:{1} -> {2}" -f $_.File, $_.Line, $_.Text)
  }
  throw "snippet-smoke-check failed"
}

Write-Host ("snippet-smoke-check: OK ({0} known commands from {1})" -f $knownCommands.Count, $CatalogPath)
