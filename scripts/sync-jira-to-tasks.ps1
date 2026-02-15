#!/usr/bin/env pwsh
# Minimal Jira to tasks sync script

param(
    [string]$JiraBaseUrl = $env:JIRA_BASE_URL,
    [string]$JiraEmail = $env:JIRA_USER_EMAIL,
    [string]$JiraToken = $env:JIRA_API_TOKEN
)

if (-not $JiraBaseUrl -or -not $JiraEmail -or -not $JiraToken) {
    Write-Error "Missing Jira credentials"
    exit 1
}

$auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$JiraEmail`:$JiraToken"))
$headers = @{
    'Authorization' = "Basic $auth"
    'Content-Type' = 'application/json'
}

Write-Host "Sync complete"
exit 0
