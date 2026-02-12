#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Syncs project-task.md entries to Jira as issues
    
.DESCRIPTION
    This script reads project-task.md files and creates corresponding Jira issues
    for any tasks that don't already have a Jira issue key.
#>

param(
    [string]$JiraBaseUrl = $env:JIRA_BASE_URL,
    [string]$JiraEmail = $env:JIRA_USER_EMAIL,
    [string]$JiraToken = $env:JIRA_API_TOKEN,
    [switch]$DryRun = $false,
    [switch]$Verbose = $false
)

$ErrorActionPreference = 'Stop'

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

function Get-JiraStatusFromCheckbox {
    param([string]$checkbox)
    
    switch ($checkbox) {
        '[ ]' { return 'To Do' }
        '[-]' { return 'In Progress' }
        '[~]' { return 'In Review' }
        '[x]' { return 'Done' }
        default { return 'To Do' }
    }
}

function Create-JiraIssue {
    param(
        [string]$projectKey,
        [string]$summary,
        [string]$description,
        [string[]]$labels,
        [string]$status = 'To Do'
    )
    
    try {
        $auth = Get-JiraAuth
        $headers = @{
            'Authorization' = "Basic $auth"
            'Content-Type' = 'application/json'
        }
        
        # Convert description to Atlassian Document Format (ADF)
        $adfDescription = @{
            version = 1
            type = "doc"
            content = @(
                @{
                    type = "paragraph"
                    content = @(
                        @{
                            type = "text"
                            text = $description
                        }
                    )
                }
            )
        }
        
        $body = @{
            fields = @{
                project = @{ key = $projectKey }
                summary = $summary
                description = $adfDescription
                labels = $labels
                issuetype = @{ name = 'Task' }
            }
        } | ConvertTo-Json -Depth 10
        
        $uri = "$JiraBaseUrl/rest/api/3/issue"
        
        $response = Invoke-RestMethod `
            -Uri $uri `
            -Headers $headers `
            -Method Post `
            -Body $body `
            -ErrorAction Stop
        
        # Transition issue to correct status if not "To Do"
        if ($status -ne 'To Do') {
            Transition-JiraIssue -issueKey $response.key -status $status
        }
        
        return $response.key
    }
    catch {
        Write-Log "Error creating Jira issue: $_" -Level Error
        return $null
    }
}

function Transition-JiraIssue {
    param(
        [string]$issueKey,
        [string]$status
    )
    
    try {
        $auth = Get-JiraAuth
        $headers = @{
            'Authorization' = "Basic $auth"
            'Content-Type' = 'application/json'
        }
        
        # Get available transitions
        $uri = "$JiraBaseUrl/rest/api/3/issue/$issueKey/transitions"
        $transitionsResponse = Invoke-RestMethod `
            -Uri $uri `
            -Headers $headers `
            -Method Get `
            -ErrorAction Stop
        
        # Find transition to target status
        $transition = $transitionsResponse.transitions | Where-Object { $_.to.name -eq $status } | Select-Object -First 1
        
        if ($null -eq $transition) {
            Write-Log "No transition found to status '$status' for issue $issueKey" -Level Warning
            return
        }
        
        # Perform transition
        $transitionBody = @{
            transition = @{
                id = $transition.id
            }
        } | ConvertTo-Json
        
        $transitionUri = "$JiraBaseUrl/rest/api/3/issue/$issueKey/transitions"
        Invoke-RestMethod `
            -Uri $transitionUri `
            -Headers $headers `
            -Method Post `
            -Body $transitionBody `
            -ErrorAction Stop
        
        Write-Log "Transitioned issue $issueKey to status '$status'" -Level Success
    }
    catch {
        Write-Log "Error transitioning issue $issueKey to status '$status': $_" -Level Warning
    }
}

