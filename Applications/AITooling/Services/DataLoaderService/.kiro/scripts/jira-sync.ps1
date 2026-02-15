#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Bidirectional sync between project-task.md and Jira issues
.DESCRIPTION
    - Creates Jira issues for new tasks
    - Syncs Jira status back to markdown checkboxes
    - Updates task file with issue keys and current status
    - Jira is the source of truth for task status
.PARAMETER Mode
    Sync mode: 'Auto' (automatic) or 'Manual' (user confirmation)
.PARAMETER SyncOnly
    Only sync status from Jira without creating new issues
.EXAMPLE
    .\jira-sync.ps1 -Mode Manual
    .\jira-sync.ps1 -Mode Auto -SyncOnly
#>

param(
    [ValidateSet('Auto', 'Manual')]
    [string]$Mode = 'Manual',
    [switch]$SyncOnly = $false
)

$ErrorActionPreference = 'Stop'
$WarningPreference = 'Continue'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ServiceDir = Split-Path -Parent (Split-Path -Parent $ScriptDir)
$TaskFile = Join-Path $ServiceDir '.kiro/specs/data-loader-service/project-task.md'
$EnvFile = Join-Path $ServiceDir '.env'

Write-Host "DataLoaderService Jira Sync" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $EnvFile)) {
    Write-Host "ERROR: .env file not found at $EnvFile" -ForegroundColor Red
    exit 1
}

Write-Host "Loading environment from: $EnvFile" -ForegroundColor Gray
$env:JIRA_BASE_URL = (Get-Content $EnvFile | Select-String 'JIRA_BASE_URL=' | ForEach-Object { $_.Line -replace '^JIRA_BASE_URL=', '' }).Trim()
$env:JIRA_PROJECT_KEY = (Get-Content $EnvFile | Select-String 'JIRA_PROJECT_KEY=' | ForEach-Object { $_.Line -replace '^JIRA_PROJECT_KEY=', '' }).Trim()
$env:JIRA_EMAIL = (Get-Content $EnvFile | Select-String 'JIRA_USER_EMAIL=' | ForEach-Object { $_.Line -replace '^JIRA_USER_EMAIL=', '' }).Trim()
$env:JIRA_API_TOKEN = (Get-Content $EnvFile | Select-String 'JIRA_API_TOKEN=' | ForEach-Object { $_.Line -replace '^JIRA_API_TOKEN=', '' }).Trim()

