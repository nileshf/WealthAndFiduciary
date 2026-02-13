# Update Pre-Commit Failure Post-Mortem
# Usage: .\update-pre-commit-failure.ps1 -ErrorCode CS0161 -FilePath "path/to/file.cs" -Line 148 -ErrorMessage "error message" -Fix "fix description"

param(
    [Parameter(Mandatory=$true)]
    [ValidatePattern('^CS\d+$')]
    [string]$ErrorCode,
    
    [Parameter(Mandatory=$true)]
    [string]$FilePath,
    
    [Parameter(Mandatory=$true)]
    [string]$Line,
    
    [Parameter(Mandatory=$true)]
    [string]$ErrorMessage,
    
    [Parameter(Mandatory=$true)]
    [string]$Fix
)

# File paths
$failureFile = "docs/pre-commit/pre-commit-failure.md"
$localErrorDb = ".kiro/post-mortems/confluence-pre-commit-errors.md"

# Get current date
$today = Get-Date -Format "yyyy-MM-dd"

# Read existing failure file content
if (Test-Path $failureFile) {
    $failureContent = Get-Content $failureFile -Raw
} else {
    $failureContent = $null
}

# Check if this error type already exists in the file
$existingSection = $false
if ($failureContent) {
    $pattern = "## $ErrorCode - [^\n]+"
    if ($failureContent -match $pattern) {
        $existingSection = $true
    }
}

# Count existing occurrences for this error type
$occurrenceCount = 0
if ($failureContent) {
    $occurrenceCount = ($failureContent -split "### Occurrence #").Count - 1
}

# Create new occurrence entry
$newOccurrence = @"
### Occurrence #$($occurrenceCount + 1)

**Date**: $today
**File**: `$FilePath`
**Line**: $Line
**Error Message**: `$ErrorMessage`
**Status**: Resolved

**Root Cause**: The error occurred due to a code issue in the specified file.

**Fix Applied**:
```csharp
// BEFORE (broken):
[Original broken code]

// AFTER (fixed):
$Fix
```

**Resolution Date**: $today

---

"@

# Update failure file
if ($existingSection) {
    # Append new occurrence to existing error section
    $failureContent = $failureContent -replace "(## $ErrorCode - [^\n]+\n\n)(.*?)(---\n\n)", "`$1`$2$newOccurrence"
    Set-Content -Path $failureFile -Value $failureContent -NoNewline
} else {
    # Create new error section
    $newSection = @"
## $ErrorCode - Not all code paths return a value

$newOccurrence
"@
    if ($failureContent) {
        $failureContent = $failureContent + $newSection
    } else {
        $failureContent = $newSection
    }
    Set-Content -Path $failureFile -Value $failureContent -NoNewline
}

# Update local error database
if (Test-Path $localErrorDb) {
    $dbContent = Get-Content $localErrorDb -Raw
} else {
    $dbContent = $null
}

# Check if error already exists in database
$dbPattern = "## $ErrorCode - [^\n]+"
$dbHasError = $false
if ($dbContent) {
    if ($dbContent -match $dbPattern) {
        $dbHasError = $true
    }
}

if (-not $dbHasError) {
    # Add new error entry to database
    $newDbEntry = @"
## $ErrorCode - Not all code paths return a value

**Error Message**: `$ErrorMessage`

**Root Cause**: A non-void method is missing a return statement for one or more code paths.

**Quick Fix**: Add a return statement for all code paths.

**Code Example**:

```csharp
// BEFORE (broken):
public string GetName()
{
    if (condition)
    {
        return "value";
    }
    // Missing return for else case
}

// AFTER (fixed):
public string GetName()
{
    if (condition)
    {
        return "value";
    }
    return "default";
}
```

**Prevention**: Always ensure all code paths return a value. Use `return default(Type);` for empty paths.

---

"@
    if ($dbContent) {
        $dbContent = $dbContent + $newDbEntry
    } else {
        $dbContent = $newDbEntry
    }
    Set-Content -Path $localErrorDb -Value $dbContent -NoNewline
}

Write-Host "========================================" -ForegroundColor Green
Write-Host "Pre-Commit Failure Updated" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Error Code: $ErrorCode" -ForegroundColor White
Write-Host "File: $FilePath" -ForegroundColor White
Write-Host "Line: $Line" -ForegroundColor White
Write-Host "Date: $today" -ForegroundColor White
Write-Host ""
Write-Host "Updated Files:" -ForegroundColor Cyan
Write-Host "  - $failureFile" -ForegroundColor White
Write-Host "  - $localErrorDb" -ForegroundColor White
Write-Host ""
