# Jira Task Sync Orchestrator
# Synchronizes tasks between project-task.md and Jira

param(
    [string]$ProjectTaskFile = "Applications/AITooling/Services/DataLoaderService/.kiro/specs/data-loader-service/project-task.md",
    [string]$JiraUrl = "https://nileshf.atlassian.net",
    [string]$JiraUsername = "nileshf@gmail.com",
    [string]$JiraApiToken = $env:JIRA_API_TOKEN,
    [switch]$DryRun = $false
)

# Color output
function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Warning { Write-Host $args -ForegroundColor Yellow }
function Write-Error { Write-Host $args -ForegroundColor Red }
function Write-Info { Write-Host $args -ForegroundColor Cyan }

# Create Jira API headers
function Get-JiraHeaders {
    $auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${JiraUsername}:${JiraApiToken}"))
    return @{
        "Authorization" = "Basic $auth"
        "Content-Type" = "application/json"
        "Accept" = "application/json"
    }
}

# Parse task status from checkbox
function Get-TaskStatus {
    param([string]$Checkbox)
    
    switch ($Checkbox) {
        "[ ]" { return "Not Started" }
        "[x]" { return "Completed" }
        "[X]" { return "Completed" }
        "[~]" { return "In Progress" }
        "[-]" { return "In Progress" }
        default { return "Unknown" }
    }
}

# Extract Jira issue key from task line
function Get-JiraIssueKey {
    param([string]$TaskLine)
    
    if ($TaskLine -match '\[([A-Z]+-\d+)\]') {
        return $matches[1]
    }
    return $null
}

# Get current issue status from Jira
function Get-JiraIssueStatus {
    param([string]$IssueKey)
    
    try {
        $headers = Get-JiraHeaders
        $response = Invoke-RestMethod `
            -Uri "$JiraUrl/rest/api/3/issue/$IssueKey" `
            -Headers $headers `
            -Method Get
        
        return $response.fields.status.name
    }
    catch {
        Write-Warning "Failed to get status for $IssueKey : $_"
        return $null
    }
}

# Transition Jira issue to new status
function Set-JiraIssueStatus {
    param(
        [string]$IssueKey,
        [string]$NewStatus
    )
    
    try {
        $headers = Get-JiraHeaders
        
        # Get available transitions
        $transitionsResponse = Invoke-RestMethod `
            -Uri "$JiraUrl/rest/api/3/issue/$IssueKey/transitions" `
            -Headers $headers `
            -Method Get
        
        # Find transition ID for target status
        $transition = $transitionsResponse.transitions | Where-Object { $_.to.name -eq $NewStatus }
        
        if (-not $transition) {
            Write-Warning "No transition available to '$NewStatus' for $IssueKey"
            return $false
        }
        
        # Perform transition
        $body = @{
            transition = @{
                id = $transition.id
            }
        } | ConvertTo-Json
        
        if ($DryRun) {
            Write-Info "[DRY RUN] Would transition $IssueKey to $NewStatus (transition ID: $($transition.id))"
            return $true
        }
        
        Invoke-RestMethod `
            -Uri "$JiraUrl/rest/api/3/issue/$IssueKey/transitions" `
            -Headers $headers `
            -Method Post `
            -Body $body | Out-Null
        
        Write-Success "✓ Transitioned $IssueKey to $NewStatus"
        return $true
    }
    catch {
        Write-Error "Failed to transition $IssueKey : $_"
        return $false
    }
}

# Add comment to Jira issue
function Add-JiraComment {
    param(
        [string]$IssueKey,
        [string]$Comment
    )
    
    try {
        $headers = Get-JiraHeaders
        
        $body = @{
            body = @{
                version = 1
                type = "doc"
                content = @(
                    @{
                        type = "paragraph"
                        content = @(
                            @{
                                type = "text"
                                text = $Comment
                            }
                        )
                    }
                )
            }
        } | ConvertTo-Json -Depth 10
        
        if ($DryRun) {
            Write-Info "[DRY RUN] Would add comment to $IssueKey : $Comment"
            return $true
        }
        
        Invoke-RestMethod `
            -Uri "$JiraUrl/rest/api/3/issue/$IssueKey/comments" `
            -Headers $headers `
            -Method Post `
            -Body $body | Out-Null
        
        Write-Success "✓ Added comment to $IssueKey"
        return $true
    }
    catch {
        Write-Warning "Failed to add comment to $IssueKey : $_"
        return $false
    }
}

# Main sync logic
function Sync-JiraTasks {
    Write-Info "Starting Jira Task Sync..."
    Write-Info "Project Task File: $ProjectTaskFile"
    Write-Info "Jira URL: $JiraUrl"
    
    if ($DryRun) {
        Write-Warning "[DRY RUN MODE] - No changes will be made to Jira"
    }
    
    # Check if file exists
    if (-not (Test-Path $ProjectTaskFile)) {
        Write-Error "Project task file not found: $ProjectTaskFile"
        return
    }
    
    # Read file
    $content = Get-Content $ProjectTaskFile -Raw
    
    # Parse tasks
    $taskPattern = '- (\[.\]) (.+?) - \[([A-Z]+-\d+)\]'
    $matches = [regex]::Matches($content, $taskPattern)
    
    Write-Info "Found $($matches.Count) tasks to sync"
    
    $syncedCount = 0
    $failedCount = 0
    
    foreach ($match in $matches) {
        $checkbox = $match.Groups[1].Value
        $taskDescription = $match.Groups[2].Value
        $issueKey = $match.Groups[3].Value
        
        $taskStatus = Get-TaskStatus $checkbox
        
        Write-Info "`nProcessing: $issueKey - $taskDescription"
        Write-Info "  Local Status: $taskStatus"
        
        # Get current Jira status
        $jiraStatus = Get-JiraIssueStatus $issueKey
        Write-Info "  Jira Status: $jiraStatus"
        
        # Map local status to Jira status
        $jiraTargetStatus = switch ($taskStatus) {
            "Not Started" { "To Do" }
            "In Progress" { "In Progress" }
            "Completed" { "Done" }
            default { $null }
        }
        
        if ($jiraTargetStatus -and $jiraStatus -ne $jiraTargetStatus) {
            Write-Info "  Action: Transitioning to $jiraTargetStatus"
            
            if (Set-JiraIssueStatus -IssueKey $issueKey -NewStatus $jiraTargetStatus) {
                $syncedCount++
            }
            else {
                $failedCount++
            }
        }
        else {
            Write-Info "  Action: No change needed"
            $syncedCount++
        }
    }
    
    # Summary
    Write-Info "`n" + ("=" * 50)
    Write-Success "Sync Complete!"
    Write-Info "Synced: $syncedCount tasks"
    if ($failedCount -gt 0) {
        Write-Warning "Failed: $failedCount tasks"
    }
    Write-Info "=" * 50
}

# Run sync
Sync-JiraTasks