if (-not $env:JIRA_BASE_URL -or -not $env:JIRA_PROJECT_KEY -or -not $env:JIRA_EMAIL -or -not $env:JIRA_API_TOKEN) {
    Write-Host "ERROR: Missing Jira configuration in .env file" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Jira configuration loaded" -ForegroundColor Green
Write-Host "  Project: $($env:JIRA_PROJECT_KEY)" -ForegroundColor Gray
Write-Host ""

if (-not (Test-Path $TaskFile)) {
    Write-Host "ERROR: Task file not found at $TaskFile" -ForegroundColor Red
    exit 1
}

Write-Host "Reading tasks from: $TaskFile" -ForegroundColor Gray

function Get-Tasks {
    param([string]$FilePath)
    $content = Get-Content $FilePath -Raw
    $tasks = @()
    $lines = $content -split "`n"
    
    foreach ($line in $lines) {
        # Match any checkbox status: [ ], [-], [~], [x]
        if ($line -match '- \[.\]\s+(.+?)(?:\s+\(Jira:\s+([A-Z]+-\d+),\s+Status:\s+([^)]+)\))?(?:\s*)$') {
            $taskName = $matches[1].Trim()
            $issueKey = $matches[2]
            $status = $matches[3]
            
            $tasks += @{
                Name = $taskName
                IssueKey = $issueKey
                Status = $status
                HasIssue = -not [string]::IsNullOrEmpty($issueKey)
            }
        }
    }
    return $tasks
}

function New-JiraIssue {
    param([string]$Summary, [string]$Description)
    
    $auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($env:JIRA_EMAIL):$($env:JIRA_API_TOKEN)"))
    
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
                        text = $Description
                    }
                )
            }
        )
    }
    
    # Note: We don't set status during creation - Jira creates with default status
    # Labels are set after creation using a separate update call
    $body = @{
        fields = @{
            project = @{ key = $env:JIRA_PROJECT_KEY }
            summary = $Summary
            description = $adfDescription
            issuetype = @{ name = 'Task' }
        }
    } | ConvertTo-Json -Depth 10
    
    $maxRetries = 3
    $retryCount = 0
    
    while ($retryCount -lt $maxRetries) {
        try {
            $response = Invoke-RestMethod `
                -Uri "$($env:JIRA_BASE_URL)/rest/api/3/issue" `
                -Method Post `
                -Headers @{
                    'Authorization' = "Basic $auth"
                    'Content-Type' = 'application/json'
                } `
                -Body $body `
                -TimeoutSec 30
            return $response.key
        }
        catch {
            $retryCount++
            $errorMsg = $_.Exception.Message
            
            if ($retryCount -lt $maxRetries -and ($errorMsg -match '407|503|504|timeout')) {
                Write-Host "  [RETRY $retryCount/$maxRetries] Retrying after network error..." -ForegroundColor Yellow
                Start-Sleep -Seconds (2 * $retryCount)
            }
            else {
                Write-Host "ERROR creating Jira issue: $errorMsg" -ForegroundColor Red
                return $null
            }
        }
    }
    
    return $null
}

function Get-JiraIssueStatus {
    param([string]$IssueKey)
    
    $auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($env:JIRA_EMAIL):$($env:JIRA_API_TOKEN)"))
    
    $maxRetries = 3
    $retryCount = 0
    
    while ($retryCount -lt $maxRetries) {
        try {
            $response = Invoke-RestMethod `
                -Uri "$($env:JIRA_BASE_URL)/rest/api/3/issue/$IssueKey" `
                -Method Get `
                -Headers @{
                    'Authorization' = "Basic $auth"
                    'Content-Type' = 'application/json'
                } `
                -TimeoutSec 30
            return $response.fields.status.name
        }
        catch {
            $retryCount++
            $errorMsg = $_.Exception.Message
            
            if ($retryCount -lt $maxRetries -and ($errorMsg -match '407|503|504|timeout')) {
                Start-Sleep -Seconds (2 * $retryCount)
            }
            else {
                return 'Unknown'
            }
        }
    }
    
    return 'Unknown'
}

function Set-JiraIssueStatus {
    param([string]$IssueKey, [string]$TargetStatus)
    
    $auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($env:JIRA_EMAIL):$($env:JIRA_API_TOKEN)"))
    
    # First, get available transitions
    $maxRetries = 3
    $retryCount = 0
    
    while ($retryCount -lt $maxRetries) {
        try {
            $transitionsResponse = Invoke-RestMethod `
                -Uri "$($env:JIRA_BASE_URL)/rest/api/3/issue/$IssueKey/transitions" `
                -Method Get `
                -Headers @{
                    'Authorization' = "Basic $auth"
                    'Content-Type' = 'application/json'
                } `
                -TimeoutSec 30
            
            # Find the transition to the target status
            $transition = $transitionsResponse.transitions | Where-Object { $_.to.name -eq $TargetStatus }
            
            if ($transition) {
                # Perform the transition
                $body = @{
                    transition = @{
                        id = $transition.id
                    }
                } | ConvertTo-Json -Depth 10
                
                Invoke-RestMethod `
                    -Uri "$($env:JIRA_BASE_URL)/rest/api/3/issue/$IssueKey/transitions" `
                    -Method Post `
                    -Headers @{
                        'Authorization' = "Basic $auth"
                        'Content-Type' = 'application/json'
                    } `
                    -Body $body `
                    -TimeoutSec 30 | Out-Null
                
                return $true
            }
            else {
                Write-Host "    [DEBUG] No transition found to '$TargetStatus'. Available transitions:" -ForegroundColor Gray
                $transitionsResponse.transitions | ForEach-Object { Write-Host "      - $($_.to.name)" -ForegroundColor Gray }
                return $false
            }
        }
        catch {
            $retryCount++
            $errorMsg = $_.Exception.Message
            
            if ($retryCount -lt $maxRetries -and ($errorMsg -match '407|503|504|timeout')) {
                Start-Sleep -Seconds (2 * $retryCount)
            }
            else {
                Write-Host "    [WARN] Could not transition issue: $errorMsg" -ForegroundColor Yellow
                return $false
            }
        }
    }
    
    return $false
}

