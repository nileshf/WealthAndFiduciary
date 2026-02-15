#!/usr/bin/env pwsh
$line = '- [ ] Test task to jira'
Write-Host "Testing line: $line"
Write-Host "Line length: $($line.Length)"
Write-Host "Line bytes: $([System.Text.Encoding]::UTF8.GetBytes($line) -join ',')"
Write-Host ""

# Check each character
Write-Host "Character analysis:"
for ($i = 0; $i -lt $line.Length; $i++) {
    $c = $line[$i]
    $code = [int]$c
    Write-Host "  [$i] '$c' (code: $code)"
}

Write-Host ""
Write-Host "Testing with explicit pattern:"
$pattern = '^-\s*\[([^\]]+)\]\s+([A-Z]+-\d+)?\s*-\s*(.+)'
Write-Host "Pattern: $pattern"
Write-Host "Match result: $(-not (-not ($line -match $pattern)))"
