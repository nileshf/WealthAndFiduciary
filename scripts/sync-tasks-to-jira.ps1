#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Syncs project-task.md entries to Jira as issues
#>

param(
    [string]$JiraBaseUrl = $env:JIRA_BASE_URL,
    [string]$JiraEmail = $env:JIRA_USER_EMAIL,
    [string]$JiraToken = $env:JIRA_API_TOKEN,
    [switch]$Verbose = $false
)

# Validation
if ([string]::IsNullOrEmpty($JiraBaseUrl)) {
    Write-Error "JIRA_BASE_URL environment variable is required"
    exit 1
}

if ([string]::IsNullOrEmpty($JiraEmail)) {
    Write-Error "JIRA_USER_EMAIL environment variable is required"
    exit 1
}

if ([string]::IsNullOrEmpty($JiraToken)) {
    Write-Error "JIRA_API_TOKEN environment variable is required"
    exit 1
}

Write-Host "Starting Jira sync..."
Write-Host "Base URL: $JiraBaseUrl"

# Get auth header
$auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$JiraEmail`:$JiraToken"))
$headers = @{
    'Authorization' = "Basic $auth"
    'Content-Type' = 'application/json'
}

# Test connection
try {
    $testUri = "$JiraBaseUrl/rest/api/3/myself"
    $response = Invoke-RestMethod -Uri $testUri -Headers $headers -Method Get -ErrorAction Stop
    Write-Host "✓ Successfully authenticated to Jira as: $($response.displayName)"
}
catch {
    Write-Error "Failed to authenticate to Jira: $_"
    exit 1
}

# Define services
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

$totalCreated = 0
$totalUpdated = 0

foreach ($service in $services) {
    Write-Host ""
    Write-Host "Processing $($service.name)..."
    
    if (-not (Test-Path $service.file)) {
        Write-Host "  ⚠ File not found: $($service.file)"
        continue
    }
    
    $content = Get-Content $service.file -Raw
    $lines = $content -split "`n"
    $newLines = @()
    $created = 0
    
    foreach ($line in $lines) {
        # Check if this is a task line without a Jira key
        if ($line -match '^\s*-\s+\[[ x~-]\]\s+([^-\[].+)$') {
            $description = $matches[1].Trim()
            
            # Skip if already has Jira key
            if ($description -match '^[A-Z]+-\d+\s+-') {
                $newLines += $line
                continue
            }
            
            # Skip empty descriptions
            if ([string]::IsNullOrWhiteSpace($description)) {
                $newLines += $line
                continue
            }
            
            Write-Host "  Creating issue: $description"
            
            # Determine status from checkbox
            $checkbox = if ($line -match '\[[ x~-]\]') { $matches[0] } else { '[ ]' }
            $status = switch ($checkbox) {
                '[ ]' { 'To Do' }
                '[-]' { 'In Progress' }
                '[~]' { 'In Review' }
                '[x]' { 'Done' }
                default { 'To Do' }
            }
            
            # Create Jira issue
            try {
                $body = @{
                    fields = @{
                        project = @{ key = $service.project }
                        summary = $description
                        description = @{
                            version = 1
                            type = "doc"
                            content = @(
                                @{
                                    type = "paragraph"
                                    content = @(
                                        @{
                                            type = "text"
                                            text = "Created from project-task.md for $($service.name)"
                                        }
                                    )
                                }
                            )
                        }
                        labels = @($service.label)
                        issuetype = @{ name = 'Task' }
                    }
                } | ConvertTo-Json -Depth 10
                
                $issueUri = "$JiraBaseUrl/rest/api/3/issue"
                $issueResponse = Invoke-RestMethod -Uri $issueUri -Headers $headers -Method Post -Body $body -ErrorAction Stop
                $issueKey = $issueResponse.key
                
                Write-Host "    ✓ Created: $issueKey"
                
                # Transition to correct status if needed
                if ($status -ne 'To Do') {
                    try {
                        $transUri = "$JiraBaseUrl/rest/api/3/issue/$issueKey/transitions"
                        $transResponse = Invoke-RestMethod -Uri $transUri -Headers $headers -Method Get -ErrorAction Stop
                        $trans = $transResponse.transitions | Where-Object { $_.to.name -eq $status } | Select-Object -First 1
                        
                        if ($trans) {
                            $transBody = @{ transition = @{ id = $trans.id } } | ConvertTo-Json
                            Invoke-RestMethod -Uri $transUri -Headers $headers -Method Post -Body $transBody -ErrorAction Stop
                            Write-Host "    ✓ Transitioned to: $status"
                        }
                    }
                    catch {
                        Write-Host "    ⚠ Could not transition to $status : $_"
                    }
                }
                
                # Update the line with issue key
                $checkbox = $line -replace '.*(\[[ x~-]\]).*/','$1'
                $newLine = "- $checkbox $issueKey - $description"
                $newLines += $newLine
                $created++
                $totalCreated++
            }
            catch {
                Write-Host "    ✗ Error: $_"
                $newLines += $line
            }
        }
        else {
            $newLines += $line
        }
    }
    
    # Write updated file if changes were made
    if ($created -gt 0) {
        $newContent = $newLines -join "`n"
        Set-Content -Path $service.file -Value $newContent -NoNewline
        Write-Host "  ✓ Updated file with $created issue(s)"
        $totalUpdated++
    }
    else {
        Write-Host "  ℹ No new tasks to create"
    }
}

Write-Host ""
Write-Host "✓ Sync complete: $totalCreated issues created, $totalUpdated file(s) updated"
exit 0
