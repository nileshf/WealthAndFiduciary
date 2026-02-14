#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Automated setup script for Jira Sync - Configure environment from .env
.DESCRIPTION
    Non-interactive setup that loads configuration from .env file
.EXAMPLE
    ./setup-jira-sync-auto.ps1 -ServiceName "SecurityService"
#>

param(
    [string]$ServiceName = "SecurityService"
)

$ErrorActionPreference = 'Continue'

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Jira Sync Automated Setup" -ForegroundColor Cyan
Write-Host "Load configuration from .env" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Initialize config
$config = @{}
$envFile = ".env"

# Load from .env file
if (-not (Test-Path $envFile)) {
    Write-Host "ERROR: .env file not found" -ForegroundColor Red
    exit 1
}

Write-Host "Loading configuration from .env" -ForegroundColor Green

$envLines = Get-Content $envFile
foreach ($line in $envLines) {
    if ($line.StartsWith('#') -or [string]::IsNullOrWhiteSpace($line)) {
        continue
    }
    
    $parts = $line.Split('=', 2)
    if ($parts.Count -eq 2) {
        $key = $parts[0].Trim()
        $value = $parts[1].Trim()
        
        if ($key -eq 'JIRA_BASE_URL') { $config.JiraBaseUrl = $value }
        if ($key -eq 'JIRA_USER_EMAIL') { $config.JiraEmail = $value }
        if ($key -eq 'JIRA_API_TOKEN') { $config.JiraToken = $value }
        if ($key -eq 'JIRA_PROJECT_KEY') { $config.JiraProjectKey = $value }
    }
}

if (-not $config.JiraBaseUrl -or -not $config.JiraEmail -or -not $config.JiraToken) {
    Write-Host "ERROR: Missing required Jira configuration in .env" -ForegroundColor Red
    exit 1
}

Write-Host "  Base URL: $($config.JiraBaseUrl)" -ForegroundColor Yellow
Write-Host "  Email: $($config.JiraEmail)" -ForegroundColor Yellow
Write-Host "  Project Key: $($config.JiraProjectKey)" -ForegroundColor Yellow

# Service mapping
$services = @{
    "SecurityService" = "Applications/AITooling/Services/SecurityService/.kiro/specs/security-service/project-task.md"
    "DataLoaderService" = "Applications/AITooling/Services/DataLoaderService/.kiro/specs/data-loader-service/project-task.md"
    "FullViewSecurity" = "Applications/FullView/Services/FullViewSecurity/.kiro/specs/fullview-security/project-task.md"
    "INN8DataSource" = "Applications/FullView/Services/INN8DataSource/.kiro/specs/inn8-data-source/project-task.md"
}

if (-not $services.ContainsKey($ServiceName)) {
    Write-Host "ERROR: Unknown service: $ServiceName" -ForegroundColor Red
    Write-Host "Available services: $($services.Keys -join ', ')" -ForegroundColor Yellow
    exit 1
}

$config.ServiceName = $ServiceName
$config.TaskFile = $services[$ServiceName]

Write-Host ""
Write-Host "Selected service: $($config.ServiceName)" -ForegroundColor Green
Write-Host "  Task file: $($config.TaskFile)" -ForegroundColor Yellow

# Verify Task File
if (-not (Test-Path $config.TaskFile)) {
    Write-Host "ERROR: Task file not found: $($config.TaskFile)" -ForegroundColor Red
    exit 1
}

Write-Host "Task file found" -ForegroundColor Green

# Save Configuration
$configDir = ".kiro/settings"
$configFile = "$configDir/jira-sync-config.json"

if (-not (Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
}

$config | ConvertTo-Json | Set-Content $configFile
Write-Host ""
Write-Host "Configuration saved to: $configFile" -ForegroundColor Green

# Set Environment Variables
Write-Host ""
Write-Host "Setting environment variables..." -ForegroundColor Cyan
$env:JIRA_BASE_URL = $config.JiraBaseUrl
$env:JIRA_USER_EMAIL = $config.JiraEmail
$env:JIRA_API_TOKEN = $config.JiraToken
$env:SERVICE_NAME = $config.ServiceName
$env:TASK_FILE = $config.TaskFile

Write-Host "Environment variables configured" -ForegroundColor Green

Write-Host ""
Write-Host "Setup completed successfully" -ForegroundColor Green
Write-Host ""
Write-Host "You can now run the sync scripts:" -ForegroundColor Cyan
Write-Host "  ./scripts/jira-sync-step1-pull-missing-tasks.ps1" -ForegroundColor Yellow
Write-Host "  ./scripts/jira-sync-step2-push-new-tasks.ps1" -ForegroundColor Yellow
Write-Host "  ./scripts/jira-sync-step3-sync-jira-status.ps1" -ForegroundColor Yellow
Write-Host "  ./scripts/jira-sync-step4-sync-markdown-status.ps1" -ForegroundColor Yellow
Write-Host "  ./scripts/jira-sync-orchestration.ps1" -ForegroundColor Yellow
Write-Host ""

exit 0
