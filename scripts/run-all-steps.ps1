#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Run all Jira sync steps in sequence
.DESCRIPTION
    Runs all 4 sync steps with environment variables loaded from .env
#>

param(
    [string]$EnvFile = ".env"
)

$ErrorActionPreference = 'Continue'

Write-Host "==============================================================" -ForegroundColor Cyan
Write-Host "           Jira Sync - Run All Steps in Sequence                " -ForegroundColor Cyan
Write-Host "================================================================`n" -ForegroundColor Cyan

# Load environment variables from .env file
if (Test-Path $EnvFile) {
    Write-Host "Loading configuration from: $EnvFile" -ForegroundColor Cyan
    
    $envLines = Get-Content $EnvFile
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
    
    Write-Host "Environment variables loaded" -ForegroundColor Green
    
    # Display loaded environment variables
    Write-Host "`nLoaded Environment Variables:" -ForegroundColor Cyan
    Write-Host "-----------------------------" -ForegroundColor Cyan
    foreach ($line in $envLines) {
        if ($line.StartsWith('#') -or [string]::IsNullOrWhiteSpace($line)) {
            continue
        }
        
        $parts = $line.Split('=', 2)
        if ($parts.Count -eq 2) {
            $key = $parts[0].Trim()
            $value = $parts[1].Trim()
            
            # Mask sensitive values
            if ($key -match 'PASSWORD|SECRET|TOKEN|KEY|CREDENTIAL') {
                $maskedValue = if ($value.Length -gt 4) { "*" * ($value.Length - 4) + $value.Substring($value.Length - 4) } else { "****" }
                Write-Host "  $key=$maskedValue" -ForegroundColor Yellow
            }
            else {
                Write-Host "  $key=$value" -ForegroundColor Yellow
            }
        }
    }
    Write-Host "-----------------------------" -ForegroundColor Cyan
}
else {
    Write-Host "ERROR: .env file not found: $EnvFile" -ForegroundColor Red
    exit 1
}

# Get service name from environment
$serviceName = $env:SERVICE_NAME
if (-not $serviceName) {
    Write-Host "ERROR: SERVICE_NAME not set" -ForegroundColor Red
    exit 1
}

Write-Host "`nService: $serviceName" -ForegroundColor Yellow
Write-Host "----------------------------------------------------------------" -ForegroundColor Cyan

# Step 1
Write-Host "`n[1] Step 1: Pull Missing Tasks from Jira" -ForegroundColor Green
& .\scripts\jira-sync-step1-pull-missing-tasks.ps1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Step 1 failed with exit code: $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}
Write-Host "Step 1 completed successfully" -ForegroundColor Green

# Step 4 - Sync Jira to markdown (Jira is source of truth, final say)
Write-Host "`n[1] Step 4: Sync Jira Status to Markdown" -ForegroundColor Green
& .\scripts\jira-sync-step4-jira-to-markdown.ps1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Step 4 failed with exit code: $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}
Write-Host "Step 4 completed successfully" -ForegroundColor Green

Write-Host "`n==============================================================" -ForegroundColor Green
Write-Host "              All Steps Completed Successfully!                 " -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green

exit 0
