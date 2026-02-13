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
$uri = "$JiraBaseUrl/rest/api/3/search/jql?jql=$([System.Uri]::EscapeDataString($jql))&maxResults=100&fields=key,summary,status,description,labels"

try {
    $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
    $jiraIssues = $response.issues
    Write-Host "Found issues in Jira" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: Failed to fetch Jira issues: $_" -ForegroundColor Red
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
Write-Host "Found $($existingKeys.Count) existing tasks in markdown" -ForegroundColor Green

# Find missing tasks
Write-Host "`nFinding missing tasks..." -ForegroundColor Cyan
$missingTasks = @()
foreach ($issue in $jiraIssues) {
    if ($issue.key -notin $existingKeys) {
        $missingTasks += $issue
    }
}

if ($missingTasks.Count -eq 0) {
    Write-Host "No missing tasks" -ForegroundColor Green
    exit 0
}

Write-Host "Found $($missingTasks.Count) missing task(s)" -ForegroundColor Yellow

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

# Helper: Calculate string similarity (word-based)
function Get-StringSimilarity {
    param([string]$str1, [string]$str2)
    
    $str1 = $str1.ToLower()
    $str2 = $str2.ToLower()
    
    # Exact match
    if ($str1 -eq $str2) { return 1.0 }
    
    # Word-based matching
    $words1 = $str1 -split '\s+' | Where-Object { $_.Length -gt 2 }
    $words2 = $str2 -split '\s+' | Where-Object { $_.Length -gt 2 }
    
    if ($words1.Count -eq 0 -or $words2.Count -eq 0) {
        return 0
    }
    
    # Count matching words
    $matchingWords = 0
    foreach ($word1 in $words1) {
        if ($words2 -contains $word1) {
            $matchingWords++
        }
    }
    
    # Calculate similarity as percentage of matching words
    $similarity = $matchingWords / [Math]::Max($words1.Count, $words2.Count)
    return $similarity
}

# Match tasks without keys to Jira issues by summary
Write-Host "`nMatching tasks without Jira keys..." -ForegroundColor Cyan
if ($tasksWithoutKeys.Count -gt 0) {
    $updatedContent = $content
    
    foreach ($taskWithoutKey in $tasksWithoutKeys) {
        $taskSummary = $taskWithoutKey.summary
        Write-Host "  Searching for: '$taskSummary'" -ForegroundColor Cyan
        
        # Find best matching Jira issue by similarity
        $bestMatch = $null
        $bestSimilarity = 0
        
        foreach ($issue in $jiraIssues) {
            $similarity = Get-StringSimilarity $taskSummary $issue.fields.summary
            
            # Require at least 60% similarity
            if ($similarity -gt $bestSimilarity -and $similarity -ge 0.6) {
                $bestSimilarity = $similarity
                $bestMatch = $issue
            }
        }
        
        if ($bestMatch) {
            $checkbox = Get-CheckboxFromStatus $bestMatch.fields.status.name
            $oldLine = $taskWithoutKey.line
            $newLine = "- [$checkbox] $($bestMatch.key) - $($bestMatch.fields.summary)"
            
            $updatedContent = $updatedContent -replace [regex]::Escape($oldLine), $newLine
            Write-Host "    Matched to: $($bestMatch.key) (similarity: $([Math]::Round($bestSimilarity * 100))%)" -ForegroundColor Green
        }
        else {
            Write-Host "    No matching Jira issue found (required 60% similarity)" -ForegroundColor Yellow
        }
    }
    
    # Write updated content after matching
    Set-Content -Path $TaskFile -Value $updatedContent
}

# Add missing tasks to markdown (only if they match current service)
Write-Host "`nAdding missing tasks to markdown..." -ForegroundColor Cyan
$updatedContent = Get-Content $TaskFile -Raw
$addedCount = 0

foreach ($task in $missingTasks) {
    # Check if task has labels
    $taskLabels = $task.fields.labels
    if (-not $taskLabels -or $taskLabels.Count -eq 0) {
        Write-Host "  Skipped: $($task.key) (no labels)" -ForegroundColor Gray
        continue
    }
    
    # Check if any label matches the current service
    $hasServiceLabel = $false
    foreach ($label in $taskLabels) {
        if ($label.ToLower() -eq $ServiceName.ToLower()) {
            $hasServiceLabel = $true
            break
        }
    }
    
    if (-not $hasServiceLabel) {
        Write-Host "  Skipped: $($task.key) (no matching service label)" -ForegroundColor Gray
        continue
    }
    
    $checkbox = Get-CheckboxFromStatus $task.fields.status.name
    $newLine = "- [$checkbox] $($task.key) - $($task.fields.summary)"
    $updatedContent += "`n$newLine"
    Write-Host "  Added: $($task.key)" -ForegroundColor Yellow
    $addedCount++
}

# Write updated content
Set-Content -Path $TaskFile -Value $updatedContent
Write-Host "`nStep 1 completed successfully (added $addedCount task(s))" -ForegroundColor Green
exit 0
