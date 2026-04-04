$here = $PSScriptRoot
if (-not $here) { $here = "." }
$repoRoot = (Resolve-Path (Join-Path $here "..\..")).Path
$skillRoot = Join-Path $repoRoot "documentation/cypress-handover"
$examplePath = Join-Path $skillRoot "references/blocked-handover-example.md"

$scriptPaths = @{
  audit = Join-Path $skillRoot "scripts/audit-handovers.ps1"
  archive = Join-Path $skillRoot "scripts/archive-handover-scope.ps1"
  doctor = Join-Path $skillRoot "scripts/doctor-handover.ps1"
  export = Join-Path $skillRoot "scripts/export-handover-index.ps1"
  new = Join-Path $skillRoot "scripts/new-handover.ps1"
  repair = Join-Path $skillRoot "scripts/repair-handover-links.ps1"
  resolve = Join-Path $skillRoot "scripts/resolve-handover-location-conflict.ps1"
  restore = Join-Path $skillRoot "scripts/restore-handover-scope.ps1"
  validate = Join-Path $skillRoot "scripts/validate-handover.ps1"
}

function New-HandoverFixtureFile {
  param(
    [string]$Path,
    [string]$Timestamp,
    [string]$TaskLabel,
    [string]$WorkspaceRoot,
    [string]$Branch,
    [string]$Status = "Blocked",
    [string]$PreviousHandover = "No prior handover found",
    [string]$NextAction = "Take the next scoped action and record the result."
  )

  $content = Get-Content -Raw -LiteralPath $examplePath
  $content = $content -replace "`r", ""
  $content = [regex]::Replace($content, '(?m)^- Timestamp:\s*.+$', ('- Timestamp: ' + $Timestamp))
  $content = [regex]::Replace($content, '(?m)^- Task label:\s*.+$', ('- Task label: ' + $TaskLabel))
  $content = [regex]::Replace($content, '(?m)^- Workspace root:\s*.+$', ('- Workspace root: ' + $WorkspaceRoot))
  $content = [regex]::Replace($content, '(?m)^- Branch:\s*.+$', ('- Branch: ' + $Branch))
  $content = [regex]::Replace($content, '(?m)^- Previous handover:\s*.+$', ('- Previous handover: ' + $PreviousHandover))
  $content = [regex]::Replace($content, '(?m)^### Current status\n.+$', ("### Current status`n" + $Status))
  $content = [regex]::Replace($content, '(?sm)^### Next action\n.*?(?=^### |\z)', ("### Next action`n" + $NextAction + "`n`n"))
  Set-Content -LiteralPath $Path -Value $content -Encoding UTF8
}

function Set-HandoverSectionBody {
  param(
    [string]$Path,
    [string]$Heading,
    [string]$Body
  )

  $content = Get-Content -Raw -LiteralPath $Path
  $content = $content -replace "`r", ""
  $pattern = '(?sm)^' + [regex]::Escape($Heading) + '\n.*?(?=^### |\z)'
  $replacement = $Heading + "`n" + $Body + "`n`n"
  $updated = [regex]::Replace($content, $pattern, $replacement, 1)
  Set-Content -LiteralPath $Path -Value $updated -Encoding UTF8
}

function Get-HandoverMetadataLineValue {
  param(
    [string]$Path,
    [string]$Label
  )

  $content = Get-Content -Raw -LiteralPath $Path
  $content = $content -replace "`r", ""
  $pattern = '(?m)^- ' + [regex]::Escape($Label) + ':\s*(?<value>.+)$'
  $match = [regex]::Match($content, $pattern)
  if (-not $match.Success) {
    return ""
  }

  return $match.Groups["value"].Value.Trim()
}

