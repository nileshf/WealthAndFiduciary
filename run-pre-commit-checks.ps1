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

# 1. Linting - dotnet format
Write-Host "[1/5] Running dotnet format (linting)..." -ForegroundColor Yellow
try {
    dotnet format --verify --no-restore
    if ($LASTEXITCODE -eq 0) {
        Write-Host "    Linting passed" -ForegroundColor Green
    } else {
        Write-Host "    Linting failed. Run 'dotnet format' to fix issues." -ForegroundColor Red
        $failed = $true
    }
} catch {
    Write-Host "    dotnet format not available, skipping" -ForegroundColor Yellow
}

Write-Host ""

# 2. Build
Write-Host "[2/5] Running build..." -ForegroundColor Yellow
try {
    $buildOutput = dotnet build --no-restore --configuration Release 2>&1 | Out-String
    if ($LASTEXITCODE -eq 0) {
        Write-Host "    Build passed" -ForegroundColor Green
    } else {
        Write-Host "    Build failed" -ForegroundColor Red
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
            
            foreach ($errorCode in $errorCodes) {
                Write-Host "Searching for error: $errorCode" -ForegroundColor Yellow
                Write-Host ""
                
                # Call the Confluence search script
                $scriptPath = Join-Path $PSScriptRoot ".kiro/scripts/search-confluence-error.ps1"
                if (Test-Path $scriptPath) {
                    & $scriptPath -ErrorCode $errorCode
                    Write-Host ""
                } else {
                    Write-Host "Confluence search script not found at: $scriptPath" -ForegroundColor Yellow
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
