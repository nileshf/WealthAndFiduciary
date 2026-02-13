# Pre-Commit Hook Workflow

## Overview

The pre-commit hook automatically runs checks before every git commit to ensure code quality and prevent broken code from being committed.

## How It Works

```
Developer makes changes
         ↓
    git commit
         ↓
  Pre-commit hook runs:
  1. dotnet format (linting)
  2. dotnet build (compilation)
  3. dotnet test (unit tests)
  4. OpenAPI diff check
         ↓
    If all pass → Commit succeeds
         ↓
    If any fail → Error message + Confluence search
```

## Error Handling

When a build error occurs, the hook:

1. **Extracts the error code** (e.g., CS0161)
2. **Searches Confluence** for similar errors
3. **Shows the developer**:
   - Confluence page link
   - Error code and search pattern
   - Local error database path
   - PowerShell script to search automatically

## Confluence Integration

### Confluence Page
**URL**: https://nileshf.atlassian.net/wiki/spaces/WEALTHFID/pages/9175041

### Search Pattern
`[Error Code] Pre-Commit` (e.g., `CS0161 Pre-Commit`)

### Error Patterns

| Error Code | Description | Fix |
|------------|-------------|-----|
| CS0161 | Not all code paths return a value | Add return statement |
| CS1061 | Type does not contain definition | Use correct member name |
| CS0246 | Type or namespace not found | Add using directive |
| CS0103 | Name does not exist | Define identifier |

## PowerShell Script

Use the PowerShell script to search Confluence automatically:

```powershell
.\.kiro\scripts\search-confluence-error.ps1 -ErrorCode CS0161
```

This script:
- Searches Confluence for the error
- Shows the matching section
- Provides the suggested fix
- Shows the code example

## Local Error Database

**File**: `.kiro/post-mortems/confluence-pre-commit-errors.md`

Contains:
- Error patterns with fixes
- Post-mortem details
- Code examples
- Prevention tips

## Workflow Example

### Scenario: Missing Return Statement

1. **Developer makes a change**:
```csharp
public async Task<IActionResult> GetById(int id)
{
    var data = await _service.GetDataAsync();
    
    if (data == null)
    {
        return NotFound();
    }
    // Missing return statement!
}
```

2. **Pre-commit hook runs**:
```
❌ DataLoaderService build failed

🔍 Searching Confluence for similar errors...
   Confluence Page: https://nileshf.atlassian.net/wiki/spaces/WEALTHFID/pages/9175041

   Error Code: CS0161

   Search Pattern: CS0161 Pre-Commit

   Local Error Database: .kiro/post-mortems/confluence-pre-commit-errors.md

   To search Confluence automatically, run:
   powershell -ExecutionPolicy Bypass -File .kiro/scripts/search-confluence-error.ps1 -ErrorCode CS0161
```

3. **Developer runs PowerShell script**:
```powershell
.\.kiro\scripts\search-confluence-error.ps1 -ErrorCode CS0161
```

4. **Script shows the fix**:
```
🔍 Searching Confluence for error: CS0161
========================================

Confluence Page: https://nileshf.atlassian.net/wiki/spaces/WEALTHFID/pages/9175041
Search Pattern: CS0161 Pre-Commit

Found matching error in local database:

## CS0161 - Not all code paths return a value

**Error Message**: `'MethodName': not all code paths return a value`

**Root Cause**: A non-void method is missing a return statement

**Quick Fix**: Add a return statement for all code paths.

**Code Example**:

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

5. **Developer applies the fix**:
```csharp
public async Task<IActionResult> GetById(int id)
{
    var data = await _service.GetDataAsync();
    
    if (data == null)
    {
        return NotFound();
    }

    return Ok(data);  // ← Added this line
}
```

6. **Pre-commit hook passes**:
```
✅ All pre-commit checks passed!
```

## Skipping the Hook

To skip the pre-commit hook (not recommended):

```bash
git commit --no-verify
```

## Troubleshooting

### Hook not running
- Check if `.git/hooks/pre-commit` exists
- Ensure it has execute permissions
- Check if git is installed

### PowerShell script not found
- Ensure the script is at `.kiro/scripts/search-confluence-error.ps1`
- Check execution policy: `Get-ExecutionPolicy`
- Run with: `powershell -ExecutionPolicy Bypass -File .kiro/scripts/search-confluence-error.ps1`

### Confluence page not accessible
- Check internet connection
- Verify Confluence URL: https://nileshf.atlassian.net/wiki/spaces/WEALTHFID/pages/9175041
- Check local error database instead: `.kiro/post-mortems/confluence-pre-commit-errors.md`

## Files

| File | Purpose |
|------|---------|
| `.git/hooks/pre-commit` | Pre-commit hook script |
| `.kiro/scripts/search-confluence-error.ps1` | PowerShell script to search Confluence |
| `.kiro/post-mortems/confluence-pre-commit-errors.md` | Local error database |
| `.kiro/post-mortems/pre-commit-failure-2026-02-13.md` | Post-mortem for CS0161 error |
| `.kiro/templates/confluence-pre-commit-page.md` | Template for Confluence pages |
| `.kiro/hooks/pre-commit-error-handler.json` | Kiro hook for automatic Confluence search |

---

**Last Updated**: 2026-02-13
**Maintained By**: AITooling Team