#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Step 1: Pull existing tasks from Jira to project-task.md
.DESCRIPTION
    If task exists in Jira but not in project-task.md, add it to the markdown file
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

Write-Host "=== Step 1: Pull Existing Tasks from Jira ===" -ForegroundColor Green
Write-Host "Service: $ServiceName"
Write-Host "Task File: $TaskFile"
Write-Host "Project Key: $ProjectKey"

# Validation
if (-not $JiraBaseUrl -or -not $JiraEmail -or -not $JiraToken) {
    Write-Host "ERROR: Missing Jira credentials" -ForegroundColor Red
    $global:Step1Result = 1
    return 1
}

if (-not $ProjectKey) {
    Write-Host "ERROR: Missing JIRA_PROJECT_KEY" -ForegroundColor Red
    $global:Step1Result = 1
    return 1
}

if (-not (Test-Path $TaskFile)) {
    Write-Host "ERROR: Task file not found: $TaskFile" -ForegroundColor Red
    $global:Step1Result = 1
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
$jql = "project = $ProjectKey AND labels = $ServiceName"
$uri = "$JiraBaseUrl/rest/api/3/search/jql?jql=$([System.Uri]::EscapeDataString($jql))&maxResults=100&fields=key,summary,status"

try {
    $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
    $jiraIssues = $response.issues
    Write-Host "Found $($jiraIssues.Count) issues in Jira" -ForegroundColor Green
}
catch {
    Write-Host "Failed to fetch Jira issues: $_" -ForegroundColor Red
    $global:Step1Result = 1
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

Write-Host "Found $($markdownTasks.Count) tasks in markdown" -ForegroundColor Green

# Get markdown task keys
$markdownKeys = $markdownTasks | Where-Object { $_.key } | ForEach-Object { $_.key }

# Find Jira tasks not in markdown
Write-Host "`nFinding Jira tasks not in markdown..." -ForegroundColor Cyan
$missingTasks = $jiraIssues | Where-Object { $_.key -notin $markdownKeys }

if ($missingTasks.Count -eq 0) {
    Write-Host "No missing tasks to pull" -ForegroundColor Green
    $global:Step1Result = 0
    return 0
}

Write-Host "Found $($missingTasks.Count) missing task(s)" -ForegroundColor Yellow

# Map Jira status to markdown checkbox
function Get-CheckboxFromStatus {
    param([string]$status)
    
    switch ($status) {
        'To Do' { return ' ' }
        'In Progress' { return '-' }
        'In Review' { return '-' }
        'Testing' { return '~' }
        'Ready to Merge' { return '~' }
        'Done' { return 'x' }
        default { return ' ' }
    }
}

# Add missing tasks to markdown
Write-Host "`nAdding missing tasks to markdown..." -ForegroundColor Cyan
$updateMap = @{}

foreach ($issue in $missingTasks) {
    $status = $issue.fields.status.name
    $checkbox = Get-CheckboxFromStatus $status
    $summary = $issue.fields.summary
    
    $newLine = "- [$checkbox] $($issue.key) - $summary"
    $updateMap[$issue.key] = $newLine
    
    Write-Host "Adding: $newLine" -ForegroundColor Green
}

# Insert missing tasks after the Implementation Tasks section
Write-Host "`nUpdating markdown file..." -ForegroundColor Cyan

# Find the line after "## Implementation Tasks"
$lines = $content -split "`n"
$implementationSectionIndex = -1
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^## Implementation Tasks$') {
        $implementationSectionIndex = $i
        break
    }
}

if ($implementationSectionIndex -ge 0) {
    # Find the next section header or end of file
    $insertIndex = $lines.Count
    for ($i = $implementationSectionIndex + 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^## ') {
            $insertIndex = $i
            break
        }
    }
    
    # Insert missing tasks before the next section
    $missingLines = $updateMap.Values | Sort-Object
    $newLines = $lines[0..$insertIndex] + $missingLines + $lines[($insertIndex + 1)..($lines.Count - 1)]
    $content = $newLines -join "`n"
}

# Write updated content
Set-Content -Path $TaskFile -Value $content
Write-Host "`nStep 1 completed successfully" -ForegroundColor Green
$global:Step1Result = 0
return 0
