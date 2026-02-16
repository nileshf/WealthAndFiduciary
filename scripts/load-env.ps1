#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Load environment variables from .env file
.DESCRIPTION
    Reads .env file and sets environment variables for the current session
.PARAMETER EnvFile
    Path to .env file (default: .env in current directory)
.EXAMPLE
    . ./scripts/load-env.ps1
    . ./scripts/load-env.ps1 -EnvFile "Applications/AITooling/Services/SecurityService/.env"
#>

param(
    [string]$EnvFile = ".env"
)

if (-not (Test-Path $EnvFile)) {
    Write-Host "ERROR: .env file not found: $EnvFile" -ForegroundColor Red
    return $false
}

Write-Host "Loading environment from: $EnvFile" -ForegroundColor Cyan

$content = Get-Content $EnvFile -Raw
$lines = $content -split "`n"
$loadedCount = 0

foreach ($line in $lines) {
    # Skip empty lines and comments
    if (-not $line -or $line.StartsWith("#")) {
        continue
    }
    
    # Parse KEY=VALUE
    if ($line -match '^([^=]+)=(.*)$') {
        $key = $matches[1].Trim()
        $value = $matches[2].Trim()
        
        # Remove quotes if present
        if ($value -match '^"(.*)"\$') {
            $value = $matches[1]
        }
        elseif ($value -match "^'(.*)'`$") {
            $value = $matches[1]
        }
        
        # Set environment variable
        [Environment]::SetEnvironmentVariable($key, $value, "Process")
        $shortValue = if ($value.Length -gt 40) { $value.Substring(0, 40) + "..." } else { $value }
        Write-Host "  OK $key = $shortValue" -ForegroundColor Green
        $loadedCount++
    }
}

Write-Host "Loaded $loadedCount environment variable(s)" -ForegroundColor Green
return $true
