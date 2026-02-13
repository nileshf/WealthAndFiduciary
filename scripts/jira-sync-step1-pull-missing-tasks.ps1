#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Step 1: Pull missing tasks from Jira to project-task.md
.DESCRIPTION
    If task exists in Jira but not in microservice's project-task.md,
    add it to project-task.md with Jira details and comments
#>

param(
    [string]$JiraBaseUrl = $env:JIRA_BASE_URL,
    [string]$JiraEmail = $env:JIRA_USER_EMAIL,
    [string]$JiraToken = $env:JIRA_API_TOKEN,
    [string]$ServiceName = $env:SERVICE_NAME,
    [string]$TaskFile = $env:TASK_FILE
)

$ErrorActionPreference = 'Continue'

Write-Host "=== Step 1: Pull Missing Tasks from Jira ===" -ForegroundColor Green
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
$uri = "$JiraBaseUrl/rest/api/3/search/jql?jql=$([System.Uri]::EscapeDataString($jql))&maxResults=100&fields=key,summary,status,description"

try {
    $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
    $jiraIssues = $response.issues
    Write-Host "✓ Found $($jiraIssues.Count) issues in Jira" -ForegroundColor Green
}
catch {
    Write-Host "✗ Failed to fetch Jira issues: $_" -ForegroundColor Red
    exit 1
}

# Read existing tasks from markdown
Write-Host "`nReading existing tasks from markdown..." -ForegroundColor Cyan
$content = Get-Content $TaskFile -Raw
$existingKeys = @()
$tasksWithoutKeys = @()

$content -split "`n" | ForEach-Object {
    if ($_ -match '\[([x ~-])\]\s+([A-Z]+-\d+)\s*-\s*(.+)') {
        # Task with Jira key
        $existingKeys += $matches[2]
    }
    elseif ($_ -match '\[([x ~-])\]\s*-\s*(.+)') {
        # Task without Jira key - store for matching
        $checkbox = $matches[1]
        $summary = $matches[2].Trim()
        $tasksWithoutKeys += @{
            checkbox = $checkbox
            summary  = $summary
            line     = $_
        }
    }
}
Write-Host "✓ Found $($existingKeys.Count) existing tasks in markdown" -ForegroundColor Green

# Find missing tasks
Write-Host "`nFinding missing tasks..." -ForegroundColor Cyan
$missingTasks = @()
foreach ($issue in $jiraIssues) {
    if ($issue.key -notin $existingKeys) {
        $missingTasks += $issue
    }
}

if ($missingTasks.Count -eq 0) {
    Write-Host "✓ No missing tasks" -ForegroundColor Green
    exit 0
}

Write-Host "✓ Found $($missingTasks.Count) missing task(s)" -ForegroundColor Yellow

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

# Add missing tasks to markdown
Write-Host "`nAdding missing tasks to markdown..." -ForegroundColor Cyan
$updatedContent = $content
foreach ($task in $missingTasks) {
    $checkbox = Get-CheckboxFromStatus $task.fields.status.name
    $newLine = "- [$checkbox] $($task.key) - $($task.fields.summary)"
    $updatedContent += "`n$newLine"
    Write-Host "  ⊕ Added: $($task.key)" -ForegroundColor Yellow
}

# Write updated content
Set-Content -Path $TaskFile -Value $updatedContent
Write-Host "`n✓ Step 1 completed successfully" -ForegroundColor Green
exit 0
