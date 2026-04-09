param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"
$rootAbs = (Resolve-Path -LiteralPath $Root).Path
$skillRoot = Join-Path $rootAbs "documentation/cypress-handover"
$examplePath = Join-Path $skillRoot "references/blocked-handover-example.md"

$scriptPaths = @{
  audit = Join-Path $skillRoot "scripts/audit-handovers.ps1"
  complete = Join-Path $skillRoot "scripts/complete-handover.ps1"
  doctor = Join-Path $skillRoot "scripts/doctor-handover.ps1"
  diff = Join-Path $skillRoot "scripts/diff-handover-checkpoints.ps1"
  export = Join-Path $skillRoot "scripts/export-handover-index.ps1"
  find = Join-Path $skillRoot "scripts/find-handover.ps1"
  new = Join-Path $skillRoot "scripts/new-handover.ps1"
  overview = Join-Path $skillRoot "scripts/overview-handovers.ps1"
  repair = Join-Path $skillRoot "scripts/repair-handover-links.ps1"
  recommend = Join-Path $skillRoot "scripts/recommend-handover.ps1"
  rename = Join-Path $skillRoot "scripts/rename-task-label.ps1"
  resolve = Join-Path $skillRoot "scripts/resolve-handover-location-conflict.ps1"
  resume = Join-Path $skillRoot "scripts/resume-handover.ps1"
  trace = Join-Path $skillRoot "scripts/trace-handover-chain.ps1"
  validate = Join-Path $skillRoot "scripts/validate-handover.ps1"
}

foreach ($scriptPath in $scriptPaths.Values) {
  if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) {
    throw "check-cypress-handover-smoke failed: missing required script $scriptPath"
  }
}

function New-HandoverFile {
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
  $content = [regex]::Replace($content, '(?m)^- Timestamp:\s*.+$', ('- Timestamp: ' + $Timestamp))
  $content = [regex]::Replace($content, '(?m)^- Task label:\s*.+$', ('- Task label: ' + $TaskLabel))
  $content = [regex]::Replace($content, '(?m)^- Workspace root:\s*.+$', ('- Workspace root: ' + $WorkspaceRoot))
  $content = [regex]::Replace($content, '(?m)^- Branch:\s*.+$', ('- Branch: ' + $Branch))
  $content = [regex]::Replace($content, '(?m)^- Previous handover:\s*.+$', ('- Previous handover: ' + $PreviousHandover))
  $content = [regex]::Replace($content, '(?m)^### Current status\r?\n.+$', ("### Current status`r`n" + $Status))
  $content = [regex]::Replace($content, '(?sm)^### Next action\r?\n.*?(?=^### |\z)', ("### Next action`r`n" + $NextAction + "`r`n`r`n"))
  Set-Content -LiteralPath $Path -Value $content -Encoding UTF8
}

function Assert-True([bool]$Condition, [string]$Message) {
  if (-not $Condition) {
    throw $Message
  }
}

$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('cypress-handover-smoke-' + [guid]::NewGuid().ToString('N'))

