#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Run Jira sync for all services
.DESCRIPTION
    Runs all 4 sync steps for each service in sequence
#>

param(
    [string]$RootEnvFile = "Applications/.env"
)

$ErrorActionPreference = 'Continue'

Write-Host "==============================================================" -ForegroundColor Cyan
Write-Host "           Jira Sync - Run All Services                         " -ForegroundColor Cyan
Write-Host "================================================================`n" -ForegroundColor Cyan

# Load environment variables from root .env file
if (Test-Path $RootEnvFile) {
    Write-Host "Loading configuration from: $RootEnvFile" -ForegroundColor Cyan
    
    $envLines = Get-Content $RootEnvFile
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
}
else {
    Write-Host "ERROR: .env file not found: $RootEnvFile" -ForegroundColor Red
    exit 1
}

# Get services to run
$services = @(
    @{ Name = "SecurityService"; EnvFile = "Applications/AITooling/Services/SecurityService/.env" },
    @{ Name = "DataLoaderService"; EnvFile = "Applications/AITooling/Services/DataLoaderService/.env" }
)

Write-Host "Services to process: $($services.Count)" -ForegroundColor Cyan
Write-Host ""

foreach ($service in $services) {
    Write-Host "==============================================================" -ForegroundColor Cyan
    Write-Host "  Processing Service: $($service.Name)" -ForegroundColor Cyan
    Write-Host "==============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Run all steps for this service with its own .env file
    & .\scripts\run-all-steps.ps1 -EnvFile $service.EnvFile
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Service $($service.Name) failed with exit code: $LASTEXITCODE" -ForegroundColor Red
        exit $LASTEXITCODE
    }
    
    Write-Host ""
    Write-Host "Service $($service.Name) completed successfully" -ForegroundColor Green
    Write-Host ""
}

Write-Host "==============================================================" -ForegroundColor Green
Write-Host "              All Services Completed Successfully!              " -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green

exit 0
