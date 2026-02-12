#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Bidirectional sync between Jira and project-task.md files
    
.DESCRIPTION
    Syncs tasks in both directions:
    - Jira to project-task.md: Pulls Jira issues and updates markdown files
    - project-task.md to Jira: Creates new Jira issues from markdown tasks
    - Status mapping: [ ]=To Do, [-]=In Progress, [~]=In Review, [x]=Done
#>

param(
    [string]$JiraBaseUrl = $env:JIRA_BASE_URL,
    [string]$JiraEmail = $env:JIRA_USER_EMAIL,
    [string]$JiraToken = $env:JIRA_API_TOKEN,
    [switch]$DryRun = $false
)

$ErrorActionPreference = 'Stop'

# Validation
if (-not $JiraBaseUrl -or -not $JiraEmail -or -not $JiraToken) {
    Write-Error "Missing Jira credentials (JIRA_BASE_URL, JIRA_USER_EMAIL, JIRA_API_TOKEN)"
    exit 1
}

# Service configuration
$services = @(
    @{
        name = 'SecurityService'
        file = 'Applications/AITooling/Services/SecurityService/.kiro/specs/security-service/project-task.md'
        project = 'WEALTHFID'
        label = 'ai-security-service'
    },
    @{
        name = 'DataLoaderService'
        file = 'Applications/AITooling/Services/DataLoaderService/.kiro/specs/data-loader-service/project-task.md'
        project = 'WEALTHFID'
        label = 'data-loader-service'
    }
)

