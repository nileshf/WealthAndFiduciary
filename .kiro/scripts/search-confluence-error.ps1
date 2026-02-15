# Search Confluence for pre-commit build errors
# Usage: .\search-confluence-error.ps1 -ErrorCode CS0161

param(
    [Parameter(Mandatory=$true)]
    [ValidatePattern('^CS\d+$')]
    [string]$ErrorCode
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Searching Confluence for error: $ErrorCode" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Search Confluence
$confluenceUrl = "https://nileshf.atlassian.net/wiki/spaces/WEALTHFID/pages/9175041"
$searchQuery = "$ErrorCode Pre-Commit"

Write-Host "Confluence Page: $confluenceUrl" -ForegroundColor Green
Write-Host "Search Pattern: $searchQuery" -ForegroundColor Green
Write-Host ""

# Use MCP Confluence tools to fetch page content
try {
    # Get the page content using MCP
    $page = mcp_mcp_atlassian_confluence_get_page -page_id "9175041" -convert_to_markdown $true
    
    if ($page -and $page.content) {
        $content = $page.content.value
        
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "Confluence Page Content" -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        
        # Search for the error section in the markdown content
        $errorSection = $null
        
        # Split content by error sections
        $sections = $content -split "(?=\n$ErrorCode - )"
        
        foreach ($section in $sections) {
            if ($section -match "^$ErrorCode - ") {
                $errorSection = $section
                break
            }
        }
        
        if ($errorSection) {
            Write-Host "Found matching error in Confluence:" -ForegroundColor Green
            Write-Host ""
            Write-Host $errorSection -ForegroundColor White
            Write-Host ""
        } else {
            Write-Host "No matching error found in Confluence page." -ForegroundColor Yellow
            Write-Host "Please check the Confluence page manually: $confluenceUrl" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Failed to fetch Confluence page content." -ForegroundColor Red
        Write-Host "Please check the Confluence page manually: $confluenceUrl" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error fetching Confluence page: $_" -ForegroundColor Red
    Write-Host "Please check the Confluence page manually: $confluenceUrl" -ForegroundColor Yellow
}

# Check local error database
$localErrorDb = ".kiro/post-mortems/confluence-pre-commit-errors.md"
if (Test-Path $localErrorDb) {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Local Error Database Entry" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    $content = Get-Content $localErrorDb -Raw
    
    # Search for the error pattern in the local database
    $pattern = "(## $ErrorCode - [^\n]+\n\n\*\*Error Message\*\*: [^\n]+\n\n\*\*Root Cause\*\*: [^\n]+\n\n\*\*Quick Fix\*\*: [^\n]+\n\n\*\*Code Example\*\*:.*?)(?=## |\Z)"
    
    if ($content -match $pattern) {
        Write-Host "Found matching error in local database:" -ForegroundColor Green
        Write-Host ""
        Write-Host ($matches[0]) -ForegroundColor White
        Write-Host ""
    } else {
        Write-Host "No matching error found in local database." -ForegroundColor Yellow
    }
}

# Kiro's Fix Section
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Kiro's Fix" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

switch ($ErrorCode) {
    "CS0161" {
        Write-Host "Error: $ErrorCode - Not all code paths return a value" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Kiro's Analysis:" -ForegroundColor Green
        Write-Host "  This error occurs when a non-void method is missing a return statement" -ForegroundColor White
        Write-Host "  for one or more code paths (e.g., an if statement without an else return)." -ForegroundColor White
        Write-Host ""
        Write-Host "Kiro's Suggested Fix:" -ForegroundColor Green
        Write-Host "  1. Identify all code paths in the method" -ForegroundColor White
        Write-Host "  2. Ensure each path returns a value of the correct type" -ForegroundColor White
        Write-Host "  3. Use 'return default(Type);' for empty paths if appropriate" -ForegroundColor White
        Write-Host ""
        Write-Host "Quick Fix Pattern:" -ForegroundColor Green
        Write-Host "  // BEFORE (broken):" -ForegroundColor White
        Write-Host "  public string GetName()" -ForegroundColor White
        Write-Host "  {" -ForegroundColor White
        Write-Host "      if (condition)" -ForegroundColor White
        Write-Host "      {" -ForegroundColor White
        Write-Host "          return ""value"";" -ForegroundColor White
        Write-Host "      }" -ForegroundColor White
        Write-Host "      // Missing return for else case" -ForegroundColor White
        Write-Host "  }" -ForegroundColor White
        Write-Host ""
        Write-Host "  // AFTER (fixed):" -ForegroundColor White
        Write-Host "  public string GetName()" -ForegroundColor White
        Write-Host "  {" -ForegroundColor White
        Write-Host "      if (condition)" -ForegroundColor White
        Write-Host "      {" -ForegroundColor White
        Write-Host "          return ""value"";" -ForegroundColor White
        Write-Host "      }" -ForegroundColor White
        Write-Host "      return ""default"";  // Add default return" -ForegroundColor White
        Write-Host "  }" -ForegroundColor White
    }
    "CS1061" {
        Write-Host "Error: $ErrorCode - Type does not contain a definition" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Kiro's Analysis:" -ForegroundColor Green
        Write-Host "  This error occurs when trying to access a property or method that" -ForegroundColor White
        Write-Host "  doesn't exist on a type (often due to a typo)." -ForegroundColor White
        Write-Host ""
        Write-Host "Kiro's Suggested Fix:" -ForegroundColor Green
        Write-Host "  1. Check the type definition for the correct member name" -ForegroundColor White
        Write-Host "  2. Use IDE autocomplete to avoid typos" -ForegroundColor White
        Write-Host "  3. Enable nullable reference types for better IDE support" -ForegroundColor White
        Write-Host ""
        Write-Host "Quick Fix Pattern:" -ForegroundColor Green
        Write-Host "  // BEFORE (broken):" -ForegroundColor White
        Write-Host "  var user = new User();" -ForegroundColor White
        Write-Host "  var name = user.Nmae;  // Typo: should be Name" -ForegroundColor White
        Write-Host ""
        Write-Host "  // AFTER (fixed):" -ForegroundColor White
        Write-Host "  var user = new User();" -ForegroundColor White
        Write-Host "  var name = user.Name;  // Fixed typo" -ForegroundColor White
    }
    "CS0246" {
        Write-Host "Error: $ErrorCode - Type or namespace not found" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Kiro's Analysis:" -ForegroundColor Green
        Write-Host "  This error occurs when a using directive or assembly reference is missing." -ForegroundColor White
        Write-Host ""
        Write-Host "Kiro's Suggested Fix:" -ForegroundColor Green
        Write-Host "  1. Add the missing using directive at the top of the file" -ForegroundColor White
        Write-Host "  2. Run 'dotnet restore' to ensure packages are installed" -ForegroundColor White
        Write-Host "  3. Use IDE suggestions to add missing usings" -ForegroundColor White
        Write-Host ""
        Write-Host "Quick Fix Pattern:" -ForegroundColor Green
        Write-Host "  // BEFORE (broken):" -ForegroundColor White
        Write-Host "  public class MyClass" -ForegroundColor White
        Write-Host "  {" -ForegroundColor White
        Write-Host "      private ILogger _logger;  // Missing using directive" -ForegroundColor White
        Write-Host "  }" -ForegroundColor White
        Write-Host ""
        Write-Host "  // AFTER (fixed):" -ForegroundColor White
        Write-Host "  using Microsoft.Extensions.Logging;" -ForegroundColor White
        Write-Host "  public class MyClass" -ForegroundColor White
        Write-Host "  {" -ForegroundColor White
        Write-Host "      private ILogger _logger;" -ForegroundColor White
        Write-Host "  }" -ForegroundColor White
    }
    "CS0103" {
        Write-Host "Error: $ErrorCode - Name does not exist in current context" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Kiro's Analysis:" -ForegroundColor Green
        Write-Host "  This error occurs when using a variable, method, or class that hasn't been defined." -ForegroundColor White
        Write-Host ""
        Write-Host "Kiro's Suggested Fix:" -ForegroundColor Green
        Write-Host "  1. Define the identifier or check for typos" -ForegroundColor White
        Write-Host "  2. Ensure the method/class is in the correct scope" -ForegroundColor White
        Write-Host "  3. Use IDE autocomplete to avoid typos" -ForegroundColor White
        Write-Host ""
        Write-Host "Quick Fix Pattern:" -ForegroundColor Green
        Write-Host "  // BEFORE (broken):" -ForegroundColor White
        Write-Host "  public void MyMethod()" -ForegroundColor White
        Write-Host "  {" -ForegroundColor White
        Write-Host "      var result = CalculateSum(1, 2);  // CalculateSum doesn't exist" -ForegroundColor White
        Write-Host "  }" -ForegroundColor White
        Write-Host ""
        Write-Host "  // AFTER (fixed):" -ForegroundColor White
        Write-Host "  public void MyMethod()" -ForegroundColor White
        Write-Host "  {" -ForegroundColor White
        Write-Host "      var result = Add(1, 2);  // Fixed method name" -ForegroundColor White
        Write-Host "  }" -ForegroundColor White
        Write-Host ""
        Write-Host "  private int Add(int a, int b)" -ForegroundColor White
        Write-Host "  {" -ForegroundColor White
        Write-Host "      return a + b;" -ForegroundColor White
        Write-Host "  }" -ForegroundColor White
    }
    default {
        Write-Host "Error: $ErrorCode" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Kiro's Analysis:" -ForegroundColor Green
        Write-Host "  This is a build error that requires investigation." -ForegroundColor White
        Write-Host ""
        Write-Host "Kiro's Suggested Fix:" -ForegroundColor Green
        Write-Host "  1. Check the full error message in the build output" -ForegroundColor White
        Write-Host "  2. Search Confluence for the error code" -ForegroundColor White
        Write-Host "  3. Check the local error database for similar issues" -ForegroundColor White
        Write-Host "  4. Run 'dotnet build' with verbose output for more details" -ForegroundColor White
    }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Next Steps" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Review the error details above" -ForegroundColor White
Write-Host "2. Apply the suggested fix to your code" -ForegroundColor White
Write-Host "3. Run 'dotnet build' to verify the fix" -ForegroundColor White
Write-Host "4. Commit and push your changes" -ForegroundColor White
Write-Host ""
Write-Host "You can skip these checks with: git commit --no-verify" -ForegroundColor Red
Write-Host ""
