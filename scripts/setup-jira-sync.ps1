#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Setup script for Jira Sync - Configure environment and run sync operations
.DESCRIPTION
    Interactive setup for Jira sync scripts
.EXAMPLE
    ./setup-jira-sync.ps1
#>

$ErrorActionPreference = 'Continue'

# Colors
$Green = 'Green'
$Yellow = 'Yellow'
$Cyan = 'Cyan'
$Red = 'Red'

Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor $Cyan
Write-Host "║          Jira Sync Setup - Interactive Configuration            ║" -ForegroundColor $Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor $Cyan

# Initialize config
$config = @{}
$configFile = ".kiro/settings/jira-sync-config.json"
$envFile = ".env"

# Load from .env file
$loadedFromEnv = $false

if (Test-Path $envFile) {
    Write-Host "✓ Found .env file" -ForegroundColor $Green
    
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
            if ($key -eq 'JIRA_EMAIL') { $config.JiraEmail = $value }
            if ($key -eq 'JIRA_API_TOKEN') { $config.JiraToken = $value }
            if ($key -eq 'JIRA_PROJECT_KEY') { $config.JiraProjectKey = $value }
        }
    }
    
    if ($config.JiraBaseUrl -and $config.JiraEmail -and $config.JiraToken) {
        Write-Host "  Base URL: $($config.JiraBaseUrl)" -ForegroundColor $Yellow
        Write-Host "  Email: $($config.JiraEmail)" -ForegroundColor $Yellow
        Write-Host "  Project Key: $($config.JiraProjectKey)" -ForegroundColor $Yellow
        
        $useEnv = Read-Host "Use configuration from .env? (y/n)"
        if ($useEnv -eq 'y') {
            $loadedFromEnv = $true
        }
        else {
            $config = @{}
        }
    }
}

# Load from JSON config if not loaded from .env
$loadedFromJson = $false

if (-not $loadedFromEnv -and -not $config.JiraBaseUrl) {
    if (Test-Path $configFile) {
        Write-Host "✓ Found existing JSON configuration" -ForegroundColor $Green
        $config = Get-Content $configFile | ConvertFrom-Json
        Write-Host "  Base URL: $($config.JiraBaseUrl)" -ForegroundColor $Yellow
        Write-Host "  Email: $($config.JiraEmail)" -ForegroundColor $Yellow
        
        $useExisting = Read-Host "Use existing configuration? (y/n)"
        if ($useExisting -eq 'y') {
            $loadedFromJson = $true
        }
        else {
            $config = @{}
        }
    }
}

# Prompt for credentials if not loaded
if (-not $loadedFromEnv -and -not $loadedFromJson) {
    if (-not $config.JiraBaseUrl) {
        Write-Host "`n📋 Jira Configuration" -ForegroundColor $Cyan
        Write-Host "─────────────────────────────────────────────────────────────────" -ForegroundColor $Cyan
        
        $config.JiraBaseUrl = Read-Host "Jira Base URL"
        $config.JiraEmail = Read-Host "Jira Email"
        $config.JiraToken = Read-Host "Jira API Token"
        $config.JiraProjectKey = Read-Host "Jira Project Key"
    }
}

# Select Service
Write-Host "`n🔧 Service Selection" -ForegroundColor $Cyan
Write-Host "─────────────────────────────────────────────────────────────────" -ForegroundColor $Cyan

$services = @(
    @{ Name = "SecurityService"; Path = "Applications/AITooling/Services/SecurityService/.kiro/specs/security-service/project-task.md" },
    @{ Name = "DataLoaderService"; Path = "Applications/AITooling/Services/DataLoaderService/.kiro/specs/data-loader-service/project-task.md" },
    @{ Name = "FullViewSecurity"; Path = "Applications/FullView/Services/FullViewSecurity/.kiro/specs/fullview-security/project-task.md" },
    @{ Name = "INN8DataSource"; Path = "Applications/FullView/Services/INN8DataSource/.kiro/specs/inn8-data-source/project-task.md" }
)

Write-Host "Available services:" -ForegroundColor $Yellow
for ($i = 0; $i -lt $services.Count; $i++) {
    Write-Host "  $($i + 1). $($services[$i].Name)" -ForegroundColor $Yellow
}

$serviceChoice = Read-Host "Select service (1-$($services.Count))"
$serviceIndex = [int]$serviceChoice - 1

if ($serviceIndex -lt 0 -or $serviceIndex -ge $services.Count) {
    Write-Host "✗ Invalid selection" -ForegroundColor $Red
    exit 1
}

$selectedService = $services[$serviceIndex]
$config.ServiceName = $selectedService.Name
$config.TaskFile = $selectedService.Path