function Parse-ProjectTaskFile {
    param([string]$filePath)
    
    if (-not (Test-Path $filePath)) {
        return @()
    }
    
    $content = Get-Content $filePath -Raw
    $tasks = @()
    
    # Match task lines: - [ ] Description (without Jira key)
    # Pattern captures: checkbox and description
    $lines = $content -split "`n"
    
    foreach ($line in $lines) {
        # Skip lines that don't start with task marker
        if ($line -notmatch '^\s*-\s+\[') {
            continue
        }
        
        # Extract checkbox and rest of line
        if ($line -match '^\s*-\s+(\[[ x~-]\])\s+(.+)$') {
            $checkbox = $matches[1]
            $rest = $matches[2].Trim()
            
            # Skip if already has Jira key (format: ISSUE-123 - Description)
            if ($rest -match '^[A-Z]+-\d+\s+-\s+') {
                continue
            }
            
            # Skip empty descriptions
            if ([string]::IsNullOrWhiteSpace($rest)) {
                continue
            }
            
            $tasks += @{
                checkbox = $checkbox
                description = $rest
                line = $line
            }
        }
    }
    
    return $tasks
}

function Update-ProjectTaskFile {
    param(
        [string]$filePath,
        [string]$taskDescription,
        [string]$issueKey
    )
    
    if (-not (Test-Path $filePath)) {
        return $false
    }
    
    try {
        $content = Get-Content $filePath -Raw
        
        # Find and replace the task line
        # Match: - [ ] Description → - [ ] ISSUE-KEY - Description
        $oldLine = "- [ ] $taskDescription"
        $newLine = "- [ ] $issueKey - $taskDescription"
        
        if ($content -contains $oldLine) {
            $newContent = $content -replace [regex]::Escape($oldLine), $newLine
            Set-Content -Path $filePath -Value $newContent -NoNewline
            Write-Log "Updated $filePath with issue key $issueKey" -Level Success
            return $true
        }
        else {
            Write-Log "Could not find task '$taskDescription' in $filePath" -Level Warning
            return $false
        }
    }
    catch {
        Write-Log "Error updating project task file: $_" -Level Error
        return $false
    }
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
    $updatedFiles = @()
    
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
            Write-Log "Creating Jira issue for: $($task.description)" -Level Info
            
            # Get Jira status from checkbox
            $jiraStatus = Get-JiraStatusFromCheckbox -checkbox $task.checkbox
            
            if ($DryRun) {
                Write-Log "[DRY RUN] Would create issue: $($task.description) (Status: $jiraStatus)" -Level Info
                $createdCount++
            }
            else {
                $issueKey = Create-JiraIssue `
                    -projectKey $serviceConfig.jiraProject `
                    -summary $task.description `
                    -description "Created from project-task.md for $($serviceConfig.service)" `
                    -labels @($serviceConfig.jiraLabel) `
                    -status $jiraStatus
                
                if ($null -ne $issueKey) {
                    Write-Log "Created Jira issue: $issueKey (Status: $jiraStatus)" -Level Success
                    $createdCount++
                    
                    # Update project-task.md file with issue key
                    $updated = Update-ProjectTaskFile `
                        -filePath $projectTaskFile `
                        -taskDescription $task.description `
                        -issueKey $issueKey
                    
                    if ($updated) {
                        $updatedFiles += $projectTaskFile
                    }
                }
                else {
                    $errorCount++
                }
            }
        }
    }
    
    Write-Log "Sync completed: $createdCount created, $skippedCount skipped, $errorCount errors" -Level Info
    
    # Return list of updated files for git commit
    return @{
        createdCount = $createdCount
        skippedCount = $skippedCount
        errorCount = $errorCount
        updatedFiles = $updatedFiles | Select-Object -Unique
    }
}

# Main execution
try {
    $result = Sync-TasksToJira -DryRun:$DryRun
    
    Write-Log "Summary: $($result.createdCount) created, $($result.skippedCount) skipped, $($result.errorCount) errors" -Level Info
    
    if ($result.updatedFiles.Count -gt 0) {
        Write-Log "Updated files:" -Level Info
        foreach ($file in $result.updatedFiles) {
            Write-Log "  - $file" -Level Info
        }
    }
    
    exit 0
}
catch {
    Write-Log "Fatal error: $_" -Level Error
    exit 1
}
