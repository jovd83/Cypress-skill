Describe "Cypress handover package" {
  $script:here = $PSScriptRoot
  if (-not $script:here) { $script:here = "." }
  $script:repoRoot = (Resolve-Path (Join-Path $script:here "..\..")).Path
  $script:skillRoot = Join-Path $script:repoRoot "documentation/cypress-handover"
  $script:examplePath = Join-Path $script:skillRoot "references/blocked-handover-example.md"

  $script:scriptPaths = @{
    audit = Join-Path $script:skillRoot "scripts/audit-handovers.ps1"
    archive = Join-Path $script:skillRoot "scripts/archive-handover-scope.ps1"
    doctor = Join-Path $script:skillRoot "scripts/doctor-handover.ps1"
    export = Join-Path $script:skillRoot "scripts/export-handover-index.ps1"
    find = Join-Path $script:skillRoot "scripts/find-handover.ps1"
    new = Join-Path $script:skillRoot "scripts/new-handover.ps1"
    repair = Join-Path $script:skillRoot "scripts/repair-handover-links.ps1"
    resolve = Join-Path $script:skillRoot "scripts/resolve-handover-location-conflict.ps1"
    restore = Join-Path $script:skillRoot "scripts/restore-handover-scope.ps1"
    validate = Join-Path $script:skillRoot "scripts/validate-handover.ps1"
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

    $content = Get-Content -Raw -LiteralPath $script:examplePath
    $content = $content -replace "`r", ""
    
    # Use string.Replace for values that may contain backslashes or special chars
    $content = $content.Replace("2026-03-11 15:30", $Timestamp)
    $content = $content.Replace("checkout-auth-fix", $TaskLabel)
    $content = $content.Replace('C:\projects\shop-app', $WorkspaceRoot)
    $content = $content.Replace("fix/checkout-auth-refresh", $Branch)
    $content = $content.Replace("No prior handover found", $PreviousHandover)
    
    # Use regex for section bodies
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
    if (-not $match.Success) { return "" }
    return $match.Groups["value"].Value.Trim()
  }

  function Normalize-TestPath([string]$Path) {
    if ([string]::IsNullOrWhiteSpace($Path) -or ($Path -eq "No prior handover found")) { return $Path }
    return ($Path -replace '\\', '/').ToLowerInvariant().TrimEnd('/')
  }

  BeforeEach {
    $script:tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('cypress-handover-pester-' + [guid]::NewGuid().ToString('N'))
    $script:docsRoot = Join-Path $script:tempRoot 'docs/tests'
    $script:activeDir = Join-Path $script:docsRoot 'handovers'
    $script:archiveDir = Join-Path $script:activeDir 'archive'
    New-Item -ItemType Directory -Path $script:activeDir -Force | Out-Null
    New-Item -ItemType Directory -Path $script:archiveDir -Force | Out-Null

    $script:workspace = $script:tempRoot
    $script:branch = 'Unknown'
    $script:otherWorkspace = Join-Path $script:tempRoot 'other-app'
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

    if (-not (Test-Path -LiteralPath $script:activeScoped)) { throw "Fixture creation failed: $script:activeScoped not found" }
  }

  AfterEach {
    if (Test-Path -LiteralPath $script:tempRoot) {
      Remove-Item -LiteralPath $script:tempRoot -Recurse -Force
    }
  }

  It "find-handover discovers active and archived files" {
    $found = ((& $script:scriptPaths.audit -DocsRoot $script:docsRoot -Location all -Format json) | ConvertFrom-Json)
    if ($null -eq $found.Summary) { throw "audit-handovers returned null Summary from docsRoot=$script:docsRoot" }
    $found.Summary.TotalFiles | Should Be 5
    $found.Summary.ActiveFiles | Should Be 3
    $found.Summary.ArchivedFiles | Should Be 2
  }

  It "doctor recommendations are correct for conflicts" {
    $doctor = ((& $script:scriptPaths.doctor -TaskLabel 'duplicate-scope' -DocsRoot $script:docsRoot -Location all -Format json) | ConvertFrom-Json)
    $doctor.RecommendedAction | Should Be "repair"
  }

  It "doctor recommends restore for archived-only scopes" {
    $doctor = ((& $script:scriptPaths.doctor -TaskLabel 'archived-only-scope' -DocsRoot $script:docsRoot -Location all -Format json) | ConvertFrom-Json)
    $doctor.RecommendedAction | Should Be "restore"
  }

  It "archive creates archive directory and moves files" {
    $archiveResult = ((& $script:scriptPaths.archive -TaskLabel 'checkout-auth-fix' -DocsRoot $script:docsRoot -WorkspaceRoot $script:workspace -Branch $script:branch -Force -Format json) | ConvertFrom-Json)
    $archiveResult.ArchivedCount | Should Be 1
    (Normalize-TestPath $archiveResult.ArchiveDirectory) | Should Be (Normalize-TestPath $script:archiveDir)
    Test-Path -LiteralPath $script:activeScoped | Should Be $false
    $targetPath = Join-Path $script:archiveDir (Split-Path -Leaf $script:activeScoped)
    Test-Path -LiteralPath $targetPath | Should Be $true
  }

  It "archive and restore preserve a two-file completed chain" {
    $older = Join-Path $script:activeDir '20260301_0900_CypressSkillHandover.md'
    $latest = Join-Path $script:activeDir '20260302_0900_CypressSkillHandover.md'
    New-HandoverFixtureFile -Path $older -Timestamp '2026-03-01 09:00' -TaskLabel 'chain-test' -WorkspaceRoot $script:workspace -Branch $script:branch -Status 'Completed' -PreviousHandover 'No prior handover found' -NextAction 'Older checkpoint.'
    New-HandoverFixtureFile -Path $latest -Timestamp '2026-03-02 09:00' -TaskLabel 'chain-test' -WorkspaceRoot $script:workspace -Branch $script:branch -Status 'Completed' -PreviousHandover $older -NextAction 'Latest checkpoint.'

    $archiveResult = ((& $script:scriptPaths.archive -TaskLabel 'chain-test' -DocsRoot $script:docsRoot -WorkspaceRoot $script:workspace -Branch $script:branch -Format json) | ConvertFrom-Json)
    $archiveResult.ArchivedCount | Should Be 2
    (Normalize-TestPath $archiveResult.ArchiveDirectory) | Should Be (Normalize-TestPath $script:archiveDir)

    $restoreResult = ((& $script:scriptPaths.restore -TaskLabel 'chain-test' -DocsRoot $script:docsRoot -WorkspaceRoot $script:workspace -Branch $script:branch -Format json) | ConvertFrom-Json)
    $restoreResult.RestoredCount | Should Be 2
    Test-Path -LiteralPath $older | Should Be $true
    Test-Path -LiteralPath $latest | Should Be $true

    $restoredPrevious = Get-HandoverMetadataLineValue -Path $latest -Label 'Previous handover'
    (Normalize-TestPath $restoredPrevious) | Should Be (Normalize-TestPath $older)
  }

  It "archive rollback removes written archive copies when validation fails" {
    $older = Join-Path $script:activeDir '20260314_0900_CypressSkillHandover.md'
    $latest = Join-Path $script:activeDir '20260315_0900_CypressSkillHandover.md'
    New-HandoverFixtureFile -Path $older -Timestamp '2026-03-14 09:00' -TaskLabel 'archive-rollback' -WorkspaceRoot $script:workspace -Branch 'rollback/archive' -Status 'Completed' -PreviousHandover 'No prior handover found' -NextAction 'Older checkpoint.'
    New-HandoverFixtureFile -Path $latest -Timestamp '2026-03-15 09:00' -TaskLabel 'archive-rollback' -WorkspaceRoot $script:workspace -Branch 'rollback/archive' -Status 'Completed' -PreviousHandover $older -NextAction 'Latest checkpoint.'
    Set-HandoverSectionBody -Path $latest -Heading '### Validation and evidence' -Body 'TBD'

    $failedAsExpected = $false
    try {
      & $script:scriptPaths.archive -DocsRoot $script:docsRoot -TaskLabel 'archive-rollback' -WorkspaceRoot $script:workspace -Branch 'rollback/archive' -Format json | Out-Null
    } catch {
      $failedAsExpected = $_.Exception.Message -like '*validate-handover failed*'
    }

    if (-not $failedAsExpected) { throw "Expected archive to fail when a file fails validation" }
    if (-not (Test-Path -LiteralPath $older -PathType Leaf)) { throw "Expected older active file to remain" }
    if (-not (Test-Path -LiteralPath $latest -PathType Leaf)) { throw "Expected latest active file to remain" }
    $unexpectedArchiveOlder = Join-Path $script:archiveDir '20260314_0900_CypressSkillHandover.md'
    $unexpectedArchiveLatest = Join-Path $script:archiveDir '20260315_0900_CypressSkillHandover.md'
    if (Test-Path -LiteralPath $unexpectedArchiveOlder -PathType Leaf) { throw "Expected archive copy to be removed" }
  }

  It "restore rollback keeps archived files when restore target already exists" {
    $archivedOlder = Join-Path $script:archiveDir '20260302_0900_CypressSkillHandover.md'
    $archivedLatest = Join-Path $script:archiveDir '20260303_0900_CypressSkillHandover.md'
    $conflictingRestoreTarget = Join-Path $script:activeDir '20260302_0900_CypressSkillHandover.md'
    New-HandoverFixtureFile -Path $archivedOlder -Timestamp '2026-03-02 09:00' -TaskLabel 'restore-rollback' -WorkspaceRoot $script:workspace -Branch 'rollback/restore' -Status 'Completed' -PreviousHandover 'No prior handover found' -NextAction 'Older archived checkpoint.'
    New-HandoverFixtureFile -Path $archivedLatest -Timestamp '2026-03-03 09:00' -TaskLabel 'restore-rollback' -WorkspaceRoot $script:workspace -Branch 'rollback/restore' -Status 'Completed' -PreviousHandover $archivedOlder -NextAction 'Latest archived checkpoint.'
    New-HandoverFixtureFile -Path $conflictingRestoreTarget -Timestamp '2026-03-01 08:00' -TaskLabel 'unrelated-active' -WorkspaceRoot $script:workspace -Branch 'rollback/restore' -Status 'Completed' -PreviousHandover 'No prior handover found' -NextAction 'Conflicting active target.'

    $failedAsExpected = $false
    try {
      & $script:scriptPaths.restore -DocsRoot $script:docsRoot -TaskLabel 'restore-rollback' -WorkspaceRoot $script:workspace -Branch 'rollback/restore' -Format json | Out-Null
    } catch {
      $failedAsExpected = $_.Exception.Message -like '*Restore target already exists*'
    }

    if (-not $failedAsExpected) { throw "Expected restore to fail when the target active file already exists" }
    if (-not (Test-Path -LiteralPath $archivedOlder -PathType Leaf)) { throw "Expected older archived file to remain" }
  }

  It "restore rollback removes written active copies when validation fails" {
    $archivedOlder = Join-Path $script:archiveDir '20260316_0900_CypressSkillHandover.md'
    $archivedLatest = Join-Path $script:archiveDir '20260317_0900_CypressSkillHandover.md'
    New-HandoverFixtureFile -Path $archivedOlder -Timestamp '2026-03-16 09:00' -TaskLabel 'restore-validation-rollback' -WorkspaceRoot $script:workspace -Branch 'rollback/restore-validation' -Status 'Completed' -PreviousHandover 'No prior handover found' -NextAction 'Older archived checkpoint.'
    New-HandoverFixtureFile -Path $archivedLatest -Timestamp '2026-03-17 09:00' -TaskLabel 'restore-validation-rollback' -WorkspaceRoot $script:workspace -Branch 'rollback/restore-validation' -Status 'Completed' -PreviousHandover $archivedOlder -NextAction 'Latest archived checkpoint.'
    Set-HandoverSectionBody -Path $archivedLatest -Heading '### Validation and evidence' -Body 'TBD'

    $failedAsExpected = $false
    try {
      & $script:scriptPaths.restore -DocsRoot $script:docsRoot -TaskLabel 'restore-validation-rollback' -WorkspaceRoot $script:workspace -Branch 'rollback/restore-validation' -Format json | Out-Null
    } catch {
      $failedAsExpected = $_.Exception.Message -like '*validate-handover failed*'
    }

    if (-not $failedAsExpected) { throw "Expected restore to fail" }
    if (-not (Test-Path -LiteralPath $archivedOlder -PathType Leaf)) { throw "Expected archived file to remain" }
  }

  It "repair rollback restores rewritten files when scope validation fails" {
    $older = Join-Path $script:activeDir '20260318_0900_CypressSkillHandover.md'
    $latest = Join-Path $script:activeDir '20260319_0900_CypressSkillHandover.md'
    New-HandoverFixtureFile -Path $older -Timestamp '2026-03-18 09:00' -TaskLabel 'repair-rollback' -WorkspaceRoot $script:workspace -Branch 'rollback/repair' -Status 'Completed' -PreviousHandover 'No prior handover found' -NextAction 'Older checkpoint.'
    New-HandoverFixtureFile -Path $latest -Timestamp '2026-03-19 09:00' -TaskLabel 'repair-rollback' -WorkspaceRoot $script:workspace -Branch 'rollback/repair' -Status 'Blocked' -PreviousHandover (Join-Path $script:tempRoot 'missing-prior.md') -NextAction 'Repair the broken link.'
    Set-HandoverSectionBody -Path $older -Heading '### Validation and evidence' -Body 'TBD'
    $originalPrevious = Get-HandoverMetadataLineValue -Path $latest -Label 'Previous handover'

    $failedAsExpected = $false
    try {
      & $script:scriptPaths.repair -DocsRoot $script:docsRoot -Location active -TaskLabel 'repair-rollback' -WorkspaceRoot $script:workspace -Branch 'rollback/repair' -Format json | Out-Null
    } catch {
      $failedAsExpected = $_.Exception.Message -like '*validate-handover failed*'
    }

    if (-not $failedAsExpected) { throw "Expected repair to fail" }
    $currentPrevious = Get-HandoverMetadataLineValue -Path $latest -Label 'Previous handover'
    (Normalize-TestPath $currentPrevious) | Should Be (Normalize-TestPath $originalPrevious)
  }

  It "resolve conflict does not delete either location when kept files fail validation" {
    Set-HandoverSectionBody -Path $script:duplicateActive -Heading '### Validation and evidence' -Body 'TBD'

    $failedAsExpected = $false
    try {
      & $script:scriptPaths.resolve -DocsRoot $script:docsRoot -TaskLabel 'duplicate-scope' -WorkspaceRoot $script:workspace -Branch 'dup/branch' -KeepLocation active -Format json | Out-Null
    } catch {
      $failedAsExpected = $_.Exception.Message -like '*validate-handover failed*'
    }

    if (-not $failedAsExpected) { throw "Expected conflict resolution to fail" }
    if (-not (Test-Path -LiteralPath $script:duplicateActive -PathType Leaf)) { throw "Expected kept active duplicate to remain" }
  }

  It "new-handover rejects cross-scope manual previous overrides" {
    Push-Location $script:tempRoot
    try {
      $rejected = $false
      try {
        & $script:scriptPaths.new -TaskLabel 'checkout auth fix' -DocsRoot 'docs/tests' -PreviousHandover $script:activeOther -Force | Out-Null
      } catch {
        $message = $_.Exception.Message
        $rejected = ($message -like '*same Task label*') -or ($message -like '*same Workspace root*') -or ($message -like '*same Branch*')
      }
      if (-not $rejected) { throw "Expected cross-scope manual previous override to be rejected" }
    } finally {
      Pop-Location
    }
  }
}