function Set-JiraIssueLabels {
    param([string]$IssueKey, [string[]]$Labels)
    
    $auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($env:JIRA_EMAIL):$($env:JIRA_API_TOKEN)"))
    
    # Update labels using PUT request with fields object
    $body = @{
        fields = @{
            labels = $Labels
        }
    } | ConvertTo-Json -Depth 10
    
    $maxRetries = 3
    $retryCount = 0
    
    while ($retryCount -lt $maxRetries) {
        try {
            Invoke-RestMethod `
                -Uri "$($env:JIRA_BASE_URL)/rest/api/3/issue/$IssueKey" `
                -Method Put `
                -Headers @{
                    'Authorization' = "Basic $auth"
                    'Content-Type' = 'application/json'
                } `
                -Body $body `
                -TimeoutSec 30 | Out-Null
            
            Write-Host "    [OK] Labels updated: $($Labels -join ', ')" -ForegroundColor Green
            return $true
        }
        catch {
            $retryCount++
            $errorMsg = $_.Exception.Message
            
            if ($retryCount -lt $maxRetries -and ($errorMsg -match '407|503|504|timeout')) {
                Start-Sleep -Seconds (2 * $retryCount)
            }
            else {
                Write-Host "    [WARN] Could not update labels: $errorMsg" -ForegroundColor Yellow
                return $false
            }
        }
    }
    
    return $false
}

function Get-CheckboxStatus {
    param([string]$JiraStatus)
    
    # Map Jira status to markdown checkbox
    # Jira is the source of truth for status
    # TO DO -> [ ] (not started)
    # IN PROGRESS -> [-] (in progress)
    # IN REVIEW -> [-] (in progress)
    # TESTING -> [~] (queued/testing)
    # READY TO MERGE -> [~] (queued/ready)
    # DONE -> [x] (completed)
    
    $normalizedStatus = $JiraStatus.Trim().ToLower()
    
    switch ($normalizedStatus) {
        'to do' { return '[ ]' }
        'in progress' { return '[-]' }
        'in review' { return '[-]' }
        'testing' { return '[~]' }
        'ready to merge' { return '[~]' }
        'done' { return '[x]' }
        default { 
            Write-Host "    [DEBUG] Unknown status: '$normalizedStatus'" -ForegroundColor Gray
            return '[ ]' 
        }
    }
}

function Update-TaskWithJira {
    param([string]$TaskName, [string]$IssueKey, [string]$Status)
    
    Write-Host "  Updating task file: $TaskName -> $IssueKey" -ForegroundColor Cyan
    
    $checkbox = Get-CheckboxStatus $Status
    $content = Get-Content $TaskFile -Raw
    
    # Try to find existing task with or without Jira info
    $patterns = @(
        "- \[.\] $([regex]::Escape($TaskName))(?:\s+\(Jira:[^)]+\))?",
        "- \[.\]\s+$([regex]::Escape($TaskName))(?:\s+\(Jira:[^)]+\))?"
    )
    
    $newLine = "- $checkbox $TaskName (Jira: $IssueKey, Status: $Status)"
    $newContent = $content
    
    foreach ($pattern in $patterns) {
        if ($newContent -match $pattern) {
            $newContent = $newContent -replace $pattern, $newLine
            break
        }
    }
    
    if ($newContent -ne $content) {
        Set-Content $TaskFile $newContent -Encoding UTF8
        Write-Host "  [OK] Task updated: $checkbox $Status" -ForegroundColor Green
        return $true
    }
    else {
        Write-Host "  [WARN] Task line not found" -ForegroundColor Yellow
        return $false
    }
}

# ============================================================================
# MAIN SCRIPT LOGIC
# ============================================================================

$tasks = Get-Tasks $TaskFile

if ($tasks.Count -eq 0) {
    Write-Host "No tasks found in $TaskFile" -ForegroundColor Yellow
    exit 0
}

Write-Host "Found $($tasks.Count) task(s)" -ForegroundColor Green
Write-Host ""

# Separate tasks into two groups
$tasksToCreate = @()
$tasksToUpdate = @()

foreach ($task in $tasks) {
    if ($task.HasIssue) {
        Write-Host "  [OK] $($task.Name)" -ForegroundColor Green
        Write-Host "    Issue: $($task.IssueKey) (Status: $($task.Status))" -ForegroundColor Gray
        $tasksToUpdate += $task
    }
    else {
        Write-Host "  [NEW] $($task.Name)" -ForegroundColor Yellow
        Write-Host "    No Jira issue yet" -ForegroundColor Gray
        $tasksToCreate += $task
    }
}

Write-Host ""

# ============================================================================
# SYNC-ONLY MODE: Update existing tasks with current Jira status
# ============================================================================

if ($SyncOnly) {
    Write-Host "Syncing status from Jira (SyncOnly mode)..." -ForegroundColor Cyan
    Write-Host ""
    
    if ($tasksToUpdate.Count -eq 0) {
        Write-Host "No tasks with Jira issues to sync" -ForegroundColor Yellow
        exit 0
    }
    
    $syncedCount = 0
    $failedCount = 0
    
    foreach ($task in $tasksToUpdate) {
        Write-Host "Fetching status for: $($task.IssueKey)" -ForegroundColor Cyan
        
        $currentStatus = Get-JiraIssueStatus $task.IssueKey
        
        if ($currentStatus -and $currentStatus -ne 'Unknown') {
            Write-Host "  Current Jira status: $currentStatus" -ForegroundColor Gray
            
            if ($currentStatus -ne $task.Status) {
                Write-Host "  Status changed: $($task.Status) -> $currentStatus" -ForegroundColor Yellow
                
                if (Update-TaskWithJira -TaskName $task.Name -IssueKey $task.IssueKey -Status $currentStatus) {
                    $syncedCount++
                }
                else {
                    $failedCount++
                }
            }
            else {
                Write-Host "  Status unchanged" -ForegroundColor Gray
                $syncedCount++
            }
        }
        else {
            Write-Host "  [FAIL] Could not fetch status" -ForegroundColor Red
            $failedCount++
        }
        
        Write-Host ""
    }
    
    Write-Host "Sync Summary" -ForegroundColor Cyan
    Write-Host "============" -ForegroundColor Cyan
    Write-Host "Synced: $syncedCount" -ForegroundColor Green
    Write-Host "Failed: $failedCount" -ForegroundColor $(if ($failedCount -gt 0) { 'Red' } else { 'Green' })
    Write-Host ""
    
    if ($failedCount -eq 0) {
        Write-Host "[OK] Sync completed successfully" -ForegroundColor Green
        exit 0
    }
    else {
        Write-Host "[FAIL] Sync completed with errors" -ForegroundColor Red
        exit 1
    }
}

# ============================================================================
# CREATE MODE: Create new Jira issues for tasks without them
# ============================================================================

if ($tasksToCreate.Count -eq 0) {
    Write-Host "All tasks already have Jira issues" -ForegroundColor Green
    Write-Host ""
    Write-Host "Use -SyncOnly flag to sync status from Jira:" -ForegroundColor Gray
    Write-Host "  .\jira-sync.ps1 -SyncOnly" -ForegroundColor Gray
    exit 0
}

Write-Host "Creating $($tasksToCreate.Count) Jira issue(s)..." -ForegroundColor Cyan
Write-Host ""

if ($Mode -eq 'Manual') {
    Write-Host "Tasks to create:" -ForegroundColor Cyan
    foreach ($task in $tasksToCreate) {
        Write-Host "  - $($task.Name)" -ForegroundColor Yellow
    }
    Write-Host ""
    $confirm = Read-Host "Create these issues? (y/n)"
    if ($confirm -ne 'y') {
        Write-Host "Cancelled" -ForegroundColor Yellow
        exit 0
    }
}

$createdCount = 0
$failedCount = 0

foreach ($task in $tasksToCreate) {
    Write-Host "Creating issue for: $($task.Name)" -ForegroundColor Cyan
    
    $issueKey = New-JiraIssue -Summary $task.Name -Description "DataLoaderService task: $($task.Name)"
    
    if ($issueKey) {
        Write-Host "  [OK] Created: $issueKey" -ForegroundColor Green
        
        # Try to transition to "To Do" status
        Write-Host "  Transitioning to 'To Do' status..." -ForegroundColor Gray
        $transitioned = Set-JiraIssueStatus -IssueKey $issueKey -TargetStatus "To Do"
        
        if ($transitioned) {
            Write-Host "  [OK] Transitioned to 'To Do'" -ForegroundColor Green
        }
        else {
            Write-Host "  [WARN] Could not transition to 'To Do', checking current status..." -ForegroundColor Yellow
        }
        
        $status = Get-JiraIssueStatus $issueKey
        Write-Host "  Status: $status" -ForegroundColor Gray
        
        # Update labels on the issue
        Write-Host "  Updating labels..." -ForegroundColor Gray
        $labelsUpdated = Set-JiraIssueLabels -IssueKey $issueKey -Labels @('data-loader-service')
        
        if (Update-TaskWithJira -TaskName $task.Name -IssueKey $issueKey -Status $status) {
            $createdCount++
        }
        else {
            $failedCount++
        }
    }
    else {
        Write-Host "  [FAIL] Failed to create issue" -ForegroundColor Red
        $failedCount++
    }
    
    Write-Host ""
}

Write-Host "Creation Summary" -ForegroundColor Cyan
Write-Host "================" -ForegroundColor Cyan
Write-Host "Created: $createdCount" -ForegroundColor Green
Write-Host "Failed: $failedCount" -ForegroundColor $(if ($failedCount -gt 0) { 'Red' } else { 'Green' })
Write-Host ""

if ($failedCount -eq 0) {
    Write-Host "[OK] Sync completed successfully" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Gray
    Write-Host "  1. Commit changes to project-task.md" -ForegroundColor Gray
    Write-Host "  2. Use -SyncOnly flag to sync status from Jira:" -ForegroundColor Gray
    Write-Host "     .\jira-sync.ps1 -SyncOnly" -ForegroundColor Gray
    exit 0
}
else {
    Write-Host "[FAIL] Sync completed with errors" -ForegroundColor Red
    exit 1
}
