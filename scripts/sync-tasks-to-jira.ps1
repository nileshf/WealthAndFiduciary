#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Syncs project-task.md entries to Jira as issues
    
.DESCRIPTION
    This script reads project-task.md files and creates corresponding Jira issues
    for any tasks that don't already have a Jira issue key.
    
.PARAMETER JiraBaseUrl
    Base URL of Jira instance
    
.PARAMETER JiraEmail
    Email address for Jira API authentication
    
.PARAMETER JiraToken
    API token for Jira authentication
    
.PARAMETER DryRun
    If specified, shows what would be created without making changes
    
.EXAMPLE
    .\sync-tasks-to-jira.ps1 -DryRun
#>

param(
    [string]$JiraBaseUrl = $env:JIRA_BASE_URL,
    [string]$JiraEmail = $env:JIRA_USER_EMAIL,
    [string]$JiraToken = $env:JIRA_API_TOKEN,
    [switch]$DryRun = $false,
    [switch]$Verbose = $false
)

# Service registry mapping
$serviceRegistry = @{
    'ai-security-service' = @{
        application = 'AITooling'
        service = 'SecurityService'
        projectTaskFile = 'Applications/AITooling/Services/SecurityService/.kiro/specs/security-service/project-task.md'
        jiraProject = 'WEALTHFID'
        jiraLabel = 'ai-security-service'
    }
    'data-loader-service' = @{
        application = 'AITooling'
        service = 'DataLoaderService'
        projectTaskFile = 'Applications/AITooling/Services/DataLoaderService/.kiro/specs/data-loader-service/project-task.md'
        jiraProject = 'WEALTHFID'
        jiraLabel = 'data-loader-service'
    }
}

# Validation
if ([string]::IsNullOrEmpty($JiraBaseUrl)) {
    Write-Error "JiraBaseUrl is required"
    exit 1
}

if ([string]::IsNullOrEmpty($JiraEmail)) {
    Write-Error "JiraEmail is required"
    exit 1
}

if ([string]::IsNullOrEmpty($JiraToken)) {
    Write-Error "JiraToken is required"
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

function Get-JiraAuth {
    return [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$JiraEmail`:$JiraToken"))
}

function Create-JiraIssue {
    param(
        [string]$projectKey,
        [string]$summary,
        [string]$description,
        [string[]]$labels,
        [switch]$DryRun
    )
    
    if ($DryRun) {
        Write-Log "[DRY RUN] Would create issue: $summary" -Level Info
        return $null
    }
    
    try {
        $auth = Get-JiraAuth
        $headers = @{
            'Authorization' = "Basic $auth"
            'Content-Type' = 'application/json'
        }
        
        $body = @{
            fields = @{
                project = @{ key = $projectKey }
                summary = $summary
                description = $description
                labels = $labels
                issuetype = @{ name = 'Task' }
            }
        } | ConvertTo-Json
        
        $uri = "$JiraBaseUrl/rest/api/3/issue"
        
        $response = Invoke-RestMethod `
            -Uri $uri `
            -Headers $headers `
            -Method Post `
            -Body $body `
            -ErrorAction Stop
        
        return $response.key
    }
    catch {
        Write-Log "Error creating Jira issue: $_" -Level Error
        return $null
    }
}

function Parse-ProjectTaskFile {
    param([string]$filePath)
    
    if (-not (Test-Path $filePath)) {
        return @()
    }
    
    $content = Get-Content $filePath -Raw
    $tasks = @()
    
    # Match task lines: - [ ] TASK-123 - Description or - [ ] Description
    $pattern = '- \[[ x~-]\]\s+(?:([A-Z]+-\d+)\s+-\s+)?(.+?)(?:\n|$)'
    
    $matches = [regex]::Matches($content, $pattern)
    
    foreach ($match in $matches) {
        $issueKey = $match.Groups[1].Value
        $description = $match.Groups[2].Value.Trim()
        
        # Skip if already has Jira issue key
        if (-not [string]::IsNullOrEmpty($issueKey)) {
            continue
        }
        
        # Skip empty descriptions
        if ([string]::IsNullOrEmpty($description)) {
            continue
        }
        
        $tasks += @{
            description = $description
            hasJiraKey = -not [string]::IsNullOrEmpty($issueKey)
        }
    }
    
    return $tasks
}

function Sync-TasksToJira {
    param([switch]$DryRun)
    
    Write-Log "Starting project-task.md to Jira sync..." -Level Info
    
    if ($DryRun) {
        Write-Log "[DRY RUN MODE] No changes will be made" -Level Warning
    }
    
    $createdCount = 0
    $skippedCount = 0
    $errorCount = 0
    
    foreach ($serviceKey in $serviceRegistry.Keys) {
        $serviceConfig = $serviceRegistry[$serviceKey]
        $projectTaskFile = $serviceConfig.projectTaskFile
        
        Write-Log "Processing service: $($serviceConfig.service)" -Level Info
        
        if (-not (Test-Path $projectTaskFile)) {
            Write-Log "Project task file not found: $projectTaskFile" -Level Warning
            continue
        }
        
        $tasks = Parse-ProjectTaskFile -filePath $projectTaskFile
        
        if ($tasks.Count -eq 0) {
            Write-Log "No new tasks to create for $($serviceConfig.service)" -Level Info
            continue
        }
        
        foreach ($task in $tasks) {
            if ($task.hasJiraKey) {
                $skippedCount++
                continue
            }
            
            Write-Log "Creating Jira issue for: $($task.description)" -Level Info
            
            $issueKey = Create-JiraIssue `
                -projectKey $serviceConfig.jiraProject `
                -summary $task.description `
                -description "Created from project-task.md for $($serviceConfig.service)" `
                -labels @($serviceConfig.jiraLabel) `
                -DryRun:$DryRun
            
            if ($null -ne $issueKey) {
                Write-Log "Created Jira issue: $issueKey" -Level Success
                $createdCount++
            }
            else {
                $errorCount++
            }
        }
    }
    
    Write-Log "Sync completed: $createdCount created, $skippedCount skipped, $errorCount errors" -Level Info
}

# Main execution
try {
    Sync-TasksToJira -DryRun:$DryRun
    exit 0
}
catch {
    Write-Log "Fatal error: $_" -Level Error
    exit 1
}
