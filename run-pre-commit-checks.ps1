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

# Services to check
$services = @(
    @{ Name = "DataLoaderService"; Path = "Applications/AITooling/Services/DataLoaderService/DataLoaderService.csproj" },
    @{ Name = "SecurityService"; Path = "Applications/AITooling/Services/SecurityService/SecurityService.csproj" }
)

# 1. Linting - dotnet format
Write-Host "[1/5] Running dotnet format (linting)..." -ForegroundColor Yellow
$lintFailed = $false
foreach ($service in $services) {
    Write-Host "  Checking $($service.Name)..." -ForegroundColor Yellow
    try {
        # Get relative path from workspace root
        $relativePath = $service.Path.Replace("$PSScriptRoot\", "")
        # Run from workspace root - project path first, then options
        dotnet format $relativePath --verify-no-changes --no-restore
        if ($LASTEXITCODE -eq 0) {
            Write-Host "    $($service.Name) linting passed" -ForegroundColor Green
        } else {
            Write-Host "    $($service.Name) linting failed. Run 'dotnet format' to fix issues." -ForegroundColor Red
            $lintFailed = $true
            $failed = $true
        }
    } catch {
        Write-Host "    dotnet format not available, skipping" -ForegroundColor Yellow
    }
}

if (-not $lintFailed) {
    Write-Host "    Linting passed" -ForegroundColor Green
}

Write-Host ""

# 2. Build
Write-Host "[2/5] Running build..." -ForegroundColor Yellow
$buildFailed = $false
foreach ($service in $services) {
    Write-Host "  Building $($service.Name)..." -ForegroundColor Yellow
    try {
        $buildOutput = dotnet build --no-restore --configuration Release $service.Path 2>&1 | Out-String
        if ($LASTEXITCODE -eq 0) {
            Write-Host "    $($service.Name) build passed" -ForegroundColor Green
            
            # Clear pre-commit-errors.md for successful build
            $errorLogPath = Join-Path (Split-Path $service.Path -Parent) ".kiro/pre-commit/pre-commit-errors.md"
            if (Test-Path $errorLogPath) {
                Clear-Content $errorLogPath
                Add-Content $errorLogPath "# Pre-Commit Errors Log`n# Last Updated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n# Service: $($service.Name)`n# Status: BUILD PASSED`n"
            }
        } else {
            Write-Host "    $($service.Name) build failed" -ForegroundColor Red
            Write-Host ""
            Write-Host "Build Output:" -ForegroundColor Yellow
            Write-Host $buildOutput -ForegroundColor White
            Write-Host ""
            
            # Extract error codes from build output
            $errorCodes = @()
            if ($buildOutput -match 'CS\d{4}') {
                $errorCodes = [regex]::Matches($buildOutput, 'CS\d{4}') | ForEach-Object { $_.Value } | Select-Object -Unique
            }
            
            if ($errorCodes.Count -gt 0) {
                Write-Host "========================================" -ForegroundColor Cyan
                Write-Host "Searching Confluence for build errors..." -ForegroundColor Cyan
                Write-Host "========================================" -ForegroundColor Cyan
                Write-Host ""
                
                # Clear and initialize error log for this service
                $errorLogPath = Join-Path (Split-Path $service.Path -Parent) ".kiro/pre-commit/pre-commit-errors.md"
                $errorLogDir = Split-Path $errorLogPath -Parent
                if (-not (Test-Path $errorLogDir)) {
                    New-Item -ItemType Directory -Path $errorLogDir | Out-Null
                }
                
                # Initialize error log with header
                "# Pre-Commit Errors Log" | Out-File -FilePath $errorLogPath -Encoding utf8
                "# Last Updated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File -FilePath $errorLogPath -Append -Encoding utf8
                "# Service: $($service.Name)" | Out-File -FilePath $errorLogPath -Append -Encoding utf8
                "" | Out-File -FilePath $errorLogPath -Append -Encoding utf8
                
                foreach ($errorCode in $errorCodes) {
                    Write-Host "Searching for error: $errorCode" -ForegroundColor Yellow
                    Write-Host ""
                    
                    # Call the Confluence search script
                    $scriptPath = Join-Path $PSScriptRoot ".kiro/scripts/search-confluence-error.ps1"
                    if (Test-Path $scriptPath) {
                        & $scriptPath -ErrorCode $errorCode -ErrorLogPath $errorLogPath
                        Write-Host ""
                    } else {
                        Write-Host "Confluence search script not found at: $scriptPath" -ForegroundColor Yellow
                        "# Error: $errorCode - No Confluence search script found" | Out-File -FilePath $errorLogPath -Append -Encoding utf8
                    }
                }
                
                "" | Out-File -FilePath $errorLogPath -Append -Encoding utf8
                "---" | Out-File -FilePath $errorLogPath -Append -Encoding utf8
                "" | Out-File -FilePath $errorLogPath -Append -Encoding utf8
            } else {
                Write-Host "No error codes found in build output." -ForegroundColor Yellow
            }
            
            $buildFailed = $true
            $failed = $true
        }
    } catch {
        Write-Host "    $($service.Name) build failed with error: $_" -ForegroundColor Red
        $buildFailed = $true
        $failed = $true
    }
}

if (-not $buildFailed) {
    Write-Host "    Build passed" -ForegroundColor Green
}

Write-Host ""

# 3. Unit Tests
Write-Host "[3/5] Running unit tests..." -ForegroundColor Yellow
foreach ($service in $services) {
    Write-Host "  Running unit tests for $($service.Name)..." -ForegroundColor Yellow
    try {
        dotnet test --no-build --configuration Release --filter "Category=Unit" --logger "trx;LogFileName=unit-tests.trx" $service.Path
        if ($LASTEXITCODE -eq 0) {
            Write-Host "    $($service.Name) unit tests passed" -ForegroundColor Green
        } else {
            Write-Host "    $($service.Name) unit tests failed" -ForegroundColor Red
            $failed = $true
        }
    } catch {
        Write-Host "    No unit tests found for $($service.Name), skipping" -ForegroundColor Yellow
    }
}

Write-Host ""

# 4. Integration Tests
Write-Host "[4/5] Running integration tests..." -ForegroundColor Yellow
foreach ($service in $services) {
    Write-Host "  Running integration tests for $($service.Name)..." -ForegroundColor Yellow
    try {
        dotnet test --no-build --configuration Release --filter "Category=Integration" --logger "trx;LogFileName=integration-tests.trx" $service.Path
        if ($LASTEXITCODE -eq 0) {
            Write-Host "    $($service.Name) integration tests passed" -ForegroundColor Green
        } else {
            Write-Host "    $($service.Name) integration tests failed" -ForegroundColor Red
            $failed = $true
        }
    } catch {
        Write-Host "    No integration tests found for $($service.Name), skipping" -ForegroundColor Yellow
    }
}

Write-Host ""

# 5. Code Coverage
Write-Host "[5/5] Running code coverage analysis..." -ForegroundColor Yellow
foreach ($service in $services) {
    Write-Host "  Running code coverage for $($service.Name)..." -ForegroundColor Yellow
    try {
        dotnet test --no-build --configuration Release `
            /p:CollectCoverage=true `
            /p:CoverletOutputFormat=opencover `
            /p:CoverletOutput=./coverage/ `
            $service.Path
        
        Write-Host "    $($service.Name) code coverage analysis completed" -ForegroundColor Green
    } catch {
        Write-Host "    Code coverage analysis skipped for $($service.Name)" -ForegroundColor Yellow
    }
}

Write-Host ""

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
