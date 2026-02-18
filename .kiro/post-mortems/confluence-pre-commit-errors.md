# Pre-Commit Build Errors Database

> **Purpose**: Local database of pre-commit build errors with solutions
> **Last Updated**: 2026-02-18
> **Scope**: All microservices in WealthAndFiduciary
> **Confluence Link**: https://nileshf.atlassian.net/wiki/spaces/WEALTHFID/pages/9175041

## Error Categories

### CS0103 - Name Does Not Exist in Current Context

**Description**: Using a variable, method, class, or namespace that hasn't been defined or is out of scope.

**Common Causes**:
- Typo in variable/method name
- Missing using statement
- Variable declared in wrong scope
- Method not defined in class
- Namespace not imported

**Quick Fix**:
1. Check for typos in the identifier name
2. Verify the identifier is declared before use
3. Add missing `using` statements
4. Check variable scope (local, class, namespace)

**Code Example**:

BEFORE (broken):
```csharp
public void MyMethod()
{
    var result = CalculateSum(1, 2);  // CalculateSum doesn't exist
    Console.WriteLine(undefinedVariable);  // undefinedVariable not defined
}
```

AFTER (fixed):
```csharp
public void MyMethod()
{
    var result = Add(1, 2);  // Fixed method name
    var myVariable = 42;
    Console.WriteLine(myVariable);  // Now defined
}

private int Add(int a, int b)
{
    return a + b;
}
```

**Prevention**:
- Use IDE autocomplete (IntelliSense)
- Run `dotnet build` before committing
- Enable compiler warnings in IDE
- Use code analysis tools (Roslyn analyzers)

**Related Issues**:
- SecurityService: CS0103 in AuthController.cs (FIXED)
- DataLoaderService: CS1061 in DataController.cs (FIXED)

---

### CS0161 - Not All Code Paths Return a Value

**Description**: A method that should return a value has at least one code path that doesn't return anything.

**Common Causes**:
- Missing `return` statement in conditional branch
- Exception not thrown in error case
- Unreachable code after conditional
- Missing `else` clause

**Quick Fix**:
1. Identify all code paths in the method
2. Ensure each path returns a value or throws an exception
3. Add missing `return` statements
4. Consider using `throw` for error cases

**Code Example**:

BEFORE (broken):
```csharp
public string GetStatus(bool isActive)
{
    if (isActive)
    {
        return "Active";
    }
    // Missing return for false case!
}
```

AFTER (fixed):
```csharp
public string GetStatus(bool isActive)
{
    if (isActive)
    {
        return "Active";
    }
    return "Inactive";  // All paths now return
}

// OR with exception:
public string GetStatus(bool? isActive)
{
    return isActive switch
    {
        true => "Active",
        false => "Inactive",
        null => throw new ArgumentNullException(nameof(isActive))
    };
}
```

**Prevention**:
- Use switch expressions (C# 8+) for exhaustive checks
- Enable compiler warnings
- Use code analysis tools
- Write unit tests for all code paths

**Related Issues**:
- SecurityService: CS0161 in AuthController.cs (SIMULATED)
- DataLoaderService: CS0161 in DataController.cs (FIXED)

---

### CS1061 - Type Does Not Contain Definition

**Description**: Calling a method or accessing a property that doesn't exist on the type.

**Common Causes**:
- Method name typo
- Method doesn't exist on the type
- Missing using statement for extension methods
- Accessing private/internal member from outside
- Wrong object type

**Quick Fix**:
1. Check method name spelling
2. Verify method exists on the type
3. Add missing `using` statements for extension methods
4. Check access modifiers (public, private, internal)

**Code Example**:

BEFORE (broken):
```csharp
public void ProcessData()
{
    var data = new List<string>();
    data.NonExistentMethod();  // Method doesn't exist
    var count = data.Lenght;   // Typo: should be Length
}
```

AFTER (fixed):
```csharp
public void ProcessData()
{
    var data = new List<string>();
    data.Add("item");  // Correct method
    var count = data.Count;  // Correct property
}
```

**Prevention**:
- Use IDE autocomplete
- Run `dotnet build` before committing
- Enable IntelliSense in your editor
- Use code analysis tools

**Related Issues**:
- DataLoaderService: CS1061 in DataController.cs (FIXED)

---

## Error Resolution Workflow

When a pre-commit error occurs:

1. **Identify Error Code**: Look at the error message (e.g., CS0103, CS0161)
2. **Search This Database**: Find the error category above
3. **Review Quick Fix**: Follow the suggested fix steps
4. **Check Code Example**: Compare your code to the before/after example
5. **Apply Fix**: Make the necessary code changes
6. **Verify**: Run `dotnet build` to confirm the fix
7. **Commit**: Once fixed, proceed with commit

## Confluence Integration

All errors are documented in Confluence at:
https://nileshf.atlassian.net/wiki/spaces/WEALTHFID/pages/9175041

**To add a new error**:
1. Document the error here in this file
2. Create a Confluence page with the same information
3. Link the Confluence page in this file
4. Share the link with the team

## Statistics

- **Total Errors Tracked**: 3
- **Errors Fixed**: 2
- **Errors Simulated**: 1
- **Last Error**: 2026-02-18 (CS0161 - SecurityService)

---

**Maintained By**: Kiro AI Assistant
**Last Updated**: 2026-02-18
**Next Review**: 2026-02-25
