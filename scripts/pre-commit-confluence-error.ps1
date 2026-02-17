#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Handle pre-commit errors with Confluence integration
.DESCRIPTION
    1. Searches Confluence Pre-Commit Errors page for the error code
    2. Gets Kiro's suggested fix (hardcoded or generic)
    3. Clears local pre-commit file
    4. Appends error with Confluence info + Kiro suggestion to local file
    5. Appends error with Confluence info + Kiro suggestion to Confluence
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ErrorCode,
    
    [Parameter(Mandatory=$true)]
    [string]$ErrorMessage,
    
    [Parameter(Mandatory=$true)]
    [string]$SuggestedFix,
    
    [string]$ServiceName = $env:SERVICE_NAME,
    
    [string]$ConfluenceBaseUrl = $env:CONFLUENCE_BASE_URL,
    [string]$ConfluenceEmail = $env:CONFLUENCE_USER_EMAIL,
    [string]$ConfluenceToken = $env:CONFLUENCE_API_TOKEN,
    [string]$ConfluenceSpaceKey = $env:CONFLUENCE_SPACE_KEY,
    [string]$PreCommitFileUrl = $env:PRE_COMMIT_FILE_URL,
    
    [string]$PreCommitFolder = ".kiro/pre-commit",
    [string]$PreCommitFile = "pre-commit-errors.md"
)

$ErrorActionPreference = 'Continue'

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Pre-Commit Error Handler with Confluence" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Error Code: $ErrorCode" -ForegroundColor Yellow
Write-Host "Service: $ServiceName" -ForegroundColor Yellow
Write-Host ""

# Load Confluence functions FIRST
$scriptPath = Join-Path $PSScriptRoot "confluence-sync.ps1"
if (Test-Path $scriptPath) {
    Write-Host "Loading Confluence functions from: $scriptPath" -ForegroundColor Cyan
    . $scriptPath
    Write-Host "Confluence functions loaded successfully" -ForegroundColor Green
} else {
    Write-Host "ERROR: Confluence sync script not found at: $scriptPath" -ForegroundColor Red
    exit 1
}

# Function to generate detailed Kiro suggestions based on error code
function Get-KiroSuggestionForError {
    param(
        [string]$ErrorCode,
        [string]$ErrorMessage
    )
    
    switch ($ErrorCode) {
        "CS0161" {
            return @"
**Root Cause**: A non-void method is missing a return statement for one or more code paths.

**Quick Fix**: Add a return statement for all code paths.

**Code Example**:

BEFORE (broken):
``````csharp
public async Task<IActionResult> GetById(int id)
{
    var allData = await _fileLoaderService.GetAllDataAsync();
    var data = allData.FirstOrDefault(d => d.Id == id);

    if (data == null)
    {
        return NotFound(new { message = `$"Data record with ID {id} not found" });
    }
    // ❌ Missing return statement!
}
``````

AFTER (fixed):
``````csharp
public async Task<IActionResult> GetById(int id)
{
    var allData = await _fileLoaderService.GetAllDataAsync();
    var data = allData.FirstOrDefault(d => d.Id == id);

    if (data == null)
    {
        return NotFound(new { message = `$"Data record with ID {id} not found" });
    }
    
    return Ok(data);  // ✅ Added this line
}
``````

**Prevention**: Always ensure all code paths return a value. Use `return default(Type);` for empty paths.
"@
        }
        "CS1061" {
            return @"
**Root Cause**: Trying to access a property or method that doesn't exist on a type.

**Quick Fix**: Check the type definition and use the correct member name.

**Code Example**:

BEFORE (broken):
``````csharp
var user = new User();
var name = user.Nmae;  // Typo: should be Name
``````

AFTER (fixed):
``````csharp
var user = new User();
var name = user.Name;
``````

**Prevention**: Use IDE autocomplete, enable nullable reference types, run `dotnet build` before committing.
"@
        }
        "CS0246" {
            return @"
**Root Cause**: Missing using directive or assembly reference.

**Quick Fix**: Add the missing using directive or package reference.

**Code Example**:

BEFORE (broken):
``````csharp
public class MyClass
{
    private ILogger _logger;  // Missing using Microsoft.Extensions.Logging;
}
``````

AFTER (fixed):
``````csharp
using Microsoft.Extensions.Logging;

public class MyClass
{
    private ILogger _logger;
}
``````

**Prevention**: Use IDE suggestions to add missing usings, run `dotnet restore` before building.
"@
        }
        "CS0103" {
            return @"
**Root Cause**: Using a variable, method, or class that hasn't been defined.

**Quick Fix**: Define the identifier or check for typos.

**Code Example**:

BEFORE (broken):
``````csharp
public void MyMethod()
{
    var result = CalculateSum(1, 2);  // CalculateSum doesn't exist
}
``````

AFTER (fixed):
``````csharp
public void MyMethod()
{
    var result = Add(1, 2);  // Fixed method name
}

private int Add(int a, int b)
{
    return a + b;
}
``````

**Prevention**: Use IDE autocomplete, run `dotnet build` before committing.
"@
        }
        default {
            # For unknown error codes, return generic suggestion
            return @"
**Error Code**: $ErrorCode

**Error Message**:
$ErrorMessage

**Quick Fix**: Review the error message and apply the appropriate fix based on the error code.

**Prevention**: Run `dotnet build` locally before committing to catch errors early.

**Next Steps**:
1. Review the error message above
2. Search online for this error code: $ErrorCode
3. Apply the fix and re-run pre-commit checks
4. If this is a recurring error, add it to the hardcoded suggestions in `scripts/pre-commit-confluence-error.ps1`
"@
        }
    }
}

