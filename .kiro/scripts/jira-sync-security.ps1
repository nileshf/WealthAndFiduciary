#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Jira Sync Orchestrator for SecurityService
.DESCRIPTION
    Syncs tasks between project-task.md and Jira issues.
    - Creates Jira issues for tasks not in Jira
    - Updates task checkboxes based on Jira issue status
    - Syncs task status between markdown and Jira
    
    This is a two-way sync operation.
.PARAMETER ConfigFile
    Path to Jira sync configuration JSON file
.EXAMPLE
    .\scripts\jira-sync-security.ps1 -ConfigFile .kiro/settings/jira-sync-security-config.json
#>

param(
    [string]$ConfigFile = ".kiro/settings/jira-sync-security-config.json"
)

$ErrorActionPreference = 'Stop'

Write-Host "=== Jira Sync Orchestrator for SecurityService ===" -ForegroundColor Green
Write-Host "Config File: $ConfigFile"

# Load configuration
if (-not (Test-Path $ConfigFile)) {
    Write-Host "ERROR: Config file not found: $ConfigFile" -ForegroundColor Red
    exit 1
}

$config = Get-Content $ConfigFile -Raw | ConvertFrom-Json

$JiraBaseUrl = $config.JiraBaseUrl
$JiraEmail = $config.JiraEmail
$JiraToken = $config.JiraToken
$ServiceName = $config.ServiceName
$TaskFile = $config.TaskFile
$ProjectKey = $config.JiraProjectKey

Write-Host "Service: $ServiceName"
Write-Host "Project Key: $ProjectKey"
Write-Host "Task File: $TaskFile"