try {
  $docsRoot = Join-Path $tempRoot 'docs/tests'
  $activeDir = Join-Path $docsRoot 'handovers'
  $archiveDir = Join-Path $activeDir 'archive'
  New-Item -ItemType Directory -Path $activeDir -Force | Out-Null
  New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null

  $workspace = $tempRoot
  $branch = 'Unknown'
  $otherWorkspace = 'C:\projects\other-app'
  $otherBranch = 'feature/other'

  $activeScoped = Join-Path $activeDir '20260312_0900_CypressSkillHandover.md'
  $activeOther = Join-Path $activeDir '20260312_1000_CypressSkillHandover.md'
  $archiveOlder = Join-Path $archiveDir '20260310_0900_CypressSkillHandover.md'
  $archiveLatest = Join-Path $archiveDir '20260311_0900_CypressSkillHandover.md'
  $archiveOnly = Join-Path $archiveDir '20260312_1100_CypressSkillHandover.md'
  $duplicateActive = Join-Path $activeDir '20260308_0900_CypressSkillHandover.md'
  $duplicateArchive = Join-Path $archiveDir '20260308_0900_CypressSkillHandover.md'

  New-HandoverFile -Path $activeScoped -Timestamp '2026-03-12 09:00' -TaskLabel 'checkout-auth-fix' -WorkspaceRoot $workspace -Branch $branch -Status 'In progress' -PreviousHandover 'No prior handover found' -NextAction 'Continue the active checkout auth investigation.'
  New-HandoverFile -Path $activeOther -Timestamp '2026-03-12 10:00' -TaskLabel 'checkout-auth-fix' -WorkspaceRoot $otherWorkspace -Branch $otherBranch -Status 'Blocked' -PreviousHandover 'No prior handover found' -NextAction 'Handle the other workspace scope separately.'
  New-HandoverFile -Path $archiveOlder -Timestamp '2026-03-10 09:00' -TaskLabel 'archived-history' -WorkspaceRoot $workspace -Branch 'release/archive' -Status 'In progress' -PreviousHandover 'No prior handover found' -NextAction 'Review the original archived setup.'
  New-HandoverFile -Path $archiveLatest -Timestamp '2026-03-11 09:00' -TaskLabel 'archived-history' -WorkspaceRoot $workspace -Branch 'release/archive' -Status 'Completed' -PreviousHandover $archiveOlder -NextAction 'Review archived evidence before restore.'
  New-HandoverFile -Path $archiveOnly -Timestamp '2026-03-12 11:00' -TaskLabel 'archived-only-scope' -WorkspaceRoot $workspace -Branch $branch -Status 'Completed' -PreviousHandover 'No prior handover found' -NextAction 'Restore this archived-only scope before more work.'
  New-HandoverFile -Path $duplicateActive -Timestamp '2026-03-08 09:00' -TaskLabel 'duplicate-scope' -WorkspaceRoot $workspace -Branch 'dup/branch' -Status 'Completed' -PreviousHandover 'No prior handover found' -NextAction 'Active copy should stay.'
  New-HandoverFile -Path $duplicateArchive -Timestamp '2026-03-08 09:00' -TaskLabel 'duplicate-scope' -WorkspaceRoot $workspace -Branch 'dup/branch' -Status 'Completed' -PreviousHandover 'No prior handover found' -NextAction 'Archived copy is duplicated.'

  & $scriptPaths.validate -Path $activeScoped | Out-Null
  & $scriptPaths.validate -Path $archiveLatest | Out-Null

  $overviewAll = @(((& $scriptPaths.overview -DocsRoot $docsRoot -Location all -Format json) | ConvertFrom-Json))
  Assert-True ($overviewAll.Count -ge 4) "check-cypress-handover-smoke failed: overview-handovers did not return the expected entries"
  Assert-True ((@($overviewAll | Where-Object { $_.Location -eq 'archive' })).Count -ge 2) "check-cypress-handover-smoke failed: overview-handovers did not surface archived entries"

  $foundArchive = ((& $scriptPaths.find -DocsRoot $docsRoot -TaskLabel 'archived-history' -Location archive -WorkspaceRoot $workspace -Branch 'release/archive' -Format json) | ConvertFrom-Json)
  Assert-True ($foundArchive.Location -eq 'archive') "check-cypress-handover-smoke failed: find-handover did not return an archived match"

  $recommendedArchive = ((& $scriptPaths.recommend -DocsRoot $docsRoot -TaskLabel 'archived-history' -Location archive -IncludeCompleted -WorkspaceRoot $workspace -Branch 'release/archive' -Format json) | ConvertFrom-Json)
  Assert-True ($recommendedArchive.Location -eq 'archive') "check-cypress-handover-smoke failed: recommend-handover did not preserve archive location"

  $tracedArchive = @(((& $scriptPaths.trace -DocsRoot $docsRoot -TaskLabel 'archived-history' -Location archive -WorkspaceRoot $workspace -Branch 'release/archive' -Format json) | ConvertFrom-Json))
  Assert-True ($tracedArchive.Count -eq 2) "check-cypress-handover-smoke failed: trace-handover-chain did not return the archived chain"

  $diffArchive = ((& $scriptPaths.diff -DocsRoot $docsRoot -TaskLabel 'archived-history' -Location archive -WorkspaceRoot $workspace -Branch 'release/archive' -Format json) | ConvertFrom-Json)
  Assert-True (($diffArchive.LatestLocation -eq 'archive') -and ($diffArchive.PreviousLocation -eq 'archive')) "check-cypress-handover-smoke failed: diff-handover-checkpoints did not report archive locations"

  & $scriptPaths.rename -OldTaskLabel 'archived-history' -NewTaskLabel 'archived-history-repaired' -Location archive -DocsRoot $docsRoot -WorkspaceRoot $workspace -Branch 'release/archive' | Out-Null
  $renamedArchiveText = Get-Content -Raw -LiteralPath $archiveLatest
  Assert-True ($renamedArchiveText -match '(?m)^- Task label: archived-history-repaired$') "check-cypress-handover-smoke failed: rename-task-label did not rename the archived scope"
  & $scriptPaths.validate -Path $archiveLatest | Out-Null

  $auditAll = ((& $scriptPaths.audit -DocsRoot $docsRoot -Location all -Format json) | ConvertFrom-Json)
  Assert-True ($auditAll.Summary.ArchivedFiles -ge 3) "check-cypress-handover-smoke failed: audit-handovers did not count archived files"

  $doctorArchiveOnly = ((& $scriptPaths.doctor -DocsRoot $docsRoot -TaskLabel 'archived-only-scope' -Location all -WorkspaceRoot $workspace -Branch $branch -Format json) | ConvertFrom-Json)
  Assert-True ($doctorArchiveOnly.RecommendedAction -eq 'restore') "check-cypress-handover-smoke failed: doctor-handover did not recommend restore for archived-only scope"

  $doctorActive = ((& $scriptPaths.doctor -DocsRoot $docsRoot -TaskLabel 'checkout-auth-fix' -Location active -WorkspaceRoot $workspace -Branch $branch -Format json) | ConvertFrom-Json)
  Assert-True ($doctorActive.RecommendedAction -eq 'resume') "check-cypress-handover-smoke failed: doctor-handover did not recommend resume for active scope"

  $doctorDuplicate = ((& $scriptPaths.doctor -DocsRoot $docsRoot -TaskLabel 'duplicate-scope' -Location all -WorkspaceRoot $workspace -Branch 'dup/branch' -Format json) | ConvertFrom-Json)
  Assert-True ($doctorDuplicate.RecommendedAction -eq 'repair') "check-cypress-handover-smoke failed: doctor-handover did not recommend repair for duplicate active/archive scope"
  Assert-True ($doctorDuplicate.Command -like '*resolve-handover-location-conflict.ps1*') "check-cypress-handover-smoke failed: doctor-handover did not point duplicate scopes to the location-conflict resolver"

  $indexPath = Join-Path $tempRoot 'handover-index.json'
  $exportedIndex = ((& $scriptPaths.export -DocsRoot $docsRoot -Location all -IncludeHistory -Format json -OutputPath $indexPath) | ConvertFrom-Json)
  Assert-True (Test-Path -LiteralPath $indexPath -PathType Leaf) "check-cypress-handover-smoke failed: export-handover-index did not write the requested output file"
  Assert-True ((@($exportedIndex.LatestScopes)).Count -ge 4) "check-cypress-handover-smoke failed: export-handover-index did not include the latest scopes"
  Assert-True (@($exportedIndex.LatestScopes | Where-Object { $_.History.Count -ge 1 }).Count -ge 1) "check-cypress-handover-smoke failed: export-handover-index did not include scope history when requested"
  $csvExport = @(((& $scriptPaths.export -DocsRoot $docsRoot -Location all -Format csv) | Out-String).Trim().Split([Environment]::NewLine))
  Assert-True ($csvExport[0] -like '"Location","TaskLabel"*') "check-cypress-handover-smoke failed: export-handover-index did not emit CSV headers"

  $repairOlder = Join-Path $activeDir '20260309_0900_CypressSkillHandover.md'
  $repairLatest = Join-Path $activeDir '20260310_0900_CypressSkillHandover.md'
  New-HandoverFile -Path $repairOlder -Timestamp '2026-03-09 09:00' -TaskLabel 'repairable-scope' -WorkspaceRoot $workspace -Branch 'repair/branch' -Status 'In progress' -PreviousHandover 'No prior handover found' -NextAction 'Keep the older checkpoint for chain repair.'
  New-HandoverFile -Path $repairLatest -Timestamp '2026-03-10 09:00' -TaskLabel 'repairable-scope' -WorkspaceRoot $workspace -Branch 'repair/branch' -Status 'Blocked' -PreviousHandover (Join-Path $tempRoot 'missing-prior.md') -NextAction 'Repair the broken chain link.'
  $repairResult = ((& $scriptPaths.repair -DocsRoot $docsRoot -Location active -TaskLabel 'repairable-scope' -WorkspaceRoot $workspace -Branch 'repair/branch' -Format json) | ConvertFrom-Json)
  Assert-True ($repairResult.RewrittenFiles -ge 1) "check-cypress-handover-smoke failed: repair-handover-links did not rewrite the broken scope"
  & $scriptPaths.validate -Path $repairLatest | Out-Null

  $resolvedConflict = ((& $scriptPaths.resolve -DocsRoot $docsRoot -TaskLabel 'duplicate-scope' -WorkspaceRoot $workspace -Branch 'dup/branch' -KeepLocation active -Format json) | ConvertFrom-Json)
  Assert-True ($resolvedConflict.KeptLocation -eq 'active') "check-cypress-handover-smoke failed: resolve-handover-location-conflict did not keep the requested location"
  Assert-True (-not (Test-Path -LiteralPath $duplicateArchive -PathType Leaf)) "check-cypress-handover-smoke failed: resolve-handover-location-conflict did not remove the dropped archive copy"
  $auditAfterResolve = ((& $scriptPaths.audit -DocsRoot $docsRoot -Location all -Format json) | ConvertFrom-Json)
  Assert-True ((@($auditAfterResolve.CrossLocationScopeCollisions | Where-Object { $_.TaskLabel -eq 'duplicate-scope' })).Count -eq 0) "check-cypress-handover-smoke failed: resolve-handover-location-conflict did not clear the active/archive collision"

  Push-Location $tempRoot
  try {
    $beforeNewPaths = @(
      Get-ChildItem -LiteralPath $activeDir -File -Filter "*_CypressSkillHandover.md" |
        Select-Object -ExpandProperty FullName
    )
      & $scriptPaths.new -TaskLabel 'checkout auth fix' -DocsRoot 'docs/tests'
    $newPath = @(
      Get-ChildItem -LiteralPath $activeDir -File -Filter "*_CypressSkillHandover.md" |
        Select-Object -ExpandProperty FullName |
        Where-Object { $beforeNewPaths -notcontains $_ }
    ) | Select-Object -First 1
    Assert-True (Test-Path -LiteralPath $newPath -PathType Leaf) "check-cypress-handover-smoke failed: new-handover did not create a file"
    $newText = Get-Content -Raw -LiteralPath $newPath
    Assert-True ($newText -match [regex]::Escape('- Previous handover: ' + ($activeScoped -replace '\\', '/'))) "check-cypress-handover-smoke failed: new-handover did not link the same active scope"

    $manualScopeRejected = $false
    try {
      & $scriptPaths.new -TaskLabel 'checkout auth fix' -DocsRoot 'docs/tests' -PreviousHandover $activeOther -Force | Out-Null
    } catch {
      $message = $_.Exception.Message
      $manualScopeRejected = (
        ($message -like '*same Task label*') -or
        ($message -like '*same Workspace root*') -or
        ($message -like '*same Branch*')
      )
    }
    Assert-True $manualScopeRejected "check-cypress-handover-smoke failed: new-handover accepted a cross-scope manual previous handover"

    $archiveOnlyRejected = $false
    try {
      & $scriptPaths.new -TaskLabel 'archived only scope' -DocsRoot 'docs/tests' -Force | Out-Null
    } catch {
      $message = $_.Exception.Message
      $archiveOnlyRejected = ($message -like '*exists only in archive*') -and ($message -like '*restore-handover-scope.ps1*')
    }
    Assert-True $archiveOnlyRejected "check-cypress-handover-smoke failed: new-handover did not enforce restore-first behavior for archived-only scope"

    $resumeRejected = $false
    try {
      & $scriptPaths.resume -TaskLabel 'archived-only-scope' -DocsRoot 'docs/tests' -WorkspaceRoot $workspace -Branch $branch -ProgressNote 'Attempted resume.' -NextAction 'Restore first.' | Out-Null
    } catch {
      $message = $_.Exception.Message
      $resumeRejected = ($message -like '*exists only in archive*') -and ($message -like '*restore-handover-scope.ps1*')
    }
    Assert-True $resumeRejected "check-cypress-handover-smoke failed: resume-handover did not direct archived-only scope to restore"

    $completeRejected = $false
    try {
      & $scriptPaths.complete -TaskLabel 'archived-only-scope' -DocsRoot 'docs/tests' -WorkspaceRoot $workspace -Branch $branch -ValidationNote 'Would complete after restore.' | Out-Null
    } catch {
      $message = $_.Exception.Message
      $completeRejected = ($message -like '*exists only in archive*') -and ($message -like '*restore-handover-scope.ps1*')
    }
    Assert-True $completeRejected "check-cypress-handover-smoke failed: complete-handover did not direct archived-only scope to restore"
  } finally {
    Pop-Location
  }
} finally {
  if (Test-Path -LiteralPath $tempRoot) {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force
  }
}

Write-Host "check-cypress-handover-smoke: OK"