# Validate Confluence config
Write-Host "Validating Confluence configuration..." -ForegroundColor Cyan
if (-not (Test-ConfluenceConfig -BaseUrl $ConfluenceBaseUrl -Email $ConfluenceEmail -Token $ConfluenceToken -SpaceKey $ConfluenceSpaceKey)) {
    Write-Host "ERROR: Confluence configuration is incomplete" -ForegroundColor Red
    Write-Host "Please set the following environment variables:" -ForegroundColor Yellow
    Write-Host "  CONFLUENCE_BASE_URL" -ForegroundColor Gray
    Write-Host "  CONFLUENCE_USER_EMAIL" -ForegroundColor Gray
    Write-Host "  CONFLUENCE_API_TOKEN" -ForegroundColor Gray
    Write-Host "  CONFLUENCE_SPACE_KEY" -ForegroundColor Gray
    exit 1
}

# Validate service name
if (-not $ServiceName) {
    Write-Host "ERROR: SERVICE_NAME environment variable not set" -ForegroundColor Red
    exit 1
}

# Extract page ID from PRE_COMMIT_FILE_URL
$pageId = $null
if ($PreCommitFileUrl) {
    # URL format: https://nileshf.atlassian.net/wiki/pages/viewpage.action?pageId=11599873
    # Extract the numeric page ID
    if ($PreCommitFileUrl -match 'pageId=(\d+)') {
        $pageId = $matches[1]
        Write-Host "Extracted page ID from URL: $pageId" -ForegroundColor Green
    } else {
        Write-Host "WARNING: Could not extract page ID from PRE_COMMIT_FILE_URL: $PreCommitFileUrl" -ForegroundColor Yellow
    }
}

