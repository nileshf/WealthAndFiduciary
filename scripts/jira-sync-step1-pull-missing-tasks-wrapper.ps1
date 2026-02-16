#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Wrapper for Step 1: Pull missing tasks from Jira to project-task.md
.DESCRIPTION
    Loads .env file, then runs the Jira sync step 1 script
.PARAMETER ServiceName
    Service name (e.g., SecurityService, DataLoaderService)
.PARAMETER EnvFile
    Path to .env file for the service
.EXAMPLE
    ./scripts/jira-sync-step1-pull-missing-tasks-wrapper.ps1 -ServiceName "SecurityService" -EnvFile "Applications/AITooling/Services/SecurityService/.env"
#>

param(
    [string]$ServiceName,
    [string]$EnvFile
)

$ErrorActionPreference = 'Stop'

# Validate parameters
if (-not $ServiceName) {
    Write-Host "ERROR: ServiceName is required" -ForegroundColor Red
    Write-Host "Usage: ./jira-sync-step1-pull-missing-tasks-wrapper.ps1 -ServiceName 'SecurityService' -EnvFile '.env'" -ForegroundColor Yellow
    exit 1
}

if (-not $EnvFile) {
    $EnvFile = ".env"
}

# Load .env file
Write-Host "Step 0: Loading environment variables" -ForegroundColor Cyan
if (-not (Test-Path $EnvFile)) {
    Write-Host "ERROR: .env file not found: $EnvFile" -ForegroundColor Red
    exit 1
}

$content = Get-Content $EnvFile -Raw
$lines = $content -split "`n"

foreach ($line in $lines) {
    if (-not $line -or $line.StartsWith("#")) {
        continue
    }
    
    if ($line -match "^([^=]+)=(.*)$") {
        $key = $matches[1].Trim()
        $value = $matches[2].Trim()
        
        # Remove quotes if present
        if ($value -match '^"(.*)"$') {
            $value = $matches[1]
        }
        elseif ($value -match "^'(.*)'$") {
            $value = $matches[1]
        }
        
        [Environment]::SetEnvironmentVariable($key, $value, "Process")
    }
}

Write-Host "✓ Environment variables loaded" -ForegroundColor Green

# Verify required variables
Write-Host "`nVerifying required environment variables..." -ForegroundColor Cyan
$required = @("JIRA_BASE_URL", "JIRA_USER_EMAIL", "JIRA_API_TOKEN", "JIRA_PROJECT_KEY")
$allPresent = $true

foreach ($var in $required) {
    $value = [Environment]::GetEnvironmentVariable($var, "Process")
    if ($value) {
        $shortValue = if ($value.Length -gt 40) { $value.Substring(0, 40) + "..." } else { $value }
        Write-Host "  ✓ $var = $shortValue" -ForegroundColor Green
    }
    else {
        Write-Host "  ✗ $var = (missing)" -ForegroundColor Red
        $allPresent = $false
    }
}

if (-not $allPresent) {
    Write-Host "`nERROR: Missing required environment variables" -ForegroundColor Red
    exit 1
}

# Run the actual Jira sync step 1 script
Write-Host "`nRunning Jira sync step 1..." -ForegroundColor Cyan
& ./scripts/jira-sync-step1-pull-missing-tasks.ps1 -ServiceName $ServiceName

exit $LASTEXITCODE
