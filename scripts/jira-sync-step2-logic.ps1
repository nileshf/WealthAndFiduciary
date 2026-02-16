#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Step 2: Push new tasks from project-task.md to Jira (Core Logic)
.DESCRIPTION
    This is the core logic for Step 2. It expects environment variables to be loaded.
    Use jira-sync-step2-push-new-tasks.ps1 to run this with service discovery and env loading.
#>

param(
    [string]$JiraBaseUrl = $env:JIRA_BASE_URL,
    [string]$JiraEmail = $env:JIRA_USER_EMAIL,
    [string]$JiraToken = $env:JIRA_API_TOKEN,
    [string]$ServiceName = $env:SERVICE_NAME,
    [string]$TaskFile = $env:TASK_FILE,
    [string]$ProjectKey = $env:JIRA_PROJECT_KEY
)

$ErrorActionPreference = 'Continue'

Write-Host "=== Step 2: Push New Tasks to Jira ===" -ForegroundColor Green
Write-Host "Service: $ServiceName"
Write-Host "Task File: $TaskFile"
Write-Host "Project Key: $ProjectKey"

# Validation
if (-not $JiraBaseUrl -or -not $JiraEmail -or -not $JiraToken) {
    Write-Host "ERROR: Missing Jira credentials" -ForegroundColor Red
    $global:Step2Result = 1
    return 1
}

if (-not $ProjectKey) {
    Write-Host "ERROR: Missing JIRA_PROJECT_KEY" -ForegroundColor Red
    $global:Step2Result = 1
    return 1
}

if (-not (Test-Path $TaskFile)) {
    Write-Host "ERROR: Task file not found: $TaskFile" -ForegroundColor Red
    $global:Step2Result = 1
    return 1
}

# Helper: Get Jira Auth
function Get-JiraAuth {
    param([string]$Email, [string]$Token)
    $pair = "$Email`:$Token"
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
    return [System.Convert]::ToBase64String($bytes)
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

# Fetch existing Jira issues
Write-Host "`nFetching existing Jira issues..." -ForegroundColor Cyan
$headers = Get-JiraHeaders -Email $JiraEmail -Token $JiraToken
$jql = "project = $ProjectKey"
$uri = "$JiraBaseUrl/rest/api/3/search/jql?jql=$([System.Uri]::EscapeDataString($jql))&maxResults=100&fields=key,summary"

try {
    $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
    $jiraIssues = $response.issues
    $jiraKeys = $jiraIssues | ForEach-Object { $_.key }
    Write-Host "Found issues in Jira" -ForegroundColor Green
}
catch {
    Write-Host "Failed to fetch Jira issues: $_" -ForegroundColor Red
    $global:Step2Result = 1
    return 1
}

# Read tasks from markdown
Write-Host "`nReading tasks from markdown..." -ForegroundColor Cyan
$content = Get-Content $TaskFile -Raw
$markdownTasks = @()

$content -split "`n" | ForEach-Object {
    if ($_ -match '^-\s*\[([^\]]+)\](?:\s+([A-Z]+-\d+)\s*-\s*)?(.+)$') {
        $checkbox = $matches[1]
        $key = $matches[2]
        $summary = $matches[3].Trim()
        
        $markdownTasks += @{
            checkbox = $checkbox
            key      = $key
            summary  = $summary
            line     = $_
        }
    }
}

Write-Host "Found tasks in markdown" -ForegroundColor Green

# Find new tasks (no Jira key yet)
Write-Host "`nFinding new tasks without Jira keys..." -ForegroundColor Cyan
$newTasks = $markdownTasks | Where-Object { -not $_.key }

if ($newTasks.Count -eq 0) {
    Write-Host "No new tasks to push" -ForegroundColor Green
    $global:Step2Result = 0
    return 0
}

Write-Host "Found new task(s)" -ForegroundColor Yellow

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

# Create tasks in Jira
Write-Host "`nCreating tasks in Jira..." -ForegroundColor Cyan
$updatedContent = $content
$updateMap = @{}

foreach ($task in $newTasks) {
    try {
        $status = Get-StatusFromCheckbox $task.checkbox
        
        # Create the issue first (without status - determined by workflow)
        $createBody = @{
            fields = @{
                project = @{ key = $ProjectKey }
                summary = $task.summary
                issuetype = @{ name = 'Task' }
                labels = @($ServiceName)
            }
        } | ConvertTo-Json

        $createUri = "$JiraBaseUrl/rest/api/3/issue"
        $createResponse = Invoke-RestMethod -Uri $createUri -Headers $headers -Method Post -Body $createBody
        $newKey = $createResponse.key
        
        Write-Host "Created: $newKey - $($task.summary)" -ForegroundColor Yellow
        
        # Get available transitions for this issue
        $transitionsUri = "$JiraBaseUrl/rest/api/3/issue/$newKey/transitions"
        $transitionsResponse = Invoke-RestMethod -Uri $transitionsUri -Headers $headers -Method Get
        
        # Find the transition that matches the desired status
        $targetTransition = $transitionsResponse.transitions | Where-Object { $_.to.name -eq $status }
        
        if ($targetTransition) {
            # Update the status
            $transitionBody = @{
                transition = @{ id = $targetTransition.id }
            } | ConvertTo-Json
            
            $transitionUri = "$JiraBaseUrl/rest/api/3/issue/$newKey/transitions"
            $transitionResponse = Invoke-RestMethod -Uri $transitionUri -Headers $headers -Method Post -Body $transitionBody
            
            Write-Host "  Set status to: $status" -ForegroundColor Cyan
        }
        else {
            Write-Host "  WARNING: No transition found for status '$status'. Available transitions: $($transitionsResponse.transitions.name -join ', ')" -ForegroundColor Yellow
        }
        
        # Store mapping for update
        $updateMap[$task.line] = "- [$($task.checkbox)] $newKey - $($task.summary)"
    }
    catch {
        Write-Host "Failed to create task '$($task.summary)'" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Yellow
        if ($_.Exception.Response) {
            Write-Host "  Status Code: $($_.Exception.Response.StatusCode)" -ForegroundColor Yellow
            Write-Host "  Status Description: $($_.Exception.Response.StatusDescription)" -ForegroundColor Yellow
        }
        if ($_.ErrorDetails) {
            Write-Host "  Error Details: $($_.ErrorDetails.Message)" -ForegroundColor Yellow
        }
    }
}

# Update markdown with new Jira keys
Write-Host "`nUpdating markdown with Jira keys..." -ForegroundColor Cyan
foreach ($oldLine in $updateMap.Keys) {
    $newLine = $updateMap[$oldLine]
    $updatedContent = $updatedContent -replace [regex]::Escape($oldLine), $newLine
    Write-Host "Updated: $newLine" -ForegroundColor Green
}

# Write updated content
Set-Content -Path $TaskFile -Value $updatedContent
Write-Host "`nStep 2 completed successfully" -ForegroundColor Green
$global:Step2Result = 0
return 0
