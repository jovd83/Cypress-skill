$scripts = Get-ChildItem -Path documentation/cypress-handover/scripts -Filter *.ps1
foreach ($script in $scripts) {
    $content = Get-Content -Raw -LiteralPath $script.FullName
    if ($content -match '(?m)\^-\s*') {
        Write-Host "Patching $($script.Name)"
        $newContent = $content -replace "\(\?m\)\^-\s*", "(?mi)^(?:\s*-\s*|\s*)"
        
        if ($newContent -ne $content) {
            Set-Content -LiteralPath $script.FullName -Value $newContent -Encoding UTF8
        }
    }
}
