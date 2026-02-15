#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Run Step 3 Jira sync with environment variables loaded from .env
.DESCRIPTION
    Loads configuration from .env file and runs the Step 3 sync script
#>

param(
    [string]$EnvFile = "Applications/AITooling/Services/SecurityService/.env"
)

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
}
else {
    Write-Host "ERROR: .env file not found: $EnvFile" -ForegroundColor Red
    exit 1
}

# Run Step 3 script
Write-Host "`nRunning Step 3 Jira sync..." -ForegroundColor Cyan
& .\scripts\jira-sync-step3-sync-jira-status.ps1

exit $LASTEXITCODE
