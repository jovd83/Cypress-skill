$scripts = Get-ChildItem -Path documentation/cypress-handover/scripts -Filter *.ps1
foreach ($script in $scripts) {
    $content = Get-Content -Raw -LiteralPath $script.FullName
    if ($content -match 'Get-HandoverMetadataValue') {
        Write-Host "Patching $($script.Name)"
        # Match pattern = '(?m)^- ' or similar
        # We want to replace the part between ' and ' or " and "
        $newContent = [regex]::Replace($content, "pattern = '(?m)\^.*?'", "pattern = '(?mi)^(?:\s*-\s*|\s*)'")
        $newContent = [regex]::Replace($newContent, 'pattern = "(?m)\^.*?"', 'pattern = "(?mi)^(?:\s*-\s*|\s*)"')
        
        if ($newContent -ne $content) {
            Set-Content -LiteralPath $script.FullName -Value $newContent -Encoding UTF8
        }
    }
}