Describe "Cypress handover package" {
  BeforeEach {
    $script:tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('cypress-handover-pester-' + [guid]::NewGuid().ToString('N'))
    $script:docsRoot = Join-Path $script:tempRoot 'docs/tests'
    $script:activeDir = Join-Path $script:docsRoot 'handovers'
    $script:archiveDir = Join-Path $script:activeDir 'archive'
    New-Item -ItemType Directory -Path $script:activeDir -Force | Out-Null
    New-Item -ItemType Directory -Path $script:archiveDir -Force | Out-Null

    $script:workspace = $script:tempRoot
    $script:branch = 'Unknown'
    $script:otherWorkspace = 'C:\projects\other-app'
    $script:otherBranch = 'feature/other'

    $script:activeScoped = Join-Path $script:activeDir '20260312_0900_CypressSkillHandover.md'
    $script:activeOther = Join-Path $script:activeDir '20260312_1000_CypressSkillHandover.md'
    $script:archiveOnly = Join-Path $script:archiveDir '20260312_1100_CypressSkillHandover.md'
    $script:duplicateActive = Join-Path $script:activeDir '20260308_0900_CypressSkillHandover.md'
    $script:duplicateArchive = Join-Path $script:archiveDir '20260308_0900_CypressSkillHandover.md'

    New-HandoverFixtureFile -Path $script:activeScoped -Timestamp '2026-03-12 09:00' -TaskLabel 'checkout-auth-fix' -WorkspaceRoot $script:workspace -Branch $script:branch -Status 'In progress' -PreviousHandover 'No prior handover found' -NextAction 'Continue the active checkout auth investigation.'
    New-HandoverFixtureFile -Path $script:activeOther -Timestamp '2026-03-12 10:00' -TaskLabel 'checkout-auth-fix' -WorkspaceRoot $script:otherWorkspace -Branch $script:otherBranch -Status 'Blocked' -PreviousHandover 'No prior handover found' -NextAction 'Handle the other workspace scope separately.'
    New-HandoverFixtureFile -Path $script:archiveOnly -Timestamp '2026-03-12 11:00' -TaskLabel 'archived-only-scope' -WorkspaceRoot $script:workspace -Branch $script:branch -Status 'Completed' -PreviousHandover 'No prior handover found' -NextAction 'Restore this archived-only scope before more work.'
    New-HandoverFixtureFile -Path $script:duplicateActive -Timestamp '2026-03-08 09:00' -TaskLabel 'duplicate-scope' -WorkspaceRoot $script:workspace -Branch 'dup/branch' -Status 'Completed' -PreviousHandover 'No prior handover found' -NextAction 'Active copy should stay.'
    New-HandoverFixtureFile -Path $script:duplicateArchive -Timestamp '2026-03-08 09:00' -TaskLabel 'duplicate-scope' -WorkspaceRoot $script:workspace -Branch 'dup/branch' -Status 'Completed' -PreviousHandover 'No prior handover found' -NextAction 'Archived copy is duplicated.'
  }

  AfterEach {
    if (Test-Path -LiteralPath $script:tempRoot) {
      Remove-Item -LiteralPath $script:tempRoot -Recurse -Force
    }
  }

  It "doctor recommends restore for archived-only scopes" {
    $result = ((& $scriptPaths.doctor -DocsRoot $docsRoot -TaskLabel 'archived-only-scope' -Location all -WorkspaceRoot $workspace -Branch $branch -Format json) | ConvertFrom-Json)
    if ($result.RecommendedAction -ne 'restore') {
      throw "Expected restore recommendation, got '$($result.RecommendedAction)'"
    }
  }

  It "repair-handover-links repairs broken previous links" {
    $older = Join-Path $activeDir '20260309_0900_CypressSkillHandover.md'
    $latest = Join-Path $activeDir '20260310_0900_CypressSkillHandover.md'
    New-HandoverFixtureFile -Path $older -Timestamp '2026-03-09 09:00' -TaskLabel 'repairable-scope' -WorkspaceRoot $workspace -Branch 'repair/branch' -Status 'In progress' -PreviousHandover 'No prior handover found' -NextAction 'Keep the older checkpoint for chain repair.'
    New-HandoverFixtureFile -Path $latest -Timestamp '2026-03-10 09:00' -TaskLabel 'repairable-scope' -WorkspaceRoot $workspace -Branch 'repair/branch' -Status 'Blocked' -PreviousHandover (Join-Path $tempRoot 'missing-prior.md') -NextAction 'Repair the broken chain link.'
    $repairResult = ((& $scriptPaths.repair -DocsRoot $docsRoot -Location active -TaskLabel 'repairable-scope' -WorkspaceRoot $workspace -Branch 'repair/branch' -Format json) | ConvertFrom-Json)
    if ($repairResult.RewrittenFiles -lt 1) {
      throw "Expected at least one rewritten file"
    }
    & $scriptPaths.validate -Path $latest | Out-Null
  }

  It "resolve-handover-location-conflict removes duplicate archived scope when keeping active" {
    $doctorResult = ((& $scriptPaths.doctor -DocsRoot $docsRoot -TaskLabel 'duplicate-scope' -Location all -WorkspaceRoot $workspace -Branch 'dup/branch' -Format json) | ConvertFrom-Json)
    if ($doctorResult.RecommendedAction -ne 'repair') {
      throw "Expected repair recommendation for duplicate scope, got '$($doctorResult.RecommendedAction)'"
    }
    if ($doctorResult.Command -notlike '*resolve-handover-location-conflict.ps1*') {
      throw "Doctor did not point to the location-conflict resolver"
    }

    $resolved = ((& $scriptPaths.resolve -DocsRoot $docsRoot -TaskLabel 'duplicate-scope' -WorkspaceRoot $workspace -Branch 'dup/branch' -KeepLocation active -Format json) | ConvertFrom-Json)
    if ($resolved.KeptLocation -ne 'active') {
      throw "Expected active location to be kept"
    }
    if (Test-Path -LiteralPath $duplicateArchive -PathType Leaf) {
      throw "Expected archived duplicate to be removed"
    }

    $audit = ((& $scriptPaths.audit -DocsRoot $docsRoot -Location all -Format json) | ConvertFrom-Json)
    $remainingCollisions = @(
      $audit.CrossLocationScopeCollisions |
        Where-Object { $_.TaskLabel -eq 'duplicate-scope' }
    )
    if ($remainingCollisions.Count -ne 0) {
      throw "Expected duplicate scope collision to be resolved"
    }
  }

  It "export-handover-index includes histories when requested" {
    $outputPath = Join-Path $tempRoot 'handover-index.json'
    $index = ((& $scriptPaths.export -DocsRoot $docsRoot -Location all -IncludeHistory -Format json -OutputPath $outputPath) | ConvertFrom-Json)
    if (-not (Test-Path -LiteralPath $outputPath -PathType Leaf)) {
      throw "Expected export output file to be created"
    }
    if ((@($index.LatestScopes)).Count -lt 3) {
      throw "Expected latest scopes in export output"
    }
    $scopesWithHistory = @($index.LatestScopes | Where-Object { $_.History.Count -ge 1 })
    if ($scopesWithHistory.Count -lt 1) {
      throw "Expected at least one exported scope history"
    }
  }

  It "archive and restore preserve a two-file completed chain" {
    $older = Join-Path $activeDir '20260306_0900_CypressSkillHandover.md'
    $latest = Join-Path $activeDir '20260307_0900_CypressSkillHandover.md'
    New-HandoverFixtureFile -Path $older -Timestamp '2026-03-06 09:00' -TaskLabel 'completed-history' -WorkspaceRoot $workspace -Branch 'history/branch' -Status 'Completed' -PreviousHandover 'No prior handover found' -NextAction 'Older completed checkpoint.'
    New-HandoverFixtureFile -Path $latest -Timestamp '2026-03-07 09:00' -TaskLabel 'completed-history' -WorkspaceRoot $workspace -Branch 'history/branch' -Status 'Completed' -PreviousHandover $older -NextAction 'Latest completed checkpoint.'

    $archived = ((& $scriptPaths.archive -DocsRoot $docsRoot -TaskLabel 'completed-history' -WorkspaceRoot $workspace -Branch 'history/branch' -Format json) | ConvertFrom-Json)
    if ((@($archived.ArchivedPaths)).Count -ne 2) {
      throw "Expected two archived files"
    }
    if (Test-Path -LiteralPath $latest -PathType Leaf) {
      throw "Expected active completed chain to be moved to archive"
    }

    $restored = ((& $scriptPaths.restore -DocsRoot $docsRoot -TaskLabel 'completed-history' -WorkspaceRoot $workspace -Branch 'history/branch' -Format json) | ConvertFrom-Json)
    if ((@($restored.RestoredPaths)).Count -ne 2) {
      throw "Expected two restored files"
    }
    if (-not (Test-Path -LiteralPath $latest -PathType Leaf)) {
      throw "Expected latest completed checkpoint to be restored to active storage"
    }
    & $scriptPaths.validate -Path $latest | Out-Null
  }

  It "archive rollback keeps active files when archive target already exists" {
    $older = Join-Path $activeDir '20260304_0900_CypressSkillHandover.md'
    $latest = Join-Path $activeDir '20260305_0900_CypressSkillHandover.md'
    $conflictingArchiveTarget = Join-Path $archiveDir '20260304_0900_CypressSkillHandover.md'
    New-HandoverFixtureFile -Path $older -Timestamp '2026-03-04 09:00' -TaskLabel 'archive-rollback' -WorkspaceRoot $workspace -Branch 'rollback/archive' -Status 'Completed' -PreviousHandover 'No prior handover found' -NextAction 'Older completed checkpoint.'
    New-HandoverFixtureFile -Path $latest -Timestamp '2026-03-05 09:00' -TaskLabel 'archive-rollback' -WorkspaceRoot $workspace -Branch 'rollback/archive' -Status 'Completed' -PreviousHandover $older -NextAction 'Latest completed checkpoint.'
    New-HandoverFixtureFile -Path $conflictingArchiveTarget -Timestamp '2026-03-01 09:00' -TaskLabel 'unrelated-archive' -WorkspaceRoot $workspace -Branch 'rollback/archive' -Status 'Completed' -PreviousHandover 'No prior handover found' -NextAction 'Conflicting archive target.'

    $failedAsExpected = $false
    try {
      & $scriptPaths.archive -DocsRoot $docsRoot -TaskLabel 'archive-rollback' -WorkspaceRoot $workspace -Branch 'rollback/archive' -Format json | Out-Null
    } catch {
      $failedAsExpected = $_.Exception.Message -like '*Archive target already exists*'
    }

    if (-not $failedAsExpected) {
      throw "Expected archive to fail when the target archive file already exists"
    }
    if (-not (Test-Path -LiteralPath $older -PathType Leaf)) {
      throw "Expected older active file to remain after archive rollback"
    }
    if (-not (Test-Path -LiteralPath $latest -PathType Leaf)) {
      throw "Expected latest active file to remain after archive rollback"
    }
  }

  It "archive rollback removes written archive copies when validation fails" {
    $older = Join-Path $activeDir '20260314_0900_CypressSkillHandover.md'
    $latest = Join-Path $activeDir '20260315_0900_CypressSkillHandover.md'
    New-HandoverFixtureFile -Path $older -Timestamp '2026-03-14 09:00' -TaskLabel 'archive-validation-rollback' -WorkspaceRoot $workspace -Branch 'rollback/archive-validation' -Status 'Completed' -PreviousHandover 'No prior handover found' -NextAction 'Older completed checkpoint.'
    New-HandoverFixtureFile -Path $latest -Timestamp '2026-03-15 09:00' -TaskLabel 'archive-validation-rollback' -WorkspaceRoot $workspace -Branch 'rollback/archive-validation' -Status 'Completed' -PreviousHandover $older -NextAction 'Latest completed checkpoint.'
    Set-HandoverSectionBody -Path $latest -Heading '### Validation and evidence' -Body 'TBD'

    $failedAsExpected = $false
    try {
      & $scriptPaths.archive -DocsRoot $docsRoot -TaskLabel 'archive-validation-rollback' -WorkspaceRoot $workspace -Branch 'rollback/archive-validation' -Format json | Out-Null
    } catch {
      $failedAsExpected = $_.Exception.Message -like '*validate-handover failed*'
    }

    if (-not $failedAsExpected) {
      throw "Expected archive to fail when a copied handover fails validation"
    }
    if (-not (Test-Path -LiteralPath $older -PathType Leaf)) {
      throw "Expected older active file to remain after validation rollback"
    }
    if (-not (Test-Path -LiteralPath $latest -PathType Leaf)) {
      throw "Expected latest active file to remain after validation rollback"
    }
    $unexpectedArchiveOlder = Join-Path $archiveDir '20260314_0900_CypressSkillHandover.md'
    $unexpectedArchiveLatest = Join-Path $archiveDir '20260315_0900_CypressSkillHandover.md'
    if (Test-Path -LiteralPath $unexpectedArchiveOlder -PathType Leaf) {
      throw "Expected written archive copy to be removed after validation rollback"
    }
    if (Test-Path -LiteralPath $unexpectedArchiveLatest -PathType Leaf) {
      throw "Expected latest written archive copy to be removed after validation rollback"
    }
  }

  It "restore rollback keeps archived files when restore target already exists" {
    $archivedOlder = Join-Path $archiveDir '20260302_0900_CypressSkillHandover.md'
    $archivedLatest = Join-Path $archiveDir '20260303_0900_CypressSkillHandover.md'
    $conflictingRestoreTarget = Join-Path $activeDir '20260302_0900_CypressSkillHandover.md'
    New-HandoverFixtureFile -Path $archivedOlder -Timestamp '2026-03-02 09:00' -TaskLabel 'restore-rollback' -WorkspaceRoot $workspace -Branch 'rollback/restore' -Status 'Completed' -PreviousHandover 'No prior handover found' -NextAction 'Older archived checkpoint.'
    New-HandoverFixtureFile -Path $archivedLatest -Timestamp '2026-03-03 09:00' -TaskLabel 'restore-rollback' -WorkspaceRoot $workspace -Branch 'rollback/restore' -Status 'Completed' -PreviousHandover $archivedOlder -NextAction 'Latest archived checkpoint.'
    New-HandoverFixtureFile -Path $conflictingRestoreTarget -Timestamp '2026-03-01 08:00' -TaskLabel 'unrelated-active' -WorkspaceRoot $workspace -Branch 'rollback/restore' -Status 'Completed' -PreviousHandover 'No prior handover found' -NextAction 'Conflicting active target.'

    $failedAsExpected = $false
    try {
      & $scriptPaths.restore -DocsRoot $docsRoot -TaskLabel 'restore-rollback' -WorkspaceRoot $workspace -Branch 'rollback/restore' -Format json | Out-Null
    } catch {
      $failedAsExpected = $_.Exception.Message -like '*Restore target already exists*'
    }

    if (-not $failedAsExpected) {
      throw "Expected restore to fail when the target active file already exists"
    }
    if (-not (Test-Path -LiteralPath $archivedOlder -PathType Leaf)) {
      throw "Expected older archived file to remain after restore rollback"
    }
    if (-not (Test-Path -LiteralPath $archivedLatest -PathType Leaf)) {
      throw "Expected latest archived file to remain after restore rollback"
    }
  }

  It "restore rollback removes written active copies when validation fails" {
    $archivedOlder = Join-Path $archiveDir '20260316_0900_CypressSkillHandover.md'
    $archivedLatest = Join-Path $archiveDir '20260317_0900_CypressSkillHandover.md'
    New-HandoverFixtureFile -Path $archivedOlder -Timestamp '2026-03-16 09:00' -TaskLabel 'restore-validation-rollback' -WorkspaceRoot $workspace -Branch 'rollback/restore-validation' -Status 'Completed' -PreviousHandover 'No prior handover found' -NextAction 'Older archived checkpoint.'
    New-HandoverFixtureFile -Path $archivedLatest -Timestamp '2026-03-17 09:00' -TaskLabel 'restore-validation-rollback' -WorkspaceRoot $workspace -Branch 'rollback/restore-validation' -Status 'Completed' -PreviousHandover $archivedOlder -NextAction 'Latest archived checkpoint.'
    Set-HandoverSectionBody -Path $archivedLatest -Heading '### Validation and evidence' -Body 'TBD'

    $failedAsExpected = $false
    try {
      & $scriptPaths.restore -DocsRoot $docsRoot -TaskLabel 'restore-validation-rollback' -WorkspaceRoot $workspace -Branch 'rollback/restore-validation' -Format json | Out-Null
    } catch {
      $failedAsExpected = $_.Exception.Message -like '*validate-handover failed*'
    }

    if (-not $failedAsExpected) {
      throw "Expected restore to fail when a restored handover fails validation"
    }
    if (-not (Test-Path -LiteralPath $archivedOlder -PathType Leaf)) {
      throw "Expected older archived file to remain after validation rollback"
    }
    if (-not (Test-Path -LiteralPath $archivedLatest -PathType Leaf)) {
      throw "Expected latest archived file to remain after validation rollback"
    }
    $unexpectedActiveOlder = Join-Path $activeDir '20260316_0900_CypressSkillHandover.md'
    $unexpectedActiveLatest = Join-Path $activeDir '20260317_0900_CypressSkillHandover.md'
    if (Test-Path -LiteralPath $unexpectedActiveOlder -PathType Leaf) {
      throw "Expected written active copy to be removed after validation rollback"
    }
    if (Test-Path -LiteralPath $unexpectedActiveLatest -PathType Leaf) {
      throw "Expected latest written active copy to be removed after validation rollback"
    }
  }

  It "repair rollback restores rewritten files when scope validation fails" {
    $older = Join-Path $activeDir '20260318_0900_CypressSkillHandover.md'
    $latest = Join-Path $activeDir '20260319_0900_CypressSkillHandover.md'
    New-HandoverFixtureFile -Path $older -Timestamp '2026-03-18 09:00' -TaskLabel 'repair-rollback' -WorkspaceRoot $workspace -Branch 'rollback/repair' -Status 'Completed' -PreviousHandover 'No prior handover found' -NextAction 'Older checkpoint.'
    New-HandoverFixtureFile -Path $latest -Timestamp '2026-03-19 09:00' -TaskLabel 'repair-rollback' -WorkspaceRoot $workspace -Branch 'rollback/repair' -Status 'Blocked' -PreviousHandover (Join-Path $tempRoot 'missing-prior.md') -NextAction 'Repair the broken link.'
    Set-HandoverSectionBody -Path $older -Heading '### Validation and evidence' -Body 'TBD'
    $originalPrevious = Get-HandoverMetadataLineValue -Path $latest -Label 'Previous handover'

    $failedAsExpected = $false
    try {
      & $scriptPaths.repair -DocsRoot $docsRoot -Location active -TaskLabel 'repair-rollback' -WorkspaceRoot $workspace -Branch 'rollback/repair' -Format json | Out-Null
    } catch {
      $failedAsExpected = $_.Exception.Message -like '*validate-handover failed*'
    }

    if (-not $failedAsExpected) {
      throw "Expected repair to fail when another file in the scope fails validation"
    }
    $currentPrevious = Get-HandoverMetadataLineValue -Path $latest -Label 'Previous handover'
    if ($currentPrevious -ne $originalPrevious) {
      throw "Expected previous-handover metadata to be rolled back after repair validation failure"
    }
  }

  It "resolve conflict does not delete either location when kept files fail validation" {
    Set-HandoverSectionBody -Path $duplicateActive -Heading '### Validation and evidence' -Body 'TBD'

    $failedAsExpected = $false
    try {
      & $scriptPaths.resolve -DocsRoot $docsRoot -TaskLabel 'duplicate-scope' -WorkspaceRoot $workspace -Branch 'dup/branch' -KeepLocation active -Format json | Out-Null
    } catch {
      $failedAsExpected = $_.Exception.Message -like '*validate-handover failed*'
    }

    if (-not $failedAsExpected) {
      throw "Expected conflict resolution to fail when the kept active file does not validate"
    }
    if (-not (Test-Path -LiteralPath $duplicateActive -PathType Leaf)) {
      throw "Expected kept active duplicate to remain after validation failure"
    }
    if (-not (Test-Path -LiteralPath $duplicateArchive -PathType Leaf)) {
      throw "Expected removable archived duplicate to remain after validation failure"
    }
  }

  It "new-handover rejects cross-scope manual previous overrides" {
    Push-Location $tempRoot
    try {
      $rejected = $false
      try {
        & $scriptPaths.new -TaskLabel 'checkout auth fix' -DocsRoot 'docs/tests' -PreviousHandover $activeOther -Force | Out-Null
      } catch {
        $message = $_.Exception.Message
        $rejected = ($message -like '*same Workspace root*') -or ($message -like '*same Branch*') -or ($message -like '*same Task label*')
      }
      if (-not $rejected) {
        throw "Expected cross-scope manual previous override to be rejected"
      }
    } finally {
      Pop-Location
    }
  }
}
