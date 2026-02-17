# Pre-commit error handler for SecurityService
# Searches Confluence and local error database for build errors

param(
    [Parameter(Mandatory=$true)]
    [ValidatePattern('^CS\d{4}$')]
    [string]$ErrorCode,
    
    [Parameter(Mandatory=$false)]
    [string]$ServiceName = "SecurityService",
    
    [Parameter(Mandatory=$false)]
    [string]$FilePath = "Unknown",
    
    [Parameter(Mandatory=$false)]
    [string]$LineNumber = "Unknown"
)

# Configuration
$serviceRoot = "Applications/AITooling/Services/SecurityService"
$confluencePageUrl = "https://nileshf.atlassian.net/wiki/spaces/WEALTHFID/pages/9175041"
$localErrorDb = "$serviceRoot/.kiro/post-mortems/pre-commit-errors.md"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Build Error Handler - $ServiceName" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Search local DB first
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Searching Local Error Database" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$localErrorFound = $false
if (Test-Path $localErrorDb) {
    $content = Get-Content $localErrorDb -Raw
    if ($content -match "## $ErrorCode -") {
        $localErrorFound = $true
        Write-Host "Found in Local Error Database" -ForegroundColor Cyan
        Write-Host ""
        
        # Extract the error section
        $lines = $content -split "`r?`n"
        $inErrorSection = $false
        $errorLines = @()
        
        foreach ($line in $lines) {
            if ($line -match "^## $ErrorCode -") {
                $inErrorSection = $true
            }
            
            if ($inErrorSection) {
                $errorLines += $line
                
                if ($line -match "^## [A-Z]" -and $line -notmatch "^## $ErrorCode -") {
                    break
                }
            }
        }
        
        if ($errorLines.Count -gt 0) {
            Write-Host ($errorLines -join "`n") -ForegroundColor White
            Write-Host ""
        }
    }
}

# Search Confluence using MCP tool
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Confluence Search Results" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

try {
    $confluenceResult = mcp_mcp_atlassian_confluence_search -query "$ErrorCode Pre-Commit" -limit 5
    
    if ($confluenceResult) {
        Write-Host "Confluence Search Results for: $ErrorCode Pre-Commit" -ForegroundColor White
        Write-Host ""
        
        $results = $confluenceResult | ConvertFrom-Json
        if ($results.results) {
            foreach ($result in $results.results) {
                $title = $result.title
                $url = "https://nileshf.atlassian.net/wiki$page=$($result.id)"
                Write-Host "Title: $title" -ForegroundColor Cyan
                Write-Host "URL: $url" -ForegroundColor White
                Write-Host ""
            }
        } else {
            Write-Host "No results found on Confluence for: $ErrorCode Pre-Commit" -ForegroundColor Yellow
            Write-Host ""
        }
    }
} catch {
    Write-Host "Confluence Search: MCP tool not available" -ForegroundColor Yellow
    Write-Host "Please visit: $confluencePageUrl" -ForegroundColor White
    Write-Host ""
}

# Get Kiro's fix suggestion
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Kiro's Fix Suggestion" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

switch ($ErrorCode) {
    "CS0161" {
        Write-Host "Error: $ErrorCode - Not all code paths return a value" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Root Cause:" -ForegroundColor Green
        Write-Host "  A non-void method is missing a return statement for one or more code paths." -ForegroundColor White
        Write-Host ""
        Write-Host "Quick Fix:" -ForegroundColor Green
        Write-Host "  Add a return statement for all code paths." -ForegroundColor White
        Write-Host ""
        Write-Host "Code Example:" -ForegroundColor Green
        Write-Host ""
        Write-Host "  // BEFORE (broken):" -ForegroundColor Cyan
        Write-Host "  public string GetName()" -ForegroundColor White
        Write-Host "  {" -ForegroundColor White
        Write-Host "      if (condition)" -ForegroundColor White
        Write-Host "      {" -ForegroundColor White
        Write-Host "          return ""value"";" -ForegroundColor White
        Write-Host "      }" -ForegroundColor White
        Write-Host "      // Missing return for else case" -ForegroundColor Gray
        Write-Host "  }" -ForegroundColor White
        Write-Host ""
        Write-Host "  // AFTER (fixed):" -ForegroundColor Cyan
        Write-Host "  public string GetName()" -ForegroundColor White
        Write-Host "  {" -ForegroundColor White
        Write-Host "      if (condition)" -ForegroundColor White
        Write-Host "      {" -ForegroundColor White
        Write-Host "          return ""value"";" -ForegroundColor White
        Write-Host "      }" -ForegroundColor White
        Write-Host "      return ""default"";  // Add default return" -ForegroundColor Green
        Write-Host "  }" -ForegroundColor White
        Write-Host ""
        Write-Host "Prevention:" -ForegroundColor Green
        Write-Host "  Always ensure all code paths return a value." -ForegroundColor White
        Write-Host "  Use 'return default(Type);' for empty paths if appropriate." -ForegroundColor White
    }
    default {
        Write-Host "Error: $ErrorCode" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Kiro's Analysis:" -ForegroundColor Green
        Write-Host "  This is a build error that requires investigation." -ForegroundColor White
        Write-Host ""
        Write-Host "Suggested Steps:" -ForegroundColor Green
        Write-Host "  1. Check the full error message in the build output" -ForegroundColor White
        Write-Host "  2. Review the Confluence search results above" -ForegroundColor White
        Write-Host "  3. Check the local error database entry above" -ForegroundColor White
        Write-Host ""
    }
}

# Error location
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Error Location" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Service: $ServiceName" -ForegroundColor White
Write-Host "File: $FilePath" -ForegroundColor White
Write-Host "Line: $LineNumber" -ForegroundColor White
Write-Host ""

# Next steps
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Next Steps" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Review the error details above" -ForegroundColor White
Write-Host "2. Apply the suggested fix to your code" -ForegroundColor White
Write-Host "3. Run 'dotnet build' to verify the fix" -ForegroundColor White
Write-Host "4. Commit and push your changes" -ForegroundColor White
Write-Host ""

# If error not found in local database, add it
if (-not $localErrorFound) {
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "New Error Detected" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "This error is not yet documented in the local error database." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To add this error to the database, update:" -ForegroundColor Yellow
    Write-Host "  $localErrorDb" -ForegroundColor White
    Write-Host ""
    Write-Host "Include:" -ForegroundColor Yellow
    Write-Host "  - Error message" -ForegroundColor White
    Write-Host "  - Root cause" -ForegroundColor White
    Write-Host "  - Fix steps" -ForegroundColor White
    Write-Host "  - Code example (before/after)" -ForegroundColor White
    Write-Host "  - Date of occurrence" -ForegroundColor White
    Write-Host ""
}
