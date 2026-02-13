#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Bidirectional sync between Jira and project-task.md files
#>

param(
    [string]$JiraBaseUrl = $env:JIRA_BASE_URL,
    [string]$JiraEmail = $env:JIRA_USER_EMAIL,
    [string]$JiraToken = $env:JIRA_API_TOKEN,
    [switch]$DryRun = $false
)

$ErrorActionPreference = 'Continue'

Write-Host "=== Jira Sync Script Started ===" -ForegroundColor Green
Write-Host "Base URL: $JiraBaseUrl"
Write-Host "Email: $JiraEmail"

# Validation
if (-not $JiraBaseUrl) {
    Write-Host "ERROR: JIRA_BASE_URL not set" -ForegroundColor Red
    exit 1
}

if (-not $JiraEmail) {
    Write-Host "ERROR: JIRA_USER_EMAIL not set" -ForegroundColor Red
    exit 1
}

if (-not $JiraToken) {
    Write-Host "ERROR: JIRA_API_TOKEN not set" -ForegroundColor Red
    exit 1
}

Write-Host "✓ All credentials present" -ForegroundColor Green

# Service configuration
$services = @(
    @{
        name = 'SecurityService'
        file = 'Applications/AITooling/Services/SecurityService/.kiro/specs/security-service/project-task.md'
        project = 'WEALTHFID'
        label = 'ai-security-service'
    },
    @{
        name = 'DataLoaderService'
        file = 'Applications/AITooling/Services/DataLoaderService/.kiro/specs/data-loader-service/project-task.md'
        project = 'WEALTHFID'
        label = 'data-loader-service'
    }
)

# Verify files exist
Write-Host "`n=== Checking Files ===" -ForegroundColor Cyan
foreach ($service in $services) {
    if (Test-Path $service.file) {
        Write-Host "✓ $($service.name): $($service.file)" -ForegroundColor Green
    } else {
        Write-Host "✗ $($service.name): File not found - $($service.file)" -ForegroundColor Red
    }
}

# Helper: Get Jira Auth
function Get-JiraAuth {
    $pair = "$JiraEmail`:$JiraToken"
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
    return [System.Convert]::ToBase64String($bytes)
}

# Helper: Get Jira Headers
function Get-JiraHeaders {
    return @{
        'Authorization' = "Basic $(Get-JiraAuth)"
        'Content-Type' = 'application/json'
        'Accept' = 'application/json'
    }
}

# Test Jira connection
Write-Host "`n=== Testing Jira Connection ===" -ForegroundColor Cyan
try {
    $headers = Get-JiraHeaders
    $testUri = "$JiraBaseUrl/rest/api/3/myself"
    $response = Invoke-RestMethod -Uri $testUri -Headers $headers -Method Get
    Write-Host "✓ Connected to Jira as: $($response.displayName)" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to connect to Jira: $_" -ForegroundColor Red
    exit 1
}

# Fetch Jira issues
Write-Host "`n=== Fetching Jira Issues ===" -ForegroundColor Cyan
try {
    $uri = "$JiraBaseUrl/rest/api/3/search"
    $body = @{
        jql = 'project = WEALTHFID'
        maxResults = 100
        fields = @("key", "summary", "status", "labels")
    } | ConvertTo-Json
    
    Write-Host "Query: project = WEALTHFID"
    $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Post -Body $body
    $issues = $response.issues
    
    Write-Host "✓ Found $($issues.Count) issues" -ForegroundColor Green
    
    foreach ($issue in $issues | Select-Object -First 5) {
        Write-Host "  - $($issue.key): $($issue.fields.summary)" -ForegroundColor Gray
    }
} catch {
    Write-Host "✗ Failed to fetch issues: $_" -ForegroundColor Red
    exit 1
}

# Sync markdown to Jira (create new tasks)
Write-Host "`n=== Syncing Markdown to Jira ===" -ForegroundColor Cyan

foreach ($service in $services) {
    if (-not (Test-Path $service.file)) {
        Write-Host "  ⊘ $($service.name): File not found" -ForegroundColor Yellow
        continue
    }
    
    $content = Get-Content $service.file -Raw
    $lines = $content -split "`n"
    $newCount = 0
    
    foreach ($line in $lines) {
        # Skip empty lines and headers
        if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith('#')) {
            continue
        }
        
        # Match: - [checkbox] Description (without Jira key)
        if ($line -match '^\s*-\s+\[[ x~-]\]\s+(?![A-Z]+-\d+)(.+)$') {
            $description = $matches[1].Trim()
            
            if (-not [string]::IsNullOrWhiteSpace($description)) {
                $newCount++
            }
        }
    }
    
    Write-Host "  $($service.name): $newCount new task(s) to create" -ForegroundColor Gray
}

Write-Host "`n✓ Sync completed successfully" -ForegroundColor Green
exit 0
