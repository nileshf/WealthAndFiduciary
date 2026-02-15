#!/usr/bin/env pwsh
$line = '- [ ] Test task to jira'
Write-Host "Testing line: $line"
Write-Host ""

# Test different regex patterns
$patterns = @(
    '\[([x ~-])\]\s+([A-Z]+-\d+)?\s*-\s*(.+)'
    '\[([^\]]+)\]\s+([A-Z]+-\d+)?\s*-\s*(.+)'
    '^-\s*\[([^\]]+)\]\s+([A-Z]+-\d+)?\s*-\s*(.+)'
)

foreach ($pattern in $patterns) {
    Write-Host "Pattern: $pattern"
    if ($line -match $pattern) {
        Write-Host "  MATCH!"
        Write-Host "  Checkbox: $($matches[1])"
        Write-Host "  Key: $($matches[2])"
        Write-Host "  Summary: $($matches[3])"
    }
    else {
        Write-Host "  NO MATCH"
    }
    Write-Host ""
}
