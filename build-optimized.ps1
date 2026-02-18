# Build Optimization Script for Demo Purposes
# This script runs the optimized build pipeline with parallel compilation and testing
# Expected execution time: 5-8 minutes (vs 15-20 minutes without optimizations)

param(
    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Debug",
    
    [switch]$SkipTests,
    
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"
$startTime = Get-Date

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Build Optimization Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Configuration: $Configuration" -ForegroundColor Yellow
Write-Host "Skip Tests: $SkipTests" -ForegroundColor Yellow
Write-Host "Start Time: $startTime" -ForegroundColor Yellow
Write-Host ""

try {
    # Step 1: Restore NuGet packages (uses cache configured in nuget.config)
    Write-Host "Step 1: Restoring NuGet packages..." -ForegroundColor Green
    Write-Host "  (Using cached packages from .nuget folder)" -ForegroundColor Gray
    dotnet restore
    if ($LASTEXITCODE -ne 0) {
        throw "NuGet restore failed"
    }
    Write-Host "  ✓ Restore completed" -ForegroundColor Green
    Write-Host ""

    # Step 2: Build with parallel compilation (-m flag)
    Write-Host "Step 2: Building solution (parallel compilation enabled)..." -ForegroundColor Green
    Write-Host "  (Using -m flag for multi-threaded compilation)" -ForegroundColor Gray
    dotnet build -m --configuration $Configuration --no-restore
    if ($LASTEXITCODE -ne 0) {
        throw "Build failed"
    }
    Write-Host "  ✓ Build completed" -ForegroundColor Green
    Write-Host ""

    # Step 3: Run tests in parallel (if not skipped)
    if (-not $SkipTests) {
        Write-Host "Step 3: Running tests (parallel execution enabled)..." -ForegroundColor Green
        Write-Host "  (Using --parallel flag for concurrent test execution)" -ForegroundColor Gray
        Write-Host "  (Property tests reduced to 50 iterations for demo speed)" -ForegroundColor Gray
        dotnet test --configuration $Configuration --no-build --parallel --logger "console;verbosity=minimal"
        if ($LASTEXITCODE -ne 0) {
            throw "Tests failed"
        }
        Write-Host "  ✓ Tests completed" -ForegroundColor Green
        Write-Host ""
    }
    else {
        Write-Host "Step 3: Skipping tests (--SkipTests flag provided)" -ForegroundColor Yellow
        Write-Host ""
    }

    # Summary
    $endTime = Get-Date
    $duration = $endTime - $startTime
    
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Build Completed Successfully!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Total Duration: $($duration.Minutes)m $($duration.Seconds)s" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Optimizations Applied:" -ForegroundColor Cyan
    Write-Host "  ✓ Parallel NuGet restore (cached packages)" -ForegroundColor Green
    Write-Host "  ✓ Parallel compilation (-m flag)" -ForegroundColor Green
    Write-Host "  ✓ In-memory database for tests" -ForegroundColor Green
    Write-Host "  ✓ Reduced property test iterations (100 → 50)" -ForegroundColor Green
    Write-Host "  ✓ Parallel test execution" -ForegroundColor Green
    Write-Host ""
    Write-Host "Expected Improvements:" -ForegroundColor Cyan
    Write-Host "  • 20-30% faster builds (parallel compilation)" -ForegroundColor Gray
    Write-Host "  • 60-70% faster tests (in-memory database)" -ForegroundColor Gray
    Write-Host "  • 40-50% faster test runs (parallel execution)" -ForegroundColor Gray
    Write-Host "  • Combined: ~5-8 minute total execution time" -ForegroundColor Gray
    Write-Host ""
}
catch {
    $endTime = Get-Date
    $duration = $endTime - $startTime
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "Build Failed!" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host "Duration: $($duration.Minutes)m $($duration.Seconds)s" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}
