#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Updates JIRA_API_TOKEN and CONFLUENCE_API_TOKEN in all .env files
.DESCRIPTION
    Reads tokens from .kiro/settings/mcp.json and updates all .env files
    in the repository with the new values.
#>

param(
    [string]$McpConfigPath = ".kiro/settings/mcp.json",
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'

Write-Host "=== Update .env Tokens ===" -ForegroundColor Green
Write-Host "MCP Config: $McpConfigPath"
Write-Host ""

if (-not (Test-Path $McpConfigPath)) {
    Write-Host "ERROR: MCP config not found: $McpConfigPath" -ForegroundColor Red
    exit 1
}

try {
    $mcpConfig = Get-Content $McpConfigPath -Raw | ConvertFrom-Json
} catch {
    Write-Host "ERROR: Failed to parse MCP config: $_" -ForegroundColor Red
    exit 1
}

$jiraToken = $null
$confluenceToken = $null

# Check for mcp-atlassian server (Atlassian MCP)
if ($mcpConfig.mcpServers.'mcp-atlassian' -and $mcpConfig.mcpServers.'mcp-atlassian'.env) {
    $jiraToken = $mcpConfig.mcpServers.'mcp-atlassian'.env.JIRA_API_TOKEN
    $confluenceToken = $mcpConfig.mcpServers.'mcp-atlassian'.env.CONFLUENCE_API_TOKEN
}

if (-not $jiraToken) {
    Write-Host "ERROR: JIRA_API_TOKEN not found in MCP config" -ForegroundColor Red
    exit 1
}

if (-not $confluenceToken) {
    Write-Host "ERROR: CONFLUENCE_API_TOKEN not found in MCP config" -ForegroundColor Red
    exit 1
}

Write-Host "Found tokens in MCP config:" -ForegroundColor Cyan
Write-Host "  JIRA_API_TOKEN: [REDACTED] (length: $($jiraToken.Length))" -ForegroundColor Gray
Write-Host "  CONFLUENCE_API_TOKEN: [REDACTED] (length: $($confluenceToken.Length))" -ForegroundColor Gray
Write-Host ""

$envFiles = Get-ChildItem -Path "." -Filter "*.env" -Recurse -File `
    | Where-Object { $_.FullName -notmatch '\\\.nuget\\' -and $_.FullName -notmatch '\\\.git\\' }
Write-Host "Found $($envFiles.Count) .env files:" -ForegroundColor Cyan
foreach ($file in $envFiles) {
    Write-Host "  - $($file.FullName)"
}
Write-Host ""

$updatedCount = 0
foreach ($envFile in $envFiles) {
    Write-Host "Processing: $($envFile.FullName)" -ForegroundColor Yellow
    
    $content = Get-Content $envFile.FullName -Raw
    $originalContent = $content
    
    $content = $content -replace '^JIRA_API_TOKEN=.*$', "JIRA_API_TOKEN=$jiraToken"
    $content = $content -replace '^CONFLUENCE_API_TOKEN=.*$', "CONFLUENCE_API_TOKEN=$confluenceToken"
    
    if ($content -ne $originalContent) {
        if ($WhatIf) {
            Write-Host "  [WHATIF] Would write changes" -ForegroundColor Cyan
        } else {
            Set-Content -Path $envFile.FullName -Value $content -NoNewline
            Write-Host "  Written changes" -ForegroundColor Green
        }
        $updatedCount++
    } else {
        Write-Host "  No changes needed" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Green
Write-Host "Updated $updatedCount of $($envFiles.Count) .env files"

if ($WhatIf) {
    Write-Host "[WHATIF] Run without -WhatIf to apply changes" -ForegroundColor Cyan
}

exit 0
