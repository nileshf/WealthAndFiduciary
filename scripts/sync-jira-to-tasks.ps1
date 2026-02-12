#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Syncs Jira tasks to service-specific project-task.md files
    
.DESCRIPTION
    This script fetches open Jira issues, identifies the service from labels,
    and updates the corresponding project-task.md file with task details.
    
.PARAMETER JiraBaseUrl
    Base URL of Jira instance (e.g., https://jira.example.com)
    
.PARAMETER JiraEmail
    Email address for Jira API authentication
    
.PARAMETER JiraToken
    API token for Jira authentication
    
.PARAMETER DryRun
    If specified, shows what would be updated without making changes
    
.EXAMPLE
    .\sync-jira-to-tasks.ps1 -DryRun
    
.EXAMPLE
    .\sync-jira-to-tasks.ps1 `
        -JiraBaseUrl "https://jira.example.com" `
        -JiraEmail "user@example.com" `
        -JiraToken "your-api-token"
#>

param(
    [string]$JiraBaseUrl = $env:JIRA_BASE_URL,
    [string]$JiraEmail = $env:JIRA_USER_EMAIL,
    [string]$JiraToken = $env:JIRA_API_TOKEN,
    [switch]$DryRun = $false,
    [switch]$Verbose = $false
)

# Service registry mapping - AITooling services only
# Note: FullView services (FullViewSecurity, INN8DataSource) are in a separate repository
$serviceRegistry = @{
    'ai-security-service' = @{
        application = 'AITooling'
        service = 'SecurityService'
        path = 'Applications/AITooling/Services/SecurityService'
        projectTaskFile = 'Applications/AITooling/Services/SecurityService/.kiro/specs/security-service/project-task.md'
        specName = 'security-service'
        database = 'SQL Server'
        schema = 'Security'
        jiraProject = 'WEALTHFID'
    }
    'data-loader-service' = @{
        application = 'AITooling'
        service = 'DataLoaderService'
        path = 'Applications/AITooling/Services/DataLoaderService'
        projectTaskFile = 'Applications/AITooling/Services/DataLoaderService/.kiro/specs/data-loader-service/project-task.md'
        specName = 'data-loader-service'
        database = 'SQL Server'
        schema = 'FileProcessing'
        jiraProject = 'WEALTHFID'
    }
}

# Validation
if ([string]::IsNullOrEmpty($JiraBaseUrl)) {
    Write-Error "JiraBaseUrl is required. Set JIRA_BASE_URL environment variable or pass -JiraBaseUrl parameter."
    exit 1
}

if ([string]::IsNullOrEmpty($JiraEmail)) {
    Write-Error "JiraEmail is required. Set JIRA_USER_EMAIL environment variable or pass -JiraEmail parameter."
    exit 1
}

if ([string]::IsNullOrEmpty($JiraToken)) {
    Write-Error "JiraToken is required. Set JIRA_API_TOKEN environment variable or pass -JiraToken parameter."
    exit 1
}

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $prefix = "[$timestamp]"
    
    switch ($Level) {
        'Info' { Write-Host "$prefix [INFO] $Message" -ForegroundColor Cyan }
        'Warning' { Write-Host "$prefix [WARN] $Message" -ForegroundColor Yellow }
        'Error' { Write-Host "$prefix [ERROR] $Message" -ForegroundColor Red }
        'Success' { Write-Host "$prefix [OK] $Message" -ForegroundColor Green }
    }
}

function Get-ServiceFromLabels {
    param([string[]]$labels)
    
    if ($null -eq $labels -or $labels.Count -eq 0) {
        return $null
    }
    
    foreach ($label in $labels) {
        if ($serviceRegistry.ContainsKey($label)) {
            return $label
        }
    }
    return $null
}

function Get-JiraIssues {
    param([string]$jql)
    
    try {
        $auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$JiraEmail`:$JiraToken"))
        $headers = @{
            'Authorization' = "Basic $auth"
            'Content-Type' = 'application/json'
        }
        
        $encodedJql = [System.Web.HttpUtility]::UrlEncode($jql)
        $uri = "$JiraBaseUrl/rest/api/3/search?jql=$encodedJql&maxResults=100"
        
        Write-Log "Fetching Jira issues: $jql" -Level Info
        
        $response = Invoke-RestMethod `
            -Uri $uri `
            -Headers $headers `
            -Method Get `
            -ErrorAction Stop
        
        Write-Log "Found $($response.issues.Count) issues" -Level Info
        return $response.issues
    }
    catch {
        Write-Log "Error fetching Jira issues: $_" -Level Error
        return @()
    }
}

