#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Auto-detect microservice and run Jira sync
.DESCRIPTION
    Detects the current microservice from the working directory
    and runs all 4 sync steps automatically
#>

$ErrorActionPreference = 'Continue'

# Auto-detect microservice from current directory
$currentDir = Get-Location
Write-Host "Current directory: $currentDir" -ForegroundColor Cyan

# Look for .env file in current or parent directories
$envFile = $null
$servicePath = $null

# Check current directory first
if (Test-Path ".\.env") {
    $envFile = ".\.env"
    $servicePath = $currentDir
}
else {
    # Search parent directories for .env
    $parent = $currentDir
    while ($parent.Parent) {
        $envPath = Join-Path $parent.FullName ".env"
        if (Test-Path $envPath) {
            $envFile = $envPath
            $servicePath = $parent.FullName
            break
        }
        $parent = $parent.Parent
    }
}

if (-not $envFile) {
    Write-Host "ERROR: No .env file found in current or parent directories" -ForegroundColor Red
    Write-Host "Please run from a microservice directory (e.g., SecurityService, DataLoaderService)" -ForegroundColor Yellow
    exit 1
}

Write-Host "Found .env file: $envFile" -ForegroundColor Green

# Load environment variables
$envLines = Get-Content $envFile
foreach ($line in $envLines) {
    if ($line.StartsWith('#') -or [string]::IsNullOrWhiteSpace($line)) {
        continue
    }
    
    $parts = $line.Split('=', 2)
    if ($parts.Count -eq 2) {
        $key = $parts[0].Trim()
        $value = $parts[1].Trim()
        
        [Environment]::SetEnvironmentVariable($key, $value, [System.EnvironmentVariableTarget]::Process)
    }
}

$serviceName = $env:SERVICE_NAME
if (-not $serviceName) {
    Write-Host "ERROR: SERVICE_NAME not set in .env file" -ForegroundColor Red
    exit 1
}

Write-Host "`n==============================================================" -ForegroundColor Cyan
Write-Host "           Jira Sync - Service: $serviceName" -ForegroundColor Cyan
Write-Host "================================================================`n" -ForegroundColor Cyan

# Step 1
Write-Host "[1] Step 1: Pull Missing Tasks from Jira" -ForegroundColor Green
& .\scripts\jira-sync-step1-pull-missing-tasks.ps1
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Host "Step 1 completed" -ForegroundColor Green

# Step 4 - Sync Jira to markdown (Jira is source of truth, final say)
Write-Host "`n[1] Step 4: Sync Jira Status to Markdown" -ForegroundColor Green
& .\scripts\jira-sync-step4-jira-to-markdown.ps1
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Host "Step 4 completed" -ForegroundColor Green

Write-Host "`n==============================================================" -ForegroundColor Green
Write-Host "              All Steps Completed Successfully!                 " -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green

exit 0
