#!/usr/bin/env pwsh
#
# Pre-commit checks script for WealthAndFiduciary
# Runs CI/CD and code review checks before commit
#

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Running Pre-Commit Checks" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Track if any checks fail
$failed = $false

# Check Confluence configuration
Write-Host "Checking Confluence configuration..." -ForegroundColor Yellow
if ($env:CONFLUENCE_BASE_URL -and $env:CONFLUENCE_USER_EMAIL -and $env:CONFLUENCE_API_TOKEN -and $env:CONFLUENCE_SPACE_KEY) {
    Write-Host "  Confluence configured: Yes" -ForegroundColor Green
} else {
    Write-Host "  Confluence configured: No (optional)" -ForegroundColor Yellow
    Write-Host "  Set CONFLUENCE_BASE_URL, CONFLUENCE_USER_EMAIL, CONFLUENCE_API_TOKEN, CONFLUENCE_SPACE_KEY to enable" -ForegroundColor Gray
}
Write-Host ""

# Discover services
Write-Host "Discovering services..." -ForegroundColor Cyan
$services = @()

$aiToolingPath = "Applications/AITooling/Services"
if (Test-Path $aiToolingPath) {
    Get-ChildItem -Path $aiToolingPath -Directory | ForEach-Object {
        if (Test-Path "$($_.FullName)/$($_.Name).csproj") {
            $services += $_.FullName
            Write-Host "  Found: $($_.Name)" -ForegroundColor Green
        }
    }
}

$fullViewPath = "Applications/FullView/Services"
if (Test-Path $fullViewPath) {
    Get-ChildItem -Path $fullViewPath -Directory | ForEach-Object {
        if (Test-Path "$($_.FullName)/$($_.Name).csproj") {
            $services += $_.FullName
            Write-Host "  Found: $($_.Name)" -ForegroundColor Green
        }
    }
}