function Test-TaskExists {
    param(
        [string]$filePath,
        [string]$taskId
    )
    
    if (-not (Test-Path $filePath)) {
        return $false
    }
    
    $content = Get-Content $filePath -Raw
    return $content -match [regex]::Escape($taskId)
}

function Add-TaskToFile {
    param(
        [string]$filePath,
        [object]$jiraIssue,
        [string]$serviceName,
        [switch]$DryRun
    )
    
    if (-not (Test-Path $filePath)) {
        Write-Log "Project task file not found: $filePath" -Level Warning
        return $false
    }
    
    $taskId = $jiraIssue.key
    $taskTitle = $jiraIssue.fields.summary
    $taskStatus = $jiraIssue.fields.status.name
    $taskUrl = $jiraIssue.self
    
    # Check if task already exists
    if (Test-TaskExists -filePath $filePath -taskId $taskId) {
        Write-Log "Task $taskId already exists in $filePath" -Level Info
        return $false
    }
    
    # Create task entry
    $taskEntry = "- [ ] $taskId - $taskTitle`n  Status: $taskStatus`n  URL: $taskUrl`n"
    
    if ($DryRun) {
        $dryRunMessage = "[DRY RUN] Would add to $filePath" + [Environment]::NewLine + $taskEntry
        Write-Log $dryRunMessage -Level Info
        return $true
    }
    
    try {
        Add-Content -Path $filePath -Value $taskEntry -ErrorAction Stop
        Write-Log "Added task $taskId to $filePath" -Level Success
        return $true
    }
    catch {
        Write-Log "Error adding task to $filePath : $_" -Level Error
        return $false
    }
}

function Sync-JiraToProjectTasks {
    param(
        [switch]$DryRun
    )
    
    Write-Log "Starting Jira to project-task.md sync..." -Level Info
    
    if ($DryRun) {
        Write-Log "[DRY RUN MODE] No changes will be made" -Level Warning
    }
    
    # Get all open Jira issues
    $jql = 'status NOT IN (Done, Closed, Resolved) AND labels is not EMPTY'
    $issues = Get-JiraIssues -jql $jql
    
    if ($issues.Count -eq 0) {
        Write-Log "No open issues found" -Level Info
        return
    }
    
    $syncedCount = 0
    $skippedCount = 0
    $errorCount = 0
    
    foreach ($issue in $issues) {
        $labels = $issue.fields.labels
        $service = Get-ServiceFromLabels -labels $labels
        
        if ($null -eq $service) {
            Write-Log "Issue $($issue.key) has no service label, skipping" -Level Warning
            $skippedCount++
            continue
        }
        
        $serviceConfig = $serviceRegistry[$service]
        $projectTaskFile = $serviceConfig.projectTaskFile
        
        Write-Log "Processing $($issue.key) for service: $($serviceConfig.service)" -Level Info
        
        $success = Add-TaskToFile `
            -filePath $projectTaskFile `
            -jiraIssue $issue `
            -serviceName $service `
            -DryRun:$DryRun
        
        if ($success) {
            $syncedCount++
        }
        else {
            $errorCount++
        }
    }
    
    Write-Log "Sync completed: $syncedCount synced, $skippedCount skipped, $errorCount errors" -Level Info
}

# Main execution
try {
    Sync-JiraToProjectTasks -DryRun:$DryRun
    exit 0
}
catch {
    Write-Log "Fatal error: $_" -Level Error
    exit 1
}
