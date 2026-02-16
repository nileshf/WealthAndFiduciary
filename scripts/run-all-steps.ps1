#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Run all Jira sync steps for all services
.DESCRIPTION
    Runs all 4 sync steps for each service.
    Each step script handles its own service discovery and .env loading.
.PARAMETER ServiceName
    Optional: Run for specific service only (e.g., SecurityService, DataLoaderService)
.EXAMPLE
    .\scripts\run-all-steps.ps1                    # Run for all services
    .\scripts\run-all-steps.ps1 -ServiceName "SecurityService"  # Run for one service
#>

param(
    [string]$ServiceName
)

$ErrorActionPreference = 'Continue'

Write-Host "==============================================================" -ForegroundColor Cyan
Write-Host "           Jira Sync - Run All Steps for All Services           " -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

if ($ServiceName) {
    Write-Host "Running for specific service: $ServiceName" -ForegroundColor Yellow
}
else {
    Write-Host "Running for all services" -ForegroundColor Yellow
}
Write-Host ""

# Step 1 - Pull missing tasks from Jira
Write-Host "==============================================================" -ForegroundColor Cyan
Write-Host "                    STEP 1                                     " -ForegroundColor Cyan
Write-Host "==============================================================" -ForegroundColor Cyan
$global:Step1Result = $null
& .\scripts\jira-sync-step1-pull-missing-tasks.ps1 -ServiceName $ServiceName
if ($global:Step1Result -ne 0) {
    Write-Host "Step 1 failed with exit code: $($global:Step1Result)" -ForegroundColor Red
    exit 1
}
Write-Host "Step 1 completed successfully" -ForegroundColor Green

# Clear environment variables before next step
[Environment]::SetEnvironmentVariable('JIRA_BASE_URL', $null, [System.EnvironmentVariableTarget]::Process)
[Environment]::SetEnvironmentVariable('JIRA_USER_EMAIL', $null, [System.EnvironmentVariableTarget]::Process)
[Environment]::SetEnvironmentVariable('JIRA_API_TOKEN', $null, [System.EnvironmentVariableTarget]::Process)
[Environment]::SetEnvironmentVariable('SERVICE_NAME', $null, [System.EnvironmentVariableTarget]::Process)
[Environment]::SetEnvironmentVariable('TASK_FILE', $null, [System.EnvironmentVariableTarget]::Process)
[Environment]::SetEnvironmentVariable('JIRA_PROJECT_KEY', $null, [System.EnvironmentVariableTarget]::Process)

# Step 2 - Push new tasks to Jira
Write-Host "==============================================================" -ForegroundColor Cyan
Write-Host "                    STEP 2                                     " -ForegroundColor Cyan
Write-Host "==============================================================" -ForegroundColor Cyan
$global:Step2Result = $null
& .\scripts\jira-sync-step2-push-new-tasks.ps1 -ServiceName $ServiceName
if ($global:Step2Result -ne 0) {
    Write-Host "Step 2 failed with exit code: $($global:Step2Result)" -ForegroundColor Red
    exit 1
}
Write-Host "Step 2 completed successfully" -ForegroundColor Green

# Clear environment variables before next step
[Environment]::SetEnvironmentVariable('JIRA_BASE_URL', $null, [System.EnvironmentVariableTarget]::Process)
[Environment]::SetEnvironmentVariable('JIRA_USER_EMAIL', $null, [System.EnvironmentVariableTarget]::Process)
[Environment]::SetEnvironmentVariable('JIRA_API_TOKEN', $null, [System.EnvironmentVariableTarget]::Process)
[Environment]::SetEnvironmentVariable('SERVICE_NAME', $null, [System.EnvironmentVariableTarget]::Process)
[Environment]::SetEnvironmentVariable('TASK_FILE', $null, [System.EnvironmentVariableTarget]::Process)
[Environment]::SetEnvironmentVariable('JIRA_PROJECT_KEY', $null, [System.EnvironmentVariableTarget]::Process)

# Step 3 - Sync markdown status to Jira
Write-Host "==============================================================" -ForegroundColor Cyan
Write-Host "                    STEP 3                                     " -ForegroundColor Cyan
Write-Host "==============================================================" -ForegroundColor Cyan
$global:Step3Result = $null
& .\scripts\jira-sync-step3-markdown-to-jira.ps1 -ServiceName $ServiceName
if ($global:Step3Result -ne 0) {
    Write-Host "Step 3 failed with exit code: $($global:Step3Result)" -ForegroundColor Red
    exit 1
}
Write-Host "Step 3 completed successfully" -ForegroundColor Green

# Clear environment variables before next step
[Environment]::SetEnvironmentVariable('JIRA_BASE_URL', $null, [System.EnvironmentVariableTarget]::Process)
[Environment]::SetEnvironmentVariable('JIRA_USER_EMAIL', $null, [System.EnvironmentVariableTarget]::Process)
[Environment]::SetEnvironmentVariable('JIRA_API_TOKEN', $null, [System.EnvironmentVariableTarget]::Process)
[Environment]::SetEnvironmentVariable('SERVICE_NAME', $null, [System.EnvironmentVariableTarget]::Process)
[Environment]::SetEnvironmentVariable('TASK_FILE', $null, [System.EnvironmentVariableTarget]::Process)
[Environment]::SetEnvironmentVariable('JIRA_PROJECT_KEY', $null, [System.EnvironmentVariableTarget]::Process)

# Step 4 - Sync Jira status to markdown (Jira is source of truth, final say)
Write-Host "==============================================================" -ForegroundColor Cyan
Write-Host "                    STEP 4                                     " -ForegroundColor Cyan
Write-Host "==============================================================" -ForegroundColor Cyan
$global:Step4Result = $null
& .\scripts\jira-sync-step4-jira-to-markdown.ps1 -ServiceName $ServiceName
if ($global:Step4Result -ne 0) {
    Write-Host "Step 4 failed with exit code: $($global:Step4Result)" -ForegroundColor Red
    exit 1
}
Write-Host "Step 4 completed successfully" -ForegroundColor Green

Write-Host ""
Write-Host "==============================================================" -ForegroundColor Cyan
Write-Host "All Steps Completed Successfully!" -ForegroundColor Green
Write-Host "==============================================================" -ForegroundColor Cyan
exit 0
