$scripts = Get-ChildItem -Path documentation/cypress-handover/scripts -Filter *.ps1
foreach ($script in $scripts) {
    $content = Get-Content -Raw -LiteralPath $script.FullName
    $changed = $false

    # Fix Get-HandoverMetadataValue pattern
    if ($content -match '\(\?m\)\^-\s*') {
        Write-Host "Patching regex in $($script.Name)"
        $content = $content -replace "\(\?m\)\^-\s*", "(?mi)^(?:\s*-\s*|\s*)"
        $changed = $true
    }

    # Specifically for validate-handover.ps1 strict metadata check
    if ($script.Name -eq "validate-handover.ps1") {
        Write-Host "Patching strict check in validate-handover.ps1"
        # Original: if ($text -notmatch ("(?m)^" + [regex]::Escape($metadataLine) + "\s+.+$")) {
        $old = 'if ($text -notmatch ("(?m)^" + [regex]::Escape($metadataLine) + "\s+.+$")) {'
        $new = 'if ($text -notmatch ("(?mi)^(?:\s*-\s*|\s*)" + [regex]::Escape($metadataLine -replace "^- ", "") + "\s+.+$")) {'
        if ($content.Contains($old)) {
            $content = $content.Replace($old, $new)
            $changed = $true
        }
    }

    if ($changed) {
        Set-Content -LiteralPath $script.FullName -Value $content -Encoding UTF8
    }
}
