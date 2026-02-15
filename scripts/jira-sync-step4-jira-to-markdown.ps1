#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Step 4: Sync status changes from Jira to project-task.md
.DESCRIPTION
    If task status changes in project-task.md, update the status in Jira
    to reflect the new status. This runs BEFORE Step 3 so that Jira
    receives updates from markdown first, then markdown is updated from
    Jira (Jira is the ultimate source of truth).
#>

param(
    [string]$JiraBaseUrl = $env:JIRA_BASE_URL,
    [string]$JiraEmail = $env:JIRA_USER_EMAIL,
    [string]$JiraToken = $env:JIRA_API_TOKEN,
    [string]$ServiceName = $env:SERVICE_NAME,
    [string]$TaskFile = $env:TASK_FILE
)

$ErrorActionPreference = 'Continue'

Write-Host "=== Step 4: Sync Status Changes from Jira ===" -ForegroundColor Green
Write-Host "Service: $ServiceName"
Write-Host "Task File: $TaskFile"

# Validation
if (-not $JiraBaseUrl -or -not $JiraEmail -or -not $JiraToken) {
    Write-Host "ERROR: Missing Jira credentials" -ForegroundColor Red
    Write-Host "  JIRA_BASE_URL: $([bool]$JiraBaseUrl)" -ForegroundColor Yellow
    Write-Host "  JIRA_USER_EMAIL: $([bool]$JiraEmail)" -ForegroundColor Yellow
    Write-Host "  JIRA_API_TOKEN: $([bool]$JiraToken) (length: $($JiraToken.Length))" -ForegroundColor Yellow
    exit 1
}

if (-not (Test-Path $TaskFile)) {
    Write-Host "ERROR: Task file not found: $TaskFile" -ForegroundColor Red
    exit 1
}

# Helper: Get Jira Auth
function Get-JiraAuth {
    param([string]$Email, [string]$Token)
    $pair = "$Email`:$Token"
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
    $base64 = [System.Convert]::ToBase64String($bytes)
    Write-Host "  Auth string length: $($pair.Length)" -ForegroundColor Gray
    Write-Host "  Base64 length: $($base64.Length)" -ForegroundColor Gray
    return $base64
}

# Helper: Get Jira Headers
function Get-JiraHeaders {
    param([string]$Email, [string]$Token)
    return @{
        'Authorization' = "Basic $(Get-JiraAuth -Email $Email -Token $Token)"
        'Content-Type'  = 'application/json'
        'Accept'        = 'application/json'
    }
}

# Fetch Jira issues
Write-Host "`nFetching Jira issues..." -ForegroundColor Cyan
$headers = Get-JiraHeaders -Email $JiraEmail -Token $JiraToken
$jql = 'project = WEALTHFID'
$uri = "$JiraBaseUrl/rest/api/3/search/jql?jql=$([System.Uri]::EscapeDataString($jql))&maxResults=100&fields=key,summary,status,updated"

try {
    $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
    $jiraIssues = $response.issues
    Write-Host "Found issues in Jira" -ForegroundColor Green
}
catch {
    Write-Host "✗ Failed to fetch Jira issues" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Yellow
    if ($_.Exception.Response) {
        Write-Host "  Status Code: $($_.Exception.Response.StatusCode)" -ForegroundColor Yellow
        Write-Host "  Status Description: $($_.Exception.Response.StatusDescription)" -ForegroundColor Yellow
    }
    if ($_.ErrorDetails) {
        Write-Host "  Error Details: $($_.ErrorDetails.Message)" -ForegroundColor Yellow
    }
    exit 1
}

# Create Jira status map
$jiraStatusMap = @{}
foreach ($issue in $jiraIssues) {
    $jiraStatusMap[$issue.key] = @{
        status      = $issue.fields.status.name
        transitions = $issue.transitions
    }
}

# Map checkbox to Jira status
function Get-StatusFromCheckbox {
    param([string]$checkbox)
    
    switch ($checkbox) {
        ' ' { return 'To Do' }
        '-' { return 'In Progress' }
        '~' { return 'Testing' }
        'x' { return 'Done' }
        default { return 'To Do' }
    }
}

# Get transition ID for target status
function Get-TransitionId {
    param(
        [object]$transitions,
        [string]$targetStatus
    )
    
    foreach ($transition in $transitions) {
        if ($transition.to.name -eq $targetStatus) {
            return $transition.id
        }
    }
    return $null
}

# Read tasks from markdown
Write-Host "`nReading tasks from markdown..." -ForegroundColor Cyan
$content = Get-Content $TaskFile -Raw
$lines = $content -split "`n"
$statusUpdates = 0

# Process each line
foreach ($line in $lines) {
    if ($line -match '\[([x ~-])\]\s+([A-Z]+-\d+)\s*-\s*(.+)') {
        $checkbox = $matches[1]
        $key = $matches[2]
        $summary = $matches[3]
        
        if ($jiraStatusMap.ContainsKey($key)) {
            $jiraStatus = $jiraStatusMap[$key].status
            $targetStatus = Get-StatusFromCheckbox $checkbox
            
            if ($jiraStatus -ne $targetStatus) {
                # Find transition
                $transitions = $jiraStatusMap[$key].transitions
                $transitionId = Get-TransitionId $transitions $targetStatus
                
                if ($transitionId) {
                    # Update Jira status
                    $transitionUri = "$JiraBaseUrl/rest/api/3/issue/$key/transitions"
                    $transitionBody = @{
                        transition = @{ id = $transitionId }
                    } | ConvertTo-Json

                    try {
                        Invoke-RestMethod -Uri $transitionUri -Headers $headers -Method Post -Body $transitionBody | Out-Null
                        Write-Host "  Updated: $key to [$checkbox] ($targetStatus)" -ForegroundColor Yellow
                        $statusUpdates++
                    }
                    catch {
                        Write-Host "  Failed to update $key" -ForegroundColor Red
                    }
                }
                else {
                    Write-Host "  No transition available for $key to $targetStatus" -ForegroundColor Yellow
                }
            }
        }
    }
}

if ($statusUpdates -eq 0) {
    Write-Host "No status updates needed" -ForegroundColor Green
    exit 0
}

# Write updated content
$updatedContent = $updatedLines -join "`n"
Set-Content -Path $TaskFile -Value $updatedContent

Write-Host "`nStep 4 completed successfully ($statusChanges status change(s))" -ForegroundColor Green
exit 0