# Validation
if (-not $JiraBaseUrl -or -not $JiraEmail -or -not $JiraToken) {
    Write-Host "ERROR: Missing Jira credentials in config" -ForegroundColor Red
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

# Helper: Convert title to kebab-case feature name
function ConvertTo-KebabCase {
    param([string]$Title)
    $title = $Title -replace '[^a-zA-Z0-9\s-]', ''
    $title = $title -replace '\s+', '-'
    $title = $title.ToLower()
    return $title
}

# Helper: Get Jira issue status category
function Get-JiraStatusCategory {
    param([string]$StatusName)
    $statusMap = @{
        'To Do' = 'todo'
        'In Progress' = 'inprogress'
        'Done' = 'done'
        'Testing' = 'testing'
    }
    return $statusMap[$StatusName] ?? 'todo'
}

# Helper: Get checkbox from status
function Get-CheckboxFromStatus {
    param([string]$Status)
    switch ($Status) {
        'To Do' { return ' ' }
        'In Progress' { return '-' }
        'Done' { return 'x' }
        'Testing' { return '~' }
        default { return ' ' }
    }
}

# Helper: Get status from checkbox
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

Write-Host "`n--- Step 1: Fetch Jira Issues ---" -ForegroundColor Cyan
$headers = Get-JiraHeaders -Email $JiraEmail -Token $JiraToken
$jql = "project = $ProjectKey ORDER BY created DESC"
$uri = "$JiraBaseUrl/rest/api/3/search?jql=$([System.Uri]::EscapeDataString($jql))&maxResults=100&fields=key,summary,status,priority,issuetype"

try {
    $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
    $jiraIssues = $response.issues
    Write-Host "Found $($jiraIssues.Count) issues in Jira" -ForegroundColor Green
}
catch {
    Write-Host "Failed to fetch Jira issues" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n--- Step 2: Read Tasks from Markdown ---" -ForegroundColor Cyan
$content = Get-Content $TaskFile -Raw
$lines = $content -split "`n"

# Parse existing tasks with Jira keys
$existingTasks = @{}
foreach ($line in $lines) {
    if ($line -match '\[([x ~-])\]\s+([A-Z]+-\d+)\s+-\s+(.+)') {
        $checkbox = $matches[1]
        $key = $matches[2]
        $summary = $matches[3]
        $existingTasks[$key] = @{
            Checkbox = $checkbox
            Summary = $summary
            Status = Get-StatusFromCheckbox $checkbox
        }
        Write-Host "  Found: $key - $summary (Status: $checkbox)" -ForegroundColor Yellow
    }
}

Write-Host "`n--- Step 3: Sync Tasks to Jira ---" -ForegroundColor Cyan
$taskCount = 0
$createdCount = 0
$updatedCount = 0

foreach ($line in $lines) {
    if ($line -match '\[([x ~-])\]\s+(.+?)\s*$') {
        $checkbox = $matches[1]
        $summary = $matches[2].Trim()
        
        # Skip if already has Jira key
        if ($summary -match '^[A-Z]+-\d+\s+-') {
            continue
        }
        
        # Skip empty or header lines
        if ([string]::IsNullOrWhiteSpace($summary) -or $summary -match '^#') {
            continue
        }
        
        $taskCount++
        $status = Get-StatusFromCheckbox $checkbox
        
        Write-Host "  Processing: $summary (Status: $status)" -ForegroundColor Yellow
        
        # Check if task already exists in Jira by summary match
        $existingIssue = $jiraIssues | Where-Object { 
            $_.fields.summary -eq $summary -and $_.fields.status.name -eq $status
        } | Select-Object -First 1
        
        if ($existingIssue) {
            Write-Host "    Found existing Jira issue: $($existingIssue.key)" -ForegroundColor Green
            $existingTasks[$existingIssue.key] = @{
                Checkbox = $checkbox
                Summary = $summary
                Status = $status
            }
            continue
        }
        
        # Create new Jira issue
        $featureName = ConvertTo-KebabCase -Title $summary
        $description = @"
## Task: $summary

**Service**: $ServiceName
**Status**: $status
**Source**: project-task.md

### Description
This task was created from the project task list in project-task.md.

### Acceptance Criteria
- [ ] Task completed successfully
- [ ] Tests passing
- [ ] Documentation updated

### Related Files
- Task File: $TaskFile
- Service: Applications/AITooling/Services/$ServiceName/
"@
        
        $issueBody = @{
            fields = @{
                project = @{
                    key = $ProjectKey
                }
                summary = $summary
                description = $description
                issuetype = @{
                    name = "Task"
                }
                priority = @{
                    name = "Medium"
                }
            }
        } | ConvertTo-Json -Depth 10
        
        $createUri = "$JiraBaseUrl/rest/api/3/issue"
        
        try {
            $createResponse = Invoke-RestMethod -Uri $createUri -Headers $headers -Method Post -Body $issueBody
            $newIssueKey = $createResponse.key
            Write-Host "    Created: $newIssueKey" -ForegroundColor Green
            $createdCount++
            
            # Update local tracking
            $existingTasks[$newIssueKey] = @{
                Checkbox = $checkbox
                Summary = $summary
                Status = $status
            }
        }
        catch {
            Write-Host "    Failed to create issue: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

Write-Host "`n--- Step 4: Update Markdown with Jira Keys ---" -ForegroundColor Cyan
$updatedContent = $content

foreach ($issue in $jiraIssues) {
    $key = $issue.key
    $summary = $issue.fields.summary
    $status = $issue.fields.status.name
    $checkbox = Get-CheckboxFromStatus $status
    
    # Check if this issue is already in the markdown
    if ($existingTasks.ContainsKey($key)) {
        $taskSummary = $existingTasks[$key].Summary
        
        # Update the line if it doesn't have the Jira key yet
        $pattern = "\[([x ~-])\]\s+$([regex]::Escape($taskSummary))\s*$"
        $replacement = "[{0}] {1} - {2}" -f $checkbox, $key, $taskSummary
        
        if ($updatedContent -match $pattern) {
            $updatedContent = $updatedContent -replace $pattern, $replacement
            Write-Host "  Updated: $key - $taskSummary" -ForegroundColor Green
            $updatedCount++
        }
    }
}

# Write updated content back to file
$updatedContent | Out-File -FilePath $TaskFile -Encoding utf8 -NoNewline
Write-Host "`nUpdated markdown file: $TaskFile" -ForegroundColor Green

Write-Host "`n--- Summary ---" -ForegroundColor Cyan
Write-Host "  Total tasks processed: $taskCount"
Write-Host "  New issues created: $createdCount"
Write-Host "  Issues updated: $updatedCount"
Write-Host "  Total issues in Jira: $($jiraIssues.Count)" -ForegroundColor Cyan

Write-Host "`n=== Jira Sync Complete ===" -ForegroundColor Green