if ($services.Count -eq 0) {
    Write-Host "ERROR: No services found" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Services to check: $($services.Count)" -ForegroundColor Yellow
Write-Host ""

# Process each service
$totalServices = $services.Count
$serviceIndex = 0

foreach ($servicePath in $services) {
    $serviceIndex++
    $serviceName = Split-Path $servicePath -Leaf
    
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "[$serviceIndex/$totalServices] Service: $serviceName" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Load .env file
    $envFile = Join-Path $servicePath ".env"
    if (Test-Path $envFile) {
        Write-Host "Loading environment from: $envFile" -ForegroundColor Cyan
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
        Write-Host "Environment loaded" -ForegroundColor Green
    } else {
        Write-Host "No .env file found at: $envFile" -ForegroundColor Yellow
    }
    Write-Host ""
    
    # Change to service directory
    Set-Location $servicePath
    
    # Clear pre-commit error file at start of each service check (fresh start)
    $preCommitPath = Join-Path $servicePath ".kiro/pre-commit"
    $preCommitFilePath = Join-Path $preCommitPath "pre-commit-errors.md"
    
    # Ensure directory exists
    if (-not (Test-Path $preCommitPath)) {
        New-Item -ItemType Directory -Path $preCommitPath -Force | Out-Null
    }
    
    # Clear the file and create fresh header
    $fileHeader = @"
# Pre-Commit Errors Log
# Last Updated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
# Service: $serviceName

"@
    Set-Content -Path $preCommitFilePath -Value $fileHeader -Encoding UTF8
    Write-Host "Cleared previous errors from local file" -ForegroundColor Cyan
    Write-Host ""
    
    # 1. Linting - dotnet format
    Write-Host "[1/5] Running dotnet format (linting)..." -ForegroundColor Yellow
    try {
        # Find the .csproj file in the service directory
        $csprojFiles = Get-ChildItem -Path $servicePath -Filter "*.csproj" -Recurse | Select-Object -First 1
        
        if ($csprojFiles) {
            # Run dotnet format with the project file
            dotnet format $csprojFiles.FullName --verify-no-changes --no-restore 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "    Linting passed" -ForegroundColor Green
            } else {
                Write-Host "    Linting failed. Run 'dotnet format' to fix issues." -ForegroundColor Red
                $failed = $true
            }
        } else {
            Write-Host "    No .csproj file found, skipping" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "    dotnet format error: $_" -ForegroundColor Yellow
    }
    
    Write-Host ""
    
    # 2. Build
    Write-Host "[2/5] Running build..." -ForegroundColor Yellow
    try {
        $buildOutput = dotnet build --configuration Release 2>&1 | Out-String
        if ($LASTEXITCODE -eq 0) {
            Write-Host "    Build passed" -ForegroundColor Green
        } else {
            Write-Host "    Build failed" -ForegroundColor Red
            Write-Host ""
            Write-Host "Build Output:" -ForegroundColor Yellow
            Write-Host $buildOutput -ForegroundColor White
            Write-Host ""
            
            # Extract error codes and their full error messages from build output
            $errorMatches = [regex]::Matches($buildOutput, 'error (CS\d{4}): (.+?)(?=\n|$)')
            
            if ($errorMatches.Count -gt 0) {
                Write-Host "========================================" -ForegroundColor Cyan
                Write-Host "Processing build errors with Confluence..." -ForegroundColor Cyan
                Write-Host "========================================" -ForegroundColor Cyan
                Write-Host ""
                
                # Deduplicate errors (build output may contain same error multiple times)
                $uniqueErrors = @{}
                foreach ($match in $errorMatches) {
                    $errorCode = $match.Groups[1].Value
                    $errorMessage = $match.Groups[2].Value
                    $key = "$errorCode|$errorMessage"
                    
                    if (-not $uniqueErrors.ContainsKey($key)) {
                        $uniqueErrors[$key] = @{
                            Code = $errorCode
                            Message = $errorMessage
                        }
                    }
                }
                
                # Process unique errors only
                $errorIndex = 0
                foreach ($errorKey in $uniqueErrors.Keys) {
                    $errorIndex++
                    $error = $uniqueErrors[$errorKey]
                    $errorCode = $error.Code
                    $errorMessage = $error.Message
                    
                    Write-Host "[$errorIndex/$($uniqueErrors.Count)] Processing error: $errorCode" -ForegroundColor Yellow
                    Write-Host "Message: $errorMessage" -ForegroundColor Gray
                    Write-Host ""
                    
                    # Call the Confluence error handler
                    $scriptPath = Join-Path $PSScriptRoot "scripts/pre-commit-confluence-error.ps1"
                    if (Test-Path $scriptPath) {
                        # Call error handler with error code and message
                        & $scriptPath `
                            -ErrorCode $errorCode `
                            -ErrorMessage $errorMessage `
                            -SuggestedFix "See Kiro's suggestion below" `
                            -ServiceName $serviceName `
                            -PreCommitFolder ".kiro/pre-commit" `
                            -PreCommitFile "pre-commit-errors.md"
                        
                        Write-Host ""
                    } else {
                        Write-Host "ERROR: Confluence error handler not found at: $scriptPath" -ForegroundColor Red
                    }
                }
            } else {
                Write-Host "No error codes found in build output." -ForegroundColor Yellow
            }
            
            $failed = $true
        }
    } catch {
        Write-Host "    Build failed with error: $_" -ForegroundColor Red
        $failed = $true
    }
    
    Write-Host ""
    
    # 3. Unit Tests
    Write-Host "[3/5] Running unit tests..." -ForegroundColor Yellow
    try {
        dotnet test --no-build --configuration Release --filter "Category=Unit" --logger "trx;LogFileName=unit-tests.trx"
        if ($LASTEXITCODE -eq 0) {
            Write-Host "    Unit tests passed" -ForegroundColor Green
        } else {
            Write-Host "    Unit tests failed" -ForegroundColor Red
            $failed = $true
        }
    } catch {
        Write-Host "    No unit tests found, skipping" -ForegroundColor Yellow
    }
    
    Write-Host ""
    
    # 4. Integration Tests
    Write-Host "[4/5] Running integration tests..." -ForegroundColor Yellow
    try {
        dotnet test --no-build --configuration Release --filter "Category=Integration" --logger "trx;LogFileName=integration-tests.trx"
        if ($LASTEXITCODE -eq 0) {
            Write-Host "    Integration tests passed" -ForegroundColor Green
        } else {
            Write-Host "    Integration tests failed" -ForegroundColor Red
            $failed = $true
        }
    } catch {
        Write-Host "    No integration tests found, skipping" -ForegroundColor Yellow
    }
    
    Write-Host ""
    
    # 5. Code Coverage
    Write-Host "[5/5] Running code coverage analysis..." -ForegroundColor Yellow
    try {
        dotnet test --no-build --configuration Release `
            /p:CollectCoverage=true `
            /p:CoverletOutputFormat=opencover `
            /p:CoverletOutput=./coverage/
        
        Write-Host "    Code coverage analysis completed" -ForegroundColor Green
    } catch {
        Write-Host "    Code coverage analysis skipped" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "Service $serviceName completed" -ForegroundColor Cyan
    Write-Host ""
    
    # Return to root
    Set-Location $PSScriptRoot
}

# Summary
Write-Host "========================================" -ForegroundColor Cyan
if ($failed) {
    Write-Host "Pre-commit checks FAILED" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please fix the issues above and try again." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To skip pre-commit checks (not recommended):" -ForegroundColor Yellow
    Write-Host "  git commit --no-verify" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "All pre-commit checks PASSED" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can proceed with your commit." -ForegroundColor Green
    exit 0
}