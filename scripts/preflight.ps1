param(
  [string]$Root = ".",
  [string]$SourceRoot = "..\Playwright-skill",
  [switch]$StrictResidue,
  [switch]$RequireParitySource,
  [switch]$SkipSync
)

$ErrorActionPreference = "Stop"
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "==> Preflight"

if (-not $SkipSync) {
  Write-Host "==> Sync agents metadata from SKILL.md frontmatter"
  & "$scriptRoot\sync-agents-metadata.ps1" -Root $Root
} else {
  Write-Host "==> Skip metadata sync (requested)"
}

Write-Host "==> Run quality gate"

$gateParams = @{
  Root = $Root
  SourceRoot = $SourceRoot
}

if ($StrictResidue) { $gateParams.StrictResidue = $true }
if ($RequireParitySource) { $gateParams.RequireParitySource = $true }

& "$scriptRoot\quality-gate.ps1" @gateParams

Write-Host "preflight: OK"
