#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Step 1: Pull missing tasks from Jira to project-task.md (Core Logic)
.DESCRIPTION
    This is the core logic for Step 1. It expects environment variables to be loaded.
    Use jira-sync-step1-pull-missing-tasks.ps1 to run this with service discovery and env loading.
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

Write-Host "=== Step 1: Pull Missing Tasks from Jira ===" -ForegroundColor Green
Write-Host "Service: $ServiceName"
Write-Host "Task File: $TaskFile"
Write-Host "Project Key: $ProjectKey"

# Validation
if (-not $JiraBaseUrl -or -not $JiraEmail -or -not $JiraToken) {
    Write-Host "ERROR: Missing Jira credentials" -ForegroundColor Red
    Write-Host "  JIRA_BASE_URL: $([bool]$JiraBaseUrl)" -ForegroundColor Yellow
    Write-Host "  JIRA_USER_EMAIL: $([bool]$JiraEmail)" -ForegroundColor Yellow
    Write-Host "  JIRA_API_TOKEN: $([bool]$JiraToken) (length: $($JiraToken.Length))" -ForegroundColor Yellow
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
    $pair = "$JiraEmail`:$JiraToken"
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
    $base64 = [System.Convert]::ToBase64String($bytes)
    Write-Host "  Auth string length: $($pair.Length)" -ForegroundColor Gray
    Write-Host "  Base64 length: $($base64.Length)" -ForegroundColor Gray
    return $base64
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
Write-Host "  Base URL: $JiraBaseUrl" -ForegroundColor Gray
Write-Host "  Email: $JiraEmail" -ForegroundColor Gray
$jql = "project = $ProjectKey"
Write-Host "  JQL: $jql" -ForegroundColor Gray
$headers = Get-JiraHeaders
$authHeader = $headers['Authorization']
$shortAuth = if ($authHeader.Length -gt 50) { $authHeader.Substring(0, 50) + "..." } else { $authHeader }
Write-Host "  Authorization header: $shortAuth" -ForegroundColor Gray
$uri = "$JiraBaseUrl/rest/api/3/search/jql?jql=$([System.Uri]::EscapeDataString($jql))&maxResults=100&fields=key,summary,status,description,labels"

try {
    $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
    $jiraIssues = $response.issues
    Write-Host "Found issues in Jira: $($jiraIssues.Count)" -ForegroundColor Green
    
    # Debug: Show first few issues
    if ($jiraIssues.Count -gt 0) {
        Write-Host "  Sample issues:" -ForegroundColor Cyan
        $jiraIssues | Select-Object -First 3 | ForEach-Object {
            Write-Host "    $($_.key): $($_.fields.summary)" -ForegroundColor Gray
        }
    }
    else {
        Write-Host "  No issues found. Checking if project exists..." -ForegroundColor Yellow
        # Try to get project info
        $projectUri = "$JiraBaseUrl/rest/api/3/project/$ProjectKey"
        try {
            $projectResponse = Invoke-RestMethod -Uri $projectUri -Headers $headers -Method Get
            Write-Host "  Project $ProjectKey exists: $($projectResponse.name)" -ForegroundColor Green
        }
        catch {
            Write-Host "  Project $ProjectKey not found or no access" -ForegroundColor Yellow
            Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Yellow
            
            # List all accessible projects
            Write-Host "  Listing accessible projects..." -ForegroundColor Cyan
            $projectsUri = "$JiraBaseUrl/rest/api/3/project"
            try {
                $projectsResponse = Invoke-RestMethod -Uri $projectsUri -Headers $headers -Method Get
                Write-Host "  Accessible projects:" -ForegroundColor Cyan
                $projectsResponse | ForEach-Object {
                    Write-Host "    $($_.key): $($_.name)" -ForegroundColor Gray
                }
            }
            catch {
                Write-Host "  Could not list projects: $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
    }
}
catch {
    Write-Host "ERROR: Failed to fetch Jira issues" -ForegroundColor Red
    Write-Host "  Status Code: $($_.Exception.Response.StatusCode)" -ForegroundColor Yellow
    Write-Host "  Status Description: $($_.Exception.Response.StatusDescription)" -ForegroundColor Yellow
    Write-Host "  Error Message: $($_.ErrorDetails.Message)" -ForegroundColor Yellow
    $global:Step1Result = 1
    return 1
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
Write-Host "Found $($tasksWithoutKeys.Count) tasks without Jira keys" -ForegroundColor Gray

# Find missing tasks
Write-Host "`nFinding missing tasks..." -ForegroundColor Cyan
Write-Host "  Total Jira issues fetched: $($jiraIssues.Count)" -ForegroundColor Gray
$missingTasks = @()
foreach ($issue in $jiraIssues) {
    if ($issue.key -notin $existingKeys) {
        $missingTasks += $issue
    }
}

Write-Host "  Found $($missingTasks.Count) missing task(s) (not in markdown)" -ForegroundColor Gray

if ($missingTasks.Count -eq 0) {
    Write-Host "No missing tasks" -ForegroundColor Green
    $global:Step1Result = 0
    return 0
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
Write-Host "  Service name: $ServiceName" -ForegroundColor Gray
$updatedContent = Get-Content $TaskFile -Raw
$addedCount = 0
$skippedCount = 0

foreach ($task in $missingTasks) {
    # Check if task has labels
    $taskLabels = $task.fields.labels
    Write-Host "  Checking: $($task.key) - Labels: $($taskLabels -join ', ')" -ForegroundColor Gray
    
    if (-not $taskLabels -or $taskLabels.Count -eq 0) {
        Write-Host "    Skipped: $($task.key) (no labels)" -ForegroundColor Gray
        $skippedCount++
        continue
    }
    
    # Check if any label matches the current service
    $hasServiceLabel = $false
    foreach ($label in $taskLabels) {
        Write-Host "    Comparing label '$label' to service '$ServiceName'" -ForegroundColor Gray
        if ($label.ToLower() -eq $ServiceName.ToLower()) {
            $hasServiceLabel = $true
            break
        }
    }
    
    if (-not $hasServiceLabel) {
        Write-Host "    Skipped: $($task.key) (no matching service label)" -ForegroundColor Gray
        $skippedCount++
        continue
    }
    
    $checkbox = Get-CheckboxFromStatus $task.fields.status.name
    $newLine = "- [$checkbox] $($task.key) - $($task.fields.summary)"
    $updatedContent += "`n$newLine"
    Write-Host "    Added: $($task.key)" -ForegroundColor Yellow
    $addedCount++
}

Write-Host "  Total skipped (no labels or no service match): $skippedCount" -ForegroundColor Gray

# Write updated content
Set-Content -Path $TaskFile -Value $updatedContent
Write-Host "`nStep 1 completed successfully (added $addedCount task(s))" -ForegroundColor Green
$global:Step1Result = 0
return 0
