#!/usr/bin/env pwsh
$line = '- [ ] Test task to jira'
Write-Host "Testing line: $line"
Write-Host ""

# The task format is: - [checkbox] [optional-key] - summary
# But for tasks without a key, it's: - [checkbox] summary
# So we need to handle both cases

# Pattern 1: With Jira key
$pattern1 = '^-\s*\[([^\]]+)\]\s+([A-Z]+-\d+)\s*-\s*(.+)'
Write-Host "Pattern 1 (with key): $pattern1"
if ($line -match $pattern1) {
    Write-Host "  MATCH!"
    Write-Host "  Checkbox: $($matches[1])"
    Write-Host "  Key: $($matches[2])"
    Write-Host "  Summary: $($matches[3])"
}
else {
    Write-Host "  NO MATCH"
}
Write-Host ""

# Pattern 2: Without Jira key
$pattern2 = '^-\s*\[([^\]]+)\]\s+(.+)$'
Write-Host "Pattern 2 (without key): $pattern2"
if ($line -match $pattern2) {
    Write-Host "  MATCH!"
    Write-Host "  Checkbox: $($matches[1])"
    Write-Host "  Summary: $($matches[2])"
}
else {
    Write-Host "  NO MATCH"
}
Write-Host ""

# Combined pattern
$patternCombined = '^-\s*\[([^\]]+)\](?:\s+([A-Z]+-\d+)\s*-\s*)?(.+)$'
Write-Host "Combined pattern: $patternCombined"
if ($line -match $patternCombined) {
    Write-Host "  MATCH!"
    Write-Host "  Checkbox: $($matches[1])"
    Write-Host "  Key: $($matches[2])"
    Write-Host "  Summary: $($matches[3])"
}
else {
    Write-Host "  NO MATCH"
}
