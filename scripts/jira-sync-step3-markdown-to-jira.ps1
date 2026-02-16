#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Step 3: Sync status changes from project-task.md to Jira
.DESCRIPTION
    If task status changes in project-task.md, update the status in Jira
    to reflect the new status. This runs BEFORE Step 3 so that Jira
    receives updates from markdown first, then markdown is updated from
    Jira (Jira is the ultimate source of truth).
    
    Runs for all services by default, or a specific service if -ServiceName is provided
.PARAMETER ServiceName
    Optional: Run for specific service only (e.g., SecurityService, DataLoaderService)
.EXAMPLE
    .\scripts\jira-sync-step3-markdown-to-jira.ps1                    # Run for all services
    .\scripts\jira-sync-step3-markdown-to-jira.ps1 -ServiceName "SecurityService"  # Run for one service
#>

param(
    [string]$ServiceName
)

$ErrorActionPreference = 'Continue'

Write-Host "==============================================================" -ForegroundColor Cyan
Write-Host "           Step 3: Sync Status Changes to Jira                 " -ForegroundColor Cyan
Write-Host "================================================================`n" -ForegroundColor Cyan

# Discover all services
$services = @()

if ($ServiceName) {
    # Run for specific service
    $services = @($ServiceName)
}
else {
    # Discover all services
    Write-Host "Discovering services..." -ForegroundColor Cyan
    
    # AITooling services
    $aiToolingPath = "Applications/AITooling/Services"
    if (Test-Path $aiToolingPath) {
        Get-ChildItem -Path $aiToolingPath -Directory | ForEach-Object {
            if (Test-Path "$($_.FullName)/.env") {
                $services += $_.Name
                Write-Host "  Found: $($_.Name)" -ForegroundColor Green
            }
        }
    }
    
    # FullView services
    $fullViewPath = "Applications/FullView/Services"
    if (Test-Path $fullViewPath) {
        Get-ChildItem -Path $fullViewPath -Directory | ForEach-Object {
            if (Test-Path "$($_.FullName)/.env") {
                $services += $_.Name
                Write-Host "  Found: $($_.Name)" -ForegroundColor Green
            }
        }
    }
}

if ($services.Count -eq 0) {
    Write-Host "ERROR: No services found" -ForegroundColor Red
    $global:Step3Result = 1
    exit 1
}

Write-Host "`nServices to process: $($services.Count)" -ForegroundColor Yellow
$services | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
Write-Host ""

# Process each service
$totalServices = $services.Count
$successCount = 0
$failureCount = 0
$serviceIndex = 0

foreach ($service in $services) {
    $serviceIndex++
    Write-Host "`n================================================================" -ForegroundColor Cyan
    Write-Host "[$serviceIndex/$totalServices] Processing Service: $service" -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Cyan
    
    # Find service .env file
    $envFile = $null
    $possiblePaths = @(
        "Applications/AITooling/Services/$service/.env",
        "Applications/FullView/Services/$service/.env"
    )
    
    $pathFound = $false
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $envFile = $path
            $pathFound = $true
            break
        }
    }
    
    if (-not $pathFound) {
        Write-Host "ERROR: .env file not found for service: $service" -ForegroundColor Red
        $failureCount++
        continue
    }
    
    Write-Host "Loading configuration from: $envFile" -ForegroundColor Cyan
    
    # Load environment variables from .env file
    $envLines = Get-Content $envFile
    $envVarsLoaded = @{}
    
    foreach ($line in $envLines) {
        if ($line.StartsWith('#') -or [string]::IsNullOrWhiteSpace($line)) {
            continue
        }
        
        $parts = $line.Split('=', 2)
        if ($parts.Count -eq 2) {
            $key = $parts[0].Trim()
            $value = $parts[1].Trim()
            
            [Environment]::SetEnvironmentVariable($key, $value, [System.EnvironmentVariableTarget]::Process)
            $envVarsLoaded[$key] = $value
        }
    }
    
    Write-Host "Environment variables loaded: $($envVarsLoaded.Count)" -ForegroundColor Green
    
    # Display loaded environment variables
    Write-Host "`nLoaded Environment Variables:" -ForegroundColor Cyan
    Write-Host "-----------------------------" -ForegroundColor Cyan
    foreach ($kvp in $envVarsLoaded.GetEnumerator()) {
        $key = $kvp.Key
        $value = $kvp.Value
        
        # Mask sensitive values
        if ($key -match 'PASSWORD|SECRET|TOKEN|KEY|CREDENTIAL') {
            $maskedValue = if ($value.Length -gt 4) { "*" * ($value.Length - 4) + $value.Substring($value.Length - 4) } else { "****" }
            Write-Host "  $key=$maskedValue" -ForegroundColor Yellow
        }
        else {
            Write-Host "  $key=$value" -ForegroundColor Yellow
        }
    }
    Write-Host "-----------------------------" -ForegroundColor Cyan
    
    # Get service name from environment
    $serviceName = $env:SERVICE_NAME
    if (-not $serviceName) {
        Write-Host "ERROR: SERVICE_NAME not set in $envFile" -ForegroundColor Red
        $failureCount++
        continue
    }
    
    Write-Host "`nService: $serviceName" -ForegroundColor Yellow
    Write-Host "----------------------------------------------------------------" -ForegroundColor Cyan
    
    # Call the actual step logic
    $global:Step3Result = $null
    $result = & .\scripts\jira-sync-step3-logic.ps1
    if ($result -ne 0) {
        Write-Host "Step 3 failed with exit code: $result" -ForegroundColor Red
        $failureCount++
        continue
    }
    Write-Host "Step 3 completed successfully" -ForegroundColor Green
    
    $successCount++
    Write-Host "`nService $service completed successfully" -ForegroundColor Green
}

# Summary
Write-Host "`n==============================================================" -ForegroundColor Cyan
Write-Host "                    SUMMARY                                    " -ForegroundColor Cyan
Write-Host "==============================================================" -ForegroundColor Cyan
Write-Host "Total Services: $totalServices" -ForegroundColor Gray
Write-Host "Successful: $successCount" -ForegroundColor Green
Write-Host "Failed: $failureCount" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })
Write-Host "==============================================================" -ForegroundColor Cyan

if ($failureCount -eq 0) {
    Write-Host "All Steps Completed Successfully!" -ForegroundColor Green
    $global:Step3Result = 0
    return 0
}
else {
    Write-Host "Some services failed" -ForegroundColor Red
    $global:Step3Result = 1
    return 1
}
