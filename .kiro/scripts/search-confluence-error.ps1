# Search Confluence for pre-commit build errors
# Usage: .\search-confluence-error.ps1 -ErrorCode CS0161
# Note: This script provides local error database lookups and Kiro suggestions
# For Confluence integration, use Kiro's MCP tools directly

param(
    [Parameter(Mandatory=$true)]
    [ValidatePattern('^CS\d{4}$')]
    [string]$ErrorCode
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Searching for error: $ErrorCode" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check local error database
$localErrorDb = ".kiro/post-mortems/confluence-pre-commit-errors.md"
if (Test-Path $localErrorDb) {
    Write-Host "Checking local error database..." -ForegroundColor Yellow
    Write-Host ""
    
    $content = Get-Content $localErrorDb -Raw
    
    # Search for the error pattern in the local database
    if ($content -match "## Updated: .* - $ErrorCode") {
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "Found in Local Error Database" -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        
        # Extract the error section
        $pattern = "(## Updated: .*? - $ErrorCode.*?)(?=## Updated:|## How to Use|\Z)"
        if ($content -match $pattern) {
            Write-Host ($matches[1]) -ForegroundColor White
            Write-Host ""
        }
    }
}

# Kiro's Built-in Fix Suggestions
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
    "CS1061" {
        Write-Host "Error: $ErrorCode - Type does not contain a definition" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Root Cause:" -ForegroundColor Green
        Write-Host "  Trying to access a property or method that doesn't exist on a type." -ForegroundColor White
        Write-Host ""
        Write-Host "Quick Fix:" -ForegroundColor Green
        Write-Host "  Check the type definition and use the correct member name." -ForegroundColor White
        Write-Host ""
        Write-Host "Code Example:" -ForegroundColor Green
        Write-Host ""
        Write-Host "  // BEFORE (broken):" -ForegroundColor Cyan
        Write-Host "  var user = new User();" -ForegroundColor White
        Write-Host "  var name = user.Nmae;  // Typo: should be Name" -ForegroundColor White
        Write-Host ""
        Write-Host "  // AFTER (fixed):" -ForegroundColor Cyan
        Write-Host "  var user = new User();" -ForegroundColor White
        Write-Host "  var name = user.Name;  // Fixed typo" -ForegroundColor Green
        Write-Host ""
        Write-Host "Prevention:" -ForegroundColor Green
        Write-Host "  Use IDE autocomplete to avoid typos." -ForegroundColor White
        Write-Host "  Enable nullable reference types for better IDE support." -ForegroundColor White
    }
    "CS0246" {
        Write-Host "Error: $ErrorCode - Type or namespace not found" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Root Cause:" -ForegroundColor Green
        Write-Host "  Missing using directive or assembly reference." -ForegroundColor White
        Write-Host ""
        Write-Host "Quick Fix:" -ForegroundColor Green
        Write-Host "  Add the missing using directive at the top of the file." -ForegroundColor White
        Write-Host ""
        Write-Host "Code Example:" -ForegroundColor Green
        Write-Host ""
        Write-Host "  // BEFORE (broken):" -ForegroundColor Cyan
        Write-Host "  public class MyClass" -ForegroundColor White
        Write-Host "  {" -ForegroundColor White
        Write-Host "      private ILogger _logger;  // Missing using directive" -ForegroundColor White
        Write-Host "  }" -ForegroundColor White
        Write-Host ""
        Write-Host "  // AFTER (fixed):" -ForegroundColor Cyan
        Write-Host "  using Microsoft.Extensions.Logging;" -ForegroundColor Green
        Write-Host "  public class MyClass" -ForegroundColor White
        Write-Host "  {" -ForegroundColor White
        Write-Host "      private ILogger _logger;" -ForegroundColor White
        Write-Host "  }" -ForegroundColor White
        Write-Host ""
        Write-Host "Prevention:" -ForegroundColor Green
        Write-Host "  Run 'dotnet restore' before building." -ForegroundColor White
        Write-Host "  Use IDE suggestions to add missing usings." -ForegroundColor White
    }
    "CS0103" {
        Write-Host "Error: $ErrorCode - Name does not exist in current context" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Root Cause:" -ForegroundColor Green
        Write-Host "  Using a variable, method, or class that hasn't been defined." -ForegroundColor White
        Write-Host ""
        Write-Host "Quick Fix:" -ForegroundColor Green
        Write-Host "  Define the identifier or check for typos." -ForegroundColor White
        Write-Host ""
        Write-Host "Code Example:" -ForegroundColor Green
        Write-Host ""
        Write-Host "  // BEFORE (broken):" -ForegroundColor Cyan
        Write-Host "  public void MyMethod()" -ForegroundColor White
        Write-Host "  {" -ForegroundColor White
        Write-Host "      var result = CalculateSum(1, 2);  // CalculateSum doesn't exist" -ForegroundColor White
        Write-Host "  }" -ForegroundColor White
        Write-Host ""
        Write-Host "  // AFTER (fixed):" -ForegroundColor Cyan
        Write-Host "  public void MyMethod()" -ForegroundColor White
        Write-Host "  {" -ForegroundColor White
        Write-Host "      var result = Add(1, 2);  // Fixed method name" -ForegroundColor Green
        Write-Host "  }" -ForegroundColor White
        Write-Host ""
        Write-Host "  private int Add(int a, int b)" -ForegroundColor White
        Write-Host "  {" -ForegroundColor White
        Write-Host "      return a + b;" -ForegroundColor White
        Write-Host "  }" -ForegroundColor White
        Write-Host ""
        Write-Host "Prevention:" -ForegroundColor Green
        Write-Host "  Use IDE autocomplete to avoid typos." -ForegroundColor White
        Write-Host "  Run 'dotnet build' before committing." -ForegroundColor White
    }
    default {
        Write-Host "Error: $ErrorCode" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Kiro's Analysis:" -ForegroundColor Green
        Write-Host "  This is a build error that requires investigation." -ForegroundColor White
        Write-Host ""
        Write-Host "Suggested Steps:" -ForegroundColor Green
        Write-Host "  1. Check the full error message in the build output" -ForegroundColor White
        Write-Host "  2. Search Confluence for the error code" -ForegroundColor White
        Write-Host "  3. Check the local error database (.kiro/post-mortems/confluence-pre-commit-errors.md)" -ForegroundColor White
        Write-Host "  4. Run 'dotnet build' with verbose output for more details" -ForegroundColor White
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Next Steps" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Review the error details above" -ForegroundColor White
Write-Host "2. Apply the suggested fix to your code" -ForegroundColor White
Write-Host "3. Run 'dotnet build' to verify the fix" -ForegroundColor White
Write-Host "4. Commit and push your changes" -ForegroundColor White
Write-Host ""
Write-Host "For Confluence integration:" -ForegroundColor Cyan
Write-Host "  Use Kiro's MCP tools to search Confluence directly" -ForegroundColor White
Write-Host "  URL: https://nileshf.atlassian.net/wiki/spaces/WEALTHFID/pages/9175041" -ForegroundColor White
Write-Host ""