# Search Confluence for similar error
Write-Host ""
Write-Host "Searching Confluence for error code: $ErrorCode" -ForegroundColor Cyan
$confluenceErrorInfo = ""
if ($pageId) {
    # Get the Confluence page content
    $headers = Get-ConfluenceHeaders -Email $ConfluenceEmail -Token $ConfluenceToken
    $uri = "$ConfluenceBaseUrl/wiki/rest/api/content/$pageId`?expand=body.storage"
    
    try {
        $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
        $pageContent = $response.body.storage.value
        
        # Search for error code in page content
        if ($pageContent -match "Error: $ErrorCode|$ErrorCode") {
            Write-Host "Found similar error in Confluence!" -ForegroundColor Green
            $confluenceErrorInfo = "**Found in Confluence**: $PreCommitFileUrl`n`n"
        } else {
            Write-Host "Error code not found in Confluence (will be added)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "WARNING: Could not fetch Confluence page: $_" -ForegroundColor Yellow
    }
}

# Generate detailed Kiro suggestion based on error code
$detailedSuggestion = Get-KiroSuggestionForError -ErrorCode $ErrorCode -ErrorMessage $ErrorMessage

# Prepare error content for local file and Confluence
$errorTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$errorContent = @"
## Error: $ErrorCode
**Timestamp**: $errorTimestamp
**Service**: $ServiceName

**Error Message**:
```
$ErrorMessage
```

$confluenceErrorInfo

**Kiro's Suggested Fix**:

$detailedSuggestion

---

"@

# STEP 1: Update local pre-commit file (append all errors)
Write-Host ""
Write-Host "Updating local pre-commit file..." -ForegroundColor Cyan

# Create pre-commit folder if it doesn't exist
$preCommitPath = Join-Path (Get-Location) $PreCommitFolder
if (-not (Test-Path $preCommitPath)) {
    New-Item -ItemType Directory -Path $preCommitPath | Out-Null
}

$localFilePath = Join-Path $preCommitPath $PreCommitFile

# Always append error to file (main script clears it at start of each service)
Add-Content -Path $localFilePath -Value $errorContent -Encoding UTF8
Write-Host "Error appended to local pre-commit file: $localFilePath" -ForegroundColor Green

# STEP 2: Update or Append to Confluence
if ($pageId) {
    Write-Host ""
    Write-Host "Updating Confluence page..." -ForegroundColor Cyan
    
    # Get current page content
    $headers = Get-ConfluenceHeaders -Email $ConfluenceEmail -Token $ConfluenceToken
    $uri = "$ConfluenceBaseUrl/wiki/rest/api/content/$pageId`?expand=body.storage,version"
    
    try {
        $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
        $currentContent = $response.body.storage.value
        $versionNumber = $response.version.number
        
        # Check if error already exists in the page
        $errorPattern = "### Error: $ErrorCode"
        if ($currentContent -match [regex]::Escape($errorPattern)) {
            Write-Host "Error $ErrorCode already exists on page. Updating..." -ForegroundColor Yellow
            
            # Replace the existing error section
            $errorSectionPattern = "### Error: $ErrorCode.*?(?=### Error:|$)"
            $newErrorSection = @"
### Error: $ErrorCode
**Timestamp**: $errorTimestamp
**Service**: $ServiceName

**Error Message**:
```
$ErrorMessage
```

**Kiro's Suggested Fix**:

$detailedSuggestion

"@
            
            $updatedContent = $currentContent -replace $errorSectionPattern, $newErrorSection
            
            # Update the page
            $result = Update-ConfluencePage -PageId $pageId -Title $response.title -Content $updatedContent -VersionNumber $versionNumber -BaseUrl $ConfluenceBaseUrl -Email $ConfluenceEmail -Token $ConfluenceToken
            
            if ($result) {
                Write-Host "Successfully updated error on Confluence page" -ForegroundColor Green
                Write-Host "Page URL: $PreCommitFileUrl" -ForegroundColor Cyan
            } else {
                Write-Host "ERROR: Failed to update Confluence page" -ForegroundColor Red
                exit 1
            }
        } else {
            Write-Host "Error $ErrorCode not found on page. Appending..." -ForegroundColor Yellow
            
            # Prepare Confluence content
            $confluenceContent = @"
### Error: $ErrorCode
**Timestamp**: $errorTimestamp
**Service**: $ServiceName

**Error Message**:
```
$ErrorMessage
```

**Kiro's Suggested Fix**:

$detailedSuggestion

"@
            
            # Append to existing page
            $result = Append-ConfluencePage -PageId $pageId -ContentToAdd $confluenceContent -BaseUrl $ConfluenceBaseUrl -Email $ConfluenceEmail -Token $ConfluenceToken
            
            if ($result) {
                Write-Host "Successfully appended error to Confluence page" -ForegroundColor Green
                Write-Host "Page URL: $PreCommitFileUrl" -ForegroundColor Cyan
            } else {
                Write-Host "ERROR: Failed to append to Confluence page" -ForegroundColor Red
                exit 1
            }
        }
    } catch {
        Write-Host "ERROR: Failed to check/update Confluence page: $_" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host ""
    Write-Host "WARNING: No Confluence page ID found. Error logged locally only." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Pre-Commit Error Handling Complete" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "✅ Local file cleared and updated: $localFilePath" -ForegroundColor Green
if ($pageId) {
    Write-Host "✅ Error appended to Confluence: $PreCommitFileUrl" -ForegroundColor Green
}
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Review the error details above" -ForegroundColor Gray
Write-Host "2. Apply the suggested fix" -ForegroundColor Gray
Write-Host "3. Re-run pre-commit checks" -ForegroundColor Gray
Write-Host ""

exit 0
