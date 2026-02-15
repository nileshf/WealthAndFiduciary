# Pre-Commit Build Errors - Confluence Reference

This page contains common pre-commit build errors and their fixes.

## CS0161 - Not all code paths return a value

**Error Message**: `'MethodName': not all code paths return a value`

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

## CS1061 - 'Type' does not contain a definition for 'Member'

**Error Message**: `'Type' does not contain a definition for 'Member'`

**Root Cause**: Trying to access a property or method that doesn't exist on a type.

**Quick Fix**: Check the type definition and use the correct member name.

**Code Example**:

```csharp
// BEFORE (broken):
var user = new User();
var name = user.Nmae;  // Typo: should be Name

// AFTER (fixed):
var user = new User();
var name = user.Name;
```

**Prevention**: Use IDE autocomplete, enable nullable reference types, run `dotnet build` before committing.

---

## CS0246 - The type or namespace name 'Type' could not be found

**Error Message**: `The type or namespace name 'Type' could not be found`

**Root Cause**: Missing using directive or assembly reference.

**Quick Fix**: Add the missing using directive or package reference.

**Code Example**:

```csharp
// BEFORE (broken):
public class MyClass
{
    private ILogger _logger;  // Missing using Microsoft.Extensions.Logging;
}

// AFTER (fixed):
using Microsoft.Extensions.Logging;

public class MyClass
{
    private ILogger _logger;
}
```

**Prevention**: Use IDE suggestions to add missing usings, run `dotnet restore` before building.

---

## CS0103 - The name 'Identifier' does not exist in the current context

**Error Message**: `The name 'Identifier' does not exist in the current context`

**Root Cause**: Using a variable, method, or class that hasn't been defined.

**Quick Fix**: Define the identifier or check for typos.

**Code Example**:

```csharp
// BEFORE (broken):
public void MyMethod()
{
    var result = CalculateSum(1, 2);  // CalculateSum doesn't exist
}

// AFTER (fixed):
public void MyMethod()
{
    var result = Add(1, 2);  // Fixed method name
}

private int Add(int a, int b)
{
    return a + b;
}
```

**Prevention**: Use IDE autocomplete, run `dotnet build` before committing.

---

## How to Use This Page

1. **See an error?** Copy the error message
2. **Search Confluence**: Use the error code as the search term
3. **Find the fix**: Look for the matching error pattern
4. **Apply the fix**: Follow the code example
5. **Commit again**: Run `git commit` after fixing

---

## Adding New Errors

When you encounter a new pre-commit error:

1. Create a new entry in this document
2. Include: error message, root cause, fix, code example
3. Update the pre-commit hook to reference this page
4. Add to the `.kiro/post-mortems/` folder for history

## Confluence Page

**URL**: https://nileshf.atlassian.net/wiki/spaces/WEALTHFID/pages/9175041

**Search Pattern**: `[Error Code] Pre-Commit`

When you see a pre-commit build error, search Confluence for the error code to find similar issues and their fixes.

## Confluence Page

**URL**: https://nileshf.atlassian.net/wiki/spaces/WEALTHFID/pages/9175041

**Search Pattern**: `[Error Code] Pre-Commit`

When you see a pre-commit build error, search Confluence for the error code to find similar issues and their fixes.

## How It Works

1. **Pre-commit fails** → Kiro searches Confluence for similar errors
2. **If similar error found** → Kiro shows developer: Confluence page + suggested fix
3. **After fix** → Kiro automatically updates Confluence page and error database
4. **Developer gets notification** with all details
**Prevention**: Use IDE autocomplete, run `dotnet build` before committing.

---

## Updated: 2026-02-13 - CS0161 Post-Mortem

### Error Pattern: CS0161 - Not all code paths return a value

**Error Message**: `'DataController.GetById(int)': not all code paths return a value`

**File**: `Applications/AITooling/Services/DataLoaderService/API/DataController.cs`

**Line**: ~148

**Root Cause**: The `GetById` method was missing a return statement for the success case.

**Fix Applied**:
```csharp
// BEFORE:
if (data == null)
{
    return NotFound(new { message = $"Data record with ID {id} not found" });
}
// Missing return statement!

// AFTER:
if (data == null)
{
    return NotFound(new { message = $"Data record with ID {id} not found" });
}

return Ok(data);  // ← Added this line
```

**Confluence Page**: https://nileshf.atlassian.net/wiki/spaces/WEALTHFID/pages/9175041

**Search Pattern**: `CS0161 Pre-Commit`

**Incident Date**: 2026-02-13

**Status**: Resolved

**Post-Mortem**: `.kiro/post-mortems/pre-commit-failure-2026-02-13.md`

---

## How to Use This Page

1. **See an error?** Copy the error message
2. **Search Confluence**: Use the error code as the search term
3. **Find the fix**: Look for the matching error pattern
4. **Apply the fix**: Follow the code example
5. **Commit again**: Run `git commit` after fixing

---

## Adding New Errors

When you encounter a new pre-commit error:

1. Create a new entry in this document
2. Include: error message, root cause, fix, code example
3. Update the pre-commit hook to reference this page
4. Add to the `.kiro/post-mortems/` folder for history

---

## Confluence Page

**URL**: https://nileshf.atlassian.net/wiki/spaces/WEALTHFID/pages/9175041

**Search Pattern**: `[Error Code] Pre-Commit`

When you see a pre-commit build error, search Confluence for the error code to find similar issues and their fixes.

---

## How It Works

1. **Pre-commit fails** → Kiro searches Confluence for similar errors
2. **If similar error found** → Kiro shows developer: Confluence page + suggested fix
3. **After fix** → Kiro automatically updates Confluence page and error database
4. **Developer gets notification** with all details