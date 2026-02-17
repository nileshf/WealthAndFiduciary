# Pre-Commit Errors Log
# Last Updated: 2026-02-17 15:36:10
# Service: DataLoaderService

## Error: CS0161
**Timestamp**: 2026-02-17 15:36:18
**Service**: DataLoaderService

**Error Message**:
`
'DataController.GetById(int)': not all code paths return a value [C:\AIDemo\WealthAndFiduciary\Applications\AITooling\Services\DataLoaderService\DataLoaderService.csproj]
`

**Found in Confluence**: https://nileshf.atlassian.net/wiki/pages/viewpage.action?pageId=9175041



**Kiro's Suggested Fix**:

**Root Cause**: A non-void method is missing a return statement for one or more code paths.

**Quick Fix**: Add a return statement for all code paths.

**Code Example**:

BEFORE (broken):
```csharp
public async Task<IActionResult> GetById(int id)
{
    var allData = await _fileLoaderService.GetAllDataAsync();
    var data = allData.FirstOrDefault(d => d.Id == id);

    if (data == null)
    {
        return NotFound(new { message = $"Data record with ID {id} not found" });
    }
    // âŒ Missing return statement!
}
```

AFTER (fixed):
```csharp
public async Task<IActionResult> GetById(int id)
{
    var allData = await _fileLoaderService.GetAllDataAsync();
    var data = allData.FirstOrDefault(d => d.Id == id);

    if (data == null)
    {
        return NotFound(new { message = $"Data record with ID {id} not found" });
    }
    
    return Ok(data);  // âœ… Added this line
}
```

**Prevention**: Always ensure all code paths return a value. Use eturn default(Type); for empty paths.

---

## Error: CS1061
**Timestamp**: 2026-02-17 15:36:22
**Service**: DataLoaderService

**Error Message**:
`
'IEnumerable<DataRecord>' does not contain a definition for 'NonExistentMethod' and no accessible extension method 'NonExistentMethod' accepting a first argument of type 'IEnumerable<DataRecord>' could be found (are you missing a using directive or an assembly reference?) [C:\AIDemo\WealthAndFiduciary\Applications\AITooling\Services\DataLoaderService\DataLoaderService.csproj]
`

**Found in Confluence**: https://nileshf.atlassian.net/wiki/pages/viewpage.action?pageId=9175041



**Kiro's Suggested Fix**:

**Root Cause**: Trying to access a property or method that doesn't exist on a type.

**Quick Fix**: Check the type definition and use the correct member name.

**Code Example**:

BEFORE (broken):
```csharp
var user = new User();
var name = user.Nmae;  // Typo: should be Name
```

AFTER (fixed):
```csharp
var user = new User();
var name = user.Name;
```

**Prevention**: Use IDE autocomplete, enable nullable reference types, run dotnet build before committing.

---