# Helper functions
function Get-JiraAuth {
    return [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$JiraEmail`:$JiraToken"))
}

function Get-JiraHeaders {
    return @{
        'Authorization' = "Basic $(Get-JiraAuth)"
        'Content-Type' = 'application/json'
    }
}

function Get-StatusFromCheckbox {
    param([string]$checkbox)
    switch ($checkbox) {
        '[ ]' { return 'To Do' }
        '[-]' { return 'In Progress' }
        '[~]' { return 'In Review' }
        '[x]' { return 'Done' }
        default { return 'To Do' }
    }
}

function Get-CheckboxFromStatus {
    param([string]$status)
    switch ($status) {
        'To Do' { return '[ ]' }
        'In Progress' { return '[-]' }
        'In Review' { return '[~]' }
        'Done' { return '[x]' }
        default { return '[ ]' }
    }
}

function Sync-JiraToMarkdown {
    Write-Host "`n=== Syncing Jira to project-task.md ===" -ForegroundColor Cyan
    
    $headers = Get-JiraHeaders
    
    try {
        # Fetch all issues with service labels
        $uri = "$JiraBaseUrl/rest/api/3/search"
        $body = @{
            jql = 'project = WEALTHFID AND labels is not EMPTY'
            maxResults = 100
            fields = @("key", "summary", "status", "labels")
        } | ConvertTo-Json
        
        Write-Host "Fetching Jira issues..."
        $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Post -Body $body
        $issues = $response.issues
        
        Write-Host "Found $($issues.Count) Jira issues"
        
        foreach ($service in $services) {
            $serviceIssues = $issues | Where-Object { $_.fields.labels -contains $service.label }
            
            if ($serviceIssues.Count -eq 0) {
                Write-Host "  $($service.name): No issues"
                continue
            }
            
            Write-Host "  $($service.name): $($serviceIssues.Count) issue(s)"
            
            if (-not (Test-Path $service.file)) {
                Write-Host "    WARNING: File not found: $($service.file)"
                continue
            }
            
            $content = Get-Content $service.file -Raw
            $updated = $false
            
            foreach ($issue in $serviceIssues) {
                $key = $issue.key
                $summary = $issue.fields.summary
                $status = $issue.fields.status.name
                $checkbox = Get-CheckboxFromStatus -status $status
                
                # Check if issue already in file
                if ($content -match [regex]::Escape($key)) {
                    Write-Host "    OK: $key already in file"
                    continue
                }
                
                # Add issue to file with proper formatting
                $taskLine = "- $checkbox $key - $summary"
                $content += "`n$taskLine"
                $updated = $true
                Write-Host "    ADDED: $key with status $status"
            }
            
            if ($updated -and -not $DryRun) {
                Set-Content -Path $service.file -Value $content -NoNewline
                Write-Host "    SUCCESS: File updated"
            }
        }
    }
    catch {
        Write-Error "Error syncing Jira to markdown: $_"
    }
}

function Sync-MarkdownToJira {
    Write-Host "`n=== Syncing project-task.md to Jira ===" -ForegroundColor Cyan
    
    $headers = Get-JiraHeaders
    $created = 0
    $updated = 0
    
    foreach ($service in $services) {
        if (-not (Test-Path $service.file)) {
            Write-Host "  $($service.name): File not found"
            continue
        }
        
        $content = Get-Content $service.file -Raw
        $lines = $content -split "`n"
        $newTasks = @()
        $existingTasks = @()
        
        foreach ($line in $lines) {
            # Match: - [checkbox] KEY - Description (existing issue with key)
            if ($line -match '^\s*-\s+(\[[ x~-]\])\s+([A-Z]+-\d+)\s+-\s+(.+)$') {
                $checkbox = $matches[1]
                $key = $matches[2]
                $description = $matches[3].Trim()
                
                $existingTasks += @{
                    checkbox = $checkbox
                    key = $key
                    description = $description
                    line = $line
                }
            }
            # Match: - [checkbox] Description (without Jira key)
            elseif ($line -match '^\s*-\s+(\[[ x~-]\])\s+(?![A-Z]+-\d+)(.+)$') {
                $checkbox = $matches[1]
                $description = $matches[2].Trim()
                
                # Skip empty descriptions
                if ([string]::IsNullOrWhiteSpace($description)) {
                    continue
                }
                
                $newTasks += @{
                    checkbox = $checkbox
                    description = $description
                    line = $line
                }
            }
        }
        
        # Process new tasks (create issues)
        if ($newTasks.Count -gt 0) {
            Write-Host "  $($service.name): $($newTasks.Count) new task(s)"
            
            foreach ($task in $newTasks) {
                $status = Get-StatusFromCheckbox -checkbox $task.checkbox
                
                try {
                    # Create issue with proper Atlassian Document Format
                    $body = @{
                        fields = @{
                            project = @{ key = $service.project }
                            summary = $task.description
                            description = @{
                                version = 1
                                type = "doc"
                                content = @(@{
                                    type = "paragraph"
                                    content = @(@{
                                        type = "text"
                                        text = "Created from project-task.md"
                                    })
                                })
                            }
                            labels = @($service.label)
                            issuetype = @{ name = 'Task' }
                        }
                    } | ConvertTo-Json -Depth 10
                    
                    if ($DryRun) {
                        Write-Host "    [DRY RUN] Would create: $($task.description)"
                        continue
                    }
                    
                    $uri = "$JiraBaseUrl/rest/api/3/issue"
                    $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Post -Body $body
                    $issueKey = $response.key
                    
                    Write-Host "    CREATED: $issueKey"
                    
                    # Transition to correct status if not "To Do"
                    if ($status -ne 'To Do') {
                        try {
                            $transUri = "$JiraBaseUrl/rest/api/3/issue/$issueKey/transitions"
                            $transResponse = Invoke-RestMethod -Uri $transUri -Headers $headers -Method Get
                            $trans = $transResponse.transitions | Where-Object { $_.to.name -eq $status } | Select-Object -First 1
                            
                            if ($trans) {
                                $transBody = @{ transition = @{ id = $trans.id } } | ConvertTo-Json
                                Invoke-RestMethod -Uri $transUri -Headers $headers -Method Post -Body $transBody | Out-Null
                                Write-Host "      TRANSITIONED: $status"
                            }
                        }
                        catch {
                            Write-Host "      WARNING: Could not transition status: $_"
                        }
                    }
                    
                    # Update markdown file with issue key
                    $oldLine = $task.line
                    $newLine = "- $($task.checkbox) $issueKey - $($task.description)"
                    $content = $content -replace [regex]::Escape($oldLine), $newLine
                    
                    $created++
                }
                catch {
                    Write-Host "    ERROR: $_"
                }
            }
        }
        
        # Process existing tasks (update status if changed)
        if ($existingTasks.Count -gt 0) {
            Write-Host "  $($service.name): Checking $($existingTasks.Count) existing task(s) for status changes"
            
            foreach ($task in $existingTasks) {
                $status = Get-StatusFromCheckbox -checkbox $task.checkbox
                
                try {
                    # Get current issue status
                    $issueUri = "$JiraBaseUrl/rest/api/3/issue/$($task.key)"
                    $issueResponse = Invoke-RestMethod -Uri $issueUri -Headers $headers -Method Get
                    $currentStatus = $issueResponse.fields.status.name
                    
                    # If status changed, transition
                    if ($currentStatus -ne $status) {
                        if ($DryRun) {
                            Write-Host "    [DRY RUN] Would transition $($task.key) from $currentStatus to $status"
                            continue
                        }
                        
                        try {
                            $transUri = "$JiraBaseUrl/rest/api/3/issue/$($task.key)/transitions"
                            $transResponse = Invoke-RestMethod -Uri $transUri -Headers $headers -Method Get
                            $trans = $transResponse.transitions | Where-Object { $_.to.name -eq $status } | Select-Object -First 1
                            
                            if ($trans) {
                                $transBody = @{ transition = @{ id = $trans.id } } | ConvertTo-Json
                                Invoke-RestMethod -Uri $transUri -Headers $headers -Method Post -Body $transBody | Out-Null
                                Write-Host "    UPDATED: $($task.key) transitioned from $currentStatus to $status"
                                $updated++
                            }
                            else {
                                Write-Host "    WARNING: No transition available from $currentStatus to $status for $($task.key)"
                            }
                        }
                        catch {
                            Write-Host "    WARNING: Could not transition $($task.key): $_"
                        }
                    }
                }
                catch {
                    Write-Host "    WARNING: Could not fetch status for $($task.key): $_"
                }
            }
        }
        
        if (($created -gt 0 -or $updated -gt 0) -and -not $DryRun) {
            Set-Content -Path $service.file -Value $content -NoNewline
            Write-Host "    SUCCESS: File updated"
        }
    }
    
    Write-Host "  Total created: $created, updated: $updated"
}

# Main execution
try {
    Write-Host "Starting bidirectional Jira sync..." -ForegroundColor Green
    Write-Host "Base URL: $JiraBaseUrl"
    
    if ($DryRun) {
        Write-Host "[DRY RUN MODE]" -ForegroundColor Yellow
    }
    
    Sync-JiraToMarkdown
    Sync-MarkdownToJira
    
    Write-Host "`nSync complete" -ForegroundColor Green
    exit 0
}
catch {
    Write-Host "`nSync failed: $_" -ForegroundColor Red
    exit 1
}
