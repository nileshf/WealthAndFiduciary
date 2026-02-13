#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Step 3: Sync status changes from Jira to project-task.md
.DESCRIPTION
    If task status changes in Jira, update the checkbox in project-task.md
    to reflect the new status
#>

param(
    [string]$JiraBaseUrl = $env:JIRA_BASE_URL,
    [string]$JiraEmail = $env:JIRA_USER_EMAIL,
    [string]$JiraToken = $env:JIRA_API_TOKEN,
    [string]$ServiceName = $env:SERVICE_NAME,
    [string]$TaskFile = $env:TASK_FILE
)

$ErrorActionPreference = 'Continue'

Write-Host "=== Step 3: Sync Status Changes from Jira ===" -ForegroundColor Green
Write-Host "Service: $ServiceName"
Write-Host "Task File: $TaskFile"

# Validation
if (-not $JiraBaseUrl -or -not $JiraEmail -or -not $JiraToken) {
    Write-Host "ERROR: Missing Jira credentials" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $TaskFile)) {
    Write-Host "ERROR: Task file not found: $TaskFile" -ForegroundColor Red
    exit 1
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
        'Content-Type'  = 'application/json'
        'Accept'        = 'application/json'
    }
}

# Fetch Jira issues
Write-Host "`nFetching Jira issues..." -ForegroundColor Cyan
$headers = Get-JiraHeaders
$jql = 'project = WEALTHFID'
$uri = "$JiraBaseUrl/rest/api/3/search/jql?jql=$([System.Uri]::EscapeDataString($jql))&maxResults=100&fields=key,summary,status"

try {
    $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
    $jiraIssues = $response.issues
    Write-Host "✓ Found $($jiraIssues.Count) issues in Jira" -ForegroundColor Green
}
catch {
    Write-Host "✗ Failed to fetch Jira issues: $_" -ForegroundColor Red
    exit 1
}

# Create status map
$statusMap = @{}
foreach ($issue in $jiraIssues) {
    $statusMap[$issue.key] = $issue.fields.status.name
}

# Read tasks from markdown
Write-Host "`nReading tasks from markdown..." -ForegroundColor Cyan
$content = Get-Content $TaskFile -Raw
$lines = $content -split "`n"
$updatedLines = @()
$statusChanges = 0

# Map Jira status to checkbox
function Get-CheckboxFromStatus {
    param([string]$status)
    
    switch ($status.ToLower()) {
        'to do' { return ' ' }
        'in progress' { return '-' }
        'in review' { return '-' }
        'testing' { return '~' }
        'ready to merge' { return '~' }
        'done' { return 'x' }
        default { return ' ' }
    }
}

# Process each line
foreach ($line in $lines) {
    if ($line -match '\[([x ~-])\]\s+([A-Z]+-\d+)\s*-\s*(.+)$') {
        $currentCheckbox = $matches[1]
        $key = $matches[2]
        $summary = $matches[3]
        
        if ($statusMap.ContainsKey($key)) {
            $jiraStatus = $statusMap[$key]
            $newCheckbox = Get-CheckboxFromStatus $jiraStatus
            
            if ($currentCheckbox -ne $newCheckbox) {
                $newLine = "- [$newCheckbox] $key - $summary"
                $updatedLines += $newLine
                Write-Host "  ⟳ Updated: $key from [$currentCheckbox] to [$newCheckbox]" -ForegroundColor Yellow
                $statusChanges++
            }
            else {
                $updatedLines += $line
            }
        }
        else {
            $updatedLines += $line
        }
    }
    else {
        $updatedLines += $line
    }
}

if ($statusChanges -eq 0) {
    Write-Host "`n✓ No status changes detected" -ForegroundColor Green
    exit 0
}

# Write updated content
$updatedContent = $updatedLines -join "`n"
Set-Content -Path $TaskFile -Value $updatedContent

Write-Host "`n✓ Step 3 completed successfully ($statusChanges status change(s))" -ForegroundColor Green
exit 0