Write-Host "✓ Selected: $($config.ServiceName)" -ForegroundColor $Green
Write-Host "  Task file: $($config.TaskFile)" -ForegroundColor $Yellow

# Verify Task File
if (-not (Test-Path $config.TaskFile)) {
    Write-Host "`n✗ Task file not found: $($config.TaskFile)" -ForegroundColor $Red
    exit 1
}

Write-Host "✓ Task file found" -ForegroundColor $Green

# Save Configuration
$configDir = Split-Path $configFile
if (-not (Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
}

$config | ConvertTo-Json | Set-Content $configFile
Write-Host "`n✓ Configuration saved to: $configFile" -ForegroundColor $Green

$envContent = @"
# Jira Configuration
JIRA_BASE_URL=$($config.JiraBaseUrl)
JIRA_PROJECT_KEY=$($config.JiraProjectKey)

# Jira Authentication (API Token)
# Get your API token from: https://id.atlassian.com/manage-profile/security/api-tokens
JIRA_EMAIL=$($config.JiraEmail)
JIRA_API_TOKEN=$($config.JiraToken)
"@

Set-Content -Path ".env" -Value $envContent
Write-Host "✓ Configuration saved to: .env" -ForegroundColor $Green

# Set Environment Variables
Write-Host "`n🔐 Setting environment variables..." -ForegroundColor $Cyan
$env:JIRA_BASE_URL = $config.JiraBaseUrl
$env:JIRA_USER_EMAIL = $config.JiraEmail
$env:JIRA_API_TOKEN = $config.JiraToken
$env:SERVICE_NAME = $config.ServiceName
$env:TASK_FILE = $config.TaskFile

Write-Host "✓ Environment variables configured" -ForegroundColor $Green

# Select Operation
Write-Host "`n⚙️  Operation Selection" -ForegroundColor $Cyan
Write-Host "─────────────────────────────────────────────────────────────────" -ForegroundColor $Cyan

$operations = @(
    @{ Name = "Step 1: Pull Missing Tasks from Jira"; Script = "scripts/jira-sync-step1-pull-missing-tasks.ps1" },
    @{ Name = "Step 2: Push New Tasks to Jira"; Script = "scripts/jira-sync-step2-push-new-tasks.ps1" },
    @{ Name = "Step 3: Sync Jira Status to Markdown"; Script = "scripts/jira-sync-step3-sync-jira-status.ps1" },
    @{ Name = "Step 4: Sync Markdown Status to Jira"; Script = "scripts/jira-sync-step4-sync-markdown-status.ps1" },
    @{ Name = "Run All Steps (Orchestration)"; Script = "scripts/jira-sync-orchestration.ps1" }
)

Write-Host "Available operations:" -ForegroundColor $Yellow
for ($i = 0; $i -lt $operations.Count; $i++) {
    Write-Host "  $($i + 1). $($operations[$i].Name)" -ForegroundColor $Yellow
}

$opChoice = Read-Host "Select operation (1-$($operations.Count))"
$opIndex = [int]$opChoice - 1

if ($opIndex -lt 0 -or $opIndex -ge $operations.Count) {
    Write-Host "✗ Invalid selection" -ForegroundColor $Red
    exit 1
}

$selectedOp = $operations[$opIndex]

# Confirm and Execute
Write-Host "`n📋 Summary" -ForegroundColor $Cyan
Write-Host "─────────────────────────────────────────────────────────────────" -ForegroundColor $Cyan
Write-Host "Service:    $($config.ServiceName)" -ForegroundColor $Yellow
Write-Host "Task File:  $($config.TaskFile)" -ForegroundColor $Yellow
Write-Host "Operation:  $($selectedOp.Name)" -ForegroundColor $Yellow
Write-Host "Jira URL:   $($config.JiraBaseUrl)" -ForegroundColor $Yellow

$confirm = Read-Host "`nProceed? (y/n)"
if ($confirm -ne 'y') {
    Write-Host "✗ Cancelled" -ForegroundColor $Red
    exit 0
}

# Execute Script
Write-Host "`n▶️  Executing: $($selectedOp.Name)" -ForegroundColor $Green
Write-Host "─────────────────────────────────────────────────────────────────" -ForegroundColor $Cyan

if (-not (Test-Path $selectedOp.Script)) {
    Write-Host "✗ Script not found: $($selectedOp.Script)" -ForegroundColor $Red
    exit 1
}

& $selectedOp.Script

$exitCode = $LASTEXITCODE
Write-Host "`n" -ForegroundColor $Cyan

if ($exitCode -eq 0) {
    Write-Host "✓ Operation completed successfully" -ForegroundColor $Green
}
else {
    Write-Host "✗ Operation failed with exit code: $exitCode" -ForegroundColor $Red
}

exit $exitCode
