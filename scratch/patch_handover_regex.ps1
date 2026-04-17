$scripts = Get-ChildItem -Path documentation/cypress-handover/scripts -Filter *.ps1
$regexToFind = '(?m)\^\- '
$replacement = '(?mi)^(?:\s*-\s*|\s*)'

foreach ($script in $scripts) {
    $content = Get-Content -Raw -LiteralPath $script.FullName
    if ($content -match 'Get-HandoverMetadataValue') {
        Write-Host "Patching $($script.Name)"
        # Update function definition pattern
        $newContent = $content -replace "pattern = '(?m)\^-\s*'", "pattern = '(?mi)^(?:\s*-\s*|\s*)'"
        $newContent = $newContent -replace 'pattern = "(?m)\^-\s*"', 'pattern = "(?mi)^(?:\s*-\s*|\s*)"'
        # Also handle cases where the dash is missing in the regex string
        $newContent = $newContent -replace "pattern = '(?m)\^'", "pattern = '(?mi)^(?:\s*-\s*|\s*)'"
        
        if ($newContent -ne $content) {
            Set-Content -LiteralPath $script.FullName -Value $newContent -Encoding UTF8
        }
    }
}
